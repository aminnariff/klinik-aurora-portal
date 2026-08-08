import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/notification/notification_delivery_field.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationReviewStep extends StatelessWidget {
  final DropdownAttribute channel;
  final String title;
  final String body;

  /// Mirrors the choice made on the compose step; `null` means immediate.
  final DateTime? scheduledFor;

  const NotificationReviewStep({
    super.key,
    required this.channel,
    required this.title,
    required this.body,
    required this.scheduledFor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 472;
        final preview = NotificationPreview(title: title, body: body, width: narrow ? constraints.maxWidth : 240);
        final summary = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryRow(label: 'Channel', value: channel.name),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Title', value: title),
            const SizedBox(height: 12),
            _SummaryRow(label: 'Content', value: body.isEmpty ? '—' : body, maxLines: 6),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Delivery',
              value: scheduledFor == null
                  ? 'Immediately'
                  : '${formatDeliveryDate(scheduledFor!)} at ${formatDeliveryTime(scheduledFor!)}',
            ),
          ],
        );

        return narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [summary, const SizedBox(height: 16), preview],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: summary),
                  const SizedBox(width: 32),
                  preview,
                ],
              );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final int? maxLines;

  const _SummaryRow({required this.label, required this.value, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF), fontWeightDelta: -1),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: maxLines != null ? TextOverflow.ellipsis : null,
            style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2),
          ),
        ),
      ],
    );
  }
}
