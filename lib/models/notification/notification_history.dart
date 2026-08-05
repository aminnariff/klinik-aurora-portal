class NotificationHistoryResponse {
  final List<NotificationHistoryItem> items;

  NotificationHistoryResponse({required this.items});

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! List) return NotificationHistoryResponse(items: const []);
    return NotificationHistoryResponse(
      items: data
          .whereType<Map<String, dynamic>>()
          .map(NotificationHistoryItem.fromJson)
          .toList(),
    );
  }
}

class NotificationHistoryItem {
  final String? notificationId;
  final String? title;
  final String? description;
  final String? createdDate;

  NotificationHistoryItem({this.notificationId, this.title, this.description, this.createdDate});

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      notificationId: json['notificationId'] as String?,
      title: json['notificationTitle'] as String?,
      // NOTE: the API aliases notification_description as notificationDesciption (typo, missing "r").
      description: json['notificationDesciption'] as String?,
      createdDate: json['createdDate'] as String?,
    );
  }
}
