import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/promotion/create_promotion_request.dart';
import 'package:klinik_aurora_portal/models/promotion/create_promotion_response.dart';
import 'package:klinik_aurora_portal/models/promotion/promotion_all_response.dart';
import 'package:klinik_aurora_portal/models/promotion/update_promotion_request.dart';
import 'package:klinik_aurora_portal/models/promotion/update_promotion_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class PromotionController extends ChangeNotifier {
  ApiResponse<PromotionAllResponse>? _promotionAllResponse;
  ApiResponse<PromotionAllResponse>? get promotionAllResponse => _promotionAllResponse;

  set promotionAllResponse(ApiResponse<PromotionAllResponse>? value) {
    _promotionAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<PromotionAllResponse>> getAll(BuildContext context, int page, int pageSize,
      {String? promotionName, int? promotionStatus}) async {
    return ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/promotion',
      queryParameters: {
        if (notNullOrEmptyString(promotionName)) 'promotionName': promotionName,
        if (promotionStatus != null) 'promotionStatus': promotionStatus,
        'page': page,
        'pageSize': pageSize,
      },
    ).then((value) {
      try {
        return ApiResponse(code: value.code, data: PromotionAllResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdatePromotionResponse>> remove(BuildContext context, String id) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/promotion/upload/remove',
      data: {
        'id': id,
      },
    ).then((value) {
      try {
        return ApiResponse(code: value.code, data: UpdatePromotionResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<CreatePromotionResponse>> create(
      BuildContext context, CreatePromotionRequest request) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/promotion/create',
      data: {
        "promotionName": request.promotionName,
        "promotionDescription": request.promotionDescription,
        "promotionStartDate": request.promotionStartDate,
        "promotionEndDate": request.promotionEndDate,
        "showOnStart": request.showOnStart,
        "promotionTnc": request.promotionTnc,
        "voucherId": request.voucherId,
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: CreatePromotionResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdatePromotionResponse>> update(
      BuildContext context, UpdatePromotionRequest request) async {
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/promotion/update',
      data: {
        "promotionId": request.promotionId,
        "promotionName": request.promotionName,
        "promotionDescription": request.promotionDescription,
        "promotionStartDate": request.promotionStartDate,
        "promotionEndDate": request.promotionEndDate,
        "showOnStart": request.showOnStart,
        "promotionStatus": request.promotionStatus,
        "promotionTnc": request.promotionTnc,
        "voucherId": request.voucherId,
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: UpdatePromotionResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdatePromotionResponse>> upload(
      BuildContext context, String promotionId, List<FileAttribute> documents) async {
    Dio dio = Dio();
    FormData formData = FormData();

    for (FileAttribute item in documents) {
      formData.files.add(
        MapEntry(
          "promotionImage",
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
    formData.fields.add(MapEntry('promotionId', promotionId));

    try {
      return dio
          .put(
        '${Environment.appUrl}admin/promotion/upload',
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
            data: UpdatePromotionResponse.fromJson(value.data),
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
