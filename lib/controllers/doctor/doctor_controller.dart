import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/doctor/create_doctor_request.dart';
import 'package:klinik_aurora_portal/models/doctor/create_doctor_response.dart';
import 'package:klinik_aurora_portal/models/doctor/doctor_branch_response.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_request.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_response.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class DoctorController extends ChangeNotifier {
  DoctorBranchResponse? _doctorBranchResponse;
  DoctorBranchResponse? get doctorBranchResponse => _doctorBranchResponse;

  set doctorBranchResponse(DoctorBranchResponse? value) {
    _doctorBranchResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<DoctorBranchResponse>> get(
    BuildContext context,
    int page,
    int pageSize, {
    String? branchId,
    String? doctorName,
    String? doctorPhone,
    int? doctorStatus,
  }) async {
    return ApiController().call(
      context,
      method: Method.get,
      endpoint: 'admin/doctor',
      queryParameters: {
        'branchId': branchId,
        if (notNullOrEmptyString(doctorName)) 'doctorName': doctorName,
        if (notNullOrEmptyString(doctorPhone)) 'doctorPhone': doctorPhone,
        if (doctorStatus != null) 'doctorStatus': doctorStatus,
        'page': page,
        'pageSize': pageSize,
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
      endpoint: 'admin/doctor/update',
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

  static Future<ApiResponse<UpdateDoctorResponse>> upload(
      BuildContext context, String promotionId, FileAttribute document) async {
    Dio dio = Dio();
    FormData formData = FormData();

    for (FileAttribute item in [document]) {
      formData.files.add(
        MapEntry(
          "doctorImage",
          MultipartFile.fromBytes(
            item.value!,
            filename: item.name,
            contentType: item.name != null
                ? item.name!.contains(".pdf")
                    ? MediaType("application", "pdf")
                    : MediaType("image", item.name.toString().split(".").last)
                : MediaType("image", item.name.toString().split(".").last),
          ),
        ),
      );
    }
    formData.fields.add(MapEntry('doctorId', promotionId));

    try {
      return dio
          .put(
        '${Environment.appUrl}admin/doctor/upload',
        options: Options(
          method: 'PUT',
          headers: {
            Headers.acceptHeader: "*/*",
            Headers.contentTypeHeader: "multipart/form-data",
            'Authorization': 'Bearer ${prefs.getString(token)}',
          },
          contentType: "multipart/form-data",
          responseType: ResponseType.json,
        ),
        data: formData,
      )
          .then((value) {
        try {
          return ApiResponse(
            code: value.statusCode,
            data: UpdateDoctorResponse.fromJson(value.data),
          );
        } catch (e) {
          return ApiResponse(
            code: 400,
            message: e.toString(),
          );
        }
      });
    } catch (e) {
      return ApiResponse(
        code: 400,
        message: e.toString(),
      );
    }
  }
}
