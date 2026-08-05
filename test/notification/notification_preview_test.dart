import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';

void main() {
  testWidgets('renders title and body', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationPreview(title: 'Test Title', body: 'Test Body', width: 400),
          ),
        ),
      ),
    );
    expect(find.text('Test Title'), findsOneWidget);
    expect(find.text('Test Body'), findsOneWidget);
    expect(find.text('Klinik Aurora'), findsOneWidget);
  });

  testWidgets('shows placeholders when empty', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationPreview(title: '', body: '', width: 400),
          ),
        ),
      ),
    );
    expect(find.text('Notification title'), findsOneWidget);
    expect(find.text('Notification content preview'), findsOneWidget);
  });

  testWidgets('does not overflow at default width with long content', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: const MaterialApp(
          home: Scaffold(
            body: NotificationPreview(
              title: 'A very long announcement title that would overflow without ellipsis',
              body: 'A very long announcement body that would overflow without ellipsis and needs to be truncated',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
