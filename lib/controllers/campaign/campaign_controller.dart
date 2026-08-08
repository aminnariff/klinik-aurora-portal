import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/campaign/campaign.dart';

class CampaignController {
  /// `GET /admin/campaigns` returns a bare JSON array, not the `{data: [...]}`
  /// envelope most endpoints in this portal use.
  static Future<ApiResponse<List<Campaign>>> getAll(BuildContext context) {
    return ApiController().call(context, method: Method.get, endpoint: 'admin/campaigns').then((value) {
      try {
        final raw = value.data;
        if (raw is! List) {
          return ApiResponse<List<Campaign>>(code: value.code, data: const []);
        }
        return ApiResponse<List<Campaign>>(
          code: value.code,
          data: raw.whereType<Map<String, dynamic>>().map(Campaign.fromJson).toList(),
        );
      } catch (e) {
        return ApiResponse<List<Campaign>>(code: 400, message: e.toString());
      }
    });
  }

  static Future<ApiResponse> create(
    BuildContext context, {
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double globalPointMultiplier,
    required CampaignTheme theme,
    required bool isActive,
  }) {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/campaigns',
      data: {
        'name': name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'global_point_multiplier': globalPointMultiplier,
        'theme_config': theme.toJson(),
        'is_active': isActive,
      },
    );
  }

  static Future<ApiResponse> update(
    BuildContext context, {
    required String id,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double globalPointMultiplier,
    required CampaignTheme theme,
    required bool isActive,
  }) {
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/campaigns/$id',
      data: {
        'name': name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'global_point_multiplier': globalPointMultiplier,
        'theme_config': theme.toJson(),
        'is_active': isActive,
      },
    );
  }

  static Future<ApiResponse> delete(BuildContext context, String id) {
    return ApiController().call(context, method: Method.delete, endpoint: 'admin/campaigns/$id');
  }
}
