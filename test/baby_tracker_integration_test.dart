import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/aurora_3d_womb_visualizer.dart';

Widget buildTestWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: Scaffold(body: child),
  );
}

void main() {
  group('Mini3DWombOrb Component Tests', () {
    testWidgets('mounts and renders for Week 20 without errors', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Mini3DWombOrb(week: 20, size: 90),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(Mini3DWombOrb), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Mini3DWombOrb),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders gracefully for week <= 4 (blastocyst stage)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Mini3DWombOrb(week: 2, size: 80),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(Mini3DWombOrb), findsOneWidget);
    });

    testWidgets('renders gracefully for full-term neonate (week 40)', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Mini3DWombOrb(week: 40, size: 100),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(Mini3DWombOrb), findsOneWidget);
    });

    testWidgets('clamps out-of-range weeks safely without crashing', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Mini3DWombOrb(week: 99, size: 100),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(Mini3DWombOrb), findsOneWidget);
    });
  });
}
