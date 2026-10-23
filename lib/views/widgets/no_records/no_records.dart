import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';

class NoRecordsWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const NoRecordsWidget({
    super.key,
    this.title = 'No Records Found',
    this.subtitle,
    this.icon = Icons.folder_open_rounded,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC), // slate-50
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
              ),
              child: Icon(
                icon,
                size: 32,
                color: const Color(0xFF94A3B8), // slate-400
              ),
            ),
            const SizedBox(height: 16),
            AppSelectableText(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B), // slate-800
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: AppSelectableText(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B), // slate-500
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
