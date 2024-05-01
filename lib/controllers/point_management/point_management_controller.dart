import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_request.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_response.dart';

class PointManagementController extends ChangeNotifier {
  static Future<ApiResponse<CreatePointResponse>> create(BuildContext context, CreatePointRequest request) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/admin-permission',
      data: {
        "userId": request.userId,
        if (request.pointType != null) "pointType": request.pointType, // 1 = referral, 2 = voucher
        // required when point type = null
        if (request.pointType == null) "totalPoint": request.totalPoint,
        // required when point type = 1
        if (request.pointType == 1) "referralUserId": request.referralUserId,
        // requred when point type = 2
        if (request.pointType == 2) "voucherId": request.voucherId,
      },
    ).then((value) {
      try {
        return ApiResponse(code: value.code, data: CreatePointResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }
}
