import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/notification/notification_response.dart';

class NotificationController {
  static Future<ApiResponse<NotificationResponse>> send(
    BuildContext context, {
    String? topic,
    String? title,
    String? body,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/notification/send/topic',
          data: {'topic': topic, 'title': title, 'body': body},
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: NotificationResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }
}
