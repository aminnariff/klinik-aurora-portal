import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/dashboard_response.dart';

class DashboardController extends ChangeNotifier {
  DashboardResponse? _dashboardResponse;
  DashboardResponse? get dashboardResponse => _dashboardResponse;

  set dashboardResponse(DashboardResponse? value) {
    _dashboardResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<DashboardResponse>> get(BuildContext context, {String? branchId}) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/dashboard',
    )
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: DashboardResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }
}
