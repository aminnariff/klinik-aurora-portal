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
  JwtResponseModel? _jwt;
  JwtResponseModel? get jwt => _jwt;
  bool _rememberMe = false;
  bool get remember => _rememberMe;

  set jwt(JwtResponseModel? value) {
    _jwt = value;
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
      _jwt = JwtResponseModel.fromJson(json.decode(prefs.getString(jwtResponse).toString()));
      if (jwt?.expiryDt != null) {
        DateTime now = DateTime.now();
        DateTime targetTime = DateTime.parse(jwt!.expiryDt!);
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
    return _authenticationResponse?.userPermissions?.first.name ?? '';
  }

  bool hasPermission(String permission) {
    if (_authenticationResponse?.userPermissions == null) {
      return false;
    } else {
      try {
        _authenticationResponse!.userPermissions!.firstWhere((element) => element.name == permission);
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
      _jwt = JwtResponseModel.fromJson(json.decode(prefs.getString(jwtResponse).toString()));
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
      // if (_rememberMe) {
      prefs.setString(username, usernameValue ?? "");
      prefs.setString(password, passwordValue ?? "");
      // } else {
      //   prefs.remove(username);
      //   prefs.remove(password);
      // }
      prefs.setString(authResponse, json.encode(value));
      prefs.setString(jwtResponse, json.encode(value.jwtResponseModel));
      prefs.setString(token, value.jwtResponseModel?.token ?? '');
    } else if (value == null) {
      prefs.remove(authResponse);
      prefs.remove(jwtResponse);
      prefs.remove(token);
    }
    _authenticationResponse = value;
    _jwt = value?.jwtResponseModel;
    notifyListeners();
  }

  static Future<ApiResponse<AuthResponse>> logIn(BuildContext context, AuthRequest request) async {
    return ApiController()
        .call(
      context,
      method: Method.post,
      baseUrl: BaseUrl.provisioning,
      endpoint: 'api/v1/auth',
      data: request,
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
