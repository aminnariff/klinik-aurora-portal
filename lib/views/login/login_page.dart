import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/password_recovery/password_recovery_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_request.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/aurora/aurora_wave_mesh.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/glass/app_glass.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klinik_aurora_portal/controllers/auth/google_auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

bool isSessionExpiredDialogOpen = false;
final ValueNotifier<bool> sessionExpiredNotice = ValueNotifier<bool>(false);

class LoginPage extends StatefulWidget {
  final bool? resetUser;
  static const routeName = '/login';

  const LoginPage({super.key, this.resetUser});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final ValueNotifier<bool> isObscure = ValueNotifier<bool>(true);
  bool _isLoggingIn = false;
  bool _useClassicLayout = false;

  late final AnimationController _entranceCtrl;
  late final AnimationController _logoCtrl;

  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));

    _formFade = CurvedAnimation(parent: _entranceCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0));
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0)));

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0));
    _logoScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0)));

    try {
      _useClassicLayout = prefs.getBool('aurora_login_classic_layout') ?? false;
      if (prefs.getBool(rememberMe) == true) {
        usernameController.text = prefs.getString(username) ?? '';
        passwordController.text = prefs.getString(password) ?? '';
      }
    } catch (_) {}
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _logoCtrl.value = 1;
      _entranceCtrl.value = 1;
    } else {
      _logoCtrl.forward();
      _entranceCtrl.forward();
    }
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
    usernameController.dispose();
    passwordController.dispose();
    isObscure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _view();

  Widget _view() {
    return Consumer<AuthController>(
      builder: (context, controller, _) {
        if (controller.authenticationResponse != null &&
            DateTime.parse(
                  controller.authenticationResponse?.data?.expiryDt ?? '',
                ).difference(DateTime.now()).isNegative ==
                false &&
            widget.resetUser != true) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) context.replaceNamed(Homepage.routeName);
          });
          return _loadingScreen();
        }
        return _authPage();
      },
    );
  }

  Widget _authPage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070D12) : const Color(0xFFF8FAFC),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _useClassicLayout ? _classicLayout() : _modernLayout(),
          _floatingToolbar(context),
        ],
      ),
    );
  }

  Widget _modernLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Slushy glowing aurora circles (zero harsh rings)
        _slushyAuroraBackground(isDark),

        // Ambient glowing wave mesh at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AuroraWaveMesh(
            height: MediaQuery.sizeOf(context).width < 600 ? 220 : 300,
          ),
        ),

        // Centered Floating Glassmorphic Auth Form
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating Brand Logo with Aurora Halo
                    ScaleTransition(
                      scale: _logoScale,
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: _logoAvatar(72),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Brand Header with Signature Aurora Gradient
                    FadeTransition(
                      opacity: _logoFade,
                      child: Column(
                        children: [
                          Text(
                            'Welcome to',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: appInkSecondary,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 3),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFDF6E98),
                                Color(0xFF6AD1E3),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Klinik Aurora',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Enterprise Healthcare Management Portal',
                            style: TextStyle(
                              fontSize: 13,
                              color: appInkMuted,
                              fontWeight: FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Frosted Glass Auth Card with Aurora Hairline Border
                    FadeTransition(
                      opacity: _formFade,
                      child: SlideTransition(
                        position: _formSlide,
                        child: AppGlassCard(
                          auroraBorder: true,
                          padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                          borderRadius: 16,
                          blurSigma: 18,
                          child: _formContent(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Footer Assistance
                    FadeTransition(
                      opacity: _formFade,
                      child: TextButton(
                        onPressed: forgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: appInkMuted,
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Having trouble signing in? Reset Password'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _slushyAuroraBackground(bool isDark) {
    final screenH = MediaQuery.sizeOf(context).height;
    final screenW = MediaQuery.sizeOf(context).width;

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Base canvas gradient wash
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [
                        Color(0xFF070D12),
                        Color(0xFF0C141E),
                        Color(0xFF070D12),
                      ]
                    : const [
                        Color(0xFFFCF4F7), // warm soft blush
                        Color(0xFFF3FAFC), // soft cyan glow
                        Color(0xFFF8FAFC), // clean slate
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 2. Glowing Slushy Aurora Blobs with Deep Gaussian Blur (Zero Rings!)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 95, sigmaY: 95),
              child: Stack(
                children: [
                  // Top-Right Aurora Rose / Pink glow orb
                  Positioned(
                    top: -100,
                    right: -80,
                    child: Container(
                      width: 520,
                      height: 520,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFFDF6E98).withValues(alpha: 0.28)
                            : const Color(0xFFDF6E98).withValues(alpha: 0.24),
                      ),
                    ),
                  ),
                  // Center-Left Aurora Cyan glow orb
                  Positioned(
                    top: screenH * 0.12,
                    left: -120,
                    child: Container(
                      width: 500,
                      height: 500,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF6AD1E3).withValues(alpha: 0.24)
                            : const Color(0xFF6AD1E3).withValues(alpha: 0.26),
                      ),
                    ),
                  ),
                  // Bottom-Right Warm Plum / Berry glow orb
                  Positioned(
                    bottom: -100,
                    right: screenW * 0.15,
                    child: Container(
                      width: 460,
                      height: 460,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF7E2D40).withValues(alpha: 0.25)
                            : const Color(0xFFDE8BA7).withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                  // Bottom-Left Mint / Soft Cyan glow orb
                  Positioned(
                    bottom: -80,
                    left: -60,
                    child: Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1B545E).withValues(alpha: 0.22)
                            : const Color(0xFF6AD1E3).withValues(alpha: 0.20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Iconic Slushy Translucent Circles (from the classic login design!)
          // Clean, organic floating orbs that give depth without harsh rings
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.50),
                border: Border.all(
                  color: (isDark ? Colors.white : const Color(0xFFDF6E98)).withValues(alpha: isDark ? 0.06 : 0.14),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            top: screenH * 0.22,
            right: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.45),
                border: Border.all(
                  color: (isDark ? Colors.white : const Color(0xFF6AD1E3)).withValues(alpha: isDark ? 0.05 : 0.14),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: screenW * 0.25,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.40),
                border: Border.all(
                  color: (isDark ? Colors.white : const Color(0xFFDE8BA7)).withValues(alpha: isDark ? 0.05 : 0.12),
                  width: 1.5,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: 40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: isDark ? 0.02 : 0.35),
                border: Border.all(
                  color: (isDark ? Colors.white : const Color(0xFF6AD1E3)).withValues(alpha: isDark ? 0.04 : 0.10),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _classicLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 768) return _desktopClassicLayout();
        return _mobileClassicLayout();
      },
    );
  }

  Widget _desktopClassicLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(flex: 5, child: _classicBrandPanel()),
        Expanded(
          flex: 7,
          child: Container(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: _formFade,
                      child: SlideTransition(
                        position: _formSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Sign in to your account',
                              style: TextStyle(
                                fontSize: 27,
                                fontWeight: FontWeight.w800,
                                color: appInkPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter your clinic credentials to access the management portal.',
                              style: TextStyle(fontSize: 13.5, color: appInkSecondary),
                            ),
                            const SizedBox(height: 28),
                            _formContent(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileClassicLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFDF6E98),
                Color(0xFFDE8BA7),
                Color(0xFF6AD1E3),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.sizeOf(context).height * 0.28,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _logoAvatar(72),
              const SizedBox(height: 8),
              const Text(
                'Klinik Aurora',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                'Enterprise Management Portal',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.74,
            widthFactor: 1.0,
            child: FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 40, offset: Offset(0, -8))],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: appInkPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your clinic credentials to continue.',
                          style: TextStyle(fontSize: 12.5, color: appInkSecondary),
                        ),
                        const SizedBox(height: 22),
                        _formContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _classicBrandPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFDF6E98),
            Color(0xFFDE8BA7),
            Color(0xFF6AD1E3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(opacity: _logoFade, child: _logoAvatar(124)),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _logoFade,
                    child: const Text(
                      'Klinik Aurora',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeTransition(
                    opacity: _logoFade,
                    child: Text(
                      'Enterprise Clinical Management System',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _logoFade,
                    child: Text(
                      '© 2026 Klinik Aurora Group. All rights reserved.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.70), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingToolbar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: 18,
      right: 20,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.14) : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dark / Light Mode Toggle
              Tooltip(
                message: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                child: IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
                    size: 19,
                    color: isDark ? const Color(0xFFFDB813) : const Color(0xFF475569),
                  ),
                  onPressed: () => context.read<DarkModeController>().toggleDarkMode(context),
                  splashRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  constraints: const BoxConstraints(),
                ),
              ),
              Container(
                height: 16,
                width: 1,
                color: isDark ? Colors.white.withValues(alpha: 0.16) : Colors.black.withValues(alpha: 0.12),
              ),
              // View Switcher (Classic Split <-> Modern Aurora)
              Tooltip(
                message: _useClassicLayout ? 'Switch to Modern Glass View' : 'Switch to Classic Split View',
                child: IconButton(
                  icon: Icon(
                    _useClassicLayout ? Icons.auto_awesome_rounded : Icons.vertical_split_rounded,
                    size: 19,
                    color: isDark ? const Color(0xFF6AD1E3) : const Color(0xFFDF6E98),
                  ),
                  onPressed: () {
                    setState(() => _useClassicLayout = !_useClassicLayout);
                    try {
                      prefs.setBool('aurora_login_classic_layout', _useClassicLayout);
                    } catch (_) {}
                  },
                  splashRadius: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoAvatar(double size) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: appSurface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDF6E98).withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF6AD1E3).withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Image(
        image: AssetImage("assets/icons/logo/klinik-aurora.png"),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _formContent() {
    return Consumer<AuthController>(
      builder: (context, snapshot, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Session Expired Alert
            ValueListenableBuilder<bool>(
              valueListenable: sessionExpiredNotice,
              builder: (context, hasExpired, _) {
                if (!hasExpired) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: appWarningSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Your session has expired. Please sign in again.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => sessionExpiredNotice.value = false,
                        borderRadius: BorderRadius.circular(4),
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Email / Username
            _fieldLabel('Staff Email / Username'),
            const SizedBox(height: 6),
            TextFormField(
              controller: usernameController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _handleLogin(),
              onChanged: (_) {
                if (snapshot.usernameError != null) {
                  snapshot.usernameError = null;
                }
              },
              style: TextStyle(fontSize: 14, color: appInkPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? const Color(0xBF0E171E) : const Color(0xF2F1F5F9),
                hintText: 'e.g. staff@klinikaurora.com',
                hintStyle: TextStyle(fontSize: 13, color: appInkMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                prefixIcon: Icon(Icons.alternate_email_rounded, size: 18, color: appInkMuted),
                errorText: snapshot.usernameError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: appBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _useClassicLayout ? const Color(0xFF0A6C74) : primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password Field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _fieldLabel('Password'),
                TextButton(
                  onPressed: forgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 12,
                      color: _useClassicLayout ? const Color(0xFF0A6C74) : primaryAccessibleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<bool>(
              valueListenable: isObscure,
              builder: (context, obscure, _) {
                return TextFormField(
                  controller: passwordController,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  onChanged: (_) {
                    if (snapshot.passwordError != null) {
                      snapshot.passwordError = null;
                    }
                  },
                  style: TextStyle(fontSize: 14, color: appInkPrimary, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: isDark ? const Color(0xBF0E171E) : const Color(0xF2F1F5F9),
                    hintText: 'Enter your password',
                    hintStyle: TextStyle(fontSize: 13, color: appInkMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: appInkMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        size: 18,
                        color: appInkMuted,
                      ),
                      onPressed: () => isObscure.value = !isObscure.value,
                    ),
                    errorText: snapshot.passwordError,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: appBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: _useClassicLayout ? const Color(0xFF0A6C74) : primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 14),

            // Remember Me
            GestureDetector(
              onTap: () => snapshot.remember = !snapshot.remember,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: Checkbox(
                      value: snapshot.remember,
                      onChanged: (v) => snapshot.remember = v ?? false,
                      activeColor: _useClassicLayout ? const Color(0xFF0A6C74) : primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(fontSize: 12.5, color: appInkSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Submit Button
            EmilPressable(
              enabled: !_isLoggingIn,
              onTap: _handleLogin,
              child: Container(
                width: double.infinity,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _useClassicLayout
                      ? null
                      : const LinearGradient(
                          colors: [
                            Color(0xFFDF6E98), // Aurora Pink
                            Color(0xFF7E2D40), // Aurora Plum
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  color: _useClassicLayout ? const Color(0xFF0A6C74) : null,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: (_useClassicLayout ? const Color(0xFF0A6C74) : const Color(0xFFDF6E98))
                          .withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _isLoggingIn ? null : _handleLogin,
                    child: Center(
                      child: _isLoggingIn
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.0,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(width: 7),
                                Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider "OR"
            Row(
              children: [
                Expanded(child: Divider(color: appBorder, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: appInkMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: appBorder, height: 1)),
              ],
            ),

            const SizedBox(height: 16),

            // Google Workspace SSO Button
            EmilPressable(
              enabled: !_isLoggingIn,
              onTap: _handleGoogleLogin,
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _isLoggingIn ? null : _handleGoogleLogin,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(
                            '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="18px" height="18px">
                              <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
                              <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
                              <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
                              <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
                            </svg>''',
                            width: 18,
                            height: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Sign in with Google',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: appInkSecondary),
    );
  }

  void _handleGoogleLogin() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);
    try {
      final result = await GoogleAuthService.signIn();
      if (!result.success || result.idToken == null) {
        if (result.code != 'auth/popup-closed-by-user' && result.code != 'auth/cancelled-popup-request') {
          if (mounted) {
            showDialogError(context, result.error ?? 'Google sign-in was cancelled.');
          }
        }
        return;
      }

      if (!mounted) return;
      final res = await AuthController.logInWithGoogle(context, result.idToken!);
      if (responseCode(res.code)) {
        await context.read<AuthController>().setAuthenticationResponse(
          res.data,
          usernameValue: result.email,
        );
        if (mounted) context.goNamed(Homepage.routeName);
      } else {
        if (mounted) {
          showDialogError(
            context,
            res.message ?? res.data?.message ?? 'Access denied. Account not authorized.',
          );
        }
      }
    } catch (e) {
      if (mounted) showDialogError(context, 'Authentication failed: $e');
    } finally {
      if (mounted) setState(() => _isLoggingIn = false);
    }
  }

  void _handleLogin() {
    if (_isLoggingIn) return;
    validateField().then((valid) {
      if (!valid) return;
      setState(() => _isLoggingIn = true);
      AuthController.logIn(
        context,
        AuthRequest(username: usernameController.text, password: passwordController.text),
      ).then((value) async {
        if (responseCode(value.code)) {
          await context.read<AuthController>().setAuthenticationResponse(
            value.data,
            usernameValue: usernameController.text,
            passwordValue: passwordController.text,
          );
          if (mounted) context.goNamed(Homepage.routeName);
        } else {
          showDialogError(context, value.message ?? value.data?.message ?? 'Login failed. Please check your credentials.');
        }
      }).catchError((e) {
        showDialogError(context, e.toString());
      }).whenComplete(() {
        if (mounted) setState(() => _isLoggingIn = false);
      });
    });
  }

  Future<bool> validateField() async {
    bool temp = true;
    if (usernameController.text.trim().isEmpty) {
      context.read<AuthController>().usernameError = ErrorMessage.required(field: 'Email / Username');
      temp = false;
    }
    if (passwordController.text.isEmpty) {
      context.read<AuthController>().passwordError = ErrorMessage.required(field: 'Password');
      temp = false;
    }
    return temp;
  }

  void forgotPassword() {
    final initialEmail = usernameController.text.contains('@')
        ? usernameController.text.trim()
        : '';

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext dialogContext) {
        return _ForgotPasswordDialog(initialEmail: initialEmail);
      },
    );
  }

  Widget _loadingScreen() {
    return Scaffold(
      backgroundColor: appCanvas,
      body: Center(child: SizedBox(width: 140, child: Lottie.asset(
        'assets/lottie/simple-loading.json',
        width: 140,
        animate: !MediaQuery.disableAnimationsOf(context),
      ))),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _controller;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your staff email address');
      return;
    }
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
    );
    if (!emailRegex.hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await PasswordRecoveryController.forgotPassword(context, email);
    if (!mounted) return;

    setState(() => _isLoading = false);

    if (responseCode(res.code)) {
      context.pop();
      context.pushNamed(
        RouteNames.passwordRecovery,
        extra: {
          'token': res.data?.data?.token ?? '',
          'email': email,
        },
      );
    } else {
      setState(() {
        _errorMessage = res.message ?? res.data?.message ?? 'Staff email not found. Please verify and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: appSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appBorder, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                offset: const Offset(0, 20),
                blurRadius: 40,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primary, primary.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          offset: const Offset(0, 6),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => context.pop(),
                    icon: Icon(Icons.close_rounded, color: appInkMuted, size: 20),
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Reset your password',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: appInkPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your registered staff email address and we will send you a 6-digit verification code.',
                style: TextStyle(
                  fontSize: 13,
                  color: appInkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'STAFF EMAIL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: appInkSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: appInkPrimary,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: appSurfaceSubtle,
                  hintText: 'e.g. staff@klinikaurora.com',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: appInkMuted,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.alternate_email_rounded,
                    color: appInkMuted,
                    size: 18,
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        tooltip: 'Clear',
                        icon: Icon(Icons.cancel_rounded, size: 16, color: appInkMuted),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _errorMessage = null);
                        },
                      );
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: appBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primary, width: 1.5),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: appDangerSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send Verification Code',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
