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
    return GoogleAuthResult(
      success: false,
      error: 'Google Sign-In is only supported on web platform.',
    );
  }
}
