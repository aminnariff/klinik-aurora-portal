import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';

class UserController extends ChangeNotifier {
  List<UserResponse>? _userAllResponse;
  List<UserResponse>? get userAllResponse => _userAllResponse;

  set userAllResponse(List<UserResponse>? value) {
    _userAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<List<UserResponse>>> getAll(
    BuildContext context,
  ) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/user-management',
    )
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: (value.data as List).map((item) {
            return UserResponse.fromJson(item);
          }).toList(),
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
