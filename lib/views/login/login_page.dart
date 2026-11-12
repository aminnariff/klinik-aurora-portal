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
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
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
  final ValueNotifier<bool> isObscure = ValueNotifier<bool>(false);
  bool _isLoggingIn = false;

  InputFieldAttribute emailAttribute = InputFieldAttribute(
    controller: TextEditingController(text: ''),
    hintText: 'information'.tr(gender: 'email'),
    isEmail: true,
  );

  late final AnimationController _entranceCtrl;
  late final AnimationController _logoCtrl;

  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

    _formFade = CurvedAnimation(parent: _entranceCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0));
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0)));

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0));
    _logoScale = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: const Cubic(0.23, 1.0, 0.32, 1.0)));

    SchedulerBinding.instance.scheduleFrameCallback((_) async {
      _logoCtrl.forward();
      Future.delayed(const Duration(milliseconds: 60), () {
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dismissLoading();
      if (mounted) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.popUntil((route) => route.isFirst);
        }
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _logoCtrl.dispose();
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
        // Subtle ambient glow
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        // Logo area
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.28,
          child: _mobileBrandHeader(),
        ),
        // Form card
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.76,
            widthFactor: 1.0,
            child: FadeTransition(
              opacity: _formFade,
              child: SlideTransition(
                position: _formSlide,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Color(0x26000000), blurRadius: 40, offset: Offset(0, -8))],
                  ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
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
          child: FadeTransition(opacity: _logoFade, child: _logoAvatar(76)),
        ),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: _logoFade,
          child: const Text(
            'Klinik Aurora',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
          ),
        ),
        const SizedBox(height: 2),
        FadeTransition(
          opacity: _logoFade,
          child: Text(
            'Enterprise Management Portal',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _brandPanel() {
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
          // Subtle ambient radial glow circles
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
          // Center content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo with clean white circle
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(opacity: _logoFade, child: _logoAvatar(124)),
                  ),
                  const SizedBox(height: 24),
                  // Clinic name
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
                  // Tagline
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

  Widget _logoAvatar(double size) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.12),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Image(
        image: AssetImage("assets/icons/logo/klinik-aurora.png"),
        fit: BoxFit.contain,
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
            // Session Expired Banner (Non-blocking alert)
            ValueListenableBuilder<bool>(
              valueListenable: sessionExpiredNotice,
              builder: (context, hasExpired, _) {
                if (!hasExpired) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Your session has expired. Please sign in again to continue.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => sessionExpiredNotice.value = false,
                        borderRadius: BorderRadius.circular(4),
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFB45309)),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Header
            const Text(
              'Sign in to your account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Enter your clinic credentials to access the management portal.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 30),

            _fieldLabel('Email / Username'),
            const SizedBox(height: 7),
            InputField(
              field: InputFieldAttribute(
                attribute: 'email',
                controller: usernameController,
                hintText: 'loginPage'.tr(gender: 'username'),
                isEmail: true,
                isEditableColor: const Color(0xFFF8FAFC),
                errorMessage: snapshot.usernameError,
                onFieldSubmitted: (_) => _handleLogin(),
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.alternate_email_rounded, color: Colors.grey.shade500, size: 19),
                    AppPadding.horizontal(denominator: 2),
                  ],
                ),
              ),
              width: screenHeightByBreakpoint(80, 50, 380, useAbsoluteValueDesktop: true),
            ),

            const SizedBox(height: 18),

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
                    style: TextStyle(fontSize: 13, color: primaryAccessibleText, fontWeight: FontWeight.w600),
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
                isEditableColor: const Color(0xFFF8FAFC),
                errorMessage: snapshot.passwordError,
                onFieldSubmitted: (_) => _handleLogin(),
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(width: 12),
                    Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500, size: 19),
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

            const SizedBox(height: 16),

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
                      activeColor: const Color(0xFFDF6E98),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    'loginPage'.tr(gender: 'rememberMe'),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            EmilPressable(
              enabled: !_isLoggingIn,
              onTap: _handleLogin,
              child: SizedBox(
                width: screenHeightByBreakpoint(80, 50, 380, useAbsoluteValueDesktop: true),
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDF6E98),
                    disabledBackgroundColor: const Color(0xFFDF6E98).withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: _isLoggingIn
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'loginPage'.tr(gender: 'signIn'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    offset: const Offset(0, 20),
                    blurRadius: 40,
                  ),
                  BoxShadow(
                    color: primary.withValues(alpha: 0.08),
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
                          gradient: LinearGradient(
                            colors: [primary, primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
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
                          size: 26,
                        ),
                      ),
                      IconButton(
  tooltip: 'Tutup',
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
  tooltip: 'Kosongkan',
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
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: primary, width: 1.5),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(8),
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
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Send Verification Code',
                              style: TextStyle(
                                fontSize: 14,
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
        ),
      ),
    );
  }
}
