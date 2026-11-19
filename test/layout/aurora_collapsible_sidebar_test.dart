import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/aurora_collapsible_sidebar.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';

Widget _wrapSidebar({
  required SidebarXController controller,
  required List<SidebarXItem> items,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
    ],
    child: MaterialApp(
      theme: ThemeData(
        extensions: [
          AppColors.light(AuroraThemePreset.auroraPlum),
        ],
      ),
      home: Scaffold(
        body: AuroraCollapsibleSidebar(
          controller: controller,
          allItems: items,
          onAction: (_) {},
          versionWidget: const Text('v1.0.0'),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await Storage.init();
  });

  group('AuroraCollapsibleSidebar', () {
    testWidgets('sidebar width collapses from 255 to 76 on toggleExtended()', (tester) async {
      final controller = SidebarXController(selectedIndex: 0, extended: true);
      final items = [
        const SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
        const SidebarXItem(icon: Icons.calendar_month, label: 'Appointments'),
      ];

      await tester.pumpWidget(_wrapSidebar(controller: controller, items: items));
      await tester.pumpAndSettle();

      final containerFinder = find.byType(AnimatedContainer);
      expect(containerFinder, findsOneWidget);

      RenderBox renderBox = tester.renderObject(containerFinder);
      expect(renderBox.size.width, 255.0);

      // Now toggle extended to false
      controller.toggleExtended();
      await tester.pumpAndSettle();

      // Width must animate to 76.0
      renderBox = tester.renderObject(containerFinder);
      expect(renderBox.size.width, 76.0);

      // Toggle back to true
      controller.toggleExtended();
      await tester.pumpAndSettle();

      renderBox = tester.renderObject(containerFinder);
      expect(renderBox.size.width, 255.0);
    });

    testWidgets('tapping Collapse Sidebar in footer toggles extended state', (tester) async {
      final controller = SidebarXController(selectedIndex: 0, extended: true);
      final items = [
        const SidebarXItem(icon: Icons.dashboard, label: 'Dashboard'),
      ];

      await tester.pumpWidget(_wrapSidebar(controller: controller, items: items));
      await tester.pumpAndSettle();

      expect(controller.extended, isTrue);

      // Tap collapse button
      final collapseFinder = find.text('Collapse Sidebar');
      expect(collapseFinder, findsOneWidget);

      await tester.tap(collapseFinder);
      await tester.pumpAndSettle();

      expect(controller.extended, isFalse);

      final renderBox = tester.renderObject(find.byType(AnimatedContainer)) as RenderBox;
      expect(renderBox.size.width, 76.0);
    });
  });
}
