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

  static Future<ApiResponse> create(
    BuildContext context, {
    required String permissionName,
  }) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/admin-permission',
      data: {
        'roleName': permissionName,
        'permissionName': permissionName,
      },
    );
  }

  static Future<ApiResponse> update(
    BuildContext context, {
    required String permissionId,
    String? permissionName,
    int? permissionStatus,
  }) async {
    final Map<String, dynamic> data = {
      'roleId': permissionId,
      'permissionId': permissionId,
    };
    if (permissionName != null) {
      data['roleName'] = permissionName;
      data['permissionName'] = permissionName;
    }
    if (permissionStatus != null) {
      data['permissionStatus'] = permissionStatus;
    }
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/admin-permission',
      data: data,
    );
  }
}
