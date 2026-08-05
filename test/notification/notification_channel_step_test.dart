import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/views/notification/notification_channel_step.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';

void main() {
  testWidgets('tapping a channel reports the selected key', (tester) async {
    DropdownAttribute? picked;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationChannelStep(
              channels: notificationChannel,
              selected: null,
              onSelected: (channel) => picked = channel,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('All Users'));
    expect(picked?.key, 'general');

    await tester.tap(find.text('Signed In Users'));
    expect(picked?.key, 'authorised-user-announcements');
  });

  testWidgets('renders selected highlight and switching reports the new key', (tester) async {
    DropdownAttribute? picked;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: NotificationChannelStep(
              channels: notificationChannel,
              selected: notificationChannel.first,
              onSelected: (channel) => picked = channel,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    await tester.tap(find.text('Signed In Users'));
    expect(picked?.key, 'authorised-user-announcements');
  });
}
