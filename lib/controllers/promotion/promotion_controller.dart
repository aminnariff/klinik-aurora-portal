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

class PromotionController extends ChangeNotifier {
  ApiResponse<PromotionAllResponse>? _promotionAllResponse;
  ApiResponse<PromotionAllResponse>? get promotionAllResponse => _promotionAllResponse;

  set promotionAllResponse(ApiResponse<PromotionAllResponse>? value) {
    _promotionAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<PromotionAllResponse>> getAll(
    BuildContext context,
  ) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/promotion',
    )
        .then((value) {
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

  static Future<ApiResponse<CreatePromotionResponse>> create(
      String orderReference, CreatePromotionRequest request) async {
    Dio dio = Dio();
    FormData formData = FormData();

    for (FileAttribute item in request.documents) {
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
    formData.fields.add(MapEntry('promotionName', request.promotionName));
    formData.fields.add(MapEntry('promotionDescription', request.promotionDescription));
    if (request.promotionTnc != null) {
      formData.fields.add(MapEntry('promotionTnc', request.promotionTnc!));
    }
    formData.fields.add(MapEntry('promotionStartDate', request.promotionStartDate));
    formData.fields.add(MapEntry('promotionEndDate', request.promotionEndDate));
    if (request.voucherId != null) {
      formData.fields.add(MapEntry('voucherId', request.voucherId!));
    }
    formData.fields.add(MapEntry('showOnStart', request.showOnStart.toString()));

    debugPrint(formData.fields.toString());
    debugPrint(formData.files[0].value.filename);
    debugPrint(formData.files.toString());
    try {
      return dio
          .post(
        '${Environment.appUrl}admin/promotion/create',
        options: Options(
          method: 'POST',
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
            data: CreatePromotionResponse.fromJson(value.data),
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

  static Future<ApiResponse<UpdatePromotionResponse>> update(
      String orderReference, UpdatePromotionRequest request) async {
    Dio dio = Dio();
    FormData formData = FormData();

    for (FileAttribute item in request.documents) {
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
    formData.fields.add(MapEntry('promotionId', request.promotionId));
    formData.fields.add(MapEntry('promotionName', request.promotionName));
    formData.fields.add(MapEntry('promotionDescription', request.promotionDescription));
    if (request.promotionTnc != null) {
      formData.fields.add(MapEntry('promotionTnc', request.promotionTnc!));
    }
    formData.fields.add(MapEntry('promotionStartDate', request.promotionStartDate));
    formData.fields.add(MapEntry('promotionEndDate', request.promotionEndDate));
    if (request.voucherId != null) {
      formData.fields.add(MapEntry('voucherId', request.voucherId!));
    }
    formData.fields.add(MapEntry('showOnStart', request.showOnStart.toString()));
    formData.fields.add(MapEntry('promotionStatus', request.promotionStatus.toString()));

    debugPrint(formData.fields.toString());
    debugPrint(formData.files[0].value.filename);
    debugPrint(formData.files.toString());
    try {
      return dio
          .put(
        '${Environment.appUrl}admin/promotion/update',
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
