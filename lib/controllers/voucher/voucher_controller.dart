import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/voucher/create_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/create_voucher_response.dart';
import 'package:klinik_aurora_portal/models/voucher/update_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/update_voucher_response.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class VoucherController extends ChangeNotifier {
  ApiResponse<VoucherAllResponse>? _voucherAllResponse;
  ApiResponse<VoucherAllResponse>? get voucherAllResponse => _voucherAllResponse;

  set voucherAllResponse(ApiResponse<VoucherAllResponse>? value) {
    _voucherAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<VoucherAllResponse>> getAll(BuildContext context, int page, int pageSize,
      {String? voucherName, String? voucherCode, int? voucherStatus}) async {
    return ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/voucher',
      queryParameters: {
        if (notNullOrEmptyString(voucherName)) 'voucherName': voucherName,
        if (notNullOrEmptyString(voucherCode)) 'voucherCode': voucherCode,
        if (voucherStatus != null) 'voucherStatus': voucherStatus,
        'page': page,
        'pageSize': pageSize,
      },
    ).then((value) {
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

  static Future<ApiResponse<CreateVoucherResponse>> create(BuildContext context, CreateVoucherRequest request) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/voucher/create',
      data: {
        "voucherName": request.voucherName,
        "voucherDescription": request.voucherDescription,
        "voucherCode": request.voucherCode,
        "voucherPoint": request.voucherPoint,
        "voucherStartDate": request.voucherStartDate,
        "voucherEndDate": request.voucherEndDate,
        "rewardId": request.rewardId
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: CreateVoucherResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdateVoucherResponse>> update(BuildContext context, UpdateVoucherRequest request) async {
    return ApiController().call(
      context,
      method: Method.put,
      endpoint: 'admin/voucher/update',
      data: {
        "voucherId": request.voucherId,
        "voucherName": request.voucherName,
        "voucherDescription": request.voucherDescription,
        "voucherCode": request.voucherCode,
        "voucherPoint": request.voucherPoint,
        "voucherStartDate": request.voucherStartDate,
        "voucherEndDate": request.voucherEndDate,
        "voucherStatus": request.voucherStatus,
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: UpdateVoucherResponse.fromJson(value.data),
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
