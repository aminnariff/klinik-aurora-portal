import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_request.dart';
import 'package:klinik_aurora_portal/models/auth/auth_response.dart';
import 'package:provider/provider.dart';

class AuthController extends ChangeNotifier {
  AuthResponse? _authenticationResponse;
  AuthResponse? get authenticationResponse => _authenticationResponse;
  String? _usernameError;
  String? get usernameError => _usernameError;
  String? _passwordError;
  String? get passwordError => _passwordError;
  bool _rememberMe = false;
  bool get remember => _rememberMe;
  String? _branchId;
  String? get branchId => _branchId;

  set branchId(String? value) {
    _branchId = value;
    notifyListeners();
  }

  bool get isSuperAdmin {
    return prefs.getBool('isSuperAdmin') ?? false;
  }

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
    String? loginDt = _authenticationResponse?.data?.issuedDt;
    loginDt ??= prefs.getString(loginDateTime);

    if (loginDt == null || loginDt.isEmpty) {
      debugPrint("Missing or empty login date.");
      return "invalid_format";
    }

    try {
      final loginTime = DateTime.parse(loginDt);
      final now = DateTime.now();

      return (loginTime.year == now.year && loginTime.month == now.month && loginTime.day == now.day)
          ? "valid"
          : "expired";
    } catch (e) {
      debugPrint("Invalid loginDateTime format: $loginDt");
      return "invalid_format";
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
      final rawAuth = prefs.getString(authResponse);
      _rememberMe = prefs.getBool(rememberMe) ?? false;

      if (rawAuth == null || rawAuth.trim().isEmpty) {
        debugPrint("No saved authResponse found.");
        _authenticationResponse = null;
        return null;
      }

      final decoded = json.decode(rawAuth);

      if (decoded is! Map<String, dynamic>) {
        debugPrint("Decoded authResponse is not a valid JSON object.");
        _authenticationResponse = null;
        prefs.remove(authResponse);
        return null;
      }

      final parsed = AuthResponse.fromJson(decoded);
      context.read<AuthController>().authenticationResponse = parsed;

      context.read<AuthController>().branchId = parsed.data?.user?.branchId;
      _authenticationResponse = parsed;

      final expiryDtString = _authenticationResponse?.data?.expiryDt;
      if (expiryDtString == null || expiryDtString.trim().isEmpty) {
        debugPrint("AuthResponse expiryDt is null or empty.");
        _authenticationResponse = null;
        prefs.remove(authResponse);
        return null;
      }

      final expiry = DateTime.tryParse(expiryDtString);
      if (expiry == null) {
        debugPrint("Failed to parse expiryDt: $expiryDtString");
        _authenticationResponse = null;
        prefs.remove(authResponse);
        return null;
      }

      if (expiry.isBefore(DateTime.now())) {
        debugPrint("Token expired on init: $expiry");
        _authenticationResponse = null;
        prefs.remove(authResponse);
        return null;
      }

      debugPrint("Auth loaded and valid. Expires at: $expiry");
      return _authenticationResponse;
    } catch (e) {
      debugPrint("Exception while loading authResponse: $e");
      _authenticationResponse = null;
      prefs.remove(authResponse);
      return null;
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

  Future<void> setAuthenticationResponse(AuthResponse? response, {String? usernameValue, String? passwordValue}) async {
    try {
      if (response != null) {
        AuthResponse? data = response;
        data = AuthResponse(
          data: Data(
            user: response.data?.user,
            accessToken: response.data?.accessToken,
            refreshToken: response.data?.refreshToken,
            issuedDt: DateTime.now().toString(),
            expiryDt: DateTime.now().add(const Duration(minutes: 60)).toString(),
          ),
        );

        if (data.data?.accessToken == null) {
          debugPrint("Invalid auth response, forcing re-login.");
          return;
        }

        final loginDt = DateTime.now().toIso8601String();

        await prefs.setString(authResponse, jsonEncode(data));
        await prefs.setString(loginDateTime, loginDt);
        await prefs.setString(token, data.data?.accessToken ?? '');
        await prefs.setBool('isSuperAdmin', data.data?.user?.isSuperadmin ?? false);
        _authenticationResponse = data;
        notifyListeners();
      } else {
        prefs.remove(authResponse);
        prefs.remove(loginDateTime);
        prefs.remove(token);
        prefs.remove('isSuperAdmin');
        notifyListeners();
      }
    } catch (e) {
      prefs.remove(authResponse);
      prefs.remove(loginDateTime);
      prefs.remove(token);
      debugPrint("Auth save error: $e");
      notifyListeners();
    }
  }

  static Future<ApiResponse<AuthResponse>> logIn(BuildContext context, AuthRequest request) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/authentication/login',
          data: {"userEmail": request.username, "userPassword": request.password},
          isAuthenticated: false,
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: AuthResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<AuthResponse>> forgotPassword(BuildContext context, String email) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/authentication/forgot-password',
          data: {"userEmail": email},
          isAuthenticated: false,
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: AuthResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  static Future<ApiResponse<AuthResponse>> changePassword(BuildContext context, String email) async {
    return ApiController()
        .call(
          context,
          method: Method.post,
          endpoint: 'admin/authentication/forgot-password',
          data: {"userEmail": "admin@auroramembership.com"},
          isAuthenticated: false,
        )
        .then((value) {
          try {
            return ApiResponse(code: value.code, data: AuthResponse.fromJson(value.data));
          } catch (e) {
            return ApiResponse(code: 400, message: e.toString());
          }
        });
  }

  void logout(BuildContext context) {
    prefs.remove(jwtResponse);
    setAuthenticationResponse(null);
    notifyListeners();
  }
}
