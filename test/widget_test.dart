import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Widget environment smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ScreenUtilInit(
        designSize: Size(1728, 829),
        child: MaterialApp(
          home: Scaffold(
            body: Text('Klinik Aurora Portal'),
          ),
        ),
      ),
    );
    expect(find.text('Klinik Aurora Portal'), findsOneWidget);
  });
}
