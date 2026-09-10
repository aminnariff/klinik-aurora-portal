import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/branch_operations_response.dart';

class BranchOperationsController extends ChangeNotifier {
  BranchOperationsResponse? _branchOperationsResponse;
  BranchOperationsResponse? get branchOperationsResponse => _branchOperationsResponse;

  set branchOperationsResponse(BranchOperationsResponse? value) {
    _branchOperationsResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<BranchOperationsResponse>> get(BuildContext context, {String? branchId}) async {
    final query = (branchId != null && branchId.trim().isNotEmpty) ? '?branchId=${branchId.trim()}' : '';
    return ApiController().call(context, method: Method.get, endpoint: 'admin/dashboard/branch-operations$query').then((value) {
      try {
        return ApiResponse(code: value.code, data: BranchOperationsResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(code: 400, message: e.toString());
      }
    });
  }
}
