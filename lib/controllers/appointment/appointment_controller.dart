import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/models/appointment/create_appointment_request.dart';
import 'package:klinik_aurora_portal/models/appointment/create_appointment_response.dart';
import 'package:klinik_aurora_portal/models/appointment/update_appointment_request.dart';
import 'package:klinik_aurora_portal/models/service/create_service_response.dart';

class AppointmentController extends ChangeNotifier {
  ApiResponse<AppointmentResponse>? _appointmentResponse;
  ApiResponse<AppointmentResponse>? get appointmentResponse => _appointmentResponse;

  set appointmentResponse(ApiResponse<AppointmentResponse>? value) {
    _appointmentResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<CreateServiceResponse>> create(
    BuildContext context,
    CreateAppointmentRequest request,
  ) async {
    return ApiController()
        .call(context, method: Method.post, endpoint: 'admin/appointment/create', data: request.toJson())
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: CreateServiceResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateAppointmentResponse>> update(
    BuildContext context,
    UpdateAppointmentRequest request,
  ) async {
    return ApiController()
        .call(context, method: Method.put, endpoint: 'admin/appointment/update', data: request.toJson())
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: UpdateAppointmentResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  Future<ApiResponse<AppointmentResponse>> get(
    BuildContext context,
    int page,
    int pageSize, {
    List<String>? status,
    String? userId,
    String? branchId,
    String? serviceBranchId,
  }) async {
    final queryParams = {
      'appointmentStatus': status,
      if (userId != null) 'userId': userId,
      if (branchId != null) 'branchId': branchId,
      if (serviceBranchId != null) 'serviceBranchId': serviceBranchId,
      'page': page,
      'pageSize': pageSize,
    };

    final queryString = buildQueryString(queryParams);
    final fullEndpoint = 'admin/appointment$queryString';

    return ApiController().call(context, method: Method.get, endpoint: fullEndpoint).then((value) {
      try {
        return ApiResponse(code: value.code, data: AppointmentResponse.fromJson(value.data));
      } catch (e) {
        debugPrint(e.toString());
        return ApiResponse(code: 400, message: e.toString());
      }
    });
  }

  String buildQueryString(Map<String, dynamic> params) {
    final List<String> query = [];

    params.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          query.add('$key=${Uri.encodeQueryComponent(item.toString())}');
        }
      } else if (value != null) {
        query.add('$key=${Uri.encodeQueryComponent(value.toString())}');
      }
    });

    return query.isNotEmpty ? '?${query.join('&')}' : '';
  }
}
