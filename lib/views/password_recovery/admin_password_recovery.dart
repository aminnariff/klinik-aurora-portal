import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/password_recovery/password_recovery_controller.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
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
  final FocusNode passwordFocusNode = FocusNode();
  final FocusNode retypePasswordFocusNode = FocusNode();

  late InputFieldAttribute passwordAttribute;
  late InputFieldAttribute retypePasswordAttribute;

  final StreamController<DateTime> rebuild = StreamController.broadcast();
  final ValueNotifier<bool?> isSuccess = ValueNotifier(null);
  String? responseMessage;

  // Resend OTP countdown
  int _countdown = 60;
  Timer? _timer;
  bool _isResending = false;

  // Live password validation
  bool get _hasMinLength => passwordAttribute.controller.text.length >= 8;
  bool get _hasUppercase => RegExp(r'[A-Z]').hasMatch(passwordAttribute.controller.text);
  bool get _hasNumber => RegExp(r'[0-9]').hasMatch(passwordAttribute.controller.text);
  bool get _passwordsMatch =>
      passwordAttribute.controller.text.isNotEmpty &&
      passwordAttribute.controller.text == retypePasswordAttribute.controller.text;

  @override
  void initState() {
    super.initState();
    _currentToken = widget.token;
    _startTimer();

    passwordAttribute = InputFieldAttribute(
      controller: TextEditingController(),
      hintText: 'Enter new password',
      labelText: 'New Password',
      obscureText: true,
      isPassword: true,
      focusNode: passwordFocusNode,
      maxCharacter: 40,
      onChanged: (_) => rebuild.add(DateTime.now()),
    );

    retypePasswordAttribute = InputFieldAttribute(
      controller: TextEditingController(),
      hintText: 'Re-enter new password',
      labelText: 'Confirm Password',
      obscureText: true,
      isPassword: true,
      focusNode: retypePasswordFocusNode,
      maxCharacter: 40,
      onChanged: (_) => rebuild.add(DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    otpController.dispose();
    otpFocusNode.dispose();
    passwordFocusNode.dispose();
    retypePasswordFocusNode.dispose();
    passwordAttribute.controller.dispose();
    retypePasswordAttribute.controller.dispose();
    rebuild.close();
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
      showDialogError(
        context,
        'Cannot resend OTP because email address is missing. Please restart the forgot password process from sign in.',
      );
      return;
    }

    setState(() {
      _isResending = true;
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
          content: Text('A fresh 6-digit verification code has been sent to your email.'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      showDialogError(context, res.message ?? res.data?.message ?? 'Failed to resend code');
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
        backgroundColor: const Color(0xFFF3F4F6),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      offset: Offset(0, 10),
                      blurRadius: 30,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _invalidSessionScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                offset: Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_off_rounded, color: Color(0xFFD97706), size: 30),
              ),
              const SizedBox(height: 20),
              const Text(
                'Invalid or Expired Session',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'This password reset link is invalid or has expired. Please initiate a new password recovery request from the sign in page.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Button(
                  () => context.goNamed(LoginPage.routeName),
                  color: secondaryColor,
                  actionText: 'Return to Sign In',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultView(bool isSucceeded) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: isSucceeded ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isSucceeded ? Icons.check_circle_rounded : Icons.error_outline_rounded,
            color: isSucceeded ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            size: 38,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isSucceeded ? 'Password Reset Successful' : 'Password Reset Failed',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          responseMessage ??
              (isSucceeded
                  ? 'Your password has been successfully updated. You can now use your new password to sign in to your staff portal account.'
                  : 'We were unable to reset your password. Please verify the 6-digit OTP code and ensure all requirements are satisfied.'),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.45),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        if (isSucceeded)
          SizedBox(
            width: double.infinity,
            child: Button(
              () => context.goNamed(LoginPage.routeName),
              color: secondaryColor,
              actionText: 'Continue to Sign In',
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: Button(
                  () {
                    isSuccess.value = null;
                  },
                  color: secondaryColor,
                  actionText: 'Try Again',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Button(
                  () => context.goNamed(LoginPage.routeName),
                  color: Colors.grey.shade600,
                  actionText: 'Back to Sign In',
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _formView() {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 54,
      textStyle: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: secondaryColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
    );

    final errorPinTheme = defaultPinTheme.copyWith(
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand & Portal Header
        Row(
          children: [
            Image.asset(
              'assets/icons/logo/klinik-aurora.png',
              height: 38,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: secondaryColor.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Admin Portal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: secondaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Reset Your Password',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Verify your identity using the 6-digit code sent to your email, then choose a strong new password.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
        ),
        const SizedBox(height: 16),

        // Destination Email Banner (if provided)
        if (widget.email != null && widget.email!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, size: 18, color: Color(0xFF15803D)),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
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
              ],
            ),
          ),

        const SizedBox(height: 22),

        // OTP Label
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '6-Digit Verification Code',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            if (widget.email != null && widget.email!.isNotEmpty)
              _countdown > 0
                  ? Text(
                      'Resend in ${_countdown}s',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500,
                      ),
                    )
                  : InkWell(
                      onTap: _resendOtp,
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: secondaryColor,
                        ),
                      ),
                    ),
          ],
        ),
        const SizedBox(height: 10),

        // Pinput Input
        Center(
          child: Pinput(
            length: 6,
            controller: otpController,
            focusNode: otpFocusNode,
            keyboardType: TextInputType.number,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            errorPinTheme: errorPinTheme,
            onCompleted: (_) {
              passwordFocusNode.requestFocus();
            },
          ),
        ),

        const SizedBox(height: 22),

        // New Password Field
        StreamBuilder<DateTime>(
          stream: rebuild.stream,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 7),
                InputField(
                  field: InputFieldAttribute(
                    controller: passwordAttribute.controller,
                    hintText: 'Enter new password',
                    labelText: 'New Password',
                    obscureText: passwordAttribute.obscureText,
                    isPassword: true,
                    focusNode: passwordFocusNode,
                    errorMessage: passwordAttribute.errorMessage,
                    isEditableColor: const Color(0xFFF9FAFB),
                    onChanged: (_) {
                      if (passwordAttribute.errorMessage != null) {
                        passwordAttribute.errorMessage = null;
                      }
                      rebuild.add(DateTime.now());
                    },
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                const Text(
                  'Confirm New Password',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 7),
                InputField(
                  field: InputFieldAttribute(
                    controller: retypePasswordAttribute.controller,
                    hintText: 'Re-enter new password',
                    labelText: 'Confirm Password',
                    obscureText: retypePasswordAttribute.obscureText,
                    isPassword: true,
                    focusNode: retypePasswordFocusNode,
                    errorMessage: retypePasswordAttribute.errorMessage,
                    isEditableColor: const Color(0xFFF9FAFB),
                    onChanged: (_) {
                      if (retypePasswordAttribute.errorMessage != null) {
                        retypePasswordAttribute.errorMessage = null;
                      }
                      rebuild.add(DateTime.now());
                    },
                    prefixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 12),
                        Icon(Icons.lock_outline_rounded, color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  width: double.infinity,
                ),
                const SizedBox(height: 16),

                // Live Password Requirements Checklist
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password Requirements:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _requirementItem('At least 8 characters', _hasMinLength),
                      _requirementItem('Contains at least one uppercase letter (A-Z)', _hasUppercase),
                      _requirementItem('Contains at least one number (0-9)', _hasNumber),
                      _requirementItem('Passwords match', _passwordsMatch),
                    ],
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          child: Button(
            () async {
              FocusScope.of(context).unfocus();
              final isValid = await _validateFields();
              if (!isValid) return;

              showLoading();
              final res = await PasswordRecoveryController.changePassword(
                context,
                _currentToken ?? '',
                otpController.text.trim(),
                passwordAttribute.controller.text,
                retypePasswordAttribute.controller.text,
              );
              dismissLoading();

              if (responseCode(res.code)) {
                responseMessage = res.data?.message ??
                    'You have successfully updated your password. Keep your new password secure to protect your account.';
                isSuccess.value = true;
              } else {
                responseMessage = res.message ??
                    'Failed to reset password. Please check your 6-digit OTP code and try again.';
                isSuccess.value = false;
              }
            },
            color: secondaryColor,
            actionText: 'Reset Password',
          ),
        ),

        const SizedBox(height: 14),

        // Cancel / Back to Login
        Center(
          child: TextButton(
            onPressed: () => context.goNamed(LoginPage.routeName),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_rounded, size: 16, color: Colors.grey.shade600),
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

  Widget _requirementItem(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: isMet ? const Color(0xFF10B981) : Colors.grey.shade400,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet ? const Color(0xFF047857) : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _validateFields() async {
    bool valid = true;

    if (otpController.text.trim().length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit verification code.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    if (passwordAttribute.controller.text.isEmpty) {
      valid = false;
      passwordAttribute.errorMessage = 'Please enter a new password';
    } else if (passwordAttribute.controller.text.length < 8) {
      valid = false;
      passwordAttribute.errorMessage = 'Password must be at least 8 characters';
    }

    if (retypePasswordAttribute.controller.text.isEmpty) {
      valid = false;
      retypePasswordAttribute.errorMessage = 'Please confirm your new password';
    } else if (passwordAttribute.controller.text != retypePasswordAttribute.controller.text) {
      valid = false;
      retypePasswordAttribute.errorMessage = 'Passwords do not match';
    }

    rebuild.add(DateTime.now());
    return valid;
  }
}
