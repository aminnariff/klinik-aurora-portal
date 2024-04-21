import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/permission/permission_all_response.dart';

class PermissionController extends ChangeNotifier {
  PermissionAllResponse? _permissionAllResponse;
  PermissionAllResponse? get permissionAllResponse => _permissionAllResponse;

  set permissionAllResponse(PermissionAllResponse? value) {
    _permissionAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<PermissionAllResponse>> get(
    BuildContext context,
  ) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/admin-permission',
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: PermissionAllResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }
}
