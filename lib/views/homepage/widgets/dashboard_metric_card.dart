import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../widgets/motion/emil_motion.dart';
import 'package:klinik_aurora_portal/config/color.dart';

class DashboardMetricCard extends StatefulWidget {
  final int index;
  final String label;
  final String value;
  final Color accentColor;
  final IconData? icon;
  final String? subtitle;
  final Color? subtitleColor;
  final double? progress;
  final VoidCallback? onTap;

  const DashboardMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.accentColor,
    this.icon,
    this.subtitle,
    this.subtitleColor,
    this.progress,
    this.onTap,
    this.index = 6,
  });

  @override
  State<DashboardMetricCard> createState() => _DashboardMetricCardState();
}

class _DashboardMetricCardState extends State<DashboardMetricCard> {
  static final _leadingNumber = RegExp(r'^([^0-9-]*)(-?[\d,]+(?:\.\d+)?)(.*)$');

  bool _hovered = false;

  Widget _number(BuildContext context) {
    final match = _leadingNumber.firstMatch(widget.value);
    final token = match?.group(2);
    final target = token == null ? null : num.tryParse(token.replaceAll(',', ''));
    Widget label(String value) => Text(
      value,
      maxLines: 1,
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: appInkPrimary, letterSpacing: -0.5),
    );
    if (match == null || token == null || target == null) return label(widget.value);
    final decimals = token.contains('.') ? token.split('.').last.length : 0;
    final format = NumberFormat.decimalPattern('en_MY')
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return AuroraCountUp(
      value: target,
      builder: (_, value) {
        if (value == target) return label(widget.value);
        final number = token.contains(',') || decimals != 0 ? format.format(value) : value.round().toString();
        return label('${match[1]}$number${match[3]}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AuroraStaggerItem(
      index: widget.index,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _hovered && widget.onTap != null ? -2 : 0),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
        curve: EmilMotion.easeOut,
        builder: (_, dy, child) => Transform.translate(offset: Offset(0, dy), child: child),
        child: InkWell(
          onHover: widget.onTap == null ? null : (value) => setState(() => _hovered = value),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: appSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: appBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top colored accent bar (3px)
                Container(height: 3.5, color: widget.accentColor),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                                color: appInkMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.icon != null)
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: widget.accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(widget.icon, size: 14, color: widget.accentColor),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _number(context)),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: widget.subtitleColor ?? widget.accentColor,
                          ),
                        ),
                      ],
                      if (widget.progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: widget.progress!.clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: widget.accentColor.withValues(alpha: 0.12),
                            valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                          ),
                        ),
                      ],
                    ],
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
