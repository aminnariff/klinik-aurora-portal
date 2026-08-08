import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/notification/notification_delivery_field.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationComposeStep extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final VoidCallback onChanged;

  /// When the announcement should go out; `null` sends immediately.
  final DateTime? scheduledFor;
  final ValueChanged<DateTime?> onScheduleChanged;

  const NotificationComposeStep({
    super.key,
    required this.titleController,
    required this.contentController,
    required this.onChanged,
    required this.scheduledFor,
    required this.onScheduleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 472;
        final formWidth = narrow ? constraints.maxWidth : math.max(constraints.maxWidth - 272, 200.0);
        final preview = NotificationPreview(
          title: titleController.text,
          body: contentController.text,
          width: narrow ? constraints.maxWidth : 240,
        );
        final form = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
            const SizedBox(height: 8),
            InputField(
              field: InputFieldAttribute(
                controller: titleController,
                hintText: 'e.g. Exciting Updates Coming Soon!',
                isEditableColor: const Color(0xFFEEF3F7),
                maxCharacter: 60,
                onChanged: (_) => onChanged(),
              ),
              width: formWidth,
            ),
            const SizedBox(height: 6),
            Text(
              '${titleController.text.length}/60',
              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
            ),
            const SizedBox(height: 16),
            Text('Content', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
            const SizedBox(height: 8),
            InputField(
              field: InputFieldAttribute(
                controller: contentController,
                hintText: 'Write your announcement…',
                isEditableColor: const Color(0xFFEEF3F7),
                lineNumber: 3,
                maxCharacter: 200,
                onChanged: (_) => onChanged(),
              ),
              width: formWidth,
            ),
            const SizedBox(height: 6),
            Text(
              '${contentController.text.length}/200',
              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -3),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            SizedBox(
              width: formWidth,
              child: NotificationDeliveryField(value: scheduledFor, onChanged: onScheduleChanged),
            ),
          ],
        );

        return narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [form, const SizedBox(height: 16), preview],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: form),
                  const SizedBox(width: 32),
                  preview,
                ],
              );
      },
    );
  }
}
