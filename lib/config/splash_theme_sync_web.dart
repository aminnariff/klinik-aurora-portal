import 'package:web/web.dart' as web;

/// Mirrors the user's non-sensitive appearance preferences into `localStorage`
/// so `web/index.html` renders the pre-boot splash screen in the exact same
/// Light/Dark mode and brand accent color before Flutter initializes.
void syncSplashAppearance({
  required String themeMode,
  required String presetId,
}) {
  try {
    web.window.localStorage.setItem('aurora_portal_theme_mode', themeMode);
    web.window.localStorage.setItem('aurora_portal_theme_preset', presetId);
  } catch (_) {
    // Ignore storage quota / private-browsing errors safely.
  }
}
