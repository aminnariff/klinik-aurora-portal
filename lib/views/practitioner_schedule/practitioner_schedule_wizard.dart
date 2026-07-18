import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_saver.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/practitioner_schedule/schedule_payload.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_help.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_step_confirm.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_step_timing.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_target.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/weekly_availability_editor.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

const List<int> practitionerTypeValues = [1, 2, 3, 4, 5]; // see doctorType() in global.dart
const List<int> _gapOptions = [15, 30, 45, 60, 90, 120];

const Color _neutralBg = Color(0xFFF9FAFB);
const Color _neutralBorder = Color(0xFFE5E7EB);
const Color _labelColor = Color(0xFF6B7280);
const Color _textColor = Color(0xFF111827);

class PractitionerScheduleWizard extends StatefulWidget {
  /// Branch of the logged-in staff; null (HQ/superadmin) shows a branch picker.
  final String? branchId;
  const PractitionerScheduleWizard({super.key, this.branchId});

  @override
  State<PractitionerScheduleWizard> createState() => _PractitionerScheduleWizardState();
}

class _PractitionerScheduleWizardState extends State<PractitionerScheduleWizard> {
  int _step = 0; // 0 = practitioner & services, 1 = timing, 2 = confirm
  bool _saving = false;

  String? _branchId;
  List<branch_model.Data> _branches = [];
  int? _doctorTypeValue;
  List<ScheduleTarget> _targets = [];
  bool _loadingTargets = false;

  final WeeklyAvailabilityEditorController _editor = WeeklyAvailabilityEditorController();
  late DateTime _availableFrom;
  late DateTime _availableUntil;
  Map<String, List<TimeRange>?> _dateOverrides = {};

  List<SaveOutcome>? _outcomes;

  @override
  void initState() {
    super.initState();
    _branchId = widget.branchId;
    final now = DateTime.now();
    _availableFrom = DateTime(now.year, now.month, now.day);
    _availableUntil = DateTime(now.year, now.month + 3, 0); // end of month +2
    // The footer's Next/block-reason logic reads _editor.isValid and the
    // pattern; without this subscription it would go stale on pattern edits.
    _editor.addListener(_onEditorChanged);
    if (_branchId == null) _loadBranches();
  }

  void _onEditorChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _editor.removeListener(_onEditorChanged);
    _editor.dispose();
    super.dispose();
  }

  AvailabilitySchedule get schedule => AvailabilitySchedule(
    pattern: _editor.pattern,
    availableFrom: _availableFrom,
    availableUntil: _availableUntil,
    dateOverrides: _dateOverrides,
  );

  List<ScheduleTarget> get _selectedTargets => _targets.where((t) => t.selected).toList();

  String get _prefsKey => 'practitioner_pattern_${_branchId}_$_doctorTypeValue';

  // ─── Data loading ───

  Future<void> _loadBranches() async {
    final result = await BranchController.getAll(context, 1, 100);
    if (!mounted) return;
    setState(() => _branches = result.data?.data ?? []);
  }

  int _loadSeq = 0;

  Future<void> _loadTargets() async {
    if (_branchId == null || _doctorTypeValue == null) return;
    final seq = ++_loadSeq; // drop stale responses when branch/type changes quickly
    setState(() {
      _loadingTargets = true;
      _targets = [];
    });
    final result = await ServiceBranchController.getAll(context, 1, 100, branchId: _branchId);
    if (!mounted || seq != _loadSeq) return;
    final services = (result.data?.data ?? [])
        .where((s) => s.serviceBranchStatus == 1 && s.doctorType == _doctorTypeValue)
        .toList();
    setState(() {
      _loadingTargets = false;
      _targets = [
        for (final s in services) ScheduleTarget(service: s, gapMinutes: parseServiceTimeToMinutes(s.serviceTime)),
      ];
    });
    _restoreSavedState();
  }

  /// Loads existing slot records for selected targets (needed for the
  /// replace warnings on the timing step and the merge on save).
  ///
  /// Returns false (blocking navigation) if any fetch fails — proceeding
  /// with an unloaded target would wrongly create a duplicate record and
  /// skip the keep-outside-period merge for that service.
  Future<bool> _loadExistingSlots() async {
    final pending = _selectedTargets.where((t) => !t.existingLoaded).toList();
    if (pending.isEmpty) return true;
    showLoading();
    List<String> failed = [];
    try {
      await Future.wait(
        pending.map((target) async {
          final result = await ServiceBranchAvailableDtController.get(
            context,
            1,
            100,
            serviceBranchId: target.service.serviceBranchId,
          );
          if (!responseCode(result.code)) {
            failed.add(target.service.serviceName ?? target.service.serviceBranchId ?? 'Unknown service');
            return;
          }
          final record = result.data?.data?.isNotEmpty == true ? result.data!.data!.first : null;
          target.existingRecordId = record?.serviceBranchAvailableDatetimeId;
          target.existingDatetimes = record?.availableDatetimes ?? [];
          target.existingLoaded = true;
        }),
      );
    } finally {
      dismissLoading();
    }
    if (failed.isNotEmpty) {
      if (mounted) {
        showDialogError(
          context,
          'Could not load the current slots for: ${failed.join(', ')}. '
          'Please try again before continuing.',
        );
      }
      return false;
    }
    return true;
  }

  // ─── Pattern persistence (device-local, per branch + type) ───

  void _restoreSavedState() {
    try {
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.trim().isEmpty) return;
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final saved = AvailabilitySchedule.fromJson(Map<String, dynamic>.from(data['schedule']));
      _editor.setPattern(saved.pattern);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (!saved.availableUntil.isBefore(today)) {
        // Clamp a restored past start date to today: the merge would delete
        // past in-period slots that expandSchedule never regenerates.
        _availableFrom = saved.availableFrom.isBefore(today) ? today : saved.availableFrom;
        _availableUntil = saved.availableUntil;
        _dateOverrides = saved.dateOverrides;
      }
      final gaps = Map<String, dynamic>.from(data['gaps'] ?? {});
      for (final target in _targets) {
        final savedGap = gaps[target.service.serviceBranchId];
        if (savedGap is int && savedGap > 0) target.gapMinutes = savedGap;
      }
      setState(() {});
    } catch (e) {
      debugPrint('Failed to restore practitioner schedule state: $e');
    }
  }

  Future<void> _persistState() async {
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'schedule': schedule.toJson(),
        'gaps': {for (final t in _targets) t.service.serviceBranchId ?? '': t.gapMinutes},
      }),
    );
  }

  // ─── Navigation & save ───

  String? get _stepBlockReason {
    if (_step == 0) {
      if (_branchId == null) return 'Select a branch first.';
      if (_doctorTypeValue == null) return 'Select a practitioner type first.';
      if (_selectedTargets.isEmpty) return 'Tick at least one service.';
      if (_selectedTargets.any((t) => t.gapMinutes <= 0)) return 'Every ticked service needs a gap above 0 minutes.';
      return null;
    }
    if (_step == 1) {
      if (_availableUntil.isBefore(_availableFrom)) return '"Available until" must be after "Available from".';
      final today = DateTime.now();
      if (_availableUntil.isBefore(DateTime(today.year, today.month, today.day))) {
        return 'The selected period is entirely in the past.';
      }
      if (!_editor.isValid) return 'Set at least one day with valid, non-overlapping hours.';
      // Block if ANY ticked service would end up with zero slots — applying
      // would silently wipe its in-period slots and replace them with nothing.
      final currentSchedule = schedule;
      final emptyByGap = <int, bool>{};
      for (final t in _selectedTargets) {
        final isEmpty = emptyByGap.putIfAbsent(
          t.gapMinutes,
          () => expandSchedule(currentSchedule, t.gapMinutes).isEmpty,
        );
        if (isEmpty) {
          return 'No slots would be created for "${t.service.serviceName ?? 'a ticked service'}". '
              'Adjust the hours or its gap, or untick it in step 1.';
        }
      }
      return null;
    }
    return null;
  }

  Future<void> _next() async {
    final reason = _stepBlockReason;
    if (reason != null) {
      showDialogError(context, reason);
      return;
    }
    if (_step == 0) {
      final ok = await _loadExistingSlots();
      if (!ok || !mounted) return;
    }
    setState(() => _step++);
  }

  Future<void> _save({bool retryFailedOnly = false}) async {
    final targetsToSave = retryFailedOnly
        ? _selectedTargets
              .where((t) => _outcomes!.any((o) => !o.success && o.payload.serviceBranchId == t.service.serviceBranchId))
              .toList()
        : _selectedTargets;
    final payloads = [
      for (final t in targetsToSave)
        SchedulePayload(
          serviceBranchId: t.service.serviceBranchId ?? '',
          serviceName: t.service.serviceName ?? '',
          existingRecordId: t.existingRecordId,
          availableDatetimes: mergeReplacePeriod(
            existing: t.existingDatetimes,
            replacement: toUtcIsoList(expandSchedule(schedule, t.gapMinutes)),
            from: _availableFrom,
            until: _availableUntil,
          ),
        ),
    ];

    setState(() => _saving = true);
    await _persistState();
    final outcomes = await PractitionerScheduleSaver.save(context, payloads);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (retryFailedOnly && _outcomes != null) {
        final retried = {for (final o in outcomes) o.payload.serviceBranchId: o};
        _outcomes = [for (final o in _outcomes!) retried[o.payload.serviceBranchId] ?? o];
      } else {
        _outcomes = outcomes;
      }
    });
  }

  // ─── UI ───

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: screenWidth(90),
          height: screenHeight(90),
          // Inner Scaffold so SnackBars from the steps surface inside the
          // dialog instead of behind the modal barrier (same approach as
          // MultiTimeCalendarPage).
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: EdgeInsets.all(isMobile ? screenPadding : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _stepIndicator(),
                  const SizedBox(height: 20),
                  Expanded(child: _stepBody()),
                  const SizedBox(height: 16),
                  _footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: secondaryColor.withAlpha(30), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.schedule_rounded, color: secondaryColor, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Practitioner Schedule', style: AppTypography.displayMedium(context)),
              const SizedBox(height: 2),
              const Text(
                'Set availability once, apply to every service of that practitioner.',
                style: TextStyle(fontSize: 13, color: _labelColor),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => showScheduleHelp(context, _step),
          icon: const Icon(Icons.help_outline_rounded, size: 18),
          label: const Text('Help', style: TextStyle(fontWeight: FontWeight.bold)),
          style: TextButton.styleFrom(foregroundColor: Colors.orange),
        ),
        if (!_saving) CloseButton(onPressed: () => Navigator.pop(context, _outcomes != null)),
      ],
    );
  }

  Widget _stepIndicator() {
    const labels = ['1. Practitioner & services', '2. Availability timing', '3. Confirm & apply'];
    final chips = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      chips.add(_stepChip(labels[i], i));
      if (i < labels.length - 1) {
        chips.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey[400]),
          ),
        );
      }
    }
    // Horizontally scrollable so 3 chips + separators never overflow on
    // narrow phones; on desktop the content already fits so this scrolls
    // nowhere and renders pixel-identical.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: chips),
    );
  }

  Widget _stepChip(String label, int index) {
    final bool isCurrent = index == _step;
    final bool isCompleted = index < _step;
    Color bg;
    Color fg;
    if (isCurrent) {
      bg = secondaryColor;
      fg = Colors.white;
    } else if (isCompleted) {
      bg = secondaryColor.withAlpha(30);
      fg = secondaryColor;
    } else {
      bg = _neutralBg;
      fg = Colors.grey[500]!;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: isCurrent ? null : Border.all(color: _neutralBorder),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _targetsStep();
      case 1:
        return ScheduleStepTiming(
          editor: _editor,
          availableFrom: _availableFrom,
          availableUntil: _availableUntil,
          dateOverrides: _dateOverrides,
          targets: _selectedTargets,
          buildSchedule: () => schedule,
          onPeriodChanged: (from, until) => setState(() {
            _availableFrom = from;
            _availableUntil = until;
          }),
          onOverridesChanged: () => setState(() {}),
        );
      default:
        return ScheduleStepConfirm(
          targets: _selectedTargets,
          buildSchedule: () => schedule,
          doctorTypeLabel: doctorType(_doctorTypeValue),
          outcomes: _outcomes,
          saving: _saving,
          onRetryFailed: () => _save(retryFailedOnly: true),
        );
    }
  }

  Widget _targetsStep() {
    final typeLabel = _doctorTypeValue == null ? '' : doctorType(_doctorTypeValue);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.branchId == null) ...[_branchDropdown(), const SizedBox(height: 16)],
                _typeDropdown(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.branchId == null) ...[Expanded(child: _branchDropdown()), const SizedBox(width: 16)],
                Expanded(child: _typeDropdown()),
              ],
            ),
          const SizedBox(height: 20),
          if (_loadingTargets)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: secondaryColor)),
            )
          else if (_doctorTypeValue == null)
            _emptyHint('Select a practitioner type to list its active services.')
          else if (_targets.isEmpty)
            _emptyHint('No active $typeLabel services at this branch.')
          else
            _targetList(typeLabel),
        ],
      ),
    );
  }

  Widget _branchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('BRANCH'),
        const SizedBox(height: 6),
        _dropdownShell(
          child: DropdownButton<String>(
            value: _branchId,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: const Text('Select a branch', style: TextStyle(fontSize: 14)),
            items: [
              for (final b in _branches)
                DropdownMenuItem(value: b.branchId, child: Text(b.branchName ?? b.branchCode ?? '—')),
            ],
            onChanged: (value) {
              setState(() {
                _branchId = value;
                _targets = [];
              });
              _loadTargets();
            },
          ),
        ),
      ],
    );
  }

  Widget _typeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('PRACTITIONER TYPE'),
        const SizedBox(height: 6),
        _dropdownShell(
          child: DropdownButton<int>(
            value: _doctorTypeValue,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            hint: const Text('Select a practitioner type', style: TextStyle(fontSize: 14)),
            items: [for (final v in practitionerTypeValues) DropdownMenuItem(value: v, child: Text(doctorType(v)))],
            onChanged: (value) {
              setState(() => _doctorTypeValue = value);
              _loadTargets();
            },
          ),
        ),
      ],
    );
  }

  Widget _targetList(String typeLabel) {
    final selectedCount = _selectedTargets.length;
    final allSelected = selectedCount == _targets.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${_targets.length} active $typeLabel service${_targets.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  for (final t in _targets) {
                    t.selected = !allSelected;
                  }
                });
              },
              style: TextButton.styleFrom(foregroundColor: secondaryColor),
              child: Text(allSelected ? 'Untick all' : 'Tick all', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _gapInfoBanner(),
        const SizedBox(height: 16),
        for (final target in _targets) _targetRow(target),
      ],
    );
  }

  Widget _gapInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gap = time between appointment slots. It starts from each service\'s duration, '
              'but you can widen it (e.g. 45 → 60 minutes) to leave room for walk-in patients '
              'and late arrivals. Changing it here never changes the service itself.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF1E3A8A), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetRow(ScheduleTarget target) {
    final bool selected = target.selected;
    final bool gapInList = _gapOptions.contains(target.gapMinutes);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.white : _neutralBg.withAlpha(150),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? secondaryColor.withAlpha(100) : _neutralBorder, width: selected ? 1.5 : 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: selected,
              activeColor: secondaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) => setState(() => target.selected = val ?? false),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target.service.serviceName ?? '—',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: selected ? _textColor : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Duration: ${target.service.serviceTime ?? '—'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Gap:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? _neutralBg : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _neutralBorder),
            ),
            child: DropdownButton<int>(
              value: gapInList ? target.gapMinutes : null,
              hint: Text('${target.gapMinutes} min', style: const TextStyle(fontSize: 13)),
              underline: const SizedBox.shrink(),
              isDense: true,
              items: [for (final g in _gapOptions) DropdownMenuItem(value: g, child: Text('$g min'))],
              onChanged: selected
                  ? (value) {
                      if (value != null) setState(() => target.gapMinutes = value);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final reason = _stepBlockReason;
    final bool allSuccess = _outcomes != null && _outcomes!.isNotEmpty && _outcomes!.every((o) => o.success);
    final Widget? backButton = (_step > 0 && _outcomes == null)
        ? OutlinedButton(
            onPressed: _saving ? null : () => setState(() => _step--),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textColor,
              side: const BorderSide(color: _neutralBorder),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        : null;
    final Widget primaryButton = _primaryFooterButton(allSuccess: allSuccess, blocked: reason != null);

    if (isMobile) {
      // Stack vertically: the block-reason text and both buttons are too
      // cramped side-by-side on a narrow phone.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                reason,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
              ),
            ),
          Row(
            children: [
              if (backButton != null) ...[backButton, const SizedBox(width: 12)],
              Expanded(child: primaryButton),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        ?backButton,
        const Spacer(),
        if (reason != null)
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                reason,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12.5, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
              ),
            ),
          ),
        primaryButton,
      ],
    );
  }

  Widget _primaryFooterButton({required bool allSuccess, required bool blocked}) {
    if (_step < 2) {
      return ElevatedButton(
        onPressed: blocked ? null : _next,
        style: _primaryButtonStyle(),
        child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    // Step 2: confirm & apply
    if (allSuccess) {
      return ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: _primaryButtonStyle(),
        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return ElevatedButton(
      onPressed: (_saving || _outcomes != null) ? null : () => _save(),
      style: _primaryButtonStyle(),
      child: Text(_saving ? 'Applying…' : 'Apply schedule', style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
    backgroundColor: secondaryColor,
    foregroundColor: Colors.white,
    disabledBackgroundColor: secondaryColor.withAlpha(90),
    disabledForegroundColor: Colors.white70,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  // ─── Small shared UI helpers ───

  Widget _fieldLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _labelColor, letterSpacing: 0.4),
  );

  Widget _dropdownShell({required Widget child}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: _neutralBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _neutralBorder),
    ),
    child: child,
  );

  Widget _emptyHint(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    decoration: BoxDecoration(
      color: _neutralBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _neutralBorder),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, color: Colors.grey[500], fontStyle: FontStyle.italic),
    ),
  );
}
