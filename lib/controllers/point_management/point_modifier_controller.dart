import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/point_modifier.dart';

class PointModifierController {
  /// `GET /admin/point-modifiers` returns a bare JSON array of MySQL rows.
  ///
  /// [activeNow] asks the server for only what staff may apply this moment —
  /// active and inside its validity window. The management screen omits it so
  /// expired and scheduled modifiers stay visible and editable.
  static Future<ApiResponse<List<PointModifier>>> getAll(BuildContext context, {bool activeNow = false}) {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/point-modifiers',
          queryParameters: activeNow ? {'activeNow': '1'} : null,
        )
        .then((value) {
      try {
        final raw = value.data;
        if (raw is! List) {
          return ApiResponse<List<PointModifier>>(code: value.code, data: const []);
        }
        return ApiResponse<List<PointModifier>>(
          code: value.code,
          data: raw.whereType<Map<String, dynamic>>().map(PointModifier.fromJson).toList(),
        );
      } catch (e) {
        return ApiResponse<List<PointModifier>>(code: 400, message: e.toString());
      }
    });
  }

  /// What the point-awarding screen should offer — filtered by the server so a
  /// modifier that expired since page load cannot be applied.
  static Future<ApiResponse<List<PointModifier>>> getActive(BuildContext context) {
    return getAll(context, activeNow: true);
  }

  static Future<ApiResponse> create(
    BuildContext context, {
    required String itemName,
    required double multiplier,
    required int fixedBonus,
    required bool isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/point-modifiers',
      data: {
        'item_name': itemName,
        'multiplier': multiplier,
        'fixed_bonus': fixedBonus,
        'is_active': isActive,
        'start_date': _localIso(startDate),
        'end_date': _localIso(endDate),
      },
    );
  }

  static Future<ApiResponse> update(
    BuildContext context, {
    required String id,
    required String itemName,
    required double multiplier,
    required int fixedBonus,
    required bool isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/point-modifiers/$id',
      data: {
        'item_name': itemName,
        'multiplier': multiplier,
        'fixed_bonus': fixedBonus,
        'is_active': isActive,
        // Sent even when null so clearing a date actually clears the column —
        // the API treats an absent key as "leave unchanged".
        'start_date': _localIso(startDate),
        'end_date': _localIso(endDate),
      },
    );
  }

  /// Local time without a zone suffix: the column is a zone-less MySQL DATETIME
  /// compared against the server's NOW(), so converting to UTC would shift the
  /// window by the timezone offset.
  static String? _localIso(DateTime? value) {
    if (value == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)}'
        'T${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
  }

  static Future<ApiResponse> delete(BuildContext context, String id) {
    return ApiController().call(context, method: Method.delete, endpoint: 'admin/point-modifiers/$id');
  }
}
