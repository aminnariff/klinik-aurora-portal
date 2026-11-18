import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/splash_theme_sync.dart';
import 'package:klinik_aurora_portal/config/storage.dart';

enum TableDensity { compact, comfortable }

/// Manages Klinik Aurora Portal appearance settings:
/// - Light / Dark / System [ThemeMode]
/// - Curated [AuroraThemePreset] brand accent color (default: Aurora Plum)
/// - Table & control density ([TableDensity.comfortable] / [TableDensity.compact])
///
/// Persists selections in [Storage] and syncs legacy top-level color getters
/// in `config/color.dart` so all views reflect theme updates live.
class DarkModeController extends ChangeNotifier {
  static const String _themeModeKey = 'portal_theme_mode';
  static const String _themePresetKey = 'portal_theme_preset';
  static const String _tableDensityKey = 'portal_table_density';

  ThemeMode _themeMode = ThemeMode.light;
  AuroraThemePreset _preset = AuroraThemePreset.auroraPlum;
  TableDensity _tableDensity = TableDensity.comfortable;

  DarkModeController({
    ThemeMode? initialThemeMode,
    AuroraThemePreset? initialPreset,
    TableDensity? initialTableDensity,
  }) {
    if (initialThemeMode != null) _themeMode = initialThemeMode;
    if (initialPreset != null) _preset = initialPreset;
    if (initialTableDensity != null) _tableDensity = initialTableDensity;
    _syncGlobalColors();
  }

  ThemeMode get themeMode => _themeMode;
  AuroraThemePreset get preset => _preset;
  TableDensity get tableDensity => _tableDensity;
  bool get isCompact => _tableDensity == TableDensity.compact;

  /// Legacy boolean compatibility getter.
  bool get darkMode => _themeMode == ThemeMode.dark;

  /// Legacy boolean compatibility setter.
  set darkMode(bool value) {
    setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  /// Resolves whether dark mode is currently rendered for the given [context].
  bool isDarkActive(BuildContext context) {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }

  /// Loads saved appearance preferences from [prefs] if initialized.
  void loadFromStorage() {
    try {
      final savedMode = prefs.getString(_themeModeKey);
      if (savedMode != null) {
        _themeMode = _parseThemeMode(savedMode);
      }
      final savedPreset = prefs.getString(_themePresetKey);
      if (savedPreset != null) {
        _preset = AuroraThemePreset.fromId(savedPreset);
      }
      final savedDensity = prefs.getString(_tableDensityKey);
      if (savedDensity != null) {
        _tableDensity = savedDensity == 'compact' ? TableDensity.compact : TableDensity.comfortable;
      }
      _syncGlobalColors();
      if (savedMode != null || savedPreset != null) {
        _syncSplash();
      }
      notifyListeners();
    } catch (_) {
      // Safe fallback in widget tests where Storage.init() was not called.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _syncGlobalColors();
    _syncSplash();
    notifyListeners();
    try {
      await prefs.setString(_themeModeKey, _serializeThemeMode(mode));
    } catch (_) {}
  }

  Future<void> setPreset(AuroraThemePreset preset) async {
    if (_preset == preset) return;
    _preset = preset;
    _syncGlobalColors();
    _syncSplash();
    notifyListeners();
    try {
      await prefs.setString(_themePresetKey, preset.id);
    } catch (_) {}
  }

  Future<void> setTableDensity(TableDensity density) async {
    if (_tableDensity == density) return;
    _tableDensity = density;
    notifyListeners();
    try {
      await prefs.setString(_tableDensityKey, density == TableDensity.compact ? 'compact' : 'comfortable');
    } catch (_) {}
  }

  Future<void> toggleDarkMode(BuildContext context) async {
    final currentlyDark = isDarkActive(context);
    await setThemeMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> resetToDefaults() async {
    final changed = _themeMode != ThemeMode.light ||
        _preset != AuroraThemePreset.auroraPlum ||
        _tableDensity != TableDensity.comfortable;
    _themeMode = ThemeMode.light;
    _preset = AuroraThemePreset.auroraPlum;
    _tableDensity = TableDensity.comfortable;
    _syncGlobalColors();
    _syncSplash();
    if (changed) notifyListeners();
    try {
      await prefs.setString(_themeModeKey, _serializeThemeMode(_themeMode));
      await prefs.setString(_themePresetKey, _preset.id);
      await prefs.setString(_tableDensityKey, 'comfortable');
    } catch (_) {}
  }

  void _syncGlobalColors() {
    syncActiveBrandTheme(
      preset: _preset,
      isDark: _themeMode == ThemeMode.dark,
    );
  }

  void _syncSplash() {
    syncSplashAppearance(
      themeMode: _serializeThemeMode(_themeMode),
      presetId: _preset.id,
    );
  }

  static ThemeMode _parseThemeMode(String raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  static String _serializeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }
}

typedef ThemeController = DarkModeController;
