import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/password_recovery/password_recovery_controller.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:pinput/pinput.dart';

class AdminPasswordRecoveryPage extends StatefulWidget {
  static const routeName = '/password-recovery';
  final String? token;
  final String? email;

  const AdminPasswordRecoveryPage({
    super.key,
    required this.token,
    this.email,
  });

  @override
  State<AdminPasswordRecoveryPage> createState() => _AdminPasswordRecoveryPageState();
}

class _AdminPasswordRecoveryPageState extends State<AdminPasswordRecoveryPage> {
  late String? _currentToken;
  final TextEditingController otpController = TextEditingController();
  final FocusNode otpFocusNode = FocusNode();

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode confirmPasswordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  final ValueNotifier<bool?> isSuccess = ValueNotifier(null);
  String? responseMessage;
  String? _errorMessage;

  // Resend OTP countdown
  int _countdown = 60;
  Timer? _timer;
  bool _isResending = false;

  // Live password validation
  bool get _hasMinLength => passwordController.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(passwordController.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(passwordController.text);
  bool get _passwordsMatch =>
      passwordController.text.isNotEmpty &&
      passwordController.text == confirmPasswordController.text;

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasNumber) score++;
    if (_passwordsMatch) score++;
    return score;
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1:
        return const Color(0xFFEF4444); // Red
      case 2:
        return const Color(0xFFF59E0B); // Amber
      case 3:
        return const Color(0xFF0D9488); // Teal
      case 4:
        return const Color(0xFF10B981); // Emerald
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  String get _strengthLabel {
    if (passwordController.text.isEmpty) return 'Enter a password';
    switch (_strengthScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong & Secure';
      default:
        return 'Too short';
    }
  }

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    _startTimer();

    passwordController.addListener(() => setState(() {}));
    confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocusNode.dispose();
    confirmPasswordFocusNode.dispose();
    isSuccess.dispose();
    super.dispose();
  }

  void _startTimer() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0 || _isResending) return;
    if (widget.email == null || widget.email!.isEmpty) {
      setState(() {
        _errorMessage = 'Email address is missing. Please restart password recovery from sign in.';
      });
      return;
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    showLoading();
    final res = await PasswordRecoveryController.forgotPassword(context, widget.email!.trim());
    dismissLoading();

    if (!mounted) return;
    setState(() {
      _isResending = false;
    });

    if (responseCode(res.code)) {
      if (res.data?.data?.token != null) {
        _currentToken = res.data!.data!.token!;
      }
      _startTimer();
      otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('A fresh 6-digit verification code has been sent to your email.')),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.message ?? res.data?.message ?? 'Failed to resend verification code.';
      });
    }
  }

  Future<void> _submitReset() async {
    FocusScope.of(context).unfocus();

    final otp = otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter the complete 6-digit verification code.');
      otpFocusNode.requestFocus();
      return;
    }

    if (!_hasMinLength) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      passwordFocusNode.requestFocus();
      return;
    }

    if (!_hasUppercase) {
      setState(() => _errorMessage = 'Password must contain at least one uppercase letter (A-Z).');
      passwordFocusNode.requestFocus();
      return;
    }

    if (!_hasNumber) {
      setState(() => _errorMessage = 'Password must contain at least one number (0-9).');
      passwordFocusNode.requestFocus();
      return;
    }

    if (!_passwordsMatch) {
      setState(() => _errorMessage = 'Passwords do not match. Please re-enter.');
      confirmPasswordFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    showLoading();
    final res = await PasswordRecoveryController.changePassword(
      context,
      _currentToken ?? '',
      otp,
      passwordController.text,
      confirmPasswordController.text,
    );
    dismissLoading();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (responseCode(res.code)) {
      responseMessage = res.data?.message ??
          'Your password has been successfully updated. You can now use your new password to sign in to your staff portal account.';
      isSuccess.value = true;
    } else {
      setState(() {
        _errorMessage = res.message ?? res.data?.message ?? 'Failed to reset password. Please verify the code and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentToken == null || _currentToken!.isEmpty) {
      return _invalidSessionScreen();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // Ambient Decorative Gradients
            Positioned(
              top: -120,
              right: -100,
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      secondaryColor.withValues(alpha: 0.16),
                      secondaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -140,
              left: -120,
              child: Container(
                width: 480,
                height: 480,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: 0.10),
                      primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content Area
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Top Brand Bar
                        _brandBar(),
                        const SizedBox(height: 24),

                        // Card Container
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                offset: const Offset(0, 20),
                                blurRadius: 40,
                              ),
                              BoxShadow(
                                color: secondaryColor.withValues(alpha: 0.06),
                                offset: const Offset(0, 8),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: ValueListenableBuilder<bool?>(
                            valueListenable: isSuccess,
                            builder: (context, snapshot, _) {
                              if (snapshot != null) {
                                return _resultView(snapshot);
                              }
                              return _formView();
                            },
                          ),
                        ),

                        const SizedBox(height: 24),
                        // Security Notice Footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shield_outlined, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text(
                              'Authorized Healthcare Personnel · 256-bit Encrypted Session',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const ClipOval(
                child: Image(
                  image: AssetImage("assets/icons/logo/klinik-aurora.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Klinik Aurora',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Admin Portal · Security',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
        TextButton(
          onPressed: () => context.goNamed(LoginPage.routeName),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFF475569)),
              SizedBox(width: 6),
              Text(
                'Back to Sign In',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _formView() {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F172A),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: secondaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Icon & Badge Row
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: secondaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: secondaryColor.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_user_outlined, size: 13, color: secondaryColor),
                  SizedBox(width: 5),
                  Text(
                    'SECURITY VERIFICATION',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: secondaryColor,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Title & Description
        const Text(
          'Reset your password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter the 6-digit code sent to your email, then choose a strong new password.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.45),
        ),
        const SizedBox(height: 18),

        // Destination Email Banner (if provided)
        if (widget.email != null && widget.email!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 18, color: Color(0xFF15803D)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF166534)),
                      children: [
                        const TextSpan(text: 'Code sent to '),
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => context.goNamed(LoginPage.routeName),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      'Change',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // OTP Label & Resend Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '6-DIGIT VERIFICATION CODE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
                letterSpacing: 0.6,
              ),
            ),
            if (widget.email != null && widget.email!.isNotEmpty)
              _countdown > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.schedule_rounded, size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Resend in ${_countdown}s',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : InkWell(
                      onTap: _resendOtp,
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.refresh_rounded, size: 14, color: secondaryColor),
                            SizedBox(width: 4),
                            Text(
                              'Resend Code',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: secondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
          ],
        ),
        const SizedBox(height: 10),

        // Pinput PIN Boxes
        Center(
          child: Pinput(
            length: 6,
            controller: otpController,
            focusNode: otpFocusNode,
            autofocus: true,
            keyboardType: TextInputType.number,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: submittedPinTheme,
            errorPinTheme: errorPinTheme,
            onCompleted: (_) {
              passwordFocusNode.requestFocus();
            },
          ),
        ),

        const SizedBox(height: 26),

        // New Password Section
        const Text(
          'NEW PASSWORD',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: passwordController,
          focusNode: passwordFocusNode,
          obscureText: _obscurePassword,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Enter at least 8 characters',
            hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 19,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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

        const SizedBox(height: 16),

        // Confirm Password Section
        const Text(
          'CONFIRM NEW PASSWORD',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: confirmPasswordController,
          focusNode: confirmPasswordFocusNode,
          obscureText: _obscureConfirm,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: 'Re-type new password',
            hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8), size: 19),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8),
                size: 19,
              ),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
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

        const SizedBox(height: 16),

        // Live Password Strength Bar
        if (passwordController.text.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Password strength:',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              Text(
                _strengthLabel,
                style: TextStyle(fontSize: 11.5, color: _strengthColor, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(4, (index) {
              final isFilled = index < _strengthScore;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isFilled ? _strengthColor : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
        ],

        // Requirements Checklist Grid
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password Checklist:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _requirementChip('8+ characters', _hasMinLength)),
                  const SizedBox(width: 8),
                  Expanded(child: _requirementChip('1 uppercase (A-Z)', _hasUppercase)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _requirementChip('1 number (0-9)', _hasNumber)),
                  const SizedBox(width: 8),
                  Expanded(child: _requirementChip('Passwords match', _passwordsMatch)),
                ],
              ),
            ],
          ),
        ),

        // Error message banner
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReset,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: secondaryColor,
              shadowColor: secondaryColor.withValues(alpha: 0.4),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [secondaryColor, Color(0xFF3EA6B7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _isSubmitting
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
                          Icon(Icons.lock_open_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Reset Password & Sign In',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Cancel / Back to Login
        Center(
          child: TextButton(
            onPressed: () => context.goNamed(LoginPage.routeName),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 15, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Cancel and Back to Sign In',
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
    );
  }

  Widget _requirementChip(String label, bool isMet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMet ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMet ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 13,
            color: isMet ? const Color(0xFF059669) : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isMet ? FontWeight.w700 : FontWeight.w500,
                color: isMet ? const Color(0xFF047857) : Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultView(bool isSucceeded) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: isSucceeded ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (isSucceeded ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            isSucceeded ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isSucceeded ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 40,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          isSucceeded ? 'Password Reset Successful!' : 'Password Reset Failed',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          responseMessage ??
              (isSucceeded
                  ? 'Your password has been successfully updated. You can now sign in with your new credentials.'
                  : 'We were unable to reset your password. Please verify the 6-digit OTP code and try again.'),
          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (isSucceeded)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => context.goNamed(LoginPage.routeName),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: secondaryColor,
                shadowColor: secondaryColor.withValues(alpha: 0.4),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [secondaryColor, Color(0xFF3EA6B7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue to Sign In',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => isSuccess.value = null,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: secondaryColor,
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
                      child: const Center(
                        child: Text(
                          'Try Again',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => context.goNamed(LoginPage.routeName),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Back to Sign In',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _invalidSessionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 16),
                  blurRadius: 36,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.link_off_rounded, color: Color(0xFFD97706), size: 32),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Invalid or Expired Session',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This password reset link is invalid or has expired. Please initiate a new password recovery request from the sign in page.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.goNamed(LoginPage.routeName),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: secondaryColor,
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
                      child: const Center(
                        child: Text(
                          'Return to Sign In',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
