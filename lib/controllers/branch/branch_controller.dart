import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';
import 'package:klinik_aurora_portal/models/branch/create_branch_request.dart';
import 'package:klinik_aurora_portal/models/branch/create_branch_response.dart';
import 'package:klinik_aurora_portal/models/branch/update_branch_request.dart';
import 'package:klinik_aurora_portal/models/branch/update_branch_response.dart';

class BranchController extends ChangeNotifier {
  ApiResponse<BranchAllResponse>? _branchAllResponse;
  ApiResponse<BranchAllResponse>? get branchAllResponse => _branchAllResponse;

  set branchAllResponse(ApiResponse<BranchAllResponse>? value) {
    _branchAllResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<BranchAllResponse>> getAll(BuildContext context, int page, int pageSize) async {
    return ApiController()
        .call(
      context,
      method: Method.get,
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
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

  static Future<ApiResponse<CreateBranchResponse>> create(CreateBranchRequest request) async {
    Dio dio = Dio();
    FormData formData = FormData();

    formData.files.add(
      MapEntry(
        "branchImage",
        MultipartFile.fromBytes(
          request.branchImage.value!,
          filename: request.branchImage.name,
          contentType: MediaType("image", request.branchImage.name.toString().split(".").last),
        ),
      ),
    );

    formData.fields.add(MapEntry('branchName', request.branchName));
    formData.fields.add(MapEntry('branchCode', request.branchCode));
    formData.fields.add(MapEntry('phoneNumber', '0${request.phoneNumber}'));
    formData.fields.add(MapEntry('address', request.address));
    formData.fields.add(MapEntry('postcode', request.postcode));
    formData.fields.add(MapEntry('city', request.city));
    formData.fields.add(MapEntry('state', request.state));
    formData.fields.add(MapEntry('branchOpeningHours', request.branchOpeningHours));
    formData.fields.add(MapEntry('branchClosingHours', request.branchClosingHours));
    formData.fields.add(MapEntry('is24Hours', '${request.is24Hours}'));
    formData.fields.add(MapEntry('branchLaunchDate', request.branchLaunchDate));
    debugPrint(formData.fields.toString());
    debugPrint(formData.files[0].value.filename);
    debugPrint(formData.files.toString());
    try {
      return dio
          .post(
        '${Environment.appUrl}admin/branch',
        options: Options(
          method: 'POST',
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
            data: CreateBranchResponse.fromJson(value.data),
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

  static Future<ApiResponse<UpdateBranchResponse>> update(UpdateBranchRequest request) async {
    Dio dio = Dio();
    FormData formData = FormData();
    if (request.branchImage?.value != null) {
      formData.files.add(
        MapEntry(
          "branchImage",
          MultipartFile.fromBytes(
            request.branchImage!.value!,
            filename: request.branchImage!.name,
            contentType: MediaType("image", request.branchImage!.name.toString().split(".").last),
          ),
        ),
      );
    }

    formData.fields.add(MapEntry('branchId', request.branchId));
    formData.fields.add(MapEntry('branchName', request.branchName!));
    formData.fields.add(MapEntry('branchCode', request.branchCode!));
    formData.fields.add(MapEntry('phoneNumber', request.phoneNumber!));
    formData.fields.add(MapEntry('address', request.address!));
    formData.fields.add(MapEntry('postcode', request.postcode!));
    formData.fields.add(MapEntry('city', request.city!));
    formData.fields.add(MapEntry('state', request.state!));
    formData.fields.add(MapEntry('branchOpeningHours', request.branchOpeningHours));
    formData.fields.add(MapEntry('branchClosingHours', request.branchClosingHours));
    formData.fields.add(MapEntry('is24Hours', '${request.is24Hours}'));
    formData.fields.add(MapEntry('branchLaunchDate', request.branchLaunchDate));
    try {
      return dio
          .put(
        '${Environment.appUrl}admin/branch',
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
            data: UpdateBranchResponse.fromJson(value.data),
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
