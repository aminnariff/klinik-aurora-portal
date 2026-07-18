import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

void showScheduleHelp(BuildContext context, int step) {
  final content = switch (step) {
    0 => const [
      (
        1,
        'Pick the practitioner',
        'Choose who this schedule is for: Doctor, Sonographer, Therapist, Spa Therapist, or Dietitian. All of that practitioner\'s active services at your branch appear automatically.',
      ),
      (
        2,
        'Check the gap for each service',
        'The gap is the time between appointment slots. It starts from the service\'s duration, but you can widen it — for example set a 45-minute service to 60-minute gaps to leave room for walk-in patients and late arrivals.',
      ),
      (
        3,
        'Untick services you don\'t want to change',
        'Only ticked services will get the new schedule. Everything else is left exactly as it is.',
      ),
    ],
    1 => const [
      (
        1,
        'Set the period',
        '"Available from" and "Available until" are the dates the practitioner is available. Only slots inside this period are created or replaced — anything outside is untouched.',
      ),
      (
        2,
        'Set the weekly hours',
        'Tick working days and set hours and breaks. Use Master Timing to fill several days at once.',
      ),
      (
        3,
        'Handle special days',
        'On the calendar, tap a date to mark it as no-slots (holiday, leave) or give it custom hours for that day only.',
      ),
      (
        4,
        'Check the preview',
        'The right panel shows how many slots each service gets. An orange warning means that service already has slots in this period — they will be replaced when you apply.',
      ),
      (
        5,
        'Rebuild from existing slots',
        'On a new computer the saved pattern may be missing. "Load from existing service" rebuilds the schedule from a service\'s current slots so you can edit instead of starting over.',
      ),
    ],
    _ => const [
      (
        1,
        'Review before applying',
        'This page lists every service that will be updated, its gap, and how many slots it gets. Nothing is saved until you press "Apply schedule".',
      ),
      (
        2,
        'What applying does',
        'For each ticked service: slots inside the period are replaced with the new schedule; slots outside the period are kept.',
      ),
      (
        3,
        'If something fails',
        'Each service shows a green tick or a red error. Press "Retry failed services" to resend only the ones that failed.',
      ),
    ],
  };

  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: math.min(550, MediaQuery.of(context).size.width * 0.92),
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline_rounded, color: Colors.orange[700], size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Text('How this step works', style: AppTypography.displayMedium(context))),
                ],
              ),
              const SizedBox(height: 24),
              for (final (number, title, description) in content)
                Padding(
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
                ),
              const SizedBox(height: 8),
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
    ),
  );
}
