import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/branch_performance_response.dart';

class BranchPerformanceController extends ChangeNotifier {
  BranchPerformanceResponse? _branchPerformanceResponse;
  BranchPerformanceResponse? get branchPerformanceResponse => _branchPerformanceResponse;

  set branchPerformanceResponse(BranchPerformanceResponse? value) {
    _branchPerformanceResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<BranchPerformanceResponse>> get(BuildContext context) async {
    return ApiController()
        .call(context, method: Method.get, endpoint: 'admin/dashboard/branch-performance')
        .then((value) {
      try {
        return ApiResponse(code: value.code, data: BranchPerformanceResponse.fromJson(value.data));
      } catch (e) {
        return ApiResponse(code: 400, message: e.toString());
      }
    });
  }
}
