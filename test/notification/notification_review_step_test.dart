import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_preview.dart';
import 'package:klinik_aurora_portal/views/notification/notification_review_step.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';

void main() {
  testWidgets('renders channel, title and body summary', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationReviewStep(
              channel: DropdownAttribute('general', 'All Users'),
              title: 'Maintenance',
              body: 'Clinic closed today',
              scheduledFor: null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('All Users'), findsOneWidget);
    expect(find.text('Maintenance'), findsWidgets);
    expect(find.text('Clinic closed today'), findsWidgets);
  });

  testWidgets('renders stacked layout with preview in narrow width', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: NotificationReviewStep(
                channel: DropdownAttribute('authorised-user-announcements', 'Signed In Users'),
                title: 'Maintenance',
                body: '',
                scheduledFor: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(NotificationPreview), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
