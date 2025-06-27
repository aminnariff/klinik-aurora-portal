import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/promotion/update_promotion_response.dart';

class PaymentController extends ChangeNotifier {
  static Future<ApiResponse<UpdatePromotionResponse>> upload(
    BuildContext context,
    String appointmentId,
    String userId,
    int paymentType,
    String paymentAmount,
    List<FileAttribute> documents,
  ) async {
    Dio dio = Dio();
    FormData formData = FormData();

    for (FileAttribute item in documents) {
      formData.files.add(
        MapEntry(
          "paymentProof",
          MultipartFile.fromBytes(
            item.value!,
            filename: item.name,
            contentType:
                item.name != null
                    ? item.name!.contains(".pdf")
                        ? MediaType("application", "pdf")
                        : MediaType("image", item.name.toString().split(".").last)
                    : MediaType("image", item.name.toString().split(".").last),
          ),
        ),
      );
    }
    formData.fields.add(MapEntry('appointmentId', appointmentId));
    formData.fields.add(MapEntry('userId', userId));
    formData.fields.add(MapEntry('paymentType', paymentType.toString()));
    formData.fields.add(MapEntry('paymentAmount', paymentAmount.toString()));

    try {
      return dio
          .put(
            '${Environment.appUrl}admin/payment/upload',
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
              return ApiResponse(code: value.statusCode, data: UpdatePromotionResponse.fromJson(value.data));
            } catch (e) {
              return ApiResponse(code: 400, message: e.toString());
            }
          });
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }
}
