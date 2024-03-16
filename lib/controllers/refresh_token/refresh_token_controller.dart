import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_response.dart';

class RefreshTokenController {
  static Future<ApiResponse<AuthResponse>> refresh(BuildContext context) async {
    try {
      return ApiController()
          .call(
        context,
        method: Method.post,
        endpoint: 'api/v1/auth',
        data: {
          "username": Storage.getString(username),
          "password": Storage.getString(password),
        },
        isAuthenticated: false,
      )
          .then((value) {
        try {
          return ApiResponse(
            code: value.code,
            data: AuthResponse.fromJson(value.data),
          );
        } catch (e) {
          return ApiResponse(
            code: 400,
            message: e.toString(),
          );
        }
      });
      // return ApiController().getToken().then((token) {
      //   return Dio()
      //       .patch(
      //     '${Environment.provisioningUrl}api/v1/token/new',
      //     options: Options(
      //       headers: {
      //         Headers.acceptHeader: '*/*',
      //         Headers.contentTypeHeader: 'application/json',
      //         'Authorization': 'Bearer $token',
      //       },
      //     ),
      //   )
      //       .then((value) {
      //     return ApiResponse(
      //       code: value.statusCode,
      //       data: JwtResponseModel.fromJson(value.data["jwt"]),
      //     );
      //   });
      // });
    } catch (e) {
      debugPrint(e.toString());
      return ApiResponse(
        code: 400,
        data: AuthResponse(),
      );
    }
  }
}
