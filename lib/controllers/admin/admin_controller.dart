import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/admin/admin_all_response.dart';

class AdminController extends ChangeNotifier {
  AdminAllResponse? _adminAllResponse;
  AdminAllResponse? get adminAllResponse => _adminAllResponse;

  set adminAllResponse(AdminAllResponse? value) {
    _adminAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<AdminAllResponse>> getAll(
    BuildContext context,
  ) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/admin-management',
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: AdminAllResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }
}
