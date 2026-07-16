import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_button_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_type.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';

/// Per-type styling: pastel outer ring, solid inner circle, icon and
/// default button colour.
class _DialogStyle {
  const _DialogStyle({
    required this.outerColor,
    required this.innerColor,
    required this.icon,
    required this.buttonColor,
    required this.defaultTitle,
  });

  final Color outerColor;
  final Color innerColor;
  final IconData icon;
  final Color buttonColor;
  final String defaultTitle;

  static _DialogStyle of(DialogType type) {
    switch (type) {
      case DialogType.success:
        return const _DialogStyle(
          outerColor: Color(0xFFECFDF5),
          innerColor: Color(0xFF10B981),
          icon: Icons.check_rounded,
          buttonColor: tertiaryColor,
          defaultTitle: 'Success!',
        );
      case DialogType.error:
        return const _DialogStyle(
          outerColor: Color(0xFFFEF2F2),
          innerColor: Color(0xFFEF4444),
          icon: Icons.close_rounded,
          buttonColor: errorColor,
          defaultTitle: 'Something Went Wrong',
        );
      case DialogType.info:
        return const _DialogStyle(
          outerColor: Color(0xFFE0F6FA),
          innerColor: sidebarColor,
          icon: Icons.info_rounded,
          buttonColor: sidebarColor,
          defaultTitle: 'Attention',
        );
    }
  }
}

class AppDialog extends StatelessWidget {
  final DialogAttribute attribute;

  const AppDialog(this.attribute, {super.key});

  @override
  Widget build(BuildContext context) {
    final style = _DialogStyle.of(attribute.type);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: attribute.width ?? 400),
          child: Container(
            width: double.infinity,
            height: attribute.height,
            padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 48,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElasticIn(child: attribute.logo ?? _statusIcon(style)),
                const SizedBox(height: 24),
                AppSelectableText(
                  attribute.title ?? style.defaultTitle,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (attribute.text != null) ...[
                  const SizedBox(height: 10),
                  AppSelectableText(
                    attribute.text.toString(),
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.55),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (attribute.textWidget != null) ...[const SizedBox(height: 10), attribute.textWidget!],
                if (attribute.buttonAttributes?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      for (int index = 0; index < attribute.buttonAttributes!.length; index++) ...[
                        if (index > 0) const SizedBox(width: 10),
                        Expanded(child: _button(attribute.buttonAttributes![index], style)),
                      ],
                    ],
                  ),
                ],
                if (attribute.cancelButton != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: attribute.cancelButton!.action,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF64748B)),
                    child: Text(
                      attribute.cancelButton?.text ?? 'cancel'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(_DialogStyle style) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(color: style.outerColor, shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: style.innerColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: style.innerColor.withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(style.icon, color: Colors.white, size: 34),
        ),
      ),
    );
  }

  Widget _button(DialogButtonAttribute item, _DialogStyle style) {
    final color = item.color ?? style.buttonColor;
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: item.action,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: item.textColor ?? Colors.white,
          elevation: 8,
          shadowColor: color.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Text(
          item.text ?? 'okay'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
