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

class RewardController extends ChangeNotifier {
  ApiResponse<RewardAllResponse>? _rewardAllResponse;
  ApiResponse<RewardAllResponse>? get rewardAllResponse => _rewardAllResponse;

  set rewardAllResponse(ApiResponse<RewardAllResponse>? value) {
    _rewardAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<RewardAllResponse>> getAll(BuildContext context, int page, int pageSize,
      {String? rewardName, String? rewardId, int? rewardStatus}) async {
    return ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/reward-management',
      queryParameters: {
        if (notNullOrEmptyString(rewardId)) "rewardId": rewardId,
        if (notNullOrEmptyString(rewardName)) "rewardName": rewardName,
        if (rewardStatus != null) "rewardStatus": rewardStatus,
        'page': page,
        'pageSize': pageSize,
      },
    ).then((value) {
      try {
        return ApiResponse(code: value.code, data: RewardAllResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<CreateRewardResponse>> create(BuildContext context, CreateRewardRequest request) async {
    return ApiController().call(
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
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: CreateRewardResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdateRewardResponse>> update(BuildContext context, UpdateRewardRequest request) async {
    return ApiController().call(
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
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: UpdateRewardResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdateRewardResponse>> upload(
      BuildContext context, String rewardId, FileAttribute document) async {
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
      return dio
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
          return ApiResponse(
            code: value.statusCode,
            data: UpdateRewardResponse.fromJson(value.data),
          );
        } catch (e) {
          return ApiResponse(
            code: 400,
            message: e.toString(),
          );
        }
      });
    } catch (e) {
      return ApiResponse(
        code: 400,
        message: e.toString(),
      );
    }
  }
}
