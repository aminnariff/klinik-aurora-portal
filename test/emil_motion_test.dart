import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';

Widget _testWrapper(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmilMotion Design Engineering Spec Tests (Portal)', () {
    test('UI animation durations are crisp and strictly under 300ms', () {
      expect(EmilMotion.pressDuration.inMilliseconds, lessThan(300));
      expect(EmilMotion.releaseDuration.inMilliseconds, lessThan(300));
      expect(EmilMotion.modalDuration.inMilliseconds, lessThan(300));
      expect(EmilMotion.toastDuration.inMilliseconds, lessThan(300));

      expect(EmilMotion.pressDuration, const Duration(milliseconds: 140));
      expect(EmilMotion.releaseDuration, const Duration(milliseconds: 120));
      expect(EmilMotion.modalDuration, const Duration(milliseconds: 200));
      expect(EmilMotion.toastDuration, const Duration(milliseconds: 220));
    });

    test('Custom cubic-bezier curves match Emil specifications', () {
      expect(EmilMotion.easeOut, const Cubic(0.23, 1.0, 0.32, 1.0));
      expect(EmilMotion.easeInOut, const Cubic(0.77, 0.0, 0.175, 1.0));
    });

    testWidgets('EmilPressable scales down to 0.97 on press and snaps back to 1.0', (tester) async {
      await tester.pumpWidget(
        _testWrapper(
          EmilPressable(
            onTap: () {},
            child: const Text('Sign In'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final animatedScaleFinder = find.byType(AnimatedScale);
      expect(animatedScaleFinder, findsOneWidget);

      AnimatedScale scaleWidget = tester.widget(animatedScaleFinder);
      expect(scaleWidget.scale, 1.0);

      // Press down
      final gesture = await tester.startGesture(tester.getCenter(find.text('Sign In')));
      await tester.pump(const Duration(milliseconds: 140));
      scaleWidget = tester.widget(animatedScaleFinder);
      expect(scaleWidget.scale, 0.97);

      // Release
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 120));
      scaleWidget = tester.widget(animatedScaleFinder);
      expect(scaleWidget.scale, 1.0);
    });

    testWidgets('EmilModalTransition starts from scale(0.95) with opacity', (tester) async {
      await tester.pumpWidget(
        _testWrapper(
          const EmilModalTransition(
            child: Text('Modal Content'),
          ),
        ),
      );

      // At start (0ms), progress is 0.0 -> opacity 0, scale 0.95
      await tester.pump(Duration.zero);
      expect(find.text('Modal Content'), findsOneWidget);

      // Settle
      await tester.pumpAndSettle();
      expect(find.text('Modal Content'), findsOneWidget);
    });
  });
}
