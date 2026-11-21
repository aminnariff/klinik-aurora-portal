import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/baby_tracker/patient_recall_controller.dart';
import 'package:klinik_aurora_portal/controllers/baby_tracker/points_reengagement_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_filter_field.dart';
import 'package:klinik_aurora_portal/views/widgets/launcher/web_launcher.dart';
import 'package:klinik_aurora_portal/views/widgets/patient/patient_quick_drawer.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:provider/provider.dart';

const Color _purpleAccent = Color(0xFF7C3AED);
const Color _purpleSoftBg = Color(0xFFF5F3FF);

enum _RecallTab { scanRecalls, pointsReengagement, milestoneRules }

/// Next-Trimester Clinical Scan Recalls & Loyalty Points Re-Engagement Hub.
class TrimesterRecallPage extends StatefulWidget {
  static const routeName = RouteNames.trimesterRecalls;
  static const displayName = RouteNames.trimesterRecallsDisplay;

  const TrimesterRecallPage({super.key});

  @override
  State<TrimesterRecallPage> createState() => _TrimesterRecallPageState();
}

class _TrimesterRecallPageState extends State<TrimesterRecallPage> {
  _RecallTab _activeTab = _RecallTab.scanRecalls;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _milestone = 'all';
  bool _onlyUnbooked = true;
  String? _selectedBranchId;
  List<branch_model.Data> _branches = [];
  bool _loading = true;
  String? _error;

  PatientRecallResponse? _scanData;
  PointsReengagementResponse? _pointsData;
  final Set<String> _sendingKeys = {};

  static const _milestoneTabs = [
    ('all', 'All Windows'),
    ('nt_scan', 'W11–13 NT'),
    ('detail_scan', 'W18–24 Detail'),
    ('scan_4d5d', 'W26–32 4D/5D'),
    ('growth_scan', 'W33–36 Growth'),
  ];

  @override
  void initState() {
    super.initState();
    PortalSearchFocusBus.register(_searchFocus);
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) return;
      context.read<TopBarController>().pageValue = Homepage.getPageId(TrimesterRecallPage.displayName);
      final auth = context.read<AuthController>();
      if (!auth.isSuperAdmin) {
        _selectedBranchId = auth.authenticationResponse?.data?.user?.branchId;
      } else {
        _loadBranches();
      }
      _fetch();
    });
  }

  @override
  void dispose() {
    PortalSearchFocusBus.unregister(_searchFocus);
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    final res = await BranchController.getAll(context, 1, 100);
    if (!mounted) return;
    if (responseCode(res.code)) {
      setState(() => _branches = res.data?.data ?? []);
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_activeTab == _RecallTab.scanRecalls) {
        final res = await PatientRecallController.fetch(
          context,
          branchId: _selectedBranchId,
          milestone: _milestone,
          onlyUnbooked: _onlyUnbooked,
        );
        if (!mounted) return;
        if (responseCode(res.code) && res.data != null) {
          setState(() {
            _scanData = res.data;
          });
        } else {
          setState(() {
            _error = res.message ?? 'Failed to load recall reminders.';
          });
        }
      } else if (_activeTab == _RecallTab.pointsReengagement) {
        final res = await PointsReengagementController.fetch(
          context,
          branchId: _selectedBranchId,
          minPoints: 50,
          onlyUnbooked: _onlyUnbooked,
        );
        if (!mounted) return;
        if (responseCode(res.code) && res.data != null) {
          setState(() {
            _pointsData = res.data;
          });
        } else {
          setState(() {
            _error = res.message ?? 'Failed to load points re-engagement list.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading follow-up data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendScanRecall(PatientRecallItem item, String channel) async {
    final key = '${item.userId}:${item.milestoneKey}';
    setState(() => _sendingKeys.add(key));
    final res = await PatientRecallController.sendRecall(
      context,
      userId: item.userId,
      branchId: item.branchId,
      milestoneKey: item.milestoneKey,
      gestationalWeek: item.gestationalWeek,
      channel: channel,
      message: item.suggestedMessage,
    );
    if (!mounted) return;
    setState(() => _sendingKeys.remove(key));

    if (responseCode(res.code)) {
      final waUrl = res.data?['data']?['whatsappUrl']?.toString() ?? item.whatsappUrl;
      if ((channel == 'whatsapp' || channel == 'both') && waUrl != null && waUrl.isNotEmpty) {
        launchWebUrl(waUrl, webOnlyWindowName: '_blank');
      }
      AppToast.snackbar(context, 'Recall logged for ${item.patientName} ($channel).');
      _fetch();
    } else {
      AppToast.snackbar(context, res.message ?? 'Failed to send recall.');
    }
  }

  Future<void> _sendPointsOutreach(PointsReengagementItem item) async {
    final key = 'pts:${item.userId}';
    setState(() => _sendingKeys.add(key));

    final res = await PointsReengagementController.sendOutreach(
      context,
      userId: item.userId,
      branchId: item.branchId,
      channel: 'whatsapp',
      message: item.suggestedMessage,
    );
    if (!mounted) return;
    setState(() => _sendingKeys.remove(key));

    if (responseCode(res.code)) {
      final waUrl = res.data?['data']?['whatsappUrl']?.toString() ?? item.whatsappUrl;
      if (waUrl != null && waUrl.isNotEmpty) {
        launchWebUrl(waUrl, webOnlyWindowName: '_blank');
      }
      AppToast.snackbar(context, 'Points offer logged for ${item.patientName}.');
      _fetch();
    } else {
      AppToast.snackbar(context, res.message ?? 'Failed to send points offer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = context.read<AuthController>();
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Padding(
        padding: EdgeInsets.all(isNarrow ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient Follow-Up & Points Loyalty',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Proactively recall expectant mothers for key milestone scans and re-engage patients with unspent points.',
                      style: TextStyle(fontSize: 13, color: colors.inkMuted),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (auth.isSuperAdmin && _branches.isNotEmpty)
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _selectedBranchId,
                            hint: Text('All Branches', style: TextStyle(fontSize: 12, color: colors.inkMuted)),
                            dropdownColor: colors.surfaceElevated,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('All Branches')),
                              for (final b in _branches)
                                DropdownMenuItem<String?>(value: b.branchId, child: Text(b.branchName ?? 'Branch')),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedBranchId = v);
                              _fetch();
                            },
                          ),
                        ),
                      ),
                    AppButton.primary(
                      text: 'Refresh',
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      onPressed: _fetch,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Mode Switcher (Scan Recalls vs Points Re-Engagement vs Milestone Rules)
            Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: _modeTab(
                      tab: _RecallTab.scanRecalls,
                      label: 'Clinical Scan Recalls',
                      icon: Icons.baby_changing_station_rounded,
                      badge: _scanData != null ? '${_scanData!.pendingOutreachCount}' : null,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _modeTab(
                      tab: _RecallTab.pointsReengagement,
                      label: 'Points Re-Engagement',
                      icon: Icons.stars_rounded,
                      badge: _pointsData != null ? '${_pointsData!.uncontactedCount}' : null,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _modeTab(
                      tab: _RecallTab.milestoneRules,
                      label: 'Milestone Bonus Scheme',
                      icon: Icons.military_tech_rounded,
                      colors: colors,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Tab Body Content ──────────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_problem_rounded, size: 44, color: colors.danger),
                              const SizedBox(height: 12),
                              Text(_error!, style: TextStyle(color: colors.danger, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetch,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(backgroundColor: colors.brandPrimary, foregroundColor: Colors.white),
                              ),
                            ],
                          ),
                        )
                      : _activeTab == _RecallTab.scanRecalls
                          ? _buildScanRecallsView(colors, isNarrow)
                          : _activeTab == _RecallTab.pointsReengagement
                              ? _buildPointsReengagementView(colors, isNarrow)
                              : _buildMilestoneRulesView(colors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeTab({
    required _RecallTab tab,
    required String label,
    required IconData icon,
    String? badge,
    required AppColors colors,
  }) {
    final selected = _activeTab == tab;
    return InkWell(
      onTap: () {
        setState(() => _activeTab = tab);
        _fetch();
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? colors.brandSoftBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.brandPrimary : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? colors.brandPrimary : colors.inkMuted),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? colors.brandText : colors.inkSecondary,
                ),
              ),
            ),
            if (badge != null && badge != '0') ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? colors.brandPrimary : colors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : colors.inkMuted,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tab 1: Clinical Scan Recalls ─────────────────────────────────────
  Widget _buildScanRecallsView(AppColors colors, bool isNarrow) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = (_scanData?.items ?? []).where((item) {
      if (q.isEmpty) return true;
      return item.patientName.toLowerCase().contains(q) ||
          item.patientPhone.toLowerCase().contains(q) ||
          item.recommendedScan.toLowerCase().contains(q) ||
          item.branchName.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI + Milestone Filters
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final tab in _milestoneTabs)
                    ChoiceChip(
                      label: Text(
                        tab.$1 == 'all'
                            ? '${tab.$2} (${_scanData?.totalEligible ?? 0})'
                            : '${tab.$2} (${_scanData?.byMilestone[tab.$1] ?? 0})',
                      ),
                      selected: _milestone == tab.$1,
                      onSelected: (_) {
                        setState(() => _milestone = tab.$1);
                        _fetch();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: isNarrow ? double.infinity : 280,
                    child: AppFilterField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      hintText: 'Search mother name or phone... (/)',
                      onChanged: (_) => setState(() {}),
                      onClear: () => setState(() {}),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: _onlyUnbooked,
                        onChanged: (v) {
                          setState(() => _onlyUnbooked = v);
                          _fetch();
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Unbooked only (${_scanData?.unbookedCount ?? 0})',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.brandSoftBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pending Outreach: ${_scanData?.pendingOutreachCount ?? 0}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.brandText),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.successSoftBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Recalled: ${_scanData?.alreadyRecalledCount ?? 0}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.success),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Recall List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No expectant mothers due in this milestone filter.',
                    style: TextStyle(color: colors.inkMuted, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) => _scanRecallCard(colors, filtered[idx]),
                ),
        ),
      ],
    );
  }

  Widget _scanRecallCard(AppColors colors, PatientRecallItem item) {
    final key = '${item.userId}:${item.milestoneKey}';
    final sending = _sendingKeys.contains(key);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.alreadyRecalled ? colors.success.withValues(alpha: 0.35) : colors.border,
        ),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colors.brandPrimary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'W${item.gestationalWeek}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    InkWell(
                      onTap: () => PatientQuickDrawer.show(
                        context,
                        userId: item.userId,
                        patientName: item.patientName,
                      ),
                      child: Text(
                        item.patientName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.brandText,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.brandBorder,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.hasBooked ? colors.successSoftBg : colors.warningSoftBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.hasBooked ? 'Booked' : 'Needs Booking',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.hasBooked ? colors.success : colors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.recommendedScan} · EDD ${item.eddDate} · ${item.branchName} · ${item.patientPhone}',
                  style: TextStyle(fontSize: 12, color: colors.inkSecondary),
                ),
                if (item.alreadyRecalled) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 14, color: colors.success),
                      const SizedBox(width: 5),
                      Text(
                        'Recalled on ${item.lastRecallSentAt ?? ''} via ${item.lastRecallChannel ?? ''} by ${item.lastRecallBy ?? 'Admin'}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.success),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton.secondary(
                text: 'Push Only',
                height: 36,
                isLoading: sending,
                icon: Icon(Icons.notifications_active_outlined, size: 15, color: colors.inkSecondary),
                onPressed: sending ? null : () => _sendScanRecall(item, 'push'),
              ),
              AppButton.primary(
                text: item.alreadyRecalled ? 'Follow Up (WA + Push)' : 'Send WA + Push',
                height: 36,
                isLoading: sending,
                icon: const Icon(Icons.send_rounded, size: 15),
                onPressed: sending ? null : () => _sendScanRecall(item, 'both'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab 2: Points Re-Engagement ──────────────────────────────────────
  Widget _buildPointsReengagementView(AppColors colors, bool isNarrow) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final items = (_pointsData?.items ?? []).where((it) {
      if (q.isEmpty) return true;
      return it.patientName.toLowerCase().contains(q) ||
          it.patientPhone.toLowerCase().contains(q) ||
          it.branchName.toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Strip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isNarrow ? double.infinity : 280,
                child: AppFilterField(
                  controller: _searchCtrl,
                  focusNode: _searchFocus,
                  hintText: 'Search patient by name or phone... (/)',
                  onChanged: (_) => setState(() {}),
                  onClear: () => setState(() {}),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _onlyUnbooked,
                    onChanged: (v) {
                      setState(() => _onlyUnbooked = v);
                      _fetch();
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unbooked patients only',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _purpleSoftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Eligible Members: ${_pointsData?.totalEligible ?? 0}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _purpleAccent),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.brandSoftBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending Outreach: ${_pointsData?.uncontactedCount ?? 0}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.brandText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Member Points Cards List
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text(
                    'No members matching current points filter.',
                    style: TextStyle(color: colors.inkMuted, fontSize: 14),
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) => _pointsReengagementCard(colors, items[idx]),
                ),
        ),
      ],
    );
  }

  Widget _pointsReengagementCard(AppColors colors, PointsReengagementItem item) {
    final key = 'pts:${item.userId}';
    final sending = _sendingKeys.contains(key);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.alreadyContactedRecently ? colors.success.withValues(alpha: 0.35) : colors.border,
        ),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _purpleSoftBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.diamond_outlined, size: 12, color: _purpleAccent),
                          const SizedBox(width: 4),
                          Text(
                            '${item.totalPoints} pts (RM ${item.cashValueRm.toStringAsFixed(2)})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _purpleAccent),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => PatientQuickDrawer.show(
                        context,
                        userId: item.userId,
                        patientName: item.patientName,
                      ),
                      child: Text(
                        item.patientName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.brandText,
                          decoration: TextDecoration.underline,
                          decorationColor: colors.brandBorder,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.hasUpcomingBooking ? colors.successSoftBg : colors.warningSoftBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.hasUpcomingBooking ? 'Booked' : 'No Booking',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.hasUpcomingBooking ? colors.success : colors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.branchName} · ${item.patientPhone}${item.lastVisitDate != null ? ' · Last visit: ${item.lastVisitDate} (${item.daysSinceLastVisit}d ago)' : ''}',
                  style: TextStyle(fontSize: 12, color: colors.inkSecondary),
                ),
                if (item.nextExpiryDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Earliest points expiry: ${item.nextExpiryDate}',
                    style: TextStyle(fontSize: 11, color: colors.warning, fontWeight: FontWeight.w600),
                  ),
                ],
                if (item.alreadyContactedRecently) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 13, color: colors.success),
                      const SizedBox(width: 4),
                      Text(
                        'Outreach sent on ${item.lastOutreachDate}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.success),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          AppButton.primary(
            text: item.alreadyContactedRecently ? 'Follow Up (WhatsApp)' : 'Send Points Offer',
            height: 36,
            isLoading: sending,
            icon: const Icon(Icons.send_rounded, size: 15),
            onPressed: sending ? null : () => _sendPointsOutreach(item),
          ),
        ],
      ),
    );
  }

  // ── Tab 3: Milestone Bonus Scheme Overview ───────────────────────────
  Widget _buildMilestoneRulesView(AppColors colors) {
    final rules = [
      (
        'W11–13',
        'NT & First Trimester Scan',
        '+50 Bonus Pts',
        'Early chromosomal & nuchal translucency risk screening',
        Icons.looks_one_rounded,
        colors.info,
      ),
      (
        'W18–24',
        'Detail Anomaly Screening Scan',
        '+100 Bonus Pts',
        'Comprehensive fetal organ anatomy & structural evaluation',
        Icons.looks_two_rounded,
        colors.brandPrimary,
      ),
      (
        'W26–32',
        '4D/5D HD Live Ultrasound',
        '+100 Bonus Pts',
        'High-definition real-time facial features & emotional bonding scan',
        Icons.looks_3_rounded,
        _purpleAccent,
      ),
      (
        'W33–36',
        'Growth & Position Doppler Scan',
        '+50 Bonus Pts',
        'Late pregnancy fetal biometry, amniotic fluid, and presentation check',
        Icons.looks_4_rounded,
        colors.warning,
      ),
      (
        'Postnatal',
        'Maternal & Newborn Postnatal Check',
        '+50 Bonus Pts',
        '6-week maternal healing, infant wellness, and lactation check',
        Icons.looks_5_rounded,
        colors.success,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.military_tech_rounded, size: 24, color: colors.brandPrimary),
                    const SizedBox(width: 10),
                    Text(
                      'Pregnancy Scan Milestone Loyalty Rewards (Admin Scheme)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'These milestone bonus points are automatically suggested during Front-Desk Counter Checkout when an appointment is completed. They incentivize mothers to complete their full 5-stage clinical pregnancy monitoring journey.',
                  style: TextStyle(fontSize: 13, color: colors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final r = rules[idx];
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: r.$6.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(r.$5, color: r.$6, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: r.$6,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  r.$1,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                r.$2,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(r.$4, style: TextStyle(fontSize: 12, color: colors.inkMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _purpleSoftBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.$3,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _purpleAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
