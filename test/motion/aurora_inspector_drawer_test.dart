import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/aurora_inspector_drawer.dart';

void main() {
  testWidgets('the inspector leaves the work surface mounted and closes with Escape', (tester) async {
    final scroll = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => AuroraInspectorDrawer.show<void>(
                    context,
                    label: 'Inspector',
                    builder: (_) => const Center(child: Text('Appointment details')),
                  ),
                  child: const Text('Open inspector'),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scroll,
                    itemCount: 40,
                    itemExtent: 40,
                    itemBuilder: (_, index) => Text('Patient $index'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    scroll.jumpTo(400);
    await tester.pump();
    await tester.tap(find.text('Open inspector'));
    await tester.pumpAndSettle();
    expect(find.text('Appointment details'), findsOneWidget);
    expect(scroll.offset, 400);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Appointment details'), findsNothing);
    expect(scroll.offset, 400);
    await tester.pumpWidget(const SizedBox.shrink());
    scroll.dispose();
  });
}
