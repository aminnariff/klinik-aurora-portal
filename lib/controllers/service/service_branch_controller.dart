import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/service/update_service_response.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_available_response.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart';
import 'package:klinik_aurora_portal/models/service_branch/update_service_branch_request.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class ServiceBranchController extends ChangeNotifier {
  ServiceBranchResponse? _serviceBranchResponse;
  ServiceBranchResponse? get serviceBranchResponse => _serviceBranchResponse;
  ServiceBranchAvailableResponse? _serviceBranchAvailableResponse;
  ServiceBranchAvailableResponse? get serviceBranchAvailableResponse => _serviceBranchAvailableResponse;

  set serviceBranchResponse(ServiceBranchResponse? value) {
    _serviceBranchResponse = value;
    notifyListeners();
  }

  set serviceBranchAvailableResponse(ServiceBranchAvailableResponse? value) {
    _serviceBranchAvailableResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<ServiceBranchResponse>> getAll(
    BuildContext context,
    int page,
    int pageSize, {
    String? branchId,
    String? serviceId,
    int? serviceBranchStatus,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/service-branch',
          queryParameters: {
            if (notNullOrEmptyString(serviceId)) "serviceId": serviceId,
            if (notNullOrEmptyString(branchId)) "branchId": branchId,
            if (serviceBranchStatus != null) "serviceBranchStatus": serviceBranchStatus,
            'page': page,
            'pageSize': pageSize,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: ServiceBranchResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<ServiceBranchAvailableResponse>> available(BuildContext context, {String? branchId}) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/service-branch/available',
          queryParameters: {if (notNullOrEmptyString(branchId)) "branchId": branchId},
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: ServiceBranchAvailableResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateServiceResponse>> update(
    BuildContext context,
    UpdateServiceBranchRequest request,
  ) async {
    return ApiController()
        .call(
          context,
          method: Method.put,
          endpoint: 'admin/service-branch/update',
          data: {
            "serviceBranchId": request.serviceBranchId,
            "serviceBranchStatus": request.serviceBranchStatus,
            "serviceBranchAvailableTime": request.serviceBranchAvailableTime,
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
