import 'package:flutter/material.dart';

/// "Twins" chip for a mother who chose twins in the app's Baby Tracker
/// (baby_tracker_profile.baby_count = 2).
class TwinsBadge extends StatelessWidget {
  final double fontSize;
  const TwinsBadge({super.key, this.fontSize = 11});

  /// True for the API's babyCount value of a twin pregnancy.
  static bool isTwins(Object? babyCount) => babyCount is num ? babyCount.toInt() == 2 : babyCount?.toString() == '2';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE7F3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFF9A8D4)),
      ),
      child: Text(
        '👶👶 Twins',
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: const Color(0xFF9D174D)),
      ),
    );
  }
}
