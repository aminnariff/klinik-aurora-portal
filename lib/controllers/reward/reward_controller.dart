import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/reward/create_reward_request.dart';
import 'package:klinik_aurora_portal/models/reward/create_reward_response.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart';
import 'package:klinik_aurora_portal/models/reward/update_reward_request.dart';
import 'package:klinik_aurora_portal/models/reward/update_reward_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class EligibleRewardItem {
  final String rewardId;
  final String rewardName;
  final String? rewardDescription;
  final int rewardPoint;
  final String? rewardImage;
  final int? remaining;

  const EligibleRewardItem({
    required this.rewardId,
    required this.rewardName,
    this.rewardDescription,
    required this.rewardPoint,
    this.rewardImage,
    this.remaining,
  });

  factory EligibleRewardItem.fromJson(Map<String, dynamic> json) {
    return EligibleRewardItem(
      rewardId: json['rewardId']?.toString() ?? '',
      rewardName: json['rewardName']?.toString() ?? '',
      rewardDescription: json['rewardDescription']?.toString(),
      rewardPoint: (json['rewardPoint'] as num?)?.toInt() ?? 0,
      rewardImage: json['rewardImage']?.toString(),
      remaining: (json['remaining'] as num?)?.toInt(),
    );
  }
}

class EligibleRewardsResult {
  final int currentPoints;
  final List<EligibleRewardItem> rewards;

  const EligibleRewardsResult({
    required this.currentPoints,
    required this.rewards,
  });

  factory EligibleRewardsResult.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    return EligibleRewardsResult(
      currentPoints: (d['currentPoints'] as num?)?.toInt() ?? 0,
      rewards: ((d['rewards'] as List?) ?? [])
          .whereType<Map<String, dynamic>>()
          .map(EligibleRewardItem.fromJson)
          .toList(),
    );
  }
}

class AdminClaimRewardResult {
  final String rewardId;
  final String rewardName;
  final int pointsDeducted;
  final int newTotalPoints;

  const AdminClaimRewardResult({
    required this.rewardId,
    required this.rewardName,
    required this.pointsDeducted,
    required this.newTotalPoints,
  });

  factory AdminClaimRewardResult.fromJson(Map<String, dynamic> json) {
    final d = (json['data'] as Map<String, dynamic>?) ?? json;
    return AdminClaimRewardResult(
      rewardId: d['rewardId']?.toString() ?? '',
      rewardName: d['rewardName']?.toString() ?? '',
      pointsDeducted: (d['pointsDeducted'] as num?)?.toInt() ?? 0,
      newTotalPoints: (d['newTotalPoints'] as num?)?.toInt() ?? 0,
    );
  }
}

class RewardController extends ChangeNotifier {
  ApiResponse<RewardAllResponse>? _rewardAllResponse;
  ApiResponse<RewardAllResponse>? get rewardAllResponse => _rewardAllResponse;

  set rewardAllResponse(ApiResponse<RewardAllResponse>? value) {
    _rewardAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<RewardAllResponse>> getAll(
    BuildContext context,
    int page,
    int pageSize, {
    String? rewardName,
    String? rewardId,
    int? rewardStatus,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/reward-management',
          queryParameters: {
            if (notNullOrEmptyString(rewardId)) "rewardId": rewardId,
            if (notNullOrEmptyString(rewardName)) "rewardName": rewardName,
            "rewardStatus": ?rewardStatus,
            'page': page,
            'pageSize': pageSize,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: RewardAllResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<CreateRewardResponse>> create(BuildContext context, CreateRewardRequest request) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/reward-management/create',
          data: {
            "rewardName": request.rewardName,
            "rewardDescription": request.rewardDescription,
            "rewardStartDate": request.rewardStartDate, // set null or "" for no restrict date
            "rewardEndDate": request.rewardEndDate, // set null or "" for no restrict date
            "totalReward": request.totalReward, // set 0 to set for unlimited item
            "rewardPoint": request.rewardPoint,
            "rewardImage": request.rewardImage,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: CreateRewardResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateRewardResponse>> update(BuildContext context, UpdateRewardRequest request) async {
    return ApiController()
        .call(
          context,
          method: Method.put,
          endpoint: 'admin/reward-management/update',
          data: {
            "rewardId": request.rewardId,
            "rewardName": request.rewardName,
            "rewardDescription": request.rewardDescription,
            "rewardStartDate": request.rewardStartDate, // set null or "" for no restrict date
            "rewardEndDate": request.rewardEndDate, // set null or "" for no restrict date
            "totalReward": request.totalReward,
            "rewardStatus": request.rewardStatus,
            "rewardPoint": request.rewardPoint, // set 0 to set for unlimited item
            "rewardImage": request.rewardImage,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: UpdateRewardResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateRewardResponse>> upload(
    BuildContext context,
    String rewardId,
    FileAttribute document,
  ) async {
    Dio dio = Dio();
    FormData formData = FormData();

    for (FileAttribute item in [document]) {
      formData.files.add(
        MapEntry(
          "rewardImage",
          MultipartFile.fromBytes(
            item.value!,
            filename: item.name,
            contentType: item.name != null
                ? item.name!.contains(".pdf")
                      ? MediaType("application", "pdf")
                      : MediaType("image", item.name.toString().split(".").last)
                : MediaType("image", item.name.toString().split(".").last),
          ),
        ),
      );
    }
    formData.fields.add(MapEntry('rewardId', rewardId));

    try {
      return await dio
          .put(
            '${Environment.appUrl}admin/reward-management/upload',
            options: Options(
              method: 'PUT',
              headers: {
                Headers.acceptHeader: "*/*",
                Headers.contentTypeHeader: "multipart/form-data",
                'Authorization': 'Bearer ${prefs.getString(token)}',
              },
              contentType: "multipart/form-data",
              responseType: ResponseType.json,
            ),
            data: formData,
          )
          .then((value) {
            try {
              return ApiResponse(code: value.statusCode, data: UpdateRewardResponse.fromJson(value.data));
            } catch (e) {
              return ApiResponse(code: 400, message: e.toString());
            }
          });
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }

  static Future<ApiResponse<EligibleRewardsResult>> getEligibleForPatient(
    BuildContext context,
    String userId,
  ) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/reward-management/eligible',
          queryParameters: {'userId': userId},
        )
        .then((value) {
          try {
            return ApiResponse(
              code: value.code,
              message: value.message,
              data: value.data != null ? EligibleRewardsResult.fromJson(value.data) : null,
            );
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<AdminClaimRewardResult>> claimForPatient(
    BuildContext context, {
    required String userId,
    required String rewardId,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/reward-management/claim',
          data: {'userId': userId, 'rewardId': rewardId},
        )
        .then((value) {
          try {
            return ApiResponse(
              code: value.code,
              message: value.message,
              data: value.data != null ? AdminClaimRewardResult.fromJson(value.data) : null,
            );
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }
}
