import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/baby_tracker/patient_recall_controller.dart';
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

/// Next-Trimester Clinical Scan Recall & Follow-Up Reminders (#5).
class TrimesterRecallPage extends StatefulWidget {
  static const routeName = RouteNames.trimesterRecalls;
  static const displayName = RouteNames.trimesterRecallsDisplay;

  const TrimesterRecallPage({super.key});

  @override
  State<TrimesterRecallPage> createState() => _TrimesterRecallPageState();
}

class _TrimesterRecallPageState extends State<TrimesterRecallPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _milestone = 'all';
  bool _onlyUnbooked = true;
  String? _selectedBranchId;
  List<branch_model.Data> _branches = [];
  bool _loading = true;
  String? _error;
  PatientRecallResponse? _data;
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
    final res = await PatientRecallController.fetch(
      context,
      branchId: _selectedBranchId,
      milestone: _milestone,
      onlyUnbooked: _onlyUnbooked,
    );
    if (!mounted) return;
    if (responseCode(res.code) && res.data != null) {
      setState(() {
        _data = res.data;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load recall reminders.';
        _loading = false;
      });
    }
  }

  Future<void> _send(PatientRecallItem item, String channel) async {
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
      AppToast.snackbar(
        context,
        'Recall logged for ${item.patientName} ($channel).',
      );
      _fetch();
    } else {
      AppToast.snackbar(context, res.message ?? 'Failed to send recall.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = context.read<AuthController>();
    final isNarrow = MediaQuery.sizeOf(context).width < 900;
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = (_data?.items ?? []).where((item) {
      if (q.isEmpty) return true;
      return item.patientName.toLowerCase().contains(q) ||
          item.patientPhone.toLowerCase().contains(q) ||
          item.recommendedScan.toLowerCase().contains(q) ||
          item.branchName.toLowerCase().contains(q);
    }).toList();

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
                      'Next-Trimester Scan Recalls',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Proactively follow up expectant mothers entering NT, Detail, 4D/5D, and Growth scan windows with anti-duplicate tracking.',
                      style: TextStyle(fontSize: 13, color: colors.inkMuted),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
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

            // ── KPI + Milestone Filters ──────────────────────────────────
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
                                ? '${tab.$2} (${_data?.totalEligible ?? 0})'
                                : '${tab.$2} (${_data?.byMilestone[tab.$1] ?? 0})',
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
                            'Unbooked only (${_data?.unbookedCount ?? 0})',
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
                          'Pending Outreach: ${_data?.pendingOutreachCount ?? 0}',
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
                          'Recalled: ${_data?.alreadyRecalledCount ?? 0}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.success),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Recall List ──────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: colors.danger)))
                      : filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No expectant mothers due in this milestone filter.',
                                style: TextStyle(color: colors.inkMuted, fontSize: 14),
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, idx) => _recallCard(context, filtered[idx]),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recallCard(BuildContext context, PatientRecallItem item) {
    final colors = context.appColors;
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
                onPressed: sending ? null : () => _send(item, 'push'),
              ),
              AppButton.primary(
                text: item.alreadyRecalled ? 'Follow Up (WA + Push)' : 'Send WA + Push',
                height: 36,
                isLoading: sending,
                icon: const Icon(Icons.send_rounded, size: 15),
                onPressed: sending ? null : () => _send(item, 'both'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
