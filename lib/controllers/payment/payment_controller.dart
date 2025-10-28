import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/payment/branch_payment_summary_response.dart';
import 'package:klinik_aurora_portal/models/payment/payment_report_response.dart';
import 'package:klinik_aurora_portal/models/payment/payment_success_response.dart';
import 'package:klinik_aurora_portal/models/promotion/update_promotion_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class PaymentController extends ChangeNotifier {
  PaymentReportResponse? _paymentReportResponse;
  PaymentReportResponse? get paymentReportResponse => _paymentReportResponse;
  BranchPaymentSummaryResponse? _branchPaymentReportResponse;
  BranchPaymentSummaryResponse? get branchPaymentReportResponse => _branchPaymentReportResponse;

  set paymentReportResponse(PaymentReportResponse? value) {
    _paymentReportResponse = value;
    notifyListeners();
  }

  set branchPaymentReportResponse(BranchPaymentSummaryResponse? value) {
    _branchPaymentReportResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<PaymentReportResponse>> report(
    BuildContext context, {
    String? startDate,
    String? endDate,
    String? branchId,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/payment/report',
          queryParameters: {
            'startDate': startDate,
            'endDate': endDate,
            if (notNullOrEmptyString(branchId)) 'branchId': branchId,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: PaymentReportResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<BranchPaymentSummaryResponse>> branchReport(
    BuildContext context, {
    String? startDate,
    String? endDate,
    String? branchId,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/payment/branch-summary',
          queryParameters: {
            'startDate': startDate,
            'endDate': endDate,
            if (notNullOrEmptyString(branchId)) 'branchId': branchId,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: BranchPaymentSummaryResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<PaymentSuccessResponse>> successPayment(
    BuildContext context, {
    String? date,
    String? branchId,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/payment/success-payment',
          queryParameters: {'date': date, 'branchId': branchId},
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: PaymentSuccessResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

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
            contentType: item.name != null
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
