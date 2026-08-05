import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/notification/notification_homepage.dart';

ElevatedButton _nextButton(WidgetTester tester) =>
    tester.widget<ElevatedButton>(find.ancestor(of: find.text('Next'), matching: find.byType(ElevatedButton)));

Future<void> _pumpAnnouncementCenter(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(1728, 829),
      child: MaterialApp(
        // The real app theme (lib/config/theme.dart) sets displayMedium to 18px.
        // The test default theme uses 45px displayMedium, which combined with the
        // Ahem test font (every glyph = 1em square) blows up the header Row.
        theme: ThemeData(
          textTheme: const TextTheme(displayMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        home: const Scaffold(body: NotificationHomepage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Next is disabled until a channel is selected', (tester) async {
    await _pumpAnnouncementCenter(tester);
    expect(_nextButton(tester).onPressed, isNull);

    await tester.tap(find.text('All Users'));
    await tester.pump();
    expect(_nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('Next at compose step requires a title', (tester) async {
    await _pumpAnnouncementCenter(tester);

    await tester.tap(find.text('All Users'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    // kDebugMode pre-fills the title, so clear it to assert the gating logic.
    await tester.enterText(find.byType(TextField).first, '');
    await tester.pump();

    expect(_nextButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Hello');
    await tester.pump();
    expect(_nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('switching to History tab shows the history view', (tester) async {
    await _pumpAnnouncementCenter(tester);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Previously sent'), findsOneWidget);
    // NOTE: in the test env there is no Provider<AuthController> and no network,
    // so the real fetchHistory fails — the tab renders its ERROR state. This
    // documents that History degrades to an inline error state without a network.
    expect(find.text('Unable to load announcements.'), findsOneWidget);
  });
}
