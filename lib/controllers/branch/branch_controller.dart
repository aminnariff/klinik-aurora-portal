import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';

class BranchController extends ChangeNotifier {
  ApiResponse<BranchAllResponse>? _branchAllResponse;
  ApiResponse<BranchAllResponse>? get branchAllResponse => _branchAllResponse;

  set branchAllResponse(ApiResponse<BranchAllResponse>? value) {
    _branchAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<BranchAllResponse>> getAll(
    BuildContext context,
  ) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      endpoint: 'admin/branch',
    )
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: BranchAllResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }
}
