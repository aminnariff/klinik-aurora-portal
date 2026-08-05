import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/notification/notification_history.dart';
import 'package:klinik_aurora_portal/views/notification/notification_history_tab.dart';

void main() {
  testWidgets('shows empty state', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationHistoryTab(
              fetch: () async => ApiResponse(code: 200, data: NotificationHistoryResponse(items: const [])),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No announcements sent yet.'), findsOneWidget);
  });

  testWidgets('shows history items', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationHistoryTab(
              fetch: () async => ApiResponse(
                code: 200,
                data: NotificationHistoryResponse(
                  items: [
                    NotificationHistoryItem(
                      title: 'Maintenance',
                      description: 'Clinic closed today',
                      createdDate: '2026-08-05T12:00:00.000Z',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Maintenance'), findsOneWidget);
    expect(find.text('Clinic closed today'), findsOneWidget);
    expect(find.textContaining('Aug 2026'), findsOneWidget);
  });

  testWidgets('shows error state and retries', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationHistoryTab(
              fetch: () async {
                calls++;
                if (calls == 1) return ApiResponse(code: 500);
                return ApiResponse(code: 200, data: NotificationHistoryResponse(items: const []));
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Unable to load announcements.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No announcements sent yet.'), findsOneWidget);
  });
}
