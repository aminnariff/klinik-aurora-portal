import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/service/create_service_request.dart';
import 'package:klinik_aurora_portal/models/service/create_service_response.dart';
import 'package:klinik_aurora_portal/models/service/services_response.dart';
import 'package:klinik_aurora_portal/models/service/update_service_request.dart';
import 'package:klinik_aurora_portal/models/service/update_service_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

class ServiceController extends ChangeNotifier {
  ServicesResponse? _servicesResponse;
  ServicesResponse? get servicesResponse => _servicesResponse;

  set servicesResponse(ServicesResponse? value) {
    _servicesResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<CreateServiceResponse>> create(BuildContext context, CreateServiceRequest request) async {
    return ApiController()
        .call(context, method: Method.post, endpoint: 'admin/service/create', data: request.toJson())
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: CreateServiceResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<ServicesResponse>> getAll(
    BuildContext context,
    int page,
    int pageSize, {
    String? serviceName,
    String? serviceId,
    int? serviceStatus,
  }) async {
    return ApiController()
        .call(
          context,
          method: Method.get,
          endpoint: 'admin/service',
          queryParameters: {
            if (notNullOrEmptyString(serviceId)) "serviceId": serviceId,
            if (notNullOrEmptyString(serviceName)) "serviceName": serviceName,
            if (serviceStatus != null) "serviceStatus": serviceStatus,
            'page': page,
            'pageSize': pageSize,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: ServicesResponse.fromJson(value.data));
          } catch (e) {
            print(e.toString());
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateServiceResponse>> update(BuildContext context, UpdateServiceRequest request) async {
    return ApiController()
        .call(
          context,
          method: Method.put,
          endpoint: 'admin/service/update',
          data: {
            "serviceId": request.serviceId,
            "serviceName": request.serviceName,
            "serviceDescription": request.serviceDescription, // optional
            "servicePrice": request.servicePrice,
            "serviceBookingFee": request.serviceBookingFee, // optional
            "doctorType": request.doctorType, // 1 = General, 2 = sonographer,
            "serviceTime": request.serviceTime,
            "serviceCategory": request.serviceCategory,
            "serviceStatus": request.serviceStatus, // 1 = active, 2 = inactive
            "serviceTemplate": request.serviceTemplate,
          },
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: UpdateServiceResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<UpdateServiceResponse>> upload(
    BuildContext context,
    String serviceId,
    FileAttribute document,
  ) async {
    Dio dio = Dio();
    FormData formData = FormData();

    for (FileAttribute item in [document]) {
      formData.files.add(
        MapEntry(
          "serviceImage",
          MultipartFile.fromBytes(
            item.value!,
            filename: item.name,
            contentType:
                item.name != null
                    ? item.name!.contains(".pdf")
                        ? MediaType("application", "pdf")
                        : MediaType("image", item.name.toString().split(".").last)
                    : MediaType("image", item.name.toString().split(".").last),
          ),
        ),
      );
    }
    formData.fields.add(MapEntry('serviceId', serviceId));

    try {
      return dio
          .put(
            '${Environment.appUrl}admin/service/upload',
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
              return ApiResponse(code: value.statusCode, data: UpdateServiceResponse.fromJson(value.data));
            } catch (e) {
              return ApiResponse(code: 400, message: e.toString());
            }
          });
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }
}
