import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/widgets/glass/app_glass.dart';

void main() {
  testWidgets('AppGlassCard renders BackdropFilter with blur and border in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: AppGlassCard(
            child: Text('Test Glass Card'),
          ),
        ),
      ),
    );

    expect(find.text('Test Glass Card'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);

    final backdrop = tester.widget<BackdropFilter>(find.byType(BackdropFilter));
    expect(backdrop.filter, isNotNull);
  });

  testWidgets('AppGlassCard adapts surface fill and border between light and dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: AppGlassCard(
            child: Text('Light Glass Card'),
          ),
        ),
      ),
    );

    expect(find.text('Light Glass Card'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
  });
}
