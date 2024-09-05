import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/admin/admin_all_response.dart';
import 'package:klinik_aurora_portal/models/admin/create_admin_request.dart';
import 'package:klinik_aurora_portal/models/admin/create_admin_response.dart';
import 'package:klinik_aurora_portal/models/admin/permission_admin_response.dart';
import 'package:klinik_aurora_portal/models/admin/update_admin_request.dart';
import 'package:klinik_aurora_portal/models/admin/update_admin_response.dart';
import 'package:klinik_aurora_portal/models/admin/update_permission_admin_request.dart';
import 'package:klinik_aurora_portal/models/admin/update_permission_admin_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class AdminController extends ChangeNotifier {
  AdminAllResponse? _adminAllResponse;
  AdminAllResponse? get adminAllResponse => _adminAllResponse;

  set adminAllResponse(AdminAllResponse? value) {
    _adminAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<AdminAllResponse>> getAll(
    BuildContext context,
    int page,
    int pageSize, {
    String? userName,
    String? userPhone,
    String? userEmail,
    int? userStatus,
  }) async {
    return ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/admin-management',
      queryParameters: {
        if (notNullOrEmptyString(userName)) 'userName': userName,
        if (notNullOrEmptyString(userPhone)) 'userPhone': userPhone,
        if (notNullOrEmptyString(userEmail)) 'userEmail': userEmail,
        if (userStatus != null) 'userStatus': userStatus,
        'page': page,
        'pageSize': pageSize,
      },
    ).then((value) {
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

  static Future<ApiResponse<CreateAdminResponse>> create(BuildContext context, CreateAdminRequest request) async {
    return ApiController()
        .call(
      context,
      method: Method.post,
      data: {
        "userEmail": request.userEmail,
        "userName": request.userName,
        "userPassword": 'abCD1234',
        "userRetypePassword": "abCD1234",
        "userFullname": request.userFullname,
        if (request.branchId != null) "branchId": request.branchId,
      },
      endpoint: 'admin/admin-management/create',
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: CreateAdminResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdateAdminResponse>> update(BuildContext context, UpdateAdminRequest request) async {
    return ApiController()
        .call(
      context,
      method: Method.put,
      data: {
        "userId": request.userId,
        if (request.userFullname != null) "userFullname": request.userFullname,
        if (request.userStatus != null) "userStatus": request.userStatus,
        if (request.branchId != null) "branchId": request.branchId,
      },
      endpoint: 'admin/admin-management/update',
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: UpdateAdminResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<PermissionAdminResponse>> getPermission(BuildContext context, String userId) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      queryParameters: {
        'userId': userId,
      },
      endpoint: 'admin/admin-management/permission',
    )
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: PermissionAdminResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdatePermissionAdminResponse>> updatePermission(
      BuildContext context, UpdatePermissionAdminRequest request) async {
    return ApiController()
        .call(
      context,
      method: Method.post,
      data: {
        'userId': request.userId,
        'permissionIds': [
          for (String item in request.permissionIds ?? []) item,
        ]
      },
      endpoint: 'admin/admin-management/assign',
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: UpdatePermissionAdminResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }
}
