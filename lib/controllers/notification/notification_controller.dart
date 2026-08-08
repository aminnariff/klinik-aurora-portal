import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';
import 'package:klinik_aurora_portal/models/notification/notification_response.dart';
import 'package:klinik_aurora_portal/models/notification/scheduled_notification.dart';

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

  static Future<ApiResponse<NotificationHistoryResponse>> fetchHistory(BuildContext context) {
    return ApiController().call(context, method: Method.get, endpoint: 'admin/notification').then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: NotificationHistoryResponse.fromJson(value.data as Map<String, dynamic>),
        );
      } catch (e) {
        return ApiResponse(code: 400, message: e.toString());
      }
    });
  }

  /// Queue of notifications waiting on (or already handled by) the backend cron.
  ///
  /// Returns a bare JSON array of MySQL rows, unlike [fetchHistory].
  static Future<ApiResponse<List<ScheduledNotification>>> fetchScheduled(BuildContext context) {
    return ApiController().call(context, method: Method.get, endpoint: 'admin/scheduled-notifications').then((value) {
      try {
        final raw = value.data;
        if (raw is! List) {
          return ApiResponse<List<ScheduledNotification>>(code: value.code, data: const []);
        }
        return ApiResponse<List<ScheduledNotification>>(
          code: value.code,
          data: raw.whereType<Map<String, dynamic>>().map(ScheduledNotification.fromJson).toList(),
        );
      } catch (e) {
        return ApiResponse<List<ScheduledNotification>>(code: 400, message: e.toString());
      }
    });
  }

  /// Queues a notification for [triggerDateTime].
  ///
  /// Sent as a local-time ISO string without a zone suffix: the backend stores
  /// it in a zone-less MySQL DATETIME and the cron compares against the
  /// server's NOW(), so converting to UTC here would shift the send time.
  static Future<ApiResponse> schedule(
    BuildContext context, {
    required String topic,
    required String title,
    required String body,
    required DateTime triggerDateTime,
  }) {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/scheduled-notifications',
      data: {
        'topic': topic,
        'title': title,
        'body': body,
        'trigger_datetime': _localIso(triggerDateTime),
      },
    );
  }

  /// Edits a queued notification. The API refuses this with 409 once the cron
  /// has sent it, so what recipients actually received cannot be rewritten.
  static Future<ApiResponse> updateScheduled(
    BuildContext context, {
    required String id,
    required String topic,
    required String title,
    required String body,
    required DateTime triggerDateTime,
  }) {
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/scheduled-notifications/$id',
      data: {
        'topic': topic,
        'title': title,
        'body': body,
        'trigger_datetime': _localIso(triggerDateTime),
      },
    );
  }

  static Future<ApiResponse> cancelScheduled(BuildContext context, String id) {
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/scheduled-notifications/$id',
      data: {'status': 'CANCELLED'},
    );
  }

  static Future<ApiResponse> deleteScheduled(BuildContext context, String id) {
    return ApiController().call(context, method: Method.delete, endpoint: 'admin/scheduled-notifications/$id');
  }

  static String _localIso(DateTime value) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}'
        'T${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }
}
