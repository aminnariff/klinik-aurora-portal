import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/practitioner_schedule/practitioner_schedule_helper.dart';
import 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/weekly_availability_editor.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

// Kept so existing importers of slot_generator.dart still see TimeRange.
export 'package:klinik_aurora_portal/models/practitioner_schedule/weekly_pattern.dart' show TimeRange;

class WeeklySlotGenerator extends StatefulWidget {
  final int? initInterval;
  const WeeklySlotGenerator({super.key, this.initInterval});

  @override
  State<WeeklySlotGenerator> createState() => _WeeklySlotGeneratorState();
}

class _WeeklySlotGeneratorState extends State<WeeklySlotGenerator> {
  late final List<DateTime> months;
  late DateTime selectedMonth;
  int interval = 30;
  final WeeklyAvailabilityEditorController _editor = WeeklyAvailabilityEditorController();

  @override
  void initState() {
    super.initState();
    interval = widget.initInterval ?? 30;
    final now = DateTime.now();
    months = List.generate(4, (i) => DateTime(now.year, now.month + i));
    selectedMonth = months.first;
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  void _generateSlots() {
    final schedule = AvailabilitySchedule(
      pattern: _editor.pattern,
      availableFrom: DateTime(selectedMonth.year, selectedMonth.month, 1),
      availableUntil: DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
    );
    final slots = expandSchedule(schedule, interval)
        .map((dt) => DateFormat('yyyy-MM-dd HH:mm:ss').format(dt))
        .toList();

    if (slots.isEmpty) {
      showDialogError(
        context,
        'No slots were generated. Ensure the selected days have time ranges, and note that '
        'dates already in the past are skipped — pick a later month if this month is nearly over.',
      );
      return;
    }

    Navigator.pop(context, slots);
  }

  Future<void> _saveAllSlotsToPrefs() async {
    await prefs.setString('saved_weekly_slots', jsonEncode(_editor.pattern.toJson()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Timing template saved.'), backgroundColor: Color(0xFF16A34A)));
  }

  Future<void> _loadAllSlotsFromPrefs() async {
    try {
      final jsonString = prefs.getString('saved_weekly_slots');
      if (jsonString == null || jsonString.trim().isEmpty) {
        showDialogError(context, 'No saved timing template found.');
        return;
      }
      _editor.setPattern(WeeklyPattern.fromJson(jsonDecode(jsonString)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Timing template loaded.')));
    } catch (e) {
      debugPrint('Error loading saved slots: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load timing template.')));
    }
  }

  void _showHelpGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: math.min(550, MediaQuery.of(context).size.width * 0.9),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 12),
                  Text('Getting Started Guide', style: AppTypography.displayMedium(context)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Follow these steps to generate a complex schedule in seconds:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              _guideStep(
                1,
                'Configure Month & Interval',
                'Select the target month and the duration of each appointment slot (e.g. 30 mins) to define the base grid.',
              ),
              _guideStep(
                2,
                'Define Master Timing',
                'Set your general working hours and breaks. Use the badge at the top right of the Master Timing box to swap between "WEEKDAY" and "WEEKEND" modes.',
              ),
              _guideStep(
                3,
                'Quick Select Days',
                'Use the "Weekdays" or "Weekends" buttons to quickly highlight the relevant days in the list below.',
              ),
              _guideStep(
                4,
                'Push to Category',
                'Click the "Push to..." button to instantaneously apply your master timings to the currently selected days.',
              ),
              _guideStep(
                5,
                'Template Management',
                'Use the "Save" and "Load" buttons at the top to preserve your recurring schedules for future use across different branches.',
              ),
              _guideStep(
                6,
                'Finalize & Generate',
                'Review each day, make manual adjustments if needed, then click "Generate" at the bottom to build your calendar.',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: secondaryColor.withAlpha(20),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Got it!',
                      style: TextStyle(fontWeight: FontWeight.bold, color: secondaryColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideStep(int number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _editor,
      builder: (context, _) {
        final selectedCount = _editor.selectedDayCount;
        final canGenerate = _editor.isValid;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: secondaryColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: secondaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Weekly Slot Generator', style: AppTypography.displayMedium(context)),
                      Text(
                        'Fast-track your schedule by syncing working hours across days.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _templateBtn(
                        icon: Icons.help_outline_rounded,
                        label: 'Help',
                        onTap: () => _showHelpGuide(context),
                        color: Colors.orange[700]!,
                      ),
                      const SizedBox(width: 8),
                      _templateBtn(
                        icon: Icons.save_alt_rounded,
                        label: 'Save',
                        onTap: _saveAllSlotsToPrefs,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      _templateBtn(
                        icon: Icons.unarchive_rounded,
                        label: 'Load',
                        onTap: _loadAllSlotsFromPrefs,
                        color: Colors.grey[600]!,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Global Configuration ───
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Configuration',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _configDropdown<DateTime>(
                          label: 'Target Month',
                          value: selectedMonth,
                          items: months
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(
                                    DateFormat('MMM yyyy').format(m),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedMonth = v!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _configDropdown<int>(
                          label: 'Slot Interval',
                          value: interval,
                          items: const [15, 30, 45, 60, 90, 120]
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('$i min', style: const TextStyle(fontSize: 13)),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              interval = v!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── Weekly Availability Editor ───
            Expanded(child: WeeklyAvailabilityEditor(controller: _editor)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Wrap(
                spacing: screenPadding,
                runSpacing: screenPaddingVertical(),
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedCount == 0
                            ? 'No days selected'
                            : '$selectedCount day${selectedCount == 1 ? '' : 's'} to generate',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Text(
                        'Total working days will be calculated for the target month.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 48,
                    child: Button(canGenerate ? _generateSlots : null, actionText: 'Generate All Slots'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Helpers ───
  Widget _configDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w600),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _templateBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withAlpha(100)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
