import 'dart:async';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/doctor/create_doctor_request.dart';
import 'package:klinik_aurora_portal/models/doctor/create_doctor_response.dart';
import 'package:klinik_aurora_portal/models/doctor/doctor_branch_response.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_request.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_response.dart';

class DoctorController extends ChangeNotifier {
  DoctorBranchResponse? _doctorBranchResponse;
  DoctorBranchResponse? get doctorBranchResponse => _doctorBranchResponse;

  set doctorBranchResponse(DoctorBranchResponse? value) {
    _doctorBranchResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<DoctorBranchResponse>> get(BuildContext context, {String? branchId}) async {
    return ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/doctor',
      queryParameters: {
        'branchId': branchId,
      },
    ).then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: DoctorBranchResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<UpdateDoctorResponse>> update(BuildContext context, UpdateDoctorRequest request) async {
    return ApiController()
        .call(
      context,
      method: Method.put,
      endpoint: 'admin/doctor-management/update',
      data: request.toJson(),
    )
        .then((value) {
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

  static Future<ApiResponse<CreateDoctorResponse>> create(BuildContext context, CreateDoctorRequest request) async {
    return ApiController()
        .call(
      context,
      method: Method.post,
      endpoint: 'admin/doctor/create',
      data: request.toJson(),
    )
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: CreateDoctorResponse.fromJson(value.data),
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
