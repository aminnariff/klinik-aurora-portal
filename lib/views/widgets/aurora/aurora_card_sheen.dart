import 'package:flutter/material.dart';

class AuroraCardSheen extends StatefulWidget {
  const AuroraCardSheen({super.key, required this.child, this.radius = 8, this.ticket = false});

  final Widget child;
  final double radius;
  final bool ticket;

  @override
  State<AuroraCardSheen> createState() => _AuroraCardSheenState();
}

class _AuroraCardSheenState extends State<AuroraCardSheen> {
  Alignment _light = Alignment.topLeft;

  void _tilt(PointerEvent event) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    final point = event.localPosition;
    final next = Alignment(
      (2 * point.dx / size.width - 1).clamp(-1.0, 1.0),
      (2 * point.dy / size.height - 1).clamp(-1.0, 1.0),
    );
    if (next != _light) setState(() => _light = next);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final layout = Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: .24)),
                  gradient: RadialGradient(
                    center: reduce ? Alignment.topLeft : _light,
                    radius: 1.5,
                    colors: const [Color(0x26FFFFFF), Color(0x086AD1E3), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    final clipped = widget.ticket
        ? ClipPath(clipper: _TicketClipper(widget.radius), child: layout)
        : ClipRRect(borderRadius: BorderRadius.circular(widget.radius), child: layout);
    return MouseRegion(
      onExit: reduce ? null : (_) => setState(() => _light = Alignment.topLeft),
      child: Listener(onPointerHover: reduce ? null : _tilt, onPointerMove: reduce ? null : _tilt, child: clipped),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper(this.radius);
  final double radius;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, size.height / 2), radius: 7))
      ..addOval(Rect.fromCircle(center: Offset(size.width, size.height / 2), radius: 7));
    return Path.combine(PathOperation.difference, path, notches);
  }

  @override
  bool shouldReclip(_TicketClipper oldClipper) => oldClipper.radius != radius;
}
