import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_response.dart';
import 'package:klinik_aurora_portal/models/password_recovery/forgot_password_response.dart';

class PasswordRecoveryController extends ChangeNotifier {
  static Future<ApiResponse<ForgotPasswordResponse>> forgotPassword(BuildContext context, String? email) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/authentication/forgot-password',
      isAuthenticated: false,
      queryParameters: {
        "userEmail": email,
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: ForgotPasswordResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdateDoctorResponse>> changePassword(BuildContext context, String? password) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/authentication/change-password',
      isAuthenticated: false,
      headers: Options(
        headers: {
          Headers.acceptHeader: '*/*',
          Headers.contentTypeHeader: 'application/json',
          'Host': 'srv495548.hstgr.cloud',
          'Authorization': 'Bearer ${prefs.getString(token)}',
        },
      ),
      data: {
        "userPassword": password,
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: UpdateDoctorResponse.fromJson(value.data),
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
