import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

class AppAssetController {
  static Future<ApiResponse<String>> upload({
    required Uint8List bytes,
    required String filename,
    String? previousUrl,
    String? folder,
  }) async {
    final extension = filename.contains('.') ? filename.split('.').last.toLowerCase() : 'png';

    final formData = FormData();
    formData.files.add(
      MapEntry(
        'file',
        MultipartFile.fromBytes(
          bytes,
          filename: filename,
          contentType: MediaType('image', extension == 'jpg' ? 'jpeg' : extension),
        ),
      ),
    );
    if (folder != null && folder.trim().isNotEmpty) {
      formData.fields.add(MapEntry('folder', folder.trim()));
    }

    try {
      final response = await Dio().post(
        '${Environment.appUrl}admin/assets/upload',
        data: formData,
        options: Options(
          headers: {
            Headers.acceptHeader: '*/*',
            'Authorization': 'Bearer ${prefs.getString(token)}',
          },
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final url = response.data is Map ? response.data['url'] as String? : null;
      if (url == null || url.isEmpty) {
        return ApiResponse(code: 400, message: 'Upload succeeded but no URL was returned.');
      }
      return ApiResponse(code: 200, data: url);
    } on DioException catch (e) {
      final message = e.response?.data is Map
          ? (e.response?.data['message'] as String?)
          : e.message;
      return ApiResponse(code: e.response?.statusCode ?? 500, message: message ?? 'Network error.');
    } catch (e) {
      return ApiResponse(code: 500, message: e.toString());
    }
  }

  static Future<void> delete(String url) async {
    if (url.trim().isEmpty) return;
    try {
      await Dio().delete(
        '${Environment.appUrl}admin/assets',
        data: {'url': url.trim()},
        options: Options(
          headers: {
            Headers.acceptHeader: '*/*',
            'Authorization': 'Bearer ${prefs.getString(token)}',
          },
        ),
      );
    } catch (_) {}
  }
}
