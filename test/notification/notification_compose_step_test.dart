import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_compose_step.dart';

void main() {
  testWidgets('typing updates counters and preview via onChanged', (tester) async {
    final title = TextEditingController();
    final content = TextEditingController();
    var changed = 0;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            // Mirror the real parent (Task 7): onChanged triggers setState so
            // the counters and preview re-render from the controllers' text.
            body: StatefulBuilder(
              builder: (context, setState) => NotificationComposeStep(
                titleController: title,
                contentController: content,
                onChanged: () {
                  changed++;
                  setState(() {});
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Test');
    expect(changed, greaterThan(0));
    await tester.pump();
    expect(find.text('4/60'), findsOneWidget);
    expect(find.text('Test'), findsWidgets);
  });
}
