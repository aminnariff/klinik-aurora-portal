import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart';

class VoucherController extends ChangeNotifier {
  ApiResponse<VoucherAllResponse>? _voucherAllResponse;
  ApiResponse<VoucherAllResponse>? get voucherAllResponse => _voucherAllResponse;

  set voucherAllResponse(ApiResponse<VoucherAllResponse>? value) {
    _voucherAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<VoucherAllResponse>> getAll(
    BuildContext context,
  ) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/voucher',
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: VoucherAllResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }
}
