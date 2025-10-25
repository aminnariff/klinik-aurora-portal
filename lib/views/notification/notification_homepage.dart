import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/notification/notification_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class NotificationHomepage extends StatefulWidget {
  const NotificationHomepage({super.key});

  @override
  State<NotificationHomepage> createState() => _NotificationHomepageState();
}

class _NotificationHomepageState extends State<NotificationHomepage> {
  DropdownAttribute? _channel;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  TextEditingController titleController = TextEditingController();
  TextEditingController contentController = TextEditingController();

  @override
  void initState() {
    if (kDebugMode) {
      titleController.text = 'Exciting Updates Coming Soon!';
      contentController.text =
          'We will be launching new updates soon. Stay tuned for a better and smoother experience with Klinik Aurora.';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: BoxConstraints(maxWidth: 700, minWidth: 500),
              child: CardContainer(
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Announcement Channel', style: AppTypography.displayMedium(context)),
                      const SizedBox(height: 16),
                      StreamBuilder(
                        stream: rebuildDropdown.stream,
                        builder: (context, asyncSnapshot) {
                          return AppDropdown(
                            attributeList: DropdownAttributeList(
                              notificationChannel,
                              labelText: 'notification'.tr(gender: 'channel'),
                              value: _channel?.name,
                              onChanged: (p0) {
                                _channel = p0;
                                rebuildDropdown.add(DateTime.now());
                              },
                              width: screenWidthByBreakpoint(90, 70, 250, useAbsoluteValueDesktop: true),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        field: InputFieldAttribute(
                          controller: titleController,
                          labelText: 'notification'.tr(gender: 'title'),
                          isEditableColor: const Color(0xFFEEF3F7),
                        ),
                        width: screenWidthByBreakpoint(90, 70, 26),
                      ),
                      const SizedBox(height: 16),
                      InputField(
                        field: InputFieldAttribute(
                          controller: contentController,
                          labelText: 'notification'.tr(gender: 'content'),
                          isEditableColor: const Color(0xFFEEF3F7),
                          lineNumber: 2,
                          maxCharacter: 200,
                        ),
                        width: screenWidthByBreakpoint(90, 70, 26),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                          SizedBox(width: 16),
                          Button(
                            () {
                              final category = _channel!;
                              final title = titleController.text;
                              final content = contentController.text;

                              debugPrint('Sending notification...');
                              showConfirmDialog(
                                context,
                                'Are you sure you want to send this notification to ${category.name}? This action cannot be undone.',
                              ).then((confirmed) {
                                if (confirmed) {
                                  NotificationController.send(
                                    context,
                                    topic: category.key,
                                    title: title,
                                    body: content,
                                  ).then((value) {
                                    if (responseCode(value.code)) {
                                      Navigator.pop(context);
                                      showDialogSuccess(
                                        context,
                                        'Notification successfully sent to ${category.name}. They should receive it within a few minutes.',
                                      );
                                    } else {
                                      showDialogError(
                                        context,
                                        'Unable to send the notification at the moment. Please try again later. If the issue persists, contact the app developer.',
                                      );
                                    }
                                  });
                                }
                              });
                            },
                            actionText: 'Send',
                            color: secondaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
