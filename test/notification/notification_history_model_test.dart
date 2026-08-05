import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';

void main() {
  test('parses history item including the API typo key', () {
    final item = NotificationHistoryItem.fromJson({
      'notificationId': 'abc-123',
      'notificationTitle': 'Maintenance',
      'notificationDesciption': 'Clinic closed today',
      'createdDate': '2026-08-05T12:00:00.000Z',
    });
    expect(item.notificationId, 'abc-123');
    expect(item.title, 'Maintenance');
    expect(item.description, 'Clinic closed today');
    expect(item.createdDate, '2026-08-05T12:00:00.000Z');
  });

  test('parses response with empty data list', () {
    final response = NotificationHistoryResponse.fromJson({'data': <dynamic>[]});
    expect(response.items, isEmpty);
  });

  test('tolerates missing data key', () {
    final response = NotificationHistoryResponse.fromJson({'message': 'ok'});
    expect(response.items, isEmpty);
  });
}
