import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/password_recovery/password_recovery_controller.dart';
import 'package:klinik_aurora_portal/views/error/error.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:pinput/pinput.dart';

class AdminPasswordRecoveryPage extends StatefulWidget {
  static const routeName = '/password-recovery';
  final String? token;
  const AdminPasswordRecoveryPage({super.key, required this.token});

  @override
  State<AdminPasswordRecoveryPage> createState() => _AdminPasswordRecoveryPageState();
}

class _AdminPasswordRecoveryPageState extends State<AdminPasswordRecoveryPage> {
  InputFieldAttribute passwordAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'passwordRecoveryPage'.tr(gender: 'password'),
    obscureText: true,
    isPassword: true,
    maxCharacter: 30,
  );
  InputFieldAttribute retypePasswordAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'passwordRecoveryPage'.tr(gender: 'reEnterPassword'),
    obscureText: true,
    isPassword: true,
    maxCharacter: 30,
  );
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  StreamController<DateTime> rebuild = StreamController.broadcast();
  ValueNotifier<bool?> isSuccess = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.token == null
        ? const ErrorPage()
        : GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            body: Column(
              children: [
                Container(
                  width: screenWidth(100),
                  height: screenHeight(100),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: primaryColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    // image: DecorationImage(
                    //   image: AssetImage("assets/images/bg.png"),
                    //   fit: BoxFit.cover,
                    // ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CardContainer(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            LayoutWidget(mobile: Expanded(child: content()), desktop: Flexible(child: content())),
                          ],
                        ),
                        elevation: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
  }

  Widget content() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding),
      child: ValueListenableBuilder<bool?>(
        valueListenable: isSuccess,
        builder: (context, snapshot, _) {
          if (snapshot != null) {
            return Padding(
              padding: EdgeInsets.all(screenPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    snapshot ? 'assets/icons/success/tick-square.svg' : 'assets/icons/failed/warning.svg',
                    height: screenHeight(13),
                    colorFilter: ColorFilter.mode(
                      snapshot ? const Color(0XFF50D142) : const Color(0XFFDF184A),
                      BlendMode.srcIn,
                    ),
                  ),
                  AppPadding.vertical(),
                  Text(
                    snapshot
                        ? 'You\'ve successfully updated your password. Keep your new password secure to protect your account.'
                        : 'Oops! Something went wrong on our end. Please give it another moment and then retry changing your password.',
                  ),
                  AppPadding.vertical(denominator: 1 / 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Button(() {
                        context.pop();
                      }, actionText: 'Login'),
                    ],
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              LayoutWidget(mobile: auroraImage(), desktop: const SizedBox()),
              AppPadding.vertical(denominator: 1 / 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutWidget(
                    mobile: const SizedBox(),
                    desktop: Row(children: [auroraImage(), AppPadding.horizontal()]),
                  ),
                  LayoutWidget(mobile: Expanded(child: fields()), desktop: Flexible(child: fields())),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget fields() {
    return Column(
      children: [
        Text('Change Password', style: AppTypography.displayLarge(context).apply(fontSizeDelta: 4)),
        AppPadding.vertical(),
        Text(
          'passwordRecoveryPage'.tr(gender: 'forgotPasswordDescription'),
          style: AppTypography.bodyMedium(context).apply(),
          textAlign: TextAlign.center,
        ),
        AppPadding.vertical(denominator: 1 / 2),
        Pinput(
          length: 6,
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textCapitalization: TextCapitalization.characters,
          forceErrorState: true,
          errorTextStyle: Theme.of(context).textTheme.bodyMedium!.apply(color: errorColor),
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          defaultPinTheme: PinTheme(
            width: 60,
            height: 60,
            textStyle: AppTypography.bodyMedium(context).apply(),
            decoration: BoxDecoration(color: textFormFieldEditableColor, borderRadius: BorderRadius.circular(12)),
          ),
          focusedPinTheme: PinTheme(
            width: 60,
            height: 60,
            textStyle: AppTypography.bodyMedium(context).apply(),
            decoration: BoxDecoration(color: const Color(0x5EE8EBF1), borderRadius: BorderRadius.circular(12)),
          ).copyWith(
            decoration: BoxDecoration(
              color: textFormFieldEditableColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 3), blurRadius: 16)],
            ),
          ),
          showCursor: true,
          cursor: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 21,
              height: 1,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFF8992A0), borderRadius: BorderRadius.circular(8)),
            ),
          ),
          // inputFormatters: [_upperCaseTextFormatter],
        ),
        AppPadding.vertical(denominator: 1 / 1.5),
        StreamBuilder<DateTime>(
          stream: rebuild.stream,
          builder: (context, snapshot) {
            return Column(
              children: [
                InputField(
                  field: InputFieldAttribute(
                    controller: passwordAttribute.controller,
                    labelText: passwordAttribute.labelText,
                    errorMessage: passwordAttribute.errorMessage,
                    obscureText: passwordAttribute.obscureText,
                    isPassword: passwordAttribute.isPassword,
                    onChanged: (value) {
                      if (passwordAttribute.errorMessage != null || retypePasswordAttribute.errorMessage != null) {
                        passwordAttribute.errorMessage = null;
                        retypePasswordAttribute.errorMessage = null;
                        rebuild.add(DateTime.now());
                      }
                    },
                  ),
                  width: screenHeightByBreakpoint(80, 50, 24),
                ),
                AppPadding.vertical(),
                InputField(
                  field: InputFieldAttribute(
                    controller: retypePasswordAttribute.controller,
                    labelText: retypePasswordAttribute.labelText,
                    errorMessage: retypePasswordAttribute.errorMessage,
                    obscureText: retypePasswordAttribute.obscureText,
                    isPassword: retypePasswordAttribute.isPassword,
                    onChanged: (value) {
                      if (passwordAttribute.errorMessage != null || retypePasswordAttribute.errorMessage != null) {
                        passwordAttribute.errorMessage = null;
                        retypePasswordAttribute.errorMessage = null;
                        rebuild.add(DateTime.now());
                      }
                    },
                  ),
                  width: screenHeightByBreakpoint(80, 50, 24),
                ),
              ],
            );
          },
        ),
        AppPadding.vertical(denominator: 1 / 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Button(
              () async {
                FocusScope.of(context).unfocus();
                validateField().then((value) {
                  if (value == true) {
                    showLoading();
                    PasswordRecoveryController.changePassword(
                      context,
                      widget.token ?? '',
                      controller.text,
                      passwordAttribute.controller.text,
                      retypePasswordAttribute.controller.text,
                    ).then((value) {
                      dismissLoading();
                      if (responseCode(value.code)) {
                        isSuccess.value = true;
                      } else {
                        isSuccess.value = false;
                      }
                    });
                  }
                });
              },
              color: secondaryColor,
              actionText: 'button'.tr(gender: 'resetPassword'),
            ),
          ],
        ),
        AppPadding.vertical(),
      ],
    );
  }

  Widget auroraImage() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(opacityCalculation(.5)),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
      ),
      child: const ClipOval(
        child: Image(
          image: AssetImage("assets/icons/logo/klinik-aurora.png"),
          // color: primary,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Future<bool> validateField() async {
    bool temp = true;
    if (passwordAttribute.controller.text == '') {
      temp = false;
      passwordAttribute.errorMessage = ErrorMessage.required(field: passwordAttribute.labelText);
    }
    if (retypePasswordAttribute.controller.text == '') {
      temp = false;
      retypePasswordAttribute.errorMessage = ErrorMessage.required(field: retypePasswordAttribute.labelText);
    }
    if (passwordAttribute.controller.text != '' && retypePasswordAttribute.controller.text != '') {
      if (passwordAttribute.controller.text != retypePasswordAttribute.controller.text) {
        temp = false;
        retypePasswordAttribute.errorMessage = 'passwordRecoveryPage'.tr(gender: 'passwordNotMatch');
      }
    }
    return temp;
  }
}
