import 'dart:convert';

/// A seasonal campaign: a date window that can boost points app-wide and
/// re-skin the mobile app.
///
/// `GET /admin/campaigns` returns raw MySQL rows, so keys are snake_case and
/// booleans arrive as TINYINT 0/1.
class Campaign {
  final String id;
  final String name;
  final DateTime? startDate;
  final DateTime? endDate;
  final double globalPointMultiplier;
  final CampaignTheme theme;
  final bool isActive;

  Campaign({
    required this.id,
    required this.name,
    this.startDate,
    this.endDate,
    this.globalPointMultiplier = 1.0,
    CampaignTheme? theme,
    this.isActive = true,
  }) : theme = theme ?? CampaignTheme.empty();

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      startDate: _toDate(json['start_date']),
      endDate: _toDate(json['end_date']),
      globalPointMultiplier: _toDouble(json['global_point_multiplier'], 1.0),
      theme: CampaignTheme.fromJson(json['theme_config']),
      isActive: _toBool(json['is_active'], true),
    );
  }

  /// True when this campaign is the one the mobile app would currently pick up.
  ///
  /// Mirrors the `WHERE now() BETWEEN start_date AND end_date AND is_active`
  /// clause in `public/get-active-campaign.ts`.
  bool get isLive {
    if (!isActive || startDate == null || endDate == null) return false;
    final now = DateTime.now();
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59);
    return !now.isBefore(start) && !now.isAfter(end);
  }

  bool overlaps(Campaign other) {
    if (startDate == null || endDate == null || other.startDate == null || other.endDate == null) {
      return false;
    }
    return !startDate!.isAfter(other.endDate!) && !other.startDate!.isAfter(endDate!);
  }

  static DateTime? _toDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _toBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return fallback;
  }
}

/// The `theme_config` JSON blob consumed by the mobile app.
///
/// Contract lives in `membership-api/docs/campaign-theme-config.md`. Every
/// field is optional — the app falls back per-field, so a partial theme is
/// valid rather than broken.
class CampaignTheme {
  final String? primaryColor;
  final String? accentColor;
  final String? backgroundColor;
  final String? splashUrl;
  final String? bannerUrl;
  final String? backgroundUrl;
  final String? lottieUrl;

  /// How the mobile app scales the background image: `cover`, `contain`, or
  /// null to let the app decide from the image's shape.
  final String? backgroundFit;

  CampaignTheme({
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
    this.splashUrl,
    this.bannerUrl,
    this.backgroundUrl,
    this.lottieUrl,
    this.backgroundFit,
  });

  factory CampaignTheme.empty() => CampaignTheme();

  factory CampaignTheme.fromJson(dynamic raw) {
    // A MySQL JSON column can surface either already-decoded or as a string,
    // depending on driver and column type — `public/get-active-campaign.ts`
    // guards against the same thing. Treating a string as "no theme" would
    // blank every field when editing an existing campaign, and saving would
    // then wipe the stored theme.
    dynamic json = raw;
    if (json is String) {
      try {
        json = jsonDecode(json);
      } catch (e) {
        return CampaignTheme.empty();
      }
    }

    if (json is! Map) return CampaignTheme.empty();
    String? read(String key) {
      final value = json[key];
      if (value is! String) return null;
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    return CampaignTheme(
      primaryColor: read('primaryColor'),
      accentColor: read('accentColor'),
      backgroundColor: read('backgroundColor'),
      splashUrl: read('splashUrl'),
      bannerUrl: read('bannerUrl'),
      backgroundUrl: read('backgroundUrl'),
      lottieUrl: read('lottieUrl'),
      backgroundFit: read('backgroundFit'),
    );
  }

  /// Omits empty fields rather than writing nulls, so the mobile app's
  /// "key absent means use the default" rule holds.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    void put(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) map[key] = value.trim();
    }

    put('primaryColor', primaryColor);
    put('accentColor', accentColor);
    put('backgroundColor', backgroundColor);
    put('splashUrl', splashUrl);
    put('bannerUrl', bannerUrl);
    put('backgroundUrl', backgroundUrl);
    put('lottieUrl', lottieUrl);
    put('backgroundFit', backgroundFit);
    return map;
  }

  bool get isEmpty => toJson().isEmpty;
}
