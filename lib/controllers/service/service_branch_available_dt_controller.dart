import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/service/service_branch_available_dt_response.dart';
import 'package:klinik_aurora_portal/models/service/update_service_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class ServiceBranchAvailableDtController extends ChangeNotifier {
  ServiceBranchAvailableDtResponse? _serviceBranchAvailableDtResponse;
  ServiceBranchAvailableDtResponse? get serviceBranchAvailableDtResponse => _serviceBranchAvailableDtResponse;

  set serviceBranchAvailableDtResponse(ServiceBranchAvailableDtResponse? value) {
    _serviceBranchAvailableDtResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<ServiceBranchAvailableDtResponse>> get(
    BuildContext context,
    int page,
    int pageSize, {
    String? branchId,
    String? serviceBranchId,
    int? serviceBranchStatus,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/service-available-datetime',
          queryParameters: {
            if (notNullOrEmptyString(serviceBranchId)) "serviceBranchId": serviceBranchId,
            if (notNullOrEmptyString(branchId)) "branchId": branchId,
            'page': page,
            'pageSize': pageSize,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: ServiceBranchAvailableDtResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateServiceResponse>> create(
    BuildContext context,
    String serviceBranchId,
    List<String> availableDatetimes,
  ) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/service-available-datetime/create',
          data: {"serviceBranchId": serviceBranchId, "availableDatetimes": availableDatetimes},
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: UpdateServiceResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateServiceResponse>> update(
    BuildContext context,
    String serviceBranchAvailableDatetimeId,
    String serviceBranchId,
    List<String> availableDatetimes,
  ) async {
    return ApiController()
        .call(
          context,
          method: Method.put,
          endpoint: 'admin/service-available-datetime/update',
          data: {
            "serviceBranchAvailableDatetimeId": serviceBranchAvailableDatetimeId,
            "serviceBranchId": serviceBranchId,
            "availableDatetimes": availableDatetimes,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: UpdateServiceResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }
}
