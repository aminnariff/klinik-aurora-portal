import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/notification/notification_controller.dart';
import 'package:klinik_aurora_portal/models/notification/scheduled_notification.dart';
import 'package:klinik_aurora_portal/views/notification/notification_delivery_field.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// Edit a notification that is still queued.
///
/// Pops `true` when saved. Only reachable for pending rows — the API returns
/// 409 for anything already sent, so a sent announcement can never be rewritten
/// after the fact.
class NotificationScheduleEditor extends StatefulWidget {
  final ScheduledNotification notification;

  const NotificationScheduleEditor({super.key, required this.notification});

  @override
  State<NotificationScheduleEditor> createState() => _NotificationScheduleEditorState();
}

class _NotificationScheduleEditorState extends State<NotificationScheduleEditor> {
  late final InputFieldAttribute _title = InputFieldAttribute(
    controller: TextEditingController(text: widget.notification.title),
    labelText: 'Title',
    maxCharacter: 60,
  );
  late final InputFieldAttribute _body = InputFieldAttribute(
    controller: TextEditingController(text: widget.notification.body),
    labelText: 'Content',
    lineNumber: 3,
    maxCharacter: 200,
  );

  late DateTime? _scheduledFor = widget.notification.triggerDateTime;
  late String _topic = widget.notification.topic;

  bool _saving = false;
  String? _validationError;

  @override
  void dispose() {
    _title.controller.dispose();
    _body.controller.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_title.controller.text.trim().isEmpty) return 'Give the announcement a title.';
    if (_body.controller.text.trim().isEmpty) return 'Write some content.';

    final when = _scheduledFor;
    if (when == null) return 'Pick a delivery time.';
    // Re-checked at save because the dialog can sit open long enough for a
    // near-future time to slip into the past.
    if (!when.isAfter(DateTime.now())) return 'That time has already passed. Pick a time in the future.';

    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    setState(() {
      _validationError = null;
      _saving = true;
    });

    final value = await NotificationController.updateScheduled(
      context,
      id: widget.notification.id,
      topic: _topic,
      title: _title.controller.text.trim(),
      body: _body.controller.text.trim(),
      triggerDateTime: _scheduledFor!,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (responseCode(value.code)) {
      Navigator.of(context).pop(true);
    } else {
      showDialogError(context, value.message ?? 'Unable to update this notification.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.min(720.0, MediaQuery.of(context).size.width * 0.94);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: CardContainer(
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Edit Scheduled Announcement', style: AppTypography.displayMedium(context)),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF637381),
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Channel', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 3)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final channel in notificationChannel)
                              ChoiceChip(
                                label: Text(channel.name),
                                selected: _topic == channel.key,
                                selectedColor: secondaryColor.withAlpha(40),
                                onSelected: (_) => setState(() => _topic = channel.key),
                              ),
                          ],
                        ),
                        AppPadding.vertical(denominator: 2),
                        InputField(field: _title..onChanged = (_) => setState(() {})),
                        AppPadding.vertical(denominator: 2),
                        InputField(field: _body..onChanged = (_) => setState(() {})),
                        AppPadding.vertical(denominator: 2),
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                        AppPadding.vertical(denominator: 2),
                        NotificationDeliveryField(
                          value: _scheduledFor,
                          allowImmediate: false,
                          onChanged: (value) => setState(() => _scheduledFor = value),
                        ),
                        AppPadding.vertical(denominator: 2),
                        NotificationPreview(
                          title: _title.controller.text,
                          body: _body.controller.text,
                          width: 240,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_validationError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _validationError!,
                      style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF991B1B)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      _saving ? null : _save,
                      actionText: _saving ? 'Saving…' : 'Save Changes',
                      color: secondaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
