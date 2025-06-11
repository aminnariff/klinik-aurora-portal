import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/appointment_dashboard_response.dart';

class AppointmentDashboardController extends ChangeNotifier {
  AppointmentDashboardResponse? _appointmentDashboardResponse;
  AppointmentDashboardResponse? get appointmentDashboardResponse => _appointmentDashboardResponse;

  set appointmentDashboardResponse(AppointmentDashboardResponse? value) {
    _appointmentDashboardResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<AppointmentDashboardResponse>> get(
    BuildContext context, {
    String? branchId,
    String? startDate,
    String? endDate,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/dashboard/appointment',
          queryParameters: {"branchId": branchId, "startDate": startDate, "endDate": endDate},
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: AppointmentDashboardResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }
}
