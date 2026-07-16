import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/refresh_token/refresh_token_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_request.dart';
import 'package:klinik_aurora_portal/models/auth/auth_response.dart';

class AuthController extends ChangeNotifier {
  /// Hydrate persisted auth synchronously on construction so the session is
  /// available to route guards / early API calls immediately after a page
  /// reload, before the async [init] flow completes.
  AuthController() {
    _hydrateFromStorage();
  }

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

  // ── Inactivity tracking ────────────────────────────────────────────────
  Timer? _inactivityTimer;
  bool _sessionExpiredByInactivity = false;
  bool get sessionExpiredByInactivity => _sessionExpiredByInactivity;

  /// Duration of inactivity before automatic logout.
  static Duration get inactivityTimeout => sessionInactivityTimeout;

  // ── Existing getters/setters ────────────────────────────────────────────

  set branchId(String? value) {
    _branchId = value;
    notifyListeners();
  }

  bool get isSuperAdmin {
    return _authenticationResponse?.data?.user?.isSuperadmin ?? false;
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

  // ── Inactivity public API ───────────────────────────────────────────────

  /// Call on every user interaction (pointer, keyboard) to reset the
  /// inactivity clock.  Persists the timestamp so it survives page reload.
  void trackActivity() {
    final now = DateTime.now().toIso8601String();
    prefs.setString(lastActivityTimestamp, now);
  }

  /// Returns `true` when the user has been idle longer than [inactivityTimeout].
  /// Reads from persisted storage so the check works across browser tabs /
  /// page reloads.
  bool isSessionInactive() {
    final raw = prefs.getString(lastActivityTimestamp);
    if (raw == null || raw.isEmpty) return false; // first visit – not inactive
    final lastActive = DateTime.tryParse(raw);
    if (lastActive == null) return false;
    final elapsed = DateTime.now().difference(lastActive);
    return elapsed >= inactivityTimeout;
  }

  /// Returns how long the user has been idle (for UI display if needed).
  Duration getIdleDuration() {
    final raw = prefs.getString(lastActivityTimestamp);
    if (raw == null || raw.isEmpty) return Duration.zero;
    final lastActive = DateTime.tryParse(raw);
    if (lastActive == null) return Duration.zero;
    return DateTime.now().difference(lastActive);
  }

  // ── Token expiry helpers ────────────────────────────────────────────────

  /// Returns `"valid"`, `"refresh"` (within 10 min of expiry), or `"expired"`.
  Future<String> checkDateTime() async {
    final expiryStr = _authenticationResponse?.data?.expiryDt;

    if (expiryStr == null || expiryStr.isEmpty) {
      debugPrint("Missing or empty expiry date.");
      return "expired";
    }

    try {
      final expiryTime = DateTime.parse(expiryStr);
      final now = DateTime.now();

      if (now.isAfter(expiryTime)) {
        debugPrint("Session expired. Expiry: $expiryTime, Now: $now");
        return "expired";
      }

      // Pre-emptive refresh if within 10 minutes
      if (expiryTime.difference(now).inMinutes < 10) {
        return "refresh";
      }

      return "valid";
    } catch (e) {
      debugPrint("Invalid expiryDt format: $expiryStr");
      return "expired";
    }
  }

  /// Synchronously load the persisted auth response into memory.
  /// Reads come from the SecurePrefs in-memory cache, so this is safe to run
  /// in the constructor. Never clears storage — [init] owns validation.
  void _hydrateFromStorage() {
    try {
      final rawAuth = prefs.getString(authResponse);
      if (rawAuth == null || rawAuth.trim().isEmpty) return;
      final decoded = json.decode(rawAuth);
      if (decoded is! Map<String, dynamic>) return;
      final parsed = AuthResponse.fromJson(decoded);
      _authenticationResponse = parsed;
      _branchId = parsed.data?.user?.branchId;
      _rememberMe = prefs.getBool(rememberMe) ?? false;
    } catch (e) {
      debugPrint("Failed to hydrate auth from storage: $e");
    }
  }

  /// In-flight refresh call, shared so concurrent API calls (e.g. several
  /// requests fired on page load) trigger only one refresh request.
  Future<bool>? _refreshInFlight;

  /// Try to refresh the access token using the stored refresh token.
  /// Returns `true` if refresh succeeded, `false` otherwise.
  /// Concurrent callers await the same in-flight request.
  Future<bool> tryRefreshToken(BuildContext context) {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;
    final future = _refreshTokenCall(context).whenComplete(() => _refreshInFlight = null);
    _refreshInFlight = future;
    return future;
  }

  Future<bool> _refreshTokenCall(BuildContext context) async {
    final refreshToken = _authenticationResponse?.data?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      debugPrint("No refresh token available.");
      return false;
    }
    try {
      final response = await RefreshTokenController.refresh(context, refreshToken: refreshToken);
      if (response.code != null && response.code! >= 200 && response.code! < 300 && response.data != null) {
        await setAuthenticationResponse(response.data);
        debugPrint("Token refreshed successfully.");
        return true;
      }
      debugPrint("Token refresh failed (code: ${response.code}).");
      return false;
    } catch (e) {
      debugPrint("Token refresh threw: $e");
      return false;
    }
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /// Load persisted auth on app start.
  ///
  /// Returns the loaded [AuthResponse] when a valid session exists, or `null`
  /// when the session is expired / needs re-login.  Unlike the old version
  /// this will **try a token refresh** when the stored token is near expiry or
  /// already expired, so the user stays logged in across page reloads.
  Future<AuthResponse?> init(BuildContext context) async {
    try {
      // 1. Check inactivity BEFORE loading auth
      if (isSessionInactive()) {
        debugPrint("Session inactive for >${inactivityTimeout.inHours}h — clearing.");
        _sessionExpiredByInactivity = true;
        await _clearAuthState();
        return null;
      }

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
        await _clearAuthState();
        return null;
      }

      final parsed = AuthResponse.fromJson(decoded);
      _authenticationResponse = parsed;
      branchId = parsed.data?.user?.branchId;

      // 2. Check token freshness; try refresh if needed
      final expiryDtString = _authenticationResponse?.data?.expiryDt;
      if (expiryDtString == null || expiryDtString.trim().isEmpty) {
        debugPrint("AuthResponse expiryDt is null or empty.");
        await _clearAuthState();
        return null;
      }

      final expiry = DateTime.tryParse(expiryDtString);

      if (expiry == null) {
        debugPrint("Failed to parse expiryDt: $expiryDtString");
        await _clearAuthState();
        return null;
      }

      // 3. If token is within 10 min of expiry OR already expired → try refresh
      final timeUntilExpiry = expiry.difference(DateTime.now());
      if (timeUntilExpiry.isNegative) {
        debugPrint("Token expired on init ($expiry) — attempting refresh…");
        final refreshed = await tryRefreshToken(context);
        if (!refreshed) {
          debugPrint("Refresh failed on init — clearing auth.");
          await _clearAuthState();
          return null;
        }
      } else if (timeUntilExpiry.inMinutes < 10) {
        debugPrint("Token near expiry on init — refreshing…");
        await tryRefreshToken(context);
        // Non-critical if this fails — still has a few minutes
      }

      // 4. Record activity timestamp for fresh session
      trackActivity();

      debugPrint("Auth loaded and valid. Expires at: ${_authenticationResponse?.data?.expiryDt}");
      return _authenticationResponse;
    } catch (e) {
      debugPrint("Exception while loading authResponse: $e");
      await _clearAuthState();
      return null;
    }
  }

  /// Start the periodic inactivity monitor.
  /// Fires every [inactivityCheckInterval] and marks the session as expired
  /// when idle time exceeds [inactivityTimeout].
  void startInactivityMonitor() {
    _inactivityTimer?.cancel();
    _sessionExpiredByInactivity = false;
    _inactivityTimer = Timer.periodic(inactivityCheckInterval, (_) {
      if (isSessionInactive()) {
        debugPrint("Inactivity threshold reached — session expired.");
        _sessionExpiredByInactivity = true;
        notifyListeners();
        stopInactivityMonitor();
      }
    });
  }

  /// Stop the periodic inactivity monitor.
  void stopInactivityMonitor() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  @override
  void dispose() {
    stopInactivityMonitor();
    super.dispose();
  }

  // ── Validation UI ───────────────────────────────────────────────────────

  set usernameError(String? value) {
    _usernameError = value;
    notifyListeners();
  }

  set passwordError(String? value) {
    _passwordError = value;
    notifyListeners();
  }

  /// Check whether the authenticated user has a specific permission.
  bool hasPermission(String permission) {
    final perms = _authenticationResponse?.data?.user?.permissions;
    if (perms == null) return false;
    return perms.contains(permission);
  }

  /// Return the first permission entry (used as a fallback name).
  String getName() {
    return _authenticationResponse?.data?.user?.permissions?.first ?? '';
  }

  // ── Remember-me ─────────────────────────────────────────────────────────

  List<String>? getRememberMeCredentials() {
    _rememberMe = prefs.getBool(rememberMe) ?? false;
    if (_rememberMe == true) {
      return [prefs.getString(username) ?? '', '']; // password loaded via loadPassword()
    } else {
      return null;
    }
  }

  Future<String> loadPassword() async {
    return prefs.getString(password) ?? '';
  }

  // ── Persist / clear auth state ──────────────────────────────────────────

  Future<void> setAuthenticationResponse(AuthResponse? response, {String? usernameValue, String? passwordValue}) async {
    try {
      if (response != null) {
        final data = AuthResponse(
          data: Data(
            user: response.data?.user,
            accessToken: response.data?.accessToken,
            refreshToken: response.data?.refreshToken,
            issuedDt: response.data?.issuedDt ?? DateTime.now().toIso8601String(),
            expiryDt: response.data?.expiryDt ?? DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
          ),
        );

        if (data.data?.accessToken == null) {
          debugPrint("Invalid auth response, forcing re-login.");
          return;
        }

        if (_rememberMe) {
          prefs.setString(username, usernameValue ?? "");
          await prefs.setString(password, passwordValue ?? "");
        } else {
          prefs.remove(username);
          await prefs.remove(password);
        }

        await prefs.setString(authResponse, jsonEncode(data));
        await prefs.setString(token, data.data?.accessToken ?? '');
        _authenticationResponse = data;
        branchId = data.data?.user?.branchId;

        // Record activity on login / token refresh
        trackActivity();
        startInactivityMonitor();

        notifyListeners();
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      debugPrint("Auth save error: $e");
      await _clearAuthState();
    }
  }

  /// Clears all persisted auth state and resets in-memory fields.
  Future<void> _clearAuthState() async {
    prefs.remove(authResponse);
    prefs.remove(token);
    await prefs.remove(password);
    _authenticationResponse = null;
    branchId = null;
    _sessionExpiredByInactivity = false;
    stopInactivityMonitor();
    notifyListeners();
  }

  // ── Network calls ───────────────────────────────────────────────────────

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

  // ── Logout ──────────────────────────────────────────────────────────────

  Future<void> logout(BuildContext context) async {
    prefs.remove(jwtResponse);
    await _clearAuthState();
  }
}
