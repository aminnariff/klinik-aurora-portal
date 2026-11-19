import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_queue_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_filter_field.dart';
import 'package:klinik_aurora_portal/views/widgets/patient/patient_quick_drawer.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:provider/provider.dart';

/// Receptionist Front-Desk Queue & Check-In Board ("Today's Flow") (#1).
class QueueBoardPage extends StatefulWidget {
  static const routeName = RouteNames.queueBoard;
  static const displayName = RouteNames.queueBoardDisplay;

  const QueueBoardPage({super.key});

  @override
  State<QueueBoardPage> createState() => _QueueBoardPageState();
}

class _QueueBoardPageState extends State<QueueBoardPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _autoRefresh;

  DateTime _selectedDate = DateTime.now();
  String? _selectedBranchId;
  List<branch_model.Data> _branches = [];
  bool _loading = true;
  String? _error;
  QueueBoardData? _board;
  final Set<String> _updatingIds = {};

  @override
  void initState() {
    super.initState();
    PortalSearchFocusBus.register(_searchFocus);
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) return;
      context.read<TopBarController>().pageValue = Homepage.getPageId(QueueBoardPage.displayName);
      final auth = context.read<AuthController>();
      if (!auth.isSuperAdmin) {
        _selectedBranchId = auth.authenticationResponse?.data?.user?.branchId;
      } else {
        _loadBranches();
      }
      _fetch();
    });
    _autoRefresh = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) _fetch(silent: true);
    });
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
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

  Future<void> _fetch({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final res = await AppointmentQueueController.fetch(
      context,
      branchId: _selectedBranchId,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
    );
    if (!mounted) return;
    if (responseCode(res.code) && res.data != null) {
      setState(() {
        _board = res.data;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load queue board.';
        _loading = false;
      });
    }
  }

  Future<void> _advance(QueueAppointmentItem item, String nextStatus, {String? roomLabel}) async {
    setState(() => _updatingIds.add(item.appointmentId));
    final res = await AppointmentQueueController.updateStatus(
      context,
      appointmentId: item.appointmentId,
      queueStatus: nextStatus,
      roomLabel: roomLabel,
    );
    if (!mounted) return;
    setState(() => _updatingIds.remove(item.appointmentId));
    if (responseCode(res.code)) {
      AppToast.snackbar(context, '${item.patientName} moved to ${_prettyStage(nextStatus)}');
      _fetch(silent: true);
    } else {
      AppToast.snackbar(context, res.message ?? 'Failed to update status.');
    }
  }

  Future<void> _promptRoomAndMove(QueueAppointmentItem item) async {
    final ctrl = TextEditingController(text: item.roomLabel ?? 'Scan Room 1');
    final room = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colors = ctx.appColors;
        return Dialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.border),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Assign Room / Station',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Moving ${item.patientName} into active scan/consultation.',
                    style: TextStyle(fontSize: 12, color: colors.inkMuted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ctrl,
                    autofocus: true,
                    onSubmitted: (val) => Navigator.of(ctx).pop(val.trim().isNotEmpty ? val.trim() : 'Scan Room 1'),
                    decoration: const InputDecoration(
                      labelText: 'Room Label',
                      hintText: 'e.g. Scan Room 1, Consultation A',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: ['Scan Room 1', 'Scan Room 2', 'Consult Room A', 'Consult Room B']
                        .map(
                          (preset) => ActionChip(
                            label: Text(preset),
                            backgroundColor: colors.surfaceSubtle,
                            onPressed: () => Navigator.of(ctx).pop(preset),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton.secondary(
                        text: 'Cancel',
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                      const SizedBox(width: 8),
                      AppButton.primary(
                        text: 'Move to Room',
                        onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    ctrl.dispose();
    if (room != null && mounted) {
      await _advance(item, 'in_room', roomLabel: room);
    }
  }

  List<QueueAppointmentItem> _filtered(String stage) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return (_board?.items ?? []).where((item) {
      final matchesStage = stage == 'done'
          ? (item.queueStatus == 'completed' || item.queueStatus == 'no_show')
          : item.queueStatus == stage;
      if (!matchesStage) return false;
      if (q.isEmpty) return true;
      return item.patientName.toLowerCase().contains(q) ||
          item.patientPhone.toLowerCase().contains(q) ||
          item.serviceName.toLowerCase().contains(q) ||
          (item.doctorName?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = context.read<AuthController>();
    final isNarrow = MediaQuery.sizeOf(context).width < 960;

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
                      "Today's Flow · Front-Desk Queue",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Check patients in, assign rooms, monitor live wait times, and complete visits in one click.',
                      style: TextStyle(fontSize: 13, color: colors.inkMuted),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Date stepper
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Previous day',
                            onPressed: () {
                              setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
                              _fetch();
                            },
                            icon: Icon(Icons.chevron_left_rounded, size: 20, color: colors.inkSecondary),
                          ),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                                _fetch();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              child: Text(
                                DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Next day',
                            onPressed: () {
                              setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1)));
                              _fetch();
                            },
                            icon: Icon(Icons.chevron_right_rounded, size: 20, color: colors.inkSecondary),
                          ),
                        ],
                      ),
                    ),
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
                                DropdownMenuItem<String?>(
                                  value: b.branchId,
                                  child: Text(b.branchName ?? 'Branch'),
                                ),
                            ],
                            onChanged: (v) {
                              setState(() => _selectedBranchId = v);
                              _fetch();
                            },
                          ),
                        ),
                      ),
                    AppButton.secondary(
                      text: 'Book Walk-In (N)',
                      icon: Icon(Icons.person_add_alt_1_rounded, size: 16, color: colors.inkSecondary),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const AppointmentDetails(type: 'create'),
                      ).then((_) => _fetch(silent: true)),
                    ),
                    AppButton.primary(
                      text: 'Refresh',
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      onPressed: () => _fetch(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── KPI + Search Strip ───────────────────────────────────────
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: isNarrow ? double.infinity : 280,
                  child: AppFilterField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    hintText: 'Filter patient, service, doctor... (/)',
                    onChanged: (_) => setState(() {}),
                    onClear: () => setState(() {}),
                  ),
                ),
                _kpiPill(context, 'Scheduled', '${_board?.scheduled ?? 0}', colors.info),
                _kpiPill(context, 'Checked In', '${_board?.checkedIn ?? 0}', colors.warning),
                _kpiPill(context, 'In Room', '${_board?.inRoom ?? 0}', colors.brandText),
                _kpiPill(context, 'Completed', '${_board?.completed ?? 0}', colors.success),
                _kpiPill(context, 'No-Show', '${_board?.noShow ?? 0}', colors.danger),
                _kpiPill(
                  context,
                  'Avg Wait',
                  '${_board?.avgWaitMinutes ?? 0} min',
                  (_board?.avgWaitMinutes ?? 0) > 20 ? colors.danger : colors.inkSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Kanban Columns ───────────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: colors.danger)))
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = [
                              _column(context, 'Scheduled', 'scheduled', colors.info, Icons.schedule_rounded),
                              _column(context, 'Checked In', 'checked_in', colors.warning, Icons.how_to_reg_rounded),
                              _column(context, 'In Scan / Room', 'in_room', colors.brandText, Icons.medical_services_rounded),
                              _column(context, 'Completed / No-Show', 'done', colors.success, Icons.check_circle_outline_rounded),
                            ];
                            if (constraints.maxWidth >= 1040) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < cols.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 12),
                                    Expanded(child: cols[i]),
                                  ],
                                ],
                              );
                            }
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < cols.length; i++) ...[
                                    if (i > 0) const SizedBox(width: 12),
                                    SizedBox(width: 310, child: cols[i]),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiPill(BuildContext context, String label, String value, Color accent) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(fontSize: 12, color: colors.inkMuted, fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(fontSize: 13, color: accent, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _column(BuildContext context, String title, String stage, Color accent, IconData icon) {
    final colors = context.appColors;
    final items = _filtered(stage);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No patients here',
                      style: TextStyle(fontSize: 12, color: colors.inkMuted),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) => _patientCard(context, items[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(BuildContext context, QueueAppointmentItem item) {
    final colors = context.appColors;
    final busy = _updatingIds.contains(item.appointmentId);
    final isNoShow = item.queueStatus == 'no_show';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNoShow ? colors.danger.withValues(alpha: 0.4) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.brandSoftBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.appointmentTime,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.brandText),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: item.isPaid ? colors.successSoftBg : colors.warningSoftBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isPaid ? 'Paid' : 'Unpaid',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.isPaid ? colors.success : colors.warning,
                  ),
                ),
              ),
              const Spacer(),
              if (item.queueStatus == 'checked_in' && item.waitMinutes > 0)
                Text(
                  '${item.waitMinutes}m wait',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.waitMinutes >= 20 ? colors.danger : colors.warning,
                  ),
                ),
              if (isNoShow)
                Text(
                  'NO-SHOW',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: colors.danger),
                ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: item.userId.isNotEmpty
                ? () => PatientQuickDrawer.show(context, userId: item.userId, patientName: item.patientName)
                : null,
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.patientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.brandText,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.brandBorder,
                    ),
                  ),
                ),
                Icon(Icons.open_in_new_rounded, size: 13, color: colors.inkMuted),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.serviceName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.doctorName ?? 'Unassigned'}${item.roomLabel != null && item.roomLabel!.isNotEmpty ? ' · ${item.roomLabel}' : ''}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: colors.inkMuted),
          ),
          const SizedBox(height: 10),
          if (busy)
            Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.brandPrimary),
              ),
            )
          else
            _actionStrip(context, item),
        ],
      ),
    );
  }

  Widget _actionStrip(BuildContext context, QueueAppointmentItem item) {
    final colors = context.appColors;
    switch (item.queueStatus) {
      case 'scheduled':
        return Row(
          children: [
            Expanded(
              child: AppButton.primary(
                text: 'Check In',
                height: 34,
                onPressed: () => _advance(item, 'checked_in'),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Mark No-Show',
              onPressed: () => _advance(item, 'no_show'),
              icon: Icon(Icons.person_off_outlined, size: 18, color: colors.danger),
            ),
          ],
        );
      case 'checked_in':
        return Row(
          children: [
            Expanded(
              child: AppButton.primary(
                text: 'Move to Room',
                height: 34,
                onPressed: () => _promptRoomAndMove(item),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Return to Scheduled',
              onPressed: () => _advance(item, 'scheduled'),
              icon: Icon(Icons.undo_rounded, size: 18, color: colors.inkMuted),
            ),
          ],
        );
      case 'in_room':
        return Row(
          children: [
            Expanded(
              child: AppButton.primary(
                text: 'Complete Visit',
                height: 34,
                onPressed: () => _advance(item, 'completed'),
              ),
            ),
          ],
        );
      default:
        final completedLabel = _formatCompletedTime(item.completedAt);
        return Row(
          children: [
            Expanded(
              child: Text(
                completedLabel != null ? 'Done · $completedLabel' : _prettyStage(item.queueStatus),
                style: TextStyle(fontSize: 11, color: colors.inkMuted, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => _advance(item, 'scheduled'),
              child: const Text('Reopen', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
    }
  }

  String? _formatCompletedTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) return DateFormat('HH:mm').format(parsed.toLocal());
    final parts = raw.trim().split(RegExp(r'[ T]'));
    final tail = parts.isNotEmpty ? parts.last : raw.trim();
    return tail.length >= 5 ? tail.substring(0, 5) : tail;
  }

  static String _prettyStage(String s) {
    switch (s) {
      case 'checked_in':
        return 'Checked In';
      case 'in_room':
        return 'In Room';
      case 'completed':
        return 'Completed';
      case 'no_show':
        return 'No-Show';
      default:
        return 'Scheduled';
    }
  }
}
