import 'package:flutter/material.dart';

/// Curated, WCAG AA/AAA-verified brand accent presets for Klinik Aurora Portal.
///
/// Default is [AuroraThemePreset.auroraPlum] (#7E2D40), derived directly from
/// Klinik Aurora's signature brand identity and paired as a crisp
/// split-complementary accent against the deep slate-teal navigation sidebar.
enum AuroraThemePreset {
  auroraPlum(
    id: 'aurora_plum',
    name: 'Aurora Plum',
    subtitle: 'Signature clinical burgundy',
    primaryLight: Color(0xFF7E2D40),
    primaryHoverLight: Color(0xFF662233),
    primaryDark: Color(0xFFA83E58),
    primaryHoverDark: Color(0xFFC24C69),
    accessibleTextLight: Color(0xFF7E2D40),
    accessibleTextDark: Color(0xFFF3A6B9),
    gradientEndLight: Color(0xFF5A1E2D),
    contrastBadge: 'AAA 9.2:1',
  ),
  auroraBerry(
    id: 'aurora_berry',
    name: 'Aurora Berry',
    subtitle: 'Warm jewel-tone rose',
    primaryLight: Color(0xFF9D2B54),
    primaryHoverLight: Color(0xFF7F1D42),
    primaryDark: Color(0xFFBE3C6B),
    primaryHoverDark: Color(0xFFD64D7F),
    accessibleTextLight: Color(0xFF9D2B54),
    accessibleTextDark: Color(0xFFF5A3C3),
    gradientEndLight: Color(0xFF6F1B3B),
    contrastBadge: 'AAA 7.6:1',
  ),
  auroraPetrol(
    id: 'aurora_petrol',
    name: 'Aurora Petrol',
    subtitle: 'Ocean slate matched to sidebar',
    primaryLight: Color(0xFF165E73),
    primaryHoverLight: Color(0xFF0F4859),
    primaryDark: Color(0xFF1F7D99),
    primaryHoverDark: Color(0xFF2893B3),
    accessibleTextLight: Color(0xFF165E73),
    accessibleTextDark: Color(0xFF7DD3E8),
    gradientEndLight: Color(0xFF0E4150),
    contrastBadge: 'AAA 7.4:1',
  ),
  clinicalTeal(
    id: 'clinical_teal',
    name: 'Clinical Teal',
    subtitle: 'Classic healthcare teal',
    primaryLight: Color(0xFF0F766E),
    primaryHoverLight: Color(0xFF0C5E58),
    primaryDark: Color(0xFF0E7D74),
    primaryHoverDark: Color(0xFF139187),
    accessibleTextLight: Color(0xFF0F766E),
    accessibleTextDark: Color(0xFF5EEAD4),
    gradientEndLight: Color(0xFF1B545E),
    contrastBadge: 'AA 5.5:1',
  ),
  auroraIndigo(
    id: 'aurora_indigo',
    name: 'Aurora Indigo',
    subtitle: 'Executive clinical navy-violet',
    primaryLight: Color(0xFF3730A3),
    primaryHoverLight: Color(0xFF2B2580),
    primaryDark: Color(0xFF554CE0),
    primaryHoverDark: Color(0xFF6B63EB),
    accessibleTextLight: Color(0xFF3730A3),
    accessibleTextDark: Color(0xFFA5B4FC),
    gradientEndLight: Color(0xFF272275),
    contrastBadge: 'AAA 9.8:1',
  ),
  auroraEmerald(
    id: 'aurora_emerald',
    name: 'Aurora Emerald',
    subtitle: 'Botanical deep green',
    primaryLight: Color(0xFF047857),
    primaryHoverLight: Color(0xFF065F46),
    primaryDark: Color(0xFF067E5B),
    primaryHoverDark: Color(0xFF0A936B),
    accessibleTextLight: Color(0xFF047857),
    accessibleTextDark: Color(0xFF6EE7B7),
    gradientEndLight: Color(0xFF065F46),
    contrastBadge: 'AA 5.5:1',
  );

  final String id;
  final String name;
  final String subtitle;
  final Color primaryLight;
  final Color primaryHoverLight;
  final Color primaryDark;
  final Color primaryHoverDark;
  final Color accessibleTextLight;
  final Color accessibleTextDark;
  final Color gradientEndLight;
  final String contrastBadge;

  const AuroraThemePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.primaryLight,
    required this.primaryHoverLight,
    required this.primaryDark,
    required this.primaryHoverDark,
    required this.accessibleTextLight,
    required this.accessibleTextDark,
    required this.gradientEndLight,
    required this.contrastBadge,
  });

  Color primaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primaryLight;

  Color hoverFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryHoverDark : primaryHoverLight;

  Color accessibleTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? accessibleTextDark : accessibleTextLight;

  List<Color> gradientFor(Brightness brightness) => brightness == Brightness.dark
      ? [primaryDark, primaryLight]
      : [primaryLight, gradientEndLight];

  static AuroraThemePreset fromId(String? id) {
    if (id == null || id.isEmpty) return AuroraThemePreset.auroraBerry;
    for (final preset in AuroraThemePreset.values) {
      if (preset.id == id) return preset;
    }
    return AuroraThemePreset.auroraBerry;
  }
}
