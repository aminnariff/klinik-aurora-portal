import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/service/service_branch_exception_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class ServiceBranchExceptionController extends ChangeNotifier {
  ServiceBranchExceptionResponse? _serviceBranchExceptionResponse;
  ServiceBranchExceptionResponse? get serviceBranchExceptionResponse => _serviceBranchExceptionResponse;

  set serviceBranchExceptionResponse(ServiceBranchExceptionResponse? value) {
    _serviceBranchExceptionResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<ServiceBranchExceptionResponse>> get(
    BuildContext context,
    int page,
    int pageSize, {
    String? branchId,
    String? serviceBranchId,
    String? serviceId,
    String? exceptionDate,
    String? exceptionTime,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/service-branch-exception',
          queryParameters: {
            if (notNullOrEmptyString(serviceBranchId)) "serviceBranchId": serviceBranchId,
            if (notNullOrEmptyString(branchId)) "branchId": branchId,
            if (notNullOrEmptyString(serviceId)) "serviceId": serviceId,
            if (notNullOrEmptyString(exceptionDate)) "exceptionDate": exceptionDate,
            if (notNullOrEmptyString(exceptionTime)) "exceptionTime": exceptionTime,
            'page': page,
            'pageSize': pageSize,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: ServiceBranchExceptionResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static String convertToUtcIsoString(String date, String time) {
    try {
      // Step 1: Combine date and time into one string
      final combined = '$date $time'; // e.g. "2025-06-25 17:00:00"

      // Step 2: Parse into local DateTime
      final localDateTime = DateTime.parse(combined);

      // Step 3: Convert to UTC
      final utcDateTime = localDateTime.toUtc();

      // Step 4: Return ISO string with 'Z' to indicate UTC
      return utcDateTime.toIso8601String();
    } catch (e) {
      return '';
    }
  }
}
