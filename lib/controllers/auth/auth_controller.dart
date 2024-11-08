import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_request.dart';
import 'package:klinik_aurora_portal/models/auth/auth_response.dart';

class AuthController extends ChangeNotifier {
  AuthResponse? _authenticationResponse;
  AuthResponse? get authenticationResponse => _authenticationResponse;
  String? _usernameError;
  String? get usernameError => _usernameError;
  String? _passwordError;
  String? get passwordError => _passwordError;
  bool _rememberMe = false;
  bool get remember => _rememberMe;

  set authenticationResponse(AuthResponse? value) {
    _authenticationResponse = value;
    notifyListeners();
  }

  set remember(bool value) {
    _rememberMe = value;
    prefs.setBool(rememberMe, value);
    notifyListeners();
  }

  Future<String> checkDateTime() async {
    try {
      _authenticationResponse = AuthResponse.fromJson(json.decode(prefs.getString(authResponse).toString()));
      if (_authenticationResponse?.data?.expiryDt != null) {
        DateTime now = DateTime.now();
        DateTime targetTime = DateTime.parse(_authenticationResponse!.data!.expiryDt!);
        Duration difference = targetTime.difference(now);
        if (difference.isNegative) {
          return 'expired';
        } else if (difference <= const Duration(minutes: 5)) {
          return 'refresh';
        } else {
          return 'continue';
        }
      } else {
        return 'expired';
      }
    } catch (e) {
      return 'expired';
    }
  }

  String getName() {
    return _authenticationResponse?.data?.user?.permissions?.first ?? '';
  }

  bool hasPermission(String permission) {
    if (_authenticationResponse?.data?.user?.permissions == null) {
      return false;
    } else {
      try {
        _authenticationResponse!.data?.user?.permissions!.firstWhere((element) => element == permission);
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  Future<AuthResponse?> init(BuildContext context) async {
    try {
      String? auth = prefs.getString(authResponse);
      _rememberMe = prefs.getBool(rememberMe) ?? false;
      Map<String, dynamic> dataMap = json.decode(auth.toString());
      _authenticationResponse = AuthResponse.fromJson(dataMap);
      return _authenticationResponse;
    } catch (e) {
      _authenticationResponse = null;
      return _authenticationResponse;
    }
  }

  set usernameError(String? value) {
    _usernameError = value;
    notifyListeners();
  }

  set passwordError(String? value) {
    _passwordError = value;
    notifyListeners();
  }

  List<String>? getRememberMeCredentials() {
    _rememberMe = prefs.getBool(rememberMe) ?? false;
    if (_rememberMe == true) {
      return [prefs.getString(username) ?? '', prefs.getString(password) ?? ''];
    } else {
      return null;
    }
  }

  setAuthenticationResponse(AuthResponse? value, {String? usernameValue, String? passwordValue}) async {
    if (value != null) {
      value = AuthResponse(
        data: Data(
          user: value.data?.user,
          accessToken: value.data?.accessToken,
          refreshToken: value.data?.refreshToken,
          issuedDt: DateTime.now().toString(),
          expiryDt: DateTime.now().add(const Duration(minutes: 30)).toString(),
        ),
      );
      // if (_rememberMe) {
      prefs.setString(username, usernameValue ?? "");
      prefs.setString(password, passwordValue ?? "");
      // } else {
      //   prefs.remove(username);
      //   prefs.remove(password);
      // }
      prefs.setString(
        authResponse,
        json.encode(value),
      );
      prefs.setString(token, value.data?.accessToken ?? '');
    } else if (value == null) {
      prefs.remove(authResponse);
      prefs.remove(jwtResponse);
      prefs.remove(token);
    }
    _authenticationResponse = value;
    notifyListeners();
  }

  static Future<ApiResponse<AuthResponse>> logIn(BuildContext context, AuthRequest request) async {
    // return ApiResponse(
    //   code: 200,
    //   data: AuthResponse.fromJson(
    //     {
    //       "jwtResponseModel": {
    //         "token": "kahjkjhajkhaa",
    //         "issuedDt": DateTime.now().toString(),
    //         "expiryDt": DateTime.now().add(const Duration(minutes: 30)).toString(),
    //       },
    //     },
    //   ),
    // );

    return ApiController()
        .call(
      context,
      method: Method.post,
      endpoint: 'admin/authentication/login',
      data: {
        "userEmail": request.username,
        "userPassword": request.password,
      },
      isAuthenticated: false,
    )
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: AuthResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<AuthResponse>> forgotPassword(BuildContext context, String email) async {
    return ApiController()
        .call(
      context,
      method: Method.post,
      endpoint: 'admin/authentication/forgot-password',
      data: {
        "userEmail": email,
      },
      isAuthenticated: false,
    )
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: AuthResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  static Future<ApiResponse<AuthResponse>> changePassword(BuildContext context, String email) async {
    return ApiController()
        .call(
      context,
      method: Method.post,
      endpoint: 'admin/authentication/forgot-password',
      data: {
        "userEmail": "admin@auroramembership.com",
      },
      isAuthenticated: false,
    )
        .then((value) {
      try {
        return ApiResponse(
          code: value.code,
          data: AuthResponse.fromJson(value.data),
        );
      } catch (e) {
        return ApiResponse(
          code: 400,
          message: e.toString(),
        );
      }
    });
  }

  void logout(BuildContext context) {
    setAuthenticationResponse(null);
    notifyListeners();
  }
}
