import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/homepage/widgets/dashboard_panel.dart';

void main() {
  Widget panel(String value, {bool reduce = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: DashboardPanel(order: 3, child: Text(value)),
    ),
  );

  Finder transition() => find.descendant(of: find.byType(DashboardPanel), matching: find.byType(Transform));

  testWidgets('reveals the panel in under 280 ms and keeps it settled on data updates', (tester) async {
    await tester.pumpWidget(panel('Room 1'));
    expect(tester.widget<Transform>(transition()).transform.getTranslation().y, 6);
    await tester.pump(const Duration(milliseconds: 279));
    expect(tester.widget<Transform>(transition()).transform.getTranslation().y, 0);

    await tester.pumpWidget(panel('Room 2'));
    expect(find.text('Room 2'), findsOneWidget);
    expect(tester.widget<Transform>(transition()).transform.getTranslation().y, 0);
  });

  testWidgets('shows the full panel immediately with reduced motion', (tester) async {
    await tester.pumpWidget(panel('Room 1', reduce: true));

    expect(find.text('Room 1'), findsOneWidget);
    expect(transition(), findsNothing);
  });
}
