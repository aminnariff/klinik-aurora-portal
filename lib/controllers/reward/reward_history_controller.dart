import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/reward/create_reward_history_request.dart';
import 'package:klinik_aurora_portal/models/reward/create_reward_history_response.dart';
import 'package:klinik_aurora_portal/models/reward/reward_history_response.dart';
import 'package:klinik_aurora_portal/models/reward/update_reward_history_request.dart';
import 'package:klinik_aurora_portal/models/reward/update_reward_response.dart';

class RewardHistoryController extends ChangeNotifier {
  ApiResponse<RewardHistoryResponse>? _rewardHistoryResponse;
  ApiResponse<RewardHistoryResponse>? get rewardHistoryResponse => _rewardHistoryResponse;

  set rewardHistoryResponse(ApiResponse<RewardHistoryResponse>? value) {
    _rewardHistoryResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<RewardHistoryResponse>> getAll(BuildContext context,
      {String? pointTransactionId, String? rewardId, String? customerName}) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/reward-history',
      queryParameters: rewardId != null || pointTransactionId != null || customerName != null
          ? {
              if (rewardId != null) "rewardId": rewardId,
              if (pointTransactionId != null) "pointTransactionId": pointTransactionId,
              if (customerName != null) "userFullname": customerName,
            }
          : null,
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: RewardHistoryResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<CreateRewardHistoryResponse>> create(
      BuildContext context, CreateRewardHistoryRequest request) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/reward-history/create',
      data: {
        "rewardId": request.rewardId,
        "pointTransactionId": request.pointTransactionId,
        "rewardHistoryDescription": request.rewardHistoryDescription,
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: CreateRewardHistoryResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdateRewardResponse>> update(
      BuildContext context, UpdateRewardHistoryRequest request) async {
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/reward-history/update',
      data: {
        "rewardId": request.rewardId,
        "rewardHistoryId": request.rewardHistoryId,
        "pointTransactionId": request.pointTransactionId,
        "rewardHistoryDescription": request.rewardHistoryDescription,
        "rewardHistoryStatus": request.rewardHistoryStatus, // 1 - in-progress, 0 = completed
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
          "rewardHistoryImage",
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
    formData.fields.add(MapEntry('rewardHistoryId', rewardId));

    try {
      return dio
          .put(
        '${Environment.appUrl}admin/reward-history/upload',
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
