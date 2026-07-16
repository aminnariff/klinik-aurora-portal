import 'dart:ui';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/confirmation_dialog_attribute.dart';

class ConfirmationDialog extends StatelessWidget {
  final ConfirmationDialogAttribute attribute;

  const ConfirmationDialog(this.attribute, {super.key});

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(32),
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
                ElasticIn(child: attribute.logo ?? _questionIcon()),
                const SizedBox(height: 22),
                Text(
                  attribute.title ?? 'Are you sure?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                if (attribute.text != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    attribute.text.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.55),
                  ),
                ],
                if (attribute.textWidget != null) ...[const SizedBox(height: 10), attribute.textWidget!],
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(child: _cancelButton(context)),
                    const SizedBox(width: 10),
                    Expanded(child: _confirmButton(context)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _questionIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF59E0B),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.help_outline_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _confirmButton(BuildContext context) {
    final color = attribute.confrimButton?.color ?? tertiaryColor;
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: attribute.confrimButton?.action ?? () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: attribute.confrimButton?.textColor ?? Colors.white,
          elevation: 8,
          shadowColor: color.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          attribute.confrimButton?.text ?? 'Confirm',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }

  Widget _cancelButton(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextButton(
        onPressed: attribute.cancelButton?.action ?? () => Navigator.pop(context, false),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF1F5F9),
          foregroundColor: const Color(0xFF334155),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          attribute.cancelButton?.text ?? 'Cancel',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
    );
  }
}
