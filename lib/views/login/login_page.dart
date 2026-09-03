import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/password_recovery/password_recovery_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_request.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/password_recovery/admin_password_recovery.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

bool isSessionExpiredDialogOpen = false;

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
  final ValueNotifier<bool> isObscure = ValueNotifier<bool>(false);

  InputFieldAttribute emailAttribute = InputFieldAttribute(
    controller: TextEditingController(text: ''),
    hintText: 'information'.tr(gender: 'email'),
    isEmail: true,
  );

  late final AnimationController _entranceCtrl;
  late final AnimationController _logoCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);

    _formFade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _pulse = Tween<double>(begin: 0.5, end: 0.9).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    SchedulerBinding.instance.scheduleFrameCallback((_) async {
      _logoCtrl.forward();
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _entranceCtrl.forward();
      });

      final authController = context.read<AuthController>();
      await authController.init(context);

      // Load remember-me credentials (runs regardless of init result)
      final rememberMeCredentials = authController.getRememberMeCredentials();
      final remember = prefs.getBool(rememberMe) ?? false;
      context.read<AuthController>().remember = remember;
      if (rememberMeCredentials != null && remember == true) {
        usernameController.text = rememberMeCredentials[0];
        passwordController.text = await authController.loadPassword();
      }
    });

    dismissLoading();
    isSessionExpiredDialogOpen = false;
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    usernameController.dispose();
    passwordController.dispose();
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 768) return _desktopLayout();
          return _mobileLayout();
        },
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      children: [
        Expanded(flex: 5, child: _brandPanel()),
        Expanded(flex: 7, child: _desktopFormPanel()),
      ],
    );
  }

  Widget _mobileLayout() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: primaryColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        // Decorative circles
        _pulsableCircle(size: 200, topFactor: -0.08, leftFactor: -0.15),
        _pulsableCircle(size: 140, topFactor: 0.12, rightFactor: -0.1),
        // Logo area
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.3,
          child: _mobileBrandHeader(),
        ),
        // Form card
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.75,
            widthFactor: 1.0,
            child: FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 40, offset: Offset(0, -8))],
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                    child: _formContent(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _mobileBrandHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _logoScale,
          child: FadeTransition(opacity: _logoFade, child: _logoAvatar(80)),
        ),
        const SizedBox(height: 12),
        FadeTransition(
          opacity: _logoFade,
          child: const Text(
            'Klinik Aurora',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _brandPanel() {
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: primaryColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
        ),
        // Animated decorative blobs
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) => Stack(
            children: [
              Positioned(top: -90, right: -90, child: _decorCircle(280, _pulse.value * 0.16)),
              Positioned(bottom: -70, left: -110, child: _decorCircle(320, _pulse.value * 0.12)),
              Positioned(top: 200, left: -60, child: _decorCircle(160, _pulse.value * 0.20)),
              Positioned(bottom: 220, right: -40, child: _decorCircle(110, _pulse.value * 0.18)),
            ],
          ),
        ),
        // Center content
        Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(opacity: _logoFade, child: _logoAvatar(140)),
                ),
                const SizedBox(height: 28),
                // Clinic name
                FadeTransition(
                  opacity: _logoFade,
                  child: const Text(
                    'Klinik Aurora',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Tagline
                FadeTransition(
                  opacity: _logoFade,
                  child: Text(
                    'Your trusted healthcare partner',
                    style: TextStyle(
                      color: Colors.white.withAlpha(210),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Divider
                FadeTransition(
                  opacity: _logoFade,
                  child: Container(
                    width: 48,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(130),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Feature badges
                FadeTransition(
                  opacity: _logoFade,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: const [
                      _FeatureBadge(Icons.calendar_today_rounded, 'Appointments'),
                      _FeatureBadge(Icons.people_rounded, 'Patients'),
                      _FeatureBadge(Icons.medical_services_rounded, 'Services'),
                      _FeatureBadge(Icons.bar_chart_rounded, 'Analytics'),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                // Footer
                FadeTransition(
                  opacity: _logoFade,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined, color: Colors.white.withAlpha(180), size: 17),
                            const SizedBox(width: 6),
                            Text(
                              'Authorized Personnel Only  ·  System is monitored',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '© 2026 Klinik Aurora. All rights reserved.',
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(80), width: 3),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 24, offset: const Offset(0, 6))],
      ),
      child: const ClipOval(
        child: Image(image: AssetImage("assets/icons/logo/klinik-aurora.png"), fit: BoxFit.cover),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  /// Used in mobile layout for non-animated blobs (inside Stack with factors)
  Widget _pulsableCircle({required double size, double? topFactor, double? leftFactor, double? rightFactor}) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    return Positioned(
      top: topFactor != null ? screenH * topFactor : null,
      left: leftFactor != null ? screenW * leftFactor : null,
      right: rightFactor != null ? screenW * rightFactor : null,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, _) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: _pulse.value * 0.15),
          ),
        ),
      ),
    );
  }

  Widget _desktopFormPanel() {
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: SingleChildScrollView(child: _formContent()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formContent() {
    return Consumer<AuthController>(
      builder: (context, snapshot, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Portal label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: secondaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: secondaryColor.withAlpha(60)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings_rounded, color: secondaryColor, size: 17),
                  SizedBox(width: 5),
                  Text(
                    'Healthcare Admin  ·  Management Portal',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: secondaryColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Header
            const Text(
              'Welcome back!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to your account to continue',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 36),

            _fieldLabel('Email / Username'),
            const SizedBox(height: 7),
            InputField(
              field: InputFieldAttribute(
                attribute: 'email',
                controller: usernameController,
                hintText: 'loginPage'.tr(gender: 'username'),
                isEmail: true,
                isEditableColor: const Color(0xFFF3F4F6),
                errorMessage: snapshot.usernameError,
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.person_outline_rounded, color: Colors.grey.shade400, size: 20),
                    AppPadding.horizontal(denominator: 2),
                  ],
                ),
              ),
              width: screenHeightByBreakpoint(80, 50, 380, useAbsoluteValueDesktop: true),
            ),

            const SizedBox(height: 20),

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
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(fontSize: 13, color: secondaryColor, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            InputField(
              field: InputFieldAttribute(
                attribute: 'password',
                controller: passwordController,
                hintText: 'loginPage'.tr(gender: 'password'),
                obscureText: true,
                isPassword: true,
                isEditableColor: const Color(0xFFF3F4F6),
                errorMessage: snapshot.passwordError,
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
                    AppPadding.horizontal(denominator: 2),
                  ],
                ),
                obsecureAction: () {
                  isObscure.value = !isObscure.value;
                  return null;
                },
              ),
              width: screenHeightByBreakpoint(80, 50, 380, useAbsoluteValueDesktop: true),
            ),

            const SizedBox(height: 18),

            GestureDetector(
              onTap: () => snapshot.remember = !snapshot.remember,
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: snapshot.remember,
                      onChanged: (v) => snapshot.remember = v ?? false,
                      activeColor: secondaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'loginPage'.tr(gender: 'rememberMe'),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: screenHeightByBreakpoint(80, 50, 380, useAbsoluteValueDesktop: true),
              child: ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  shadowColor: secondaryColor.withAlpha(80),
                ),
                child: Text(
                  'loginPage'.tr(gender: 'signIn'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                ),
              ),
            ),

            // // Footer
            // Center(
            //   child: Column(
            //     children: [
            //       const SizedBox(height: 20),
            //       Row(
            //         mainAxisAlignment: MainAxisAlignment.center,
            //         children: [
            //           Icon(Icons.shield_outlined, size: 11, color: Colors.grey.shade400),
            //           const SizedBox(width: 5),
            //           Text(
            //             'Authorized Personnel Only  ·  System is monitored',
            //             style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            //           ),
            //         ],
            //       ),
            //       const SizedBox(height: 6),
            //       Text(
            //         '© 2026 Klinik Aurora. All rights reserved.',
            //         style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            //       ),
            //     ],
            //   ),
            // ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
    );
  }

  void _handleLogin() {
    validateField().then((valid) {
      if (!valid) return;
      showLoading();
      AuthController.logIn(
        context,
        AuthRequest(username: usernameController.text, password: passwordController.text),
      ).then((value) async {
        dismissLoading();
        if (responseCode(value.code)) {
          await context.read<AuthController>().setAuthenticationResponse(
            value.data,
            usernameValue: usernameController.text,
            passwordValue: passwordController.text,
          );
          if (mounted) context.goNamed(Homepage.routeName);
        }
      });
    });
  }

  Future<bool> validateField() async {
    bool temp = true;
    if (usernameController.text.isEmpty) {
      context.read<AuthController>().usernameError = ErrorMessage.required(field: 'loginPage'.tr(gender: 'username'));
      temp = false;
    }
    if (passwordController.text.isEmpty) {
      context.read<AuthController>().passwordError = ErrorMessage.required(field: 'loginPage'.tr(gender: 'password'));
      temp = false;
    }
    return temp;
  }

  void forgotPassword() {
    final initialEmail = usernameController.text.contains('@')
        ? usernameController.text.trim()
        : emailAttribute.controller.text.trim();

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
      backgroundColor: Colors.white,
      body: Center(child: SizedBox(width: 140, child: Lottie.asset('assets/lottie/simple-loading.json', width: 140))),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(26),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
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
  String? _errorMessage;
  bool _isLoading = false;

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
        AdminPasswordRecoveryPage.routeName,
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    offset: const Offset(0, 20),
                    blurRadius: 40,
                  ),
                  BoxShadow(
                    color: secondaryColor.withValues(alpha: 0.08),
                    offset: const Offset(0, 8),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row with Icon & Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [secondaryColor, Color(0xFF3EA6B7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: secondaryColor.withValues(alpha: 0.35),
                              offset: const Offset(0, 6),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8), size: 22),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Title & Description
                  const Text(
                    'Reset your password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your registered staff email address and we will send you a 6-digit verification code.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Input Label
                  const Text(
                    'STAFF EMAIL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sleek Custom Text Field
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      hintText: 'e.g. staff@klinikaurora.com',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.alternate_email_rounded,
                        color: Color(0xFF94A3B8),
                        size: 19,
                      ),
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) {
                          if (value.text.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                            onPressed: () {
                              _controller.clear();
                              setState(() => _errorMessage = null);
                            },
                          );
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: secondaryColor, width: 1.8),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 17),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: secondaryColor,
                        shadowColor: secondaryColor.withValues(alpha: 0.4),
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [secondaryColor, Color(0xFF3EA6B7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Send Verification Code',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Back to Sign In Link
                  Center(
                    child: TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Back to Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
