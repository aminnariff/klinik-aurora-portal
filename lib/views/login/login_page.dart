import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/password_recovery/password_recovery_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_request.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/aurora/aurora_wave_mesh.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/glass/app_glass.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
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
  final ValueNotifier<bool> isObscure = ValueNotifier<bool>(true);
  bool _isLoggingIn = false;

  late final AnimationController _entranceCtrl;
  late final AnimationController _logoCtrl;

  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));

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

    SchedulerBinding.instance.scheduleFrameCallback((_) async {
      _logoCtrl.forward();
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) _entranceCtrl.forward();
    });

    try {
      if (prefs.getBool(rememberMe) == true) {
        usernameController.text = prefs.getString(username) ?? '';
        passwordController.text = prefs.getString(password) ?? '';
      }
    } catch (_) {}
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
          // Ambient glowing wave mesh at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AuroraWaveMesh(
              height: MediaQuery.sizeOf(context).width < 600 ? 200 : 280,
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
                      // Floating Brand Logo
                      ScaleTransition(
                        scale: _logoScale,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: _logoAvatar(68),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Brand Header
                      FadeTransition(
                        opacity: _logoFade,
                        child: Column(
                          children: [
                            Text(
                              'Welcome to Klinik Aurora',
                              style: TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w800,
                                color: appInkPrimary,
                                letterSpacing: -0.4,
                              ),
                              textAlign: TextAlign.center,
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

                      // Frosted Glass Auth Card
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: AppGlassCard(
                            padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                            borderRadius: 16,
                            blurSigma: 18,
                            child: _formContent(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

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
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
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
                  borderSide: BorderSide(color: primary, width: 1.5),
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
                    style: TextStyle(fontSize: 12, color: primaryAccessibleText, fontWeight: FontWeight.w600),
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
                      borderSide: BorderSide(color: primary, width: 1.5),
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
                      activeColor: primary,
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
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor: primary.withValues(alpha: 0.6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
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
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
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
