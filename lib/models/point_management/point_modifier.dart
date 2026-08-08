/// A bonus rule applied on top of base points when awarding a transaction —
/// e.g. "Buku Pink Bonus".
///
/// `GET /admin/point-modifiers` returns raw MySQL rows, so the JSON keys are
/// snake_case. Reading them as camelCase silently yields nulls.
class PointModifier {
  final String id;
  final String itemName;
  final double multiplier;
  final int fixedBonus;
  final bool isActive;

  /// Validity window. Null on either side means unbounded, so a modifier with
  /// both null is simply always available while [isActive].
  final DateTime? startDate;
  final DateTime? endDate;

  PointModifier({
    required this.id,
    required this.itemName,
    this.multiplier = 1.0,
    this.fixedBonus = 0,
    this.isActive = true,
    this.startDate,
    this.endDate,
  });

  factory PointModifier.fromJson(Map<String, dynamic> json) {
    return PointModifier(
      id: json['id']?.toString() ?? '',
      itemName: json['item_name']?.toString() ?? '',
      multiplier: _toDouble(json['multiplier'], 1.0),
      fixedBonus: _toInt(json['fixed_bonus'], 0),
      // MySQL BOOLEAN is TINYINT(1), so this arrives as 0/1 rather than a bool.
      isActive: _toBool(json['is_active'], true),
      startDate: _toDate(json['start_date']),
      endDate: _toDate(json['end_date']),
    );
  }

  /// Keys here are what the API *accepts* on write, which the controllers map
  /// to snake_case columns — deliberately not the mirror of [fromJson].
  Map<String, dynamic> toJson() {
    return {'item_name': itemName, 'multiplier': multiplier, 'fixed_bonus': fixedBonus, 'is_active': isActive};
  }

  /// Whether staff can apply this right now. The server re-checks the same
  /// condition when points are awarded — this only drives what the UI offers.
  bool get isAvailableNow {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  bool get hasExpired => endDate != null && DateTime.now().isAfter(endDate!);

  bool get isScheduled => startDate != null && DateTime.now().isBefore(startDate!);

  /// Human description of the window, e.g. "Until 31 Aug 2026".
  String get windowLabel {
    String fmt(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';
    if (startDate == null && endDate == null) return 'Always available';
    if (startDate == null) return 'Until ${fmt(endDate!)}';
    if (endDate == null) return 'From ${fmt(startDate!)}';
    return '${fmt(startDate!)} – ${fmt(endDate!)}';
  }

  /// Points contributed by this modifier on top of [basePoints].
  ///
  /// Mirrors the server-side formula in `admin/point-management/create-point.ts`
  /// so the portal can preview a total without a round trip.
  int bonusFor(int basePoints) {
    return ((basePoints * multiplier) - basePoints).floor() + fixedBonus;
  }

  String get summary {
    final parts = <String>[];
    if (multiplier != 1.0) parts.add('${multiplier}x');
    if (fixedBonus != 0) parts.add('+$fixedBonus pts');
    return parts.isEmpty ? 'No effect' : parts.join(' and ');
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _toInt(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _toBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return fallback;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
