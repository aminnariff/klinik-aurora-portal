import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_response.dart';

class RefreshTokenController extends ChangeNotifier {
  static Future<ApiResponse<AuthResponse>> refresh(BuildContext context) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/authentication/login',
          data: {"userEmail": Storage.getString(username), "userPassword": Storage.getString(password)},
          isAuthenticated: false,
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: AuthResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }
}
