import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/aurora_3d_womb_visualizer.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ),
      ),
    );
  }

  group('Aurora3DWombVisualizer - Clinical Biometrics', () {
    test('getBiometricsForWeek returns accurate clinical data across milestone weeks', () {
      final w4 = Aurora3DWombVisualizer.getBiometricsForWeek(4);
      expect(w4.week, 4);
      expect(w4.fruit, 'Biji Popi');
      expect(w4.trimester, 1);

      final w8 = Aurora3DWombVisualizer.getBiometricsForWeek(8);
      expect(w8.fruit, 'Beri Raspberi');
      expect(w8.crlCm, 1.6);
      expect(w8.weightGrams, 1.0);
      expect(w8.trimester, 1);

      final w12 = Aurora3DWombVisualizer.getBiometricsForWeek(12);
      expect(w12.fruit, 'Limau Nipis');
      expect(w12.crlCm, 5.4);
      expect(w12.weightGrams, 14.0);
      expect(w12.trimester, 1);

      final w16 = Aurora3DWombVisualizer.getBiometricsForWeek(16);
      expect(w16.fruit, 'Avokado');
      expect(w16.trimester, 2);

      final w20 = Aurora3DWombVisualizer.getBiometricsForWeek(20);
      expect(w20.fruit, 'Pisang');
      expect(w20.crlCm, 25.6);
      expect(w20.weightGrams, 300.0);
      expect(w20.trimester, 2);
      expect(w20.milestone, contains('Anatomi scan lengkap'));

      final w24 = Aurora3DWombVisualizer.getBiometricsForWeek(24);
      expect(w24.fruit, 'Jagung');
      expect(w24.trimester, 2);

      final w28 = Aurora3DWombVisualizer.getBiometricsForWeek(28);
      expect(w28.fruit, 'Terung');
      expect(w28.weightGrams, 1000.0);
      expect(w28.trimester, 3);

      final w32 = Aurora3DWombVisualizer.getBiometricsForWeek(32);
      expect(w32.fruit, 'Kelapa Muda');
      expect(w32.trimester, 3);

      final w36 = Aurora3DWombVisualizer.getBiometricsForWeek(36);
      expect(w36.fruit, 'Betik');
      expect(w36.weightGrams, 2600.0);
      expect(w36.trimester, 3);

      final w40 = Aurora3DWombVisualizer.getBiometricsForWeek(40);
      expect(w40.fruit, 'Tembikai');
      expect(w40.crlCm, 51.2);
      expect(w40.weightGrams, 3400.0);
      expect(w40.trimester, 3);
    });

    test('clamps weeks outside 1-40 range safely', () {
      final w0 = Aurora3DWombVisualizer.getBiometricsForWeek(0);
      expect(w0.week, 1);

      final w50 = Aurora3DWombVisualizer.getBiometricsForWeek(50);
      expect(w50.week, 40);
    });
  });

  group('Aurora3DWombVisualizer - Widget UI & Interactivity', () {
    testWidgets('mounts with default initial week 20 and displays biometrics HUD', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          const Aurora3DWombVisualizer(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('3D Womb Explorer'), findsOneWidget);
      expect(find.text('Perkembangan Janin & Skala Minggu'), findsOneWidget);
      expect(find.text('Minggu 20'), findsOneWidget);
      expect(find.textContaining('Pisang'), findsOneWidget);
      expect(find.text('Trimester 2'), findsOneWidget);
      expect(find.text('25.6 cm'), findsOneWidget);
      expect(find.text('300 g'), findsOneWidget);
      expect(find.textContaining('Anatomi scan lengkap'), findsOneWidget);
    });

    testWidgets('mounts with custom clamped week', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          const Aurora3DWombVisualizer(initialWeek: 8),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Minggu 8'), findsOneWidget);
      expect(find.textContaining('Beri Raspberi'), findsOneWidget);
      expect(find.text('Trimester 1'), findsOneWidget);
      expect(find.text('1.6 cm'), findsOneWidget);
      expect(find.text('1 g'), findsOneWidget);
    });

    testWidgets('quick jump chips update week and fire onWeekChanged callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? changedWeek;
      await tester.pumpWidget(
        buildTestWidget(
          Aurora3DWombVisualizer(
            initialWeek: 20,
            onWeekChanged: (w) => changedWeek = w,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final w28Chip = find.text('W28');
      expect(w28Chip, findsOneWidget);

      await tester.tap(w28Chip);
      await tester.pump(const Duration(milliseconds: 50));

      expect(changedWeek, 28);
      expect(find.text('Minggu 28'), findsOneWidget);
      expect(find.textContaining('Terung'), findsOneWidget);
      expect(find.text('Trimester 3'), findsOneWidget);
    });

    testWidgets('slider scrub updates HUD and week number', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int? lastWeek;
      await tester.pumpWidget(
        buildTestWidget(
          Aurora3DWombVisualizer(
            initialWeek: 12,
            onWeekChanged: (w) => lastWeek = w,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Minggu 12'), findsOneWidget);

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      // Drag slider rightwards
      await tester.drag(slider, const Offset(150, 0));
      await tester.pump(const Duration(milliseconds: 50));

      expect(lastWeek, isNotNull);
      expect(lastWeek, isNot(12));
    });

    testWidgets('3D CustomPainter renders without exceptions during animation ticks', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          const Aurora3DWombVisualizer(initialWeek: 20),
        ),
      );

      // Verify custom paint exists
      expect(find.byType(CustomPaint), findsWidgets);

      // Pump several animation frames for Doppler heartbeat and idle precession
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('touch pan gesture rotates 3D womb orb and reset button restores rotation', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          const Aurora3DWombVisualizer(initialWeek: 20),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final canvasGesture = find.byKey(const ValueKey('aurora_3d_womb_gesture'));
      expect(canvasGesture, findsOneWidget);

      // Pan drag on 3D canvas
      await tester.drag(canvasGesture, const Offset(60, -40));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);

      // Tap reset button
      final resetBtn = find.byTooltip('Set Semula Putaran 3D');
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('collapsible toggle collapses and expands visualizer content', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          const Aurora3DWombVisualizer(
            initialWeek: 20,
            isCollapsible: true,
            initiallyExpanded: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Minggu 20'), findsOneWidget);

      final toggleBtn = find.byTooltip('Tutup');
      expect(toggleBtn, findsOneWidget);

      await tester.tap(toggleBtn);
      await tester.pump(const Duration(milliseconds: 50));

      // After collapse, slider and biometrics are hidden
      expect(find.byType(Slider), findsNothing);

      final expandBtn = find.byTooltip('Buka');
      expect(expandBtn, findsOneWidget);

      await tester.tap(expandBtn);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('filter CTA triggers onFilterPatients callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool filterTapped = false;
      await tester.pumpWidget(
        buildTestWidget(
          Aurora3DWombVisualizer(
            initialWeek: 20,
            onFilterPatients: () => filterTapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final filterBtn = find.textContaining('Tapis Pesakit Minggu Ini');
      expect(filterBtn, findsOneWidget);

      await tester.tap(filterBtn);
      await tester.pump(const Duration(milliseconds: 50));

      expect(filterTapped, isTrue);
    });

    testWidgets('renders gracefully on narrow screen without overflows', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        buildTestWidget(
          const Aurora3DWombVisualizer(initialWeek: 20),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('Perkembangan Janin & Skala Minggu'), findsOneWidget);
      expect(find.text('Minggu 20'), findsOneWidget);
    });

    testWidgets('renders Stage 1 blastocyst for week <= 4 without errors', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const Aurora3DWombVisualizer(initialWeek: 2),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Minggu 2'), findsOneWidget);
      expect(find.textContaining('Biji Popi'), findsOneWidget);
    });
  });
}
