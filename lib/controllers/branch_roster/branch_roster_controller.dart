import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/branch_roster/branch_roster_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class BranchRosterController extends ChangeNotifier {
  BranchRosterResponse? _branchRosterResponse;
  BranchRosterResponse? get branchRosterResponse => _branchRosterResponse;

  set branchRosterResponse(BranchRosterResponse? value) {
    _branchRosterResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<BranchRosterResponse>> get(
    BuildContext context, {
    required String branchId,
    String? doctorId,
    String? startDate,
    String? endDate,
    int? doctorType,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/branch-roster',
          queryParameters: {
            'branchId': branchId,
            if (notNullOrEmptyString(doctorId)) 'doctorId': doctorId,
            if (notNullOrEmptyString(startDate)) 'startDate': startDate,
            if (notNullOrEmptyString(endDate)) 'endDate': endDate,
            'doctorType': ?doctorType,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: BranchRosterResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<dynamic>> bulkUpsert(
    BuildContext context, {
    required String branchId,
    required String doctorId,
    required List<RosterShiftPayload> shifts,
  }) async {
    return ApiController().call(
      context,
      method: Method.post,
      endpoint: 'admin/branch-roster/bulk-upsert',
      data: {
        'branchId': branchId,
        'doctorId': doctorId,
        'shifts': shifts.map((s) => s.toJson()).toList(),
      },
    );
  }

  static Future<ApiResponse<dynamic>> delete(
    BuildContext context, {
    required String rosterId,
  }) async {
    return ApiController().call(
      context,
      method: Method.delete,
      endpoint: 'admin/branch-roster/$rosterId',
    );
  }
}
