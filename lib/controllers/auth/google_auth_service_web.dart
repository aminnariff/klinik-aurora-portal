import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

@JS('auroraGoogleSignIn')
external JSPromise<JSString>? _auroraGoogleSignInJs();

class GoogleAuthResult {
  final bool success;
  final String? idToken;
  final String? email;
  final String? error;
  final String? code;

  GoogleAuthResult({
    required this.success,
    this.idToken,
    this.email,
    this.error,
    this.code,
  });
}

class GoogleAuthService {
  static Future<GoogleAuthResult> signIn() async {
    try {
      final promise = _auroraGoogleSignInJs();
      if (promise == null) {
        return GoogleAuthResult(
          success: false,
          error: 'Google Sign-In is not initialized or not supported in this browser.',
        );
      }
      final jsString = await promise.toDart;
      final raw = jsString.toDart;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GoogleAuthResult(
        success: map['success'] == true,
        idToken: map['idToken'] as String?,
        email: map['email'] as String?,
        error: map['error'] as String?,
        code: map['code'] as String?,
      );
    } catch (e) {
      return GoogleAuthResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}
