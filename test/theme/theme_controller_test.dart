import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/theme.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/views/settings/appearance_settings_dialog.dart';
import 'package:provider/provider.dart';

double _contrastRatio(Color fg, Color bg) {
  final l1 = fg.computeLuminance();
  final l2 = bg.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AuroraThemePreset WCAG contrast verification', () {
    for (final preset in AuroraThemePreset.values) {
      test('${preset.name} meets WCAG AA (>=4.5:1) in light and dark modes', () {
        final lightTokens = AppColors.light(preset);
        final darkTokens = AppColors.dark(preset);

        // White text on light primary button
        expect(
          _contrastRatio(Colors.white, lightTokens.brandPrimary),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} light button contrast',
        );

        // White text on dark primary button
        expect(
          _contrastRatio(Colors.white, darkTokens.brandPrimary),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} dark button contrast',
        );

        // Accessible brand text on dark surface
        expect(
          _contrastRatio(darkTokens.brandText, darkTokens.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} dark accessible text contrast',
        );

        // Muted ink on light & dark surfaces
        expect(
          _contrastRatio(lightTokens.inkMuted, lightTokens.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} light muted ink contrast',
        );
        expect(
          _contrastRatio(darkTokens.inkMuted, darkTokens.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${preset.name} dark muted ink contrast',
        );
      });
    }
  });

  group('DarkModeController', () {
    test('defaults to Light mode and Aurora Berry preset', () {
      final ctrl = DarkModeController();
      expect(ctrl.themeMode, ThemeMode.light);
      expect(ctrl.preset, AuroraThemePreset.auroraBerry);
      expect(primary, AuroraThemePreset.auroraBerry.primaryLight);
    });

    test('switches preset and dark mode live and resets cleanly', () async {
      final ctrl = DarkModeController();

      await ctrl.setPreset(AuroraThemePreset.auroraPetrol);
      expect(ctrl.preset, AuroraThemePreset.auroraPetrol);
      expect(primary, AuroraThemePreset.auroraPetrol.primaryLight);

      await ctrl.setThemeMode(ThemeMode.dark);
      expect(ctrl.darkMode, isTrue);
      expect(primary, AuroraThemePreset.auroraPetrol.primaryDark);
      expect(appSurface, const Color(0xFF111B22));
      expect(appDangerSoft, const Color(0xFF3B1519));

      await ctrl.setTableDensity(TableDensity.compact);
      expect(ctrl.isCompact, isTrue);

      await ctrl.resetToDefaults();
      expect(ctrl.themeMode, ThemeMode.light);
      expect(ctrl.preset, AuroraThemePreset.auroraBerry);
      expect(ctrl.tableDensity, TableDensity.comfortable);
      expect(primary, AuroraThemePreset.auroraBerry.primaryLight);
      expect(appSurface, const Color(0xFFFFFFFF));
      expect(appDangerSoft, const Color(0xFFFEF2F2));
    });
  });

  group('AppearanceSettingsDialog widget', () {
    testWidgets('renders presets, density toggle, and live-updates controller on tap', (tester) async {
      final ctrl = DarkModeController();

      await tester.pumpWidget(
        ChangeNotifierProvider<DarkModeController>.value(
          value: ctrl,
          child: Consumer<DarkModeController>(
            builder: (context, themeCtrl, _) => MaterialApp(
              theme: buildLightTheme(context, themeCtrl.preset, themeCtrl.tableDensity),
              darkTheme: buildDarkTheme(context, themeCtrl.preset, themeCtrl.tableDensity),
              themeMode: themeCtrl.themeMode,
              home: const Scaffold(body: AppearanceSettingsDialog()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance & Theme'), findsOneWidget);
      expect(find.text('Workspace Density'), findsOneWidget);
      expect(find.text('Aurora Plum'), findsWidgets);
      expect(find.text('Aurora Berry'), findsWidgets);

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(ctrl.themeMode, ThemeMode.dark);

      await tester.tap(find.text('Compact'));
      await tester.pumpAndSettle();
      expect(ctrl.tableDensity, TableDensity.compact);

      await tester.ensureVisible(find.text('Aurora Plum').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aurora Plum').first);
      await tester.pumpAndSettle();
      expect(ctrl.preset, AuroraThemePreset.auroraPlum);

      await tester.ensureVisible(find.text('Reset Default'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset Default'));
      await tester.pumpAndSettle();
      expect(ctrl.themeMode, ThemeMode.light);
      expect(ctrl.preset, AuroraThemePreset.auroraBerry);
      expect(ctrl.tableDensity, TableDensity.comfortable);
    });
  });
}
