import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';

/// Emil Kowalski's Hold-to-Confirm pattern:
/// - 1.5s linear progress fill while pressed down
/// - 160ms snappy ease-out snap back if released prematurely
/// - scale(0.97) tactile feedback
/// - Eliminates accidental clinic cancellations / record deletions
class HoldToConfirmButton extends StatefulWidget {
  final Future<void> Function()? onConfirmed;
  final String label;
  final String holdingLabel;
  final String confirmedLabel;
  final Color baseColor;
  final Color progressColor;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final IconData? icon;

  const HoldToConfirmButton({
    super.key,
    required this.onConfirmed,
    this.label = 'Hold to Confirm',
    this.holdingLabel = 'Keep holding...',
    this.confirmedLabel = 'Confirmed',
    this.baseColor = const Color(0xFFFEF2F2), // red-50
    this.progressColor = const Color(0xFFDC2626), // red-600
    this.textColor = const Color(0xFFDC2626),
    this.height = 50,
    this.width,
    this.borderRadius = 14,
    this.icon,
  });

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHolding = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_isCompleted) {
        _isCompleted = true;
        setState(() {});
        widget.onConfirmed?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown() {
    if (_isCompleted || widget.onConfirmed == null) return;
    setState(() => _isHolding = true);
    _controller.forward();
  }

  void _onTapUp() {
    if (_isCompleted) return;
    setState(() => _isHolding = false);
    if (_controller.value < 1.0) {
      _controller.animateBack(
        0.0,
        duration: EmilMotion.releaseDuration,
        curve: EmilMotion.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isHolding ? 0.97 : 1.0,
      duration: _isHolding ? EmilMotion.pressDuration : EmilMotion.releaseDuration,
      curve: EmilMotion.easeOut,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: GestureDetector(
          onTapDown: (_) => _onTapDown(),
          onTapUp: (_) => _onTapUp(),
          onTapCancel: () => _onTapUp(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              children: [
                // Base background track
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.baseColor,
                      border: Border.all(color: widget.progressColor.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                    ),
                  ),
                ),
                // Progress fill
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _controller.value,
                      child: Container(
                        color: widget.progressColor,
                      ),
                    );
                  },
                ),
                // Label content
                Positioned.fill(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final isFilledPastHalf = _controller.value > 0.55;
                        final currentTextColor = isFilledPastHalf ? Colors.white : widget.textColor;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, size: 18, color: currentTextColor),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _isCompleted
                                  ? widget.confirmedLabel
                                  : (_isHolding ? widget.holdingLabel : widget.label),
                              style: TextStyle(
                                color: currentTextColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
