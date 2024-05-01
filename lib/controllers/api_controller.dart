import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/refresh_token/refresh_token_controller.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_button_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:provider/provider.dart';

enum Method {
  get,
  post,
  put,
  delete,
  patch,
}

enum BaseUrl {
  portal,
}

class ApiController {
  final Dio _dio = Dio();
  String getDomain(BaseUrl baseUrl) {
    if (baseUrl == BaseUrl.portal) {
      return Environment.appUrl;
    } else {
      return '';
    }
  }

  Future<String> getToken() async {
    return prefs.getString(token) ?? '';
  }

  String getPlatform() {
    if (kIsWeb) {
      return 'WEB';
    } else if (Platform.isAndroid) {
      return 'ANDROID';
    } else if (Platform.isIOS) {
      return 'IOS';
    } else {
      return 'WEB';
    }
  }

  Future<Options> getHeaders(BaseUrl baseUrl, bool isAuthenticated) async {
    return getToken().then((token) {
      if (token != '' && isAuthenticated) {
        return authenticatedHeaders(token);
      } else {
        return unauthenticatedHeaders();
      }
    });
  }

  Options authenticatedHeaders(String token) {
    return Options(
      headers: {
        Headers.acceptHeader: '*/*',
        Headers.contentTypeHeader: 'application/json',
        'Host': '91.108.104.155',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Options unauthenticatedHeaders() {
    return Options(
      headers: {
        Headers.acceptHeader: '*/*',
        Headers.contentTypeHeader: 'application/json',
        'Host': '91.108.104.155',
      },
    );
  }

  Future<bool> checkToken(BuildContext context, bool isAuthenticated) async {
    if (isAuthenticated) {
      return context.read<AuthController>().checkDateTime().then((value) async {
        String tokenStatus = value;
        debugPrint('tokenStatus : $tokenStatus');
        debugPrint('expiredAt : ${context.read<AuthController>().authenticationResponse?.data?.expiryDt}');
        if (tokenStatus == 'refresh') {
          return await RefreshTokenController.refresh(context).then((tokenRenewResponse) {
            if (responseCode(tokenRenewResponse.code)) {
              if (tokenRenewResponse.data != null) {
                context.read<AuthController>().setAuthenticationResponse(tokenRenewResponse.data);
                prefs.setString(authResponse, json.encode(tokenRenewResponse.data));
                return true;
              } else {
                return true;
              }
            } else {
              return true;
            }
          });
        } else if (tokenStatus == 'expired') {
          if (isSessionExpiredDialogOpen == false) {
            context.read<AuthController>().logout(context);
            context.goNamed(LoginPage.routeName, extra: true);
            // isSessionExpiredDialogOpen = true;
            // promptDialog(context, action: () {
            //   context.pop(context);
            //   isSessionExpiredDialogOpen = false;
            //   context.read<AuthController>().logout(context);
            //   context.goNamed(LoginPage.routeName, extra: true);
            // },
            //     text: 'error'.tr(gender: 'sessionExpired'),
            //     buttonColor: errorColor,
            //     buttonText: 'button'.tr(gender: 'reLogin'));
          }
          return true;
        } else if (tokenStatus == 'continue') {
          return true;
        } else {
          return true;
        }
      });
    } else {
      return true;
    }
  }

  Future<ApiResponse> call(
    BuildContext context, {
    BaseUrl baseUrl = BaseUrl.portal,
    required Method method,
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    dynamic data,
    bool isAuthenticated = true,
  }) async {
    return checkToken(context, isAuthenticated).then((value) async {
      // String url = getDomain(baseUrl) + endpoint;
      String url = kDebugMode ? (getDomain(baseUrl) + endpoint) : endpoint;

      try {
        switch (method) {
          case Method.get:
            return await _dio
                .get(
              url,
              queryParameters: queryParameters,
              options: await getHeaders(baseUrl, isAuthenticated),
            )
                .then((response) {
              printData(response);
              return ApiResponse(
                code: response.statusCode,
                data: response.data,
              );
            });
          case Method.post:
            return await Dio()
                .post(
              url,
              data: data,
              queryParameters: queryParameters,
              options: await getHeaders(baseUrl, isAuthenticated),
            )
                .then((response) {
              printData(response);
              return ApiResponse(
                code: response.statusCode,
                data: response.data,
              );
            });
          case Method.put:
            return await _dio
                .put(
              url,
              data: data,
              queryParameters: queryParameters,
              options: await getHeaders(baseUrl, isAuthenticated),
            )
                .then((response) {
              printData(response);
              return ApiResponse(
                code: response.statusCode,
                data: response.data,
              );
            });
          case Method.patch:
            return await _dio
                .patch(
              url,
              data: data,
              queryParameters: queryParameters,
              options: await getHeaders(baseUrl, isAuthenticated),
            )
                .then((response) {
              printData(response);
              return ApiResponse(
                code: response.statusCode,
                data: response.data,
              );
            });
          case Method.delete:
            return await _dio
                .delete(
              url,
              data: data,
              queryParameters: queryParameters,
              options: await getHeaders(baseUrl, isAuthenticated),
            )
                .then((response) {
              printData(response);
              return ApiResponse(
                code: response.statusCode,
                data: response.data,
              );
            });
        }
      } catch (e) {
        debugPrint('$e');
        if (e is DioException) {
          if (e.isNoConnectionError) {
            debugPrint('Internet connection is now offline');
          } else {
            dismissLoading();
            if (e.response?.statusCode == 401 && isAuthenticated == false) {
              Future.delayed(Duration.zero, () {
                showDialogError(context, e.response?.data?['message'] ?? '');
              });
            } else if (e.response?.statusCode == 401 ||
                e.response?.statusCode == 403 ||
                e.response?.statusCode == 410) {
              if (isSessionExpiredDialogOpen == false) {
                isSessionExpiredDialogOpen = true;
                await promptDialog(context, action: () {
                  context.pop(context);
                  isSessionExpiredDialogOpen = false;
                  context.read<AuthController>().logout(context);
                  context.goNamed(LoginPage.routeName, extra: true);
                },
                    text: 'error'.tr(gender: 'sessionExpired'),
                    buttonColor: errorColor,
                    buttonText: 'button'.tr(gender: 'reLogin'));
              }
            } else if (e.response?.statusCode == 500 || e.response?.statusCode == 503) {
              try {
                Future.delayed(Duration.zero, () {
                  return promptDialog(
                    context,
                    action: () {
                      context.pop(context);
                      return call(context,
                          baseUrl: baseUrl,
                          method: method,
                          queryParameters: queryParameters,
                          data: data,
                          isAuthenticated: isAuthenticated,
                          endpoint: endpoint);
                    },
                    text: e.response?.data?['message'] ==
                            'java.lang.ClassNotFoundException: Provider for jakarta.ws.rs.ext.RuntimeDelegate cannot be found'
                        ? 'error'.tr(gender: 'err-6')
                        : 'error'.tr(gender: e.response?.statusCode == 500 ? 'generic' : 'internal'),
                    buttonColor: errorColor,
                    buttonText: e.response?.data?['message'] ==
                            'java.lang.ClassNotFoundException: Provider for jakarta.ws.rs.ext.RuntimeDelegate cannot be found'
                        ? null
                        : 'button'.tr(gender: 'retry'),
                    barrierDismissible: true,
                  );
                });
              } catch (error) {
                debugPrint('$error');
              }
            } else if (e.response?.statusCode == 409) {
              try {
                Future.delayed(Duration.zero, () {
                  while (context.canPop()) {
                    context.pop();
                  }
                  return promptDialog(
                    context,
                    action: () {
                      context.pop(context);
                      return call(context,
                          baseUrl: baseUrl,
                          method: method,
                          queryParameters: queryParameters,
                          data: data,
                          isAuthenticated: isAuthenticated,
                          endpoint: endpoint);
                    },
                    text: 'error'.tr(gender: 'suspendedUser'),
                    buttonColor: errorColor,
                    buttonText: 'button'.tr(gender: 'reLogin'),
                    barrierDismissible: true,
                  );
                });
              } catch (error) {
                debugPrint('$error');
              }
            } else {
              return ApiResponse(
                code: e.response?.statusCode,
                message: e.response?.statusMessage,
                data: e.response?.data,
              );
            }
          }
        }
        return ApiResponse(code: 400, message: 'An Error Occurred.');
      }
    });
  }

  promptDialog(BuildContext context,
      {required Function() action,
      required String text,
      required String? buttonText,
      Color? buttonColor,
      bool barrierDismissible = false}) async {
    Future.delayed(Duration.zero, () {
      return showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (BuildContext context) {
          return AppDialog(
            DialogAttribute(
              text: text,
              buttonAttributes: [
                if (buttonText != null)
                  DialogButtonAttribute(
                    action,
                    text: buttonText,
                    color: buttonColor ?? errorColor,
                  ),
              ],
            ),
          );
        },
      );
    });
  }

  printData(Response response) {
    // debugPrint('${response.statusCode} -> ${response.data}');
  }
}

extension DioErrorExtension on DioException {
  bool get isNoConnectionError {
    return type == DioExceptionType.connectionError && error is SocketException;
  }
}

class ApiResponse<T> {
  int? code;
  String? message;
  T? data;

  ApiResponse({
    this.code,
    this.message,
    this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, {Function(dynamic)? parse}) {
    try {
      return ApiResponse(
        message: json['message'],
        code: json['code'],
        data: parse?.call(json['data']),
      );
    } catch (e) {
      return ApiResponse(
        data: parse?.call(json['data']),
      );
    }
  }

  Map<String, dynamic> toJson() => {
        "code": code,
        "message": message,
        "data": data,
      };
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
