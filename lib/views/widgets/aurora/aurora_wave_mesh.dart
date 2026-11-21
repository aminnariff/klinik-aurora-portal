import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Ambient glowing wave mesh with multi-frequency harmonic sine waves
/// and precision particle points, optimized for zero idle CPU/GPU consumption.
class AuroraWaveMesh extends StatelessWidget {
  final double height;
  final Color? accentColor;

  const AuroraWaveMesh({
    super.key,
    this.height = 260,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Soft Radial Bloom Glow behind the baseline
            Positioned(
              bottom: -40,
              left: 0,
              right: 0,
              height: height * 0.95,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomCenter,
                    radius: 1.0,
                    colors: isDark
                        ? [
                            const Color(0xFF246E7A).withValues(alpha: 0.35),
                            (accentColor ?? const Color(0xFFA83E58)).withValues(alpha: 0.24),
                            const Color(0xFF7E2D40).withValues(alpha: 0.08),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFFD5F5FA).withValues(alpha: 0.22),
                            (accentColor ?? const Color(0xFFFCE4EC)).withValues(alpha: accentColor == null ? 0.14 : 0.08),
                            const Color(0xFFF3E8FF).withValues(alpha: 0.05),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.40, 0.70, 1.0],
                  ),
                ),
              ),
            ),

            // High-precision vector wave mesh
            Positioned.fill(
              child: CustomPaint(
                painter: _AuroraMeshPainter(isDark: isDark, accentColor: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuroraMeshPainter extends CustomPainter {
  final bool isDark;

  final Color? accentColor;

  const _AuroraMeshPainter({required this.isDark, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;
    const lines = 7;
    const pointsPerLine = 48;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..isAntiAlias = true;

    for (int l = 0; l < lines; l++) {
      final lineProgress = l / lines;

      // Color interpolation: Cyan into Plum/Pink
      final Color strokeColor;
      if (isDark) {
        final r = (106 + (117 * lineProgress)).round();
        final g = (209 - (99 * lineProgress)).round();
        final b = (227 - (75 * lineProgress)).round();
        final alpha = (0.16 + ((1.0 - lineProgress) * 0.42)).clamp(0.0, 1.0);
        strokeColor = Color.fromRGBO(r, g, b, alpha);
      } else {
        final r = (106 + (117 * lineProgress)).round();
        final g = (209 - (99 * lineProgress)).round();
        final b = (227 - (75 * lineProgress)).round();
        final alpha = (0.02 + ((1.0 - lineProgress) * 0.06)).clamp(0.0, 1.0);
        strokeColor = Color.fromRGBO(r, g, b, alpha);
      }

      final tint = accentColor;
      basePaint.color = tint == null
          ? strokeColor
          : Color.lerp(strokeColor, tint.withValues(alpha: strokeColor.a), 0.75)!;
      final path = Path();
      final particleOffsets = <Offset>[];

      for (int p = 0; p <= pointsPerLine; p++) {
        final normX = p / pointsPerLine;
        final x = normX * w;

        // Static multi-harmonic wave curve:
        // y(x) = baseY + A1 * sin(k1*x) + A2 * cos(k2*x)
        final wave1 = math.sin((normX * math.pi * 3.2) + (l * 0.55)) * (24 + (l * 2.5));
        final wave2 = math.cos((normX * math.pi * 5.4) + (l * 0.35)) * 14;
        final baseY = h - 18 - ((lines - l) * (h / (lines + 2.5)));
        final y = baseY + wave1 + wave2;

        if (p == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }

        if (p % 2 == 0) {
          particleOffsets.add(Offset(x, y));
        }
      }

      canvas.drawPath(path, basePaint);

      // Draw particle points
      final pointPaint = Paint()
        ..color = basePaint.color.withValues(alpha: isDark ? (strokeColor.a * 1.3).clamp(0.0, 1.0) : (strokeColor.a * 0.4).clamp(0.0, 1.0))
        ..strokeWidth = isDark ? 2.4 : 1.2
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;

      canvas.drawPoints(PointMode.points, particleOffsets, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraMeshPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.accentColor != accentColor;
  }
}
