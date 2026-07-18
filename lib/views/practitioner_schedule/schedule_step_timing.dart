import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/date_override_calendar.dart';
import 'package:klinik_aurora_portal/views/practitioner_schedule/schedule_target.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/weekly_availability_editor.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class ScheduleStepTiming extends StatefulWidget {
  final WeeklyAvailabilityEditorController editor;
  final DateTime availableFrom;
  final DateTime availableUntil;
  final Map<String, List<TimeRange>?> dateOverrides;
  final List<ScheduleTarget> targets;
  final AvailabilitySchedule Function() buildSchedule;
  final void Function(DateTime from, DateTime until) onPeriodChanged;
  final VoidCallback onOverridesChanged;

  const ScheduleStepTiming({
    super.key,
    required this.editor,
    required this.availableFrom,
    required this.availableUntil,
    required this.dateOverrides,
    required this.targets,
    required this.buildSchedule,
    required this.onPeriodChanged,
    required this.onOverridesChanged,
  });

  @override
  State<ScheduleStepTiming> createState() => _ScheduleStepTimingState();
}

class _ScheduleStepTimingState extends State<ScheduleStepTiming> {
  static const Color _neutralBg = Color(0xFFF9FAFB);
  static const Color _neutralBorder = Color(0xFFE5E7EB);
  static const Color _labelColor = Color(0xFF6B7280);
  static const Color _textColor = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    final left = _leftColumn();
    final right = _rightColumn();
    if (isMobile) {
      // Two side-by-side flexed columns would squeeze the weekly editor and
      // the calendar preview into unusable slivers on a phone — stack them
      // full-width instead.
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [left, const SizedBox(height: 20), right],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left (flex 3): period pickers + pattern editor, in a SingleChildScrollView
        Expanded(flex: 3, child: SingleChildScrollView(child: left)),
        const SizedBox(width: 20),
        // Right (flex 2): override calendar + per-service preview, in a SingleChildScrollView
        Expanded(flex: 2, child: SingleChildScrollView(child: right)),
      ],
    );
  }

  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _periodRow(),
        const SizedBox(height: 16),
        WeeklyAvailabilityEditor(controller: widget.editor, expandDayList: false),
      ],
    );
  }

  Widget _rightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Calendar preview & day overrides',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            TextButton.icon(
              onPressed: _loadFromExistingService,
              icon: const Icon(Icons.download_rounded, size: 14),
              label: const Text('Load from existing service', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
        Text(
          'Tap a date to exclude it (holiday, leave) or set custom hours.',
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: widget.editor,
          builder: (context, _) => DateOverrideCalendar(
            from: widget.availableFrom,
            until: widget.availableUntil,
            pattern: () => widget.editor.pattern,
            dateOverrides: widget.dateOverrides,
            onChanged: widget.onOverridesChanged,
          ),
        ),
        const SizedBox(height: 16),
        const Text('Slots that will be created', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 8),
        ListenableBuilder(listenable: widget.editor, builder: (context, _) => _previewList()),
      ],
    );
  }

  // ─── Period pickers ───

  Widget _periodRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _dateField(
            label: 'AVAILABLE FROM',
            value: widget.availableFrom,
            onPicked: (picked) => widget.onPeriodChanged(picked, widget.availableUntil),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _dateField(
            label: 'AVAILABLE UNTIL (EXPIRY)',
            value: widget.availableUntil,
            onPicked: (picked) => widget.onPeriodChanged(widget.availableFrom, picked),
          ),
        ),
      ],
    );
  }

  Widget _dateField({required String label, required DateTime value, required ValueChanged<DateTime> onPicked}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _labelColor, letterSpacing: 0.4),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final initial = value.isBefore(today) ? today : value;
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: today,
              lastDate: DateTime(now.year + 1, 12, 31),
              builder: (context, child) => Theme(
                data: ThemeData(
                  colorScheme: const ColorScheme.light(
                    primary: secondaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: _textColor,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              onPicked(DateTime(picked.year, picked.month, picked.day));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _neutralBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _neutralBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: _labelColor),
                const SizedBox(width: 10),
                Text(
                  DateFormat('d MMM yyyy').format(value),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Per-service preview ───

  Widget _previewList() {
    final schedule = widget.buildSchedule();
    // Services often share a gap — expand once per distinct gap value.
    final countByGap = <int, int>{};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final target in widget.targets)
          _previewRow(
            target,
            countByGap.putIfAbsent(target.gapMinutes, () => expandSchedule(schedule, target.gapMinutes).length),
          ),
      ],
    );
  }

  Widget _previewRow(ScheduleTarget target, int count) {
    final replaced = _replacedRange(target);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _neutralBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _neutralBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  target.service.serviceName ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textColor),
                ),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 12, color: _labelColor),
                  children: [
                    TextSpan(text: '${target.gapMinutes} min · '),
                    TextSpan(
                      text: '$count slot${count == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: secondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (replaced != null) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFB45309)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Existing ${DateFormat('d MMM').format(replaced.$1)}–${DateFormat('d MMM').format(replaced.$2)} '
                    'slots (including manual per-service edits) will be replaced.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Local date span of the target's existing slots that fall inside the
  /// current [availableFrom, availableUntil] period, or null when none do.
  (DateTime, DateTime)? _replacedRange(ScheduleTarget target) {
    final fromDay = DateTime(widget.availableFrom.year, widget.availableFrom.month, widget.availableFrom.day);
    final untilDay = DateTime(widget.availableUntil.year, widget.availableUntil.month, widget.availableUntil.day);
    DateTime? min;
    DateTime? max;
    for (final iso in target.existingDatetimes) {
      final dt = DateTime.tryParse(iso)?.toLocal();
      if (dt == null) continue;
      final day = DateTime(dt.year, dt.month, dt.day);
      if (day.isBefore(fromDay) || day.isAfter(untilDay)) continue;
      if (min == null || day.isBefore(min)) min = day;
      if (max == null || day.isAfter(max)) max = day;
    }
    if (min == null || max == null) return null;
    return (min, max);
  }

  // ─── Load from existing service ───

  Widget _candidateTile(BuildContext ctx, ScheduleTarget target) {
    // Reconstruction only reads slots inside the selected period, so a
    // service whose slots all fall outside it would rebuild an empty week.
    final fromDay = DateTime(widget.availableFrom.year, widget.availableFrom.month, widget.availableFrom.day);
    final untilEnd = DateTime(widget.availableUntil.year, widget.availableUntil.month, widget.availableUntil.day + 1);
    final localDates =
        target.existingDatetimes.map((iso) => DateTime.tryParse(iso)?.toLocal()).whereType<DateTime>().toList()..sort();
    final inPeriod = localDates.where((d) => !d.isBefore(fromDay) && d.isBefore(untilEnd)).length;
    final usable = inPeriod > 0;
    final rangeLabel = localDates.isEmpty
        ? null
        : '${DateFormat('d MMM').format(localDates.first)} – ${DateFormat('d MMM yyyy').format(localDates.last)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: usable ? () => Navigator.pop(ctx, target) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: usable ? Colors.white : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (usable ? secondaryColor : Colors.grey).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.medical_services_rounded,
                  size: 18,
                  color: usable ? secondaryColor : Colors.grey[400],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.service.serviceName ?? '—',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: usable ? const Color(0xFF111827) : Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      usable
                          ? '$inPeriod of ${target.existingDatetimes.length} slots inside the selected period'
                                '${rangeLabel != null ? ' · $rangeLabel' : ''}'
                          : 'No slots inside the selected period — nothing to rebuild from',
                      style: TextStyle(fontSize: 11, color: Colors.grey[usable ? 600 : 400], height: 1.3),
                    ),
                  ],
                ),
              ),
              if (usable) Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadFromExistingService() async {
    final candidates = widget.targets.where((t) => t.existingDatetimes.isNotEmpty).toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('None of the selected services have existing slots to load from.')));
      return;
    }
    final chosen = await showDialog<ScheduleTarget>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: math.min(460, MediaQuery.of(ctx).size.width * 0.92),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: secondaryColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.download_rounded, size: 20, color: secondaryColor),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Rebuild schedule from a service',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pick a service to rebuild the weekly hours from its current slots. '
                'This replaces the pattern and day exceptions you have set here so far.',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.4),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: SingleChildScrollView(
                  child: Column(children: [for (final t in candidates) _candidateTile(ctx, t)]),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen == null) return;
    final result = reconstructSchedule(
      chosen.existingDatetimes,
      from: widget.availableFrom,
      until: widget.availableUntil,
      gapMinutes: chosen.gapMinutes,
    );
    widget.editor.setPattern(result.pattern);
    widget.dateOverrides.clear();
    widget.onOverridesChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.orange,
        content: Text(
          'Schedule rebuilt from "${chosen.service.serviceName ?? '—'}". '
          'Timings are inferred — review before applying.',
        ),
      ),
    );
  }
}
