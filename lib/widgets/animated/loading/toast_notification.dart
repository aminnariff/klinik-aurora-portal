import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { info, success, warning, error }

enum ToastPosition { top, bottom }

class ToastNotification extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final ToastPosition position;
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback? onDismiss;
  final Widget? leading;

  const ToastNotification({
    super.key,
    required this.message,
    this.title,
    this.type = ToastType.info,
    this.position = ToastPosition.bottom,
    this.duration = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 350),
    this.onDismiss,
    this.leading,
  });

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    ToastType type = ToastType.info,
    ToastPosition position = ToastPosition.bottom,
    Duration duration = const Duration(seconds: 3),
    Duration animationDuration = const Duration(milliseconds: 350),
    VoidCallback? onDismiss,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastOverlay(
        message: message,
        title: title,
        type: type,
        position: position,
        duration: duration,
        animationDuration: animationDuration,
        onDismiss: () {
          entry.remove();
          onDismiss?.call();
        },
      ),
    );
    overlay.insert(entry);
  }

  @override
  State<ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<ToastNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  void _setupAnimations() {
    _controller = AnimationController(
        vsync: this, duration: widget.animationDuration);
    final beginOffset = widget.position == ToastPosition.bottom
        ? const Offset(0, 1)
        : const Offset(0, -1);
    _slideAnim = Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: _ToastBody(
          message: widget.message,
          title: widget.title,
          type: widget.type,
          leading: widget.leading,
          onClose: _dismiss,
        ),
      ),
    );
  }
}

class _ToastOverlay extends StatefulWidget {
  final String message;
  final String? title;
  final ToastType type;
  final ToastPosition position;
  final Duration duration;
  final Duration animationDuration;
  final VoidCallback onDismiss;

  const _ToastOverlay({
    required this.message,
    required this.title,
    required this.type,
    required this.position,
    required this.duration,
    required this.animationDuration,
    required this.onDismiss,
  });

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.animationDuration);
    final beginOffset = widget.position == ToastPosition.bottom
        ? const Offset(0, 1)
        : const Offset(0, -1);
    _slideAnim = Tween<Offset>(begin: beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _dismissTimer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Positioned(
      top: widget.position == ToastPosition.top ? topPad + 16 : null,
      bottom: widget.position == ToastPosition.bottom ? bottomPad + 16 : null,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: _ToastBody(
              message: widget.message,
              title: widget.title,
              type: widget.type,
              onClose: _dismiss,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastBody extends StatelessWidget {
  final String message;
  final String? title;
  final ToastType type;
  final Widget? leading;
  final VoidCallback? onClose;

  const _ToastBody({
    required this.message,
    required this.type,
    this.title,
    this.leading,
    this.onClose,
  });

  static const _typeConfig = {
    ToastType.info: (
      icon: Icons.info_outline_rounded,
      color: Color(0xFF2196F3),
    ),
    ToastType.success: (
      icon: Icons.check_circle_outline_rounded,
      color: Color(0xFF4CAF50),
    ),
    ToastType.warning: (
      icon: Icons.warning_amber_rounded,
      color: Color(0xFFFF9800),
    ),
    ToastType.error: (
      icon: Icons.error_outline_rounded,
      color: Color(0xFFF44336),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _typeConfig[type]!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: config.color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          leading ??
              Icon(config.icon, color: config.color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClose,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
