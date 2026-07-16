import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/service_performance_response.dart';

class ServicePerformanceController extends ChangeNotifier {
  ServicePerformanceResponse? _servicePerformanceResponse;
  ServicePerformanceResponse? get servicePerformanceResponse => _servicePerformanceResponse;

  set servicePerformanceResponse(ServicePerformanceResponse? value) {
    _servicePerformanceResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<ServicePerformanceResponse>> get(
    BuildContext context, {
    String? startDate,
    String? endDate,
    String? branchId,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/dashboard/service-performance',
          queryParameters: {'startDate': ?startDate, 'endDate': ?endDate, 'branchId': ?branchId},
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: ServicePerformanceResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }
}
