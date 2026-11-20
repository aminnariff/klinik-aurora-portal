import '../widgets/motion/aurora_inspector_drawer.dart';
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
import 'package:klinik_aurora_portal/views/appointment/appointment_checkout_dialog.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_filter_field.dart';
import 'package:klinik_aurora_portal/views/widgets/launcher/web_launcher.dart';
import 'package:klinik_aurora_portal/views/widgets/patient/patient_quick_drawer.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:provider/provider.dart';

enum _ScheduleViewMode { timeline, kanban }

/// Today's Schedule & Appointments Hub.
/// Daily bookings, counter check-in, and instant checkout with loyalty points reward.
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
  _ScheduleViewMode _viewMode = _ScheduleViewMode.timeline;

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
        _error = res.message ?? "Failed to load today's schedule.";
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

  void _inspect(QueueAppointmentItem item) {
    AuroraInspectorDrawer.show<void>(
      context,
      label: 'Queue inspector',
      builder: (drawerContext) {
        Widget action(String label, VoidCallback callback) => ListTile(
          title: Text(label),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.of(drawerContext).pop();
            callback();
          },
        );

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                title: Text(item.patientName, style: Theme.of(drawerContext).textTheme.titleLarge),
                subtitle: Text(item.serviceName),
                trailing: IconButton(
                  tooltip: 'Close inspector',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(drawerContext).pop(),
                ),
              ),
              ListTile(title: const Text('Queue status'), subtitle: Text(_prettyStage(item.queueStatus))),
              ListTile(title: const Text('Appointment time'), subtitle: Text(item.appointmentTime)),
              if (item.roomLabel case final room?) ListTile(title: const Text('Room'), subtitle: Text(room)),
              const Divider(),
              if (item.userId.isNotEmpty)
                action('Patient profile', () => PatientQuickDrawer.show(context, userId: item.userId, patientName: item.patientName)),
              if (item.queueStatus == 'scheduled') ...[
                action('Check in', () => _advance(item, 'checked_in')),
                action('Mark no-show', () => _advance(item, 'no_show')),
              ],
              if (item.queueStatus == 'checked_in') action('Move to room', () => _promptRoomAndMove(item)),
              if (item.queueStatus == 'checked_in' || item.queueStatus == 'in_room')
                action('Complete and check out', () => _openCheckoutDialog(item)),
              if (item.queueStatus == 'completed') ...[
                action('Payment and receipt', () => _openCheckoutDialog(item)),
                action('Book next appointment', () => _openNextAppointmentDialog(item)),
              ],
              if (item.queueStatus == 'no_show') action('Reopen', () => _advance(item, 'scheduled')),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCheckoutDialog(QueueAppointmentItem item) async {
    final done = await AppointmentCheckoutDialog.show(
      context,
      appointmentId: item.appointmentId,
      onCompleted: () => _fetch(silent: true),
    );
    if (done == true && mounted) {
      _fetch(silent: true);
    }
  }

  void _openNextAppointmentDialog(QueueAppointmentItem item) {
    showDialog(
      context: context,
      builder: (_) => AppointmentDetails(
        type: 'create',
        initialUserId: item.userId,
        initialUserName: item.patientName,
        initialUserPhone: item.patientPhone,
        initialBranchId: item.branchId,
        initialNote: 'Follow-up booking after completing ${item.serviceName}',
        refreshData: () => _fetch(silent: true),
      ),
    );
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

  void _whatsappPatient(QueueAppointmentItem item) {
    final raw = item.patientPhone.replaceAll(RegExp(r'\D'), '');
    if (raw.isEmpty) {
      AppToast.snackbar(context, 'No phone number on record for this patient.');
      return;
    }
    final full = raw.startsWith('0') ? '6$raw' : (raw.startsWith('60') ? raw : '60$raw');
    final msg = Uri.encodeComponent(
      'Assalamualaikum / Hi ${item.patientName}, ini dari Klinik Aurora berkenaan temujanji anda (${item.serviceName}) hari ini. Kami sedia membantu.',
    );
    launchWebUrl('https://wa.me/$full?text=$msg', webOnlyWindowName: '_blank');
  }

  List<QueueAppointmentItem> _filtered(String stage) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return (_board?.items ?? []).where((item) {
      final matchesStage = stage == 'all'
          ? true
          : stage == 'done'
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
                      "Today's Schedule & Appointments",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View daily booked appointments, check patients in, and complete visits with automatic counter math & points reward.',
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
                    // View Toggle (Timeline vs Kanban)
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
                            tooltip: 'Timeline List View',
                            icon: Icon(
                              Icons.view_agenda_rounded,
                              size: 18,
                              color: _viewMode == _ScheduleViewMode.timeline ? colors.brandPrimary : colors.inkMuted,
                            ),
                            onPressed: () => setState(() => _viewMode = _ScheduleViewMode.timeline),
                          ),
                          Container(width: 1, height: 20, color: colors.border),
                          IconButton(
                            tooltip: 'Kanban Column View',
                            icon: Icon(
                              Icons.view_column_rounded,
                              size: 18,
                              color: _viewMode == _ScheduleViewMode.kanban ? colors.brandPrimary : colors.inkMuted,
                            ),
                            onPressed: () => setState(() => _viewMode = _ScheduleViewMode.kanban),
                          ),
                        ],
                      ),
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
                _kpiPill(context, 'Total Bookings', '${_board?.total ?? 0}', colors.inkPrimary),
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

            // ── Main Content View ─────────────────────────────────────────
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: colors.danger)))
                      : _viewMode == _ScheduleViewMode.timeline
                          ? _buildTimelineView(colors)
                          : _buildKanbanView(colors),
            ),
          ],
        ),
      ),
    );
  }

  // ── Timeline Schedule List View ──────────────────────────────────────
  Widget _buildTimelineView(AppColors colors) {
    final allItems = _filtered('all');

    if (allItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available_rounded, size: 48, color: colors.inkMuted),
            const SizedBox(height: 12),
            Text(
              "No bookings scheduled for ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.inkPrimary),
            ),
            const SizedBox(height: 4),
            Text('Try selecting another date or clear your search query.', style: TextStyle(fontSize: 12, color: colors.inkMuted)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: allItems.length,
        separatorBuilder: (_, _) => Divider(height: 12, color: colors.border.withValues(alpha: 0.6)),
        itemBuilder: (context, idx) {
          final item = allItems[idx];
          return _timelineRow(colors, item);
        },
      ),
    );
  }

  Widget _timelineRow(AppColors colors, QueueAppointmentItem item) {
    final isDone = item.queueStatus == 'completed';
    final isNoShow = item.queueStatus == 'no_show';
    final isBusy = _updatingIds.contains(item.appointmentId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDone
            ? colors.surfaceSubtle.withValues(alpha: 0.5)
            : isNoShow
                ? colors.danger.withValues(alpha: 0.04)
                : colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNoShow
              ? colors.danger.withValues(alpha: 0.3)
              : isDone
                  ? colors.border
                  : colors.brandBorder.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time Slot Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colors.brandSoftBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.appointmentTime,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.brandText),
                ),
                Text(
                  _prettyStage(item.queueStatus),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _stageColor(colors, item.queueStatus)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Patient Name & Clinical Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => _inspect(item),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
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
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded, size: 12, color: colors.inkMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      item.serviceName,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkSecondary),
                    ),
                    if (item.doctorName != null && item.doctorName!.isNotEmpty) ...[
                      Text(' · ', style: TextStyle(color: colors.inkMuted)),
                      Flexible(
                        child: Text(
                          item.doctorName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: colors.inkMuted),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Payment & Status Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: item.isPaid ? colors.successSoftBg : colors.warningSoftBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.isPaid ? 'Deposit Paid' : 'Unpaid',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: item.isPaid ? colors.success : colors.warning,
              ),
            ),
          ),
          if (item.queueStatus == 'checked_in' && item.waitMinutes > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: item.waitMinutes >= 20 ? colors.dangerSoftBg : colors.warningSoftBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.waitMinutes}m wait',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: item.waitMinutes >= 20 ? colors.danger : colors.warning,
                ),
              ),
            ),
          ],
          const SizedBox(width: 14),

          // Action Strip
          if (isBusy)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.brandPrimary),
            )
          else ...[
            // WhatsApp Contact Button
            IconButton(
              tooltip: 'Message Patient via WhatsApp',
              icon: Icon(Icons.chat_bubble_outline_rounded, size: 17, color: colors.success),
              onPressed: () => _whatsappPatient(item),
            ),
            const SizedBox(width: 4),

            // Action based on status
            if (item.queueStatus == 'scheduled') ...[
              AppButton.primary(
                text: 'Check In',
                height: 32,
                onPressed: () => _advance(item, 'checked_in'),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Mark No-Show',
                icon: Icon(Icons.person_off_outlined, size: 17, color: colors.danger),
                onPressed: () => _advance(item, 'no_show'),
              ),
            ] else if (item.queueStatus == 'checked_in' || item.queueStatus == 'in_room') ...[
              if (item.queueStatus == 'checked_in') ...[
                AppButton.secondary(
                  text: 'To Room',
                  height: 32,
                  onPressed: () => _promptRoomAndMove(item),
                ),
                const SizedBox(width: 6),
              ],
              AppButton.primary(
                text: 'Complete & Checkout',
                height: 32,
                icon: const Icon(Icons.point_of_sale_rounded, size: 14),
                onPressed: () => _openCheckoutDialog(item),
              ),
            ] else ...[
              // Completed or No-show
              if (isDone) ...[
                AppButton.primary(
                  text: 'Book Next',
                  height: 32,
                  icon: const Icon(Icons.calendar_month_rounded, size: 13),
                  onPressed: () => _openNextAppointmentDialog(item),
                ),
                const SizedBox(width: 6),
              ],
              AppButton.secondary(
                text: isDone ? 'Receipt' : 'Reopen',
                height: 32,
                onPressed: () {
                  if (isDone) {
                    _openCheckoutDialog(item);
                  } else {
                    _advance(item, 'scheduled');
                  }
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ── Kanban Column View ──────────────────────────────────────────────
  Widget _buildKanbanView(AppColors colors) {
    return LayoutBuilder(
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
                    itemBuilder: (context, idx) => _kanbanCard(context, items[idx]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _kanbanCard(BuildContext context, QueueAppointmentItem item) {
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
                  item.isPaid ? 'Deposit Paid' : 'Unpaid',
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
            onTap: () => _inspect(item),
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
            _kanbanActionStrip(context, item),
        ],
      ),
    );
  }

  Widget _kanbanActionStrip(BuildContext context, QueueAppointmentItem item) {
    final colors = context.appColors;
    switch (item.queueStatus) {
      case 'scheduled':
        return Row(
          children: [
            Expanded(
              child: AppButton.primary(
                text: 'Check In',
                height: 32,
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
              child: AppButton.secondary(
                text: 'To Room',
                height: 32,
                onPressed: () => _promptRoomAndMove(item),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: AppButton.primary(
                text: 'Checkout',
                height: 32,
                icon: const Icon(Icons.point_of_sale_rounded, size: 13),
                onPressed: () => _openCheckoutDialog(item),
              ),
            ),
          ],
        );
      case 'in_room':
        return Row(
          children: [
            Expanded(
              child: AppButton.primary(
                text: 'Complete & Checkout',
                height: 32,
                icon: const Icon(Icons.point_of_sale_rounded, size: 14),
                onPressed: () => _openCheckoutDialog(item),
              ),
            ),
          ],
        );
      default:
        final completedLabel = _formatCompletedTime(item.completedAt);
        final isDone = item.queueStatus == 'completed';
        return Row(
          children: [
            Expanded(
              child: Text(
                completedLabel != null ? 'Done · $completedLabel' : _prettyStage(item.queueStatus),
                style: TextStyle(fontSize: 11, color: colors.inkMuted, fontWeight: FontWeight.w600),
              ),
            ),
            if (isDone) ...[
              AppButton.secondary(
                text: 'Next',
                height: 28,
                onPressed: () => _openNextAppointmentDialog(item),
              ),
              const SizedBox(width: 4),
            ],
            TextButton(
              onPressed: () => _advance(item, 'scheduled'),
              child: const Text('Reopen', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
    }
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

  Color _stageColor(AppColors colors, String stage) {
    switch (stage) {
      case 'checked_in':
        return colors.warning;
      case 'in_room':
        return colors.brandText;
      case 'completed':
        return colors.success;
      case 'no_show':
        return colors.danger;
      default:
        return colors.info;
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
