import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/widgets/aurora/aurora_wave_mesh.dart';

void main() {
  testWidgets('AuroraWaveMesh paints wave mesh and ambient bloom in dark mode', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        themeMode: ThemeMode.dark,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AuroraWaveMesh(height: 260),
          ),
        ),
      ),
    );

    expect(find.byType(AuroraWaveMesh), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('AuroraWaveMesh paints wave mesh in light mode without throwing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        themeMode: ThemeMode.light,
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: AuroraWaveMesh(height: 260),
          ),
        ),
      ),
    );

    expect(find.byType(AuroraWaveMesh), findsOneWidget);
  });
}
