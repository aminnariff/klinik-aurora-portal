import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
import 'package:klinik_aurora_portal/models/service/services_response.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';

/// Antenatal timeline steps a service can count as (membership-api keys).
const Map<String, String> pregnancyScanSteps = {
  'nt_scan': 'NT scan',
  'detail_scan': 'Detail scan',
  'scan_4d5d': '4D/5D scan',
  'growth_scan': 'Growth scan',
};

/// A gestational range in weeks + days, stored as "11w0d-13w6d".
class GestationalRangeValue {
  final int startWeeks, startDays, endWeeks, endDays;

  const GestationalRangeValue(this.startWeeks, this.startDays, this.endWeeks, this.endDays);

  /// Highest week the pickers offer (the server accepts up to 45w0d).
  static const int maxWeeks = 44;

  static final RegExp _pattern = RegExp(r'^\s*(\d{1,2})\s*w\s*([0-6])\s*d\s*[-–]\s*(\d{1,2})\s*w\s*([0-6])\s*d\s*$', caseSensitive: false);

  /// Null when [value] is empty or not in the stored format.
  static GestationalRangeValue? tryParse(String? value) {
    final m = _pattern.firstMatch(value ?? '');
    if (m == null) return null;
    final range = GestationalRangeValue(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), int.parse(m[4]!));
    return range.startWeeks > maxWeeks || range.endWeeks > maxWeeks ? null : range;
  }

  int get startDay => startWeeks * 7 + startDays;
  int get endDay => endWeeks * 7 + endDays;
  bool get isValid => endDay >= startDay;

  @override
  String toString() => '${startWeeks}w${startDays}d-${endWeeks}w${endDays}d';
}

/// Superadmin-only settings that decide the patient's Antenatal Scan Timeline:
/// the service's gestational range, which timeline steps it counts as, and
/// whether it is for single or twin pregnancies. Saved on its own, separately
/// from the service form.
class PregnancyScanSettingsCard extends StatefulWidget {
  final Data service;

  /// Called with the saved values so the caller can refresh its copy.
  final ValueChanged<Data>? onSaved;

  const PregnancyScanSettingsCard({super.key, required this.service, this.onSaved});

  @override
  State<PregnancyScanSettingsCard> createState() => _PregnancyScanSettingsCardState();
}

class _PregnancyScanSettingsCardState extends State<PregnancyScanSettingsCard> {
  late bool _hasRange;
  late GestationalRangeValue _range;
  late Set<String> _steps;
  String? _pregnancyType;
  bool _saving = false;
  late final bool _unparsedRange;

  @override
  void initState() {
    super.initState();
    final parsed = GestationalRangeValue.tryParse(widget.service.eddRequired);
    final stored = widget.service.eddRequired?.trim() ?? '';
    _unparsedRange = stored.isNotEmpty && parsed == null;
    _hasRange = parsed != null;
    _range = parsed ?? const GestationalRangeValue(11, 0, 13, 6);
    _steps = widget.service.scanMilestones.where(pregnancyScanSteps.containsKey).toSet();
    _pregnancyType = widget.service.pregnancyType;
  }

  Future<void> _save() async {
    if (_hasRange && !_range.isValid) {
      showDialogError(context, 'The range must end on or after its start.');
      return;
    }
    setState(() => _saving = true);
    final steps = pregnancyScanSteps.keys.where(_steps.contains).toList();
    final eddRequired = _hasRange ? _range.toString() : null;
    final res = await ServiceController.updateScanSettings(
      context,
      serviceId: widget.service.serviceId!,
      eddRequired: eddRequired,
      scanMilestones: steps,
      pregnancyType: _pregnancyType,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (responseCode(res.code)) {
      widget.service
        ..eddRequired = eddRequired
        ..scanMilestones = steps
        ..pregnancyType = _pregnancyType;
      widget.onSaved?.call(widget.service);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pregnancy scan settings saved.')));
    } else {
      showDialogError(context, res.message ?? res.data?.message ?? 'Could not save (${res.code}).');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pregnant_woman_rounded, size: 16, color: appInkMuted),
              const SizedBox(width: 6),
              Text(
                'PREGNANCY SCAN SETTINGS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: appInkSecondary, letterSpacing: 0.8),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                child: const Text(
                  'Superadmin',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Booking uses the range to check the mother is eligible. For a service tagged with a timeline step, '
            'it also sets that step\'s window on the patient\'s Antenatal Scan Timeline.',
            style: TextStyle(fontSize: 12, height: 1.4, color: appInkMuted),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _hasRange,
            onChanged: _saving ? null : (v) => setState(() => _hasRange = v ?? false),
            title: const Text('Has a gestational range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: _unparsedRange
                ? Text(
                    'Stored value "${widget.service.eddRequired}" is not in the 11w0d-13w6d format and will be replaced.',
                    style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                  )
                : null,
          ),
          if (_hasRange) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _rangeEnd(
                  'From',
                  _range.startWeeks,
                  _range.startDays,
                  (w, d) => GestationalRangeValue(w, d, _range.endWeeks, _range.endDays),
                ),
                _rangeEnd(
                  'To',
                  _range.endWeeks,
                  _range.endDays,
                  (w, d) => GestationalRangeValue(_range.startWeeks, _range.startDays, w, d),
                ),
              ],
            ),
            if (!_range.isValid)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'The range must end on or after its start.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text('Counts as timeline step', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appInkSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in pregnancyScanSteps.entries)
                FilterChip(
                  label: Text(entry.value),
                  selected: _steps.contains(entry.key),
                  onSelected: _saving
                      ? null
                      : (on) => setState(() => on ? _steps.add(entry.key) : _steps.remove(entry.key)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'A completed appointment for this service marks the step done on the patient\'s timeline. '
            'Select none for scans that are not part of the timeline.',
            style: TextStyle(fontSize: 11, height: 1.35, color: appInkMuted),
          ),
          const SizedBox(height: 16),
          Text('For', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appInkSecondary)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final (value, label) in [(null, 'Single & twins'), ('single', 'Single only'), ('twin', 'Twins only')])
                ChoiceChip(
                  label: Text(label),
                  selected: _pregnancyType == value,
                  onSelected: _saving ? null : (_) => setState(() => _pregnancyType = value),
                ),
            ],
          ),
          if (_steps.isNotEmpty && !_hasRange)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text(
                'Without a range this service does not set a timeline window. Completed appointments still count.',
                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
              ),
            ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save scan settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rangeEnd(String label, int weeks, int days, GestationalRangeValue Function(int, int) update) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 36, child: Text(label, style: TextStyle(fontSize: 12, color: appInkSecondary))),
        DropdownButton<int>(
          value: weeks,
          items: [
            for (var w = 0; w <= GestationalRangeValue.maxWeeks; w++) DropdownMenuItem(value: w, child: Text('$w w')),
          ],
          onChanged: _saving ? null : (w) => setState(() => _range = update(w!, days)),
        ),
        const SizedBox(width: 6),
        DropdownButton<int>(
          value: days,
          items: [for (var d = 0; d <= 6; d++) DropdownMenuItem(value: d, child: Text('$d d'))],
          onChanged: _saving ? null : (d) => setState(() => _range = update(weeks, d!)),
        ),
      ],
    );
  }
}
