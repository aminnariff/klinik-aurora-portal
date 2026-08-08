import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';

/// Uploads campaign artwork to Firebase Storage via the backend.
///
/// Goes direct through Dio rather than [ApiController] because that helper only
/// speaks JSON — the same reason the promotion and branch uploads do.
class CampaignAssetController {
  /// Uploads [bytes] and returns the public URL.
  ///
  /// Pass [previousUrl] when replacing an existing image: the server deletes
  /// that object after the new upload succeeds, so the bucket does not fill up
  /// with orphaned artwork. Passing an externally hosted URL is safe — the
  /// server only deletes objects it manages.
  static Future<ApiResponse<String>> upload({
    required Uint8List bytes,
    required String filename,
    String? previousUrl,
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
    if (previousUrl != null && previousUrl.trim().isNotEmpty) {
      formData.fields.add(MapEntry('previousUrl', previousUrl.trim()));
    }

    try {
      final response = await Dio().post(
        '${Environment.appUrl}admin/campaign-assets/upload',
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
      return ApiResponse(code: response.statusCode, data: url);
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] as String? : null;
      return ApiResponse(code: e.response?.statusCode ?? 400, message: message ?? 'Unable to upload the image.');
    } catch (e) {
      return ApiResponse(code: 400, message: e.toString());
    }
  }

  /// Removes a managed asset. No-ops server-side for URLs we do not own.
  static Future<ApiResponse> delete(String url) async {
    try {
      final response = await Dio().post(
        '${Environment.appUrl}admin/campaign-assets/delete',
        data: {'url': url},
        options: Options(
          headers: {
            Headers.acceptHeader: '*/*',
            Headers.contentTypeHeader: 'application/json',
            'Authorization': 'Bearer ${prefs.getString(token)}',
          },
        ),
      );
      return ApiResponse(code: response.statusCode);
    } on DioException catch (e) {
      return ApiResponse(code: e.response?.statusCode ?? 400, message: 'Unable to delete the image.');
    }
  }
}
