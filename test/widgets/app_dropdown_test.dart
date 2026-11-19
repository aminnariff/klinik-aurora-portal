import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';

void main() {
  testWidgets('AppDropdown expands to full width in bounded Column by default', (tester) async {
    const parentWidth = 450.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: parentWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdown(
                    attributeList: DropdownAttributeList(
                      [
                        DropdownAttribute('1', 'Branch A'),
                        DropdownAttribute('2', 'Branch B'),
                      ],
                      labelText: 'Branch',
                      value: 'Branch A',
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final dropdownFinder = find.byType(AppDropdown);
    expect(dropdownFinder, findsOneWidget);

    final RenderBox renderBox = tester.renderObject(dropdownFinder);
    expect(renderBox.size.width, equals(parentWidth));
  });

  testWidgets('AppDropdown respects explicit width when provided', (tester) async {
    const explicitWidth = 220.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 500.0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppDropdown(
                    attributeList: DropdownAttributeList(
                      [
                        DropdownAttribute('1', 'Active'),
                        DropdownAttribute('0', 'Inactive'),
                      ],
                      labelText: 'Status',
                      width: explicitWidth,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final dropdownFinder = find.byType(AppDropdown);
    expect(dropdownFinder, findsOneWidget);

    final RenderBox renderBox = tester.renderObject(dropdownFinder);
    expect(renderBox.size.width, equals(explicitWidth));
  });
}
