import 'package:klinik_aurora_portal/config/constants.dart';

/// A push notification queued to be sent at a future time by the backend cron
/// (`cron/send-scheduled-notification.ts`).
///
/// Raw MySQL row, so keys are snake_case.
class ScheduledNotification {
  final String id;
  final String title;
  final String body;
  final String topic;
  final DateTime? triggerDateTime;
  final String status;
  final int attempts;
  final String? lastError;
  final DateTime? sentAt;

  ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.topic,
    this.triggerDateTime,
    this.status = 'PENDING',
    this.attempts = 0,
    this.lastError,
    this.sentAt,
  });

  factory ScheduledNotification.fromJson(Map<String, dynamic> json) {
    return ScheduledNotification(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      topic: json['topic']?.toString() ?? 'general',
      triggerDateTime: _toDate(json['trigger_datetime']),
      status: json['status']?.toString() ?? 'PENDING',
      attempts: json['attempts'] is num ? (json['attempts'] as num).toInt() : 0,
      lastError: json['last_error']?.toString(),
      sentAt: _toDate(json['sent_at']),
    );
  }

  bool get isPending => status == 'PENDING' || status == 'SENDING';
  bool get isSent => status == 'SENT';
  bool get isFailed => status == 'FAILED';

  /// True once the trigger time has passed by more than the cron could
  /// plausibly account for — a real signal that the job is not running.
  ///
  /// The grace period is two full cron intervals: one because the job only
  /// fires on its tick, and one more so a single slow or skipped run does not
  /// raise a false alarm. A flat 5-minute threshold would light this up for
  /// every pending notification the moment the interval exceeded 5 minutes.
  bool get isOverdue {
    if (!isPending || triggerDateTime == null) return false;
    return DateTime.now().difference(triggerDateTime!) > scheduledNotificationInterval * 2;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}
