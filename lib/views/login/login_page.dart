import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/password_recovery/password_recovery_controller.dart';
import 'package:klinik_aurora_portal/models/auth/auth_request.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/password_recovery/admin_password_recovery.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
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

class _LoginPageState extends State<LoginPage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  ValueNotifier<bool> isObscure = ValueNotifier<bool>(false);
  bool loginSuccess = false;
  InputFieldAttribute emailAttribute = InputFieldAttribute(
    controller: TextEditingController(text: ''),
    hintText: 'information'.tr(gender: 'email'),
    isEmail: true,
  );

  @override
  void initState() {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      context.read<AuthController>().init(context).then((controller) {
        if (controller?.data != null &&
            DateTime.parse(controller?.data?.expiryDt ?? '').difference(DateTime.now()).isNegative) {
          prefs.remove(authResponse);
          prefs.remove(jwtResponse);
          prefs.remove(token);
        }
      });
      context.read<AuthController>().checkDateTime().then((value) {
        String tokenStatus = value;
        if (tokenStatus == 'expired') {
          context.read<AuthController>().logout(context);
        }
        List<String>? rememberMeCredentials = context.read<AuthController>().getRememberMeCredentials();
        bool remember = prefs.getBool(rememberMe) ?? false;
        if (rememberMeCredentials != null && remember) {
          usernameController.text = rememberMeCredentials[0];
          passwordController.text = rememberMeCredentials[1];
        }
      });
    });
    if (kDebugMode) {
      usernameController.text = 'superadmin';
      if (environment == Flavor.production) {
        usernameController.text = 'auroramedicare@gmail.com';
      } else {
        usernameController.text = 'bukit-rimau@yopmail.com';
      }
      usernameController.text = 'auroramedicare@gmail.com';
      // bndrsridamansara@gmail.com
      // Auror@123
      // usernameController.text = 'amin.ariff@klinikauroramembership.com';
      passwordController.text = 'Admin12345!';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return view();
  }

  Widget view() {
    return Consumer<AuthController>(
      builder: (context, controller, _) {
        if (controller.authenticationResponse != null &&
            DateTime.parse(
                  controller.authenticationResponse?.data?.expiryDt ?? '',
                ).difference(DateTime.now()).isNegative ==
                false &&
            (widget.resetUser != true || loginSuccess == true)) {
          Future.delayed(const Duration(milliseconds: 500), () {
            context.replaceNamed(Homepage.routeName);
          });
          return loadingScreen();
        } else {
          return LayoutWidget(mobile: authPage(), desktop: authPage());
        }
      },
    );
  }

  Widget authPage() {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: screenWidth(100),
            height: screenHeight(100),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: primaryColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
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
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding),
                        child: Column(
                          children: [
                            AppPadding.vertical(denominator: 1 / 2),
                            Container(
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
                            ),
                            // SizedBox(
                            //   child: Image(
                            //     image: const AssetImage("assets/icons/logo/klinik-aurora.png"),
                            //     // color: primary,
                            //     height: screenHeightByBreakpoint(70, 35, 20),
                            //   ),
                            // ),
                            // AppSelectableText(
                            //   'GATEWAY',
                            //   style: GoogleFonts.hindMadurai(
                            //     fontSize: 30,
                            //     fontWeight: FontWeight.w800,
                            //     letterSpacing: 15,
                            //     color: primary,
                            //   ),
                            // ),
                            AppPadding.vertical(denominator: 1 / 3),
                            Consumer<AuthController>(
                              builder: (context, snapshot, _) {
                                return Column(
                                  children: [
                                    InputField(
                                      field: InputFieldAttribute(
                                        attribute: 'email',
                                        controller: usernameController,
                                        hintText: 'loginPage'.tr(gender: 'username'),
                                        isEmail: true,
                                        isEditableColor: const Color(0xFFEAF2FA),
                                        errorMessage: snapshot.usernameError,
                                        prefixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            const SizedBox(width: 12),
                                            const FaIcon(Icons.person, color: primary),
                                            AppPadding.horizontal(denominator: 2),
                                          ],
                                        ),
                                      ),
                                      width: screenHeightByBreakpoint(80, 50, 450, useAbsoluteValueDesktop: true),
                                    ),
                                    AppPadding.vertical(),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        InputField(
                                          field: InputFieldAttribute(
                                            attribute: 'password',
                                            controller: passwordController,
                                            hintText: 'loginPage'.tr(gender: 'password'),
                                            obscureText: true,
                                            isPassword: true,
                                            isEditableColor: const Color(0xFFEAF2FA),
                                            errorMessage: snapshot.passwordError,
                                            prefixIcon: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              children: [
                                                const SizedBox(width: 12),
                                                const FaIcon(Icons.lock, color: primary),
                                                AppPadding.horizontal(denominator: 2),
                                              ],
                                            ),
                                            obsecureAction: () {
                                              isObscure.value = !isObscure.value;
                                              return null;
                                            },
                                          ),
                                          width: screenHeightByBreakpoint(80, 50, 450, useAbsoluteValueDesktop: true),
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                forgotPassword();
                                                // context.pushNamed(AdminPasswordRecoveryPage.routeName, extra: '');
                                              },
                                              child: Text(
                                                'loginPage'.tr(gender: 'forgotPassword'),
                                                style: AppTypography.bodyMedium(
                                                  context,
                                                ).apply(fontWeightDelta: 1, color: Colors.grey),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                            Consumer<AuthController>(
                              builder: (context, snapshot, _) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Checkbox(
                                      value: snapshot.remember,
                                      onChanged: (value) {
                                        snapshot.remember = value ?? false;
                                      },
                                      activeColor: CupertinoColors.activeBlue,
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        snapshot.remember = !snapshot.remember;
                                      },
                                      child: Text('loginPage'.tr(gender: 'rememberMe')),
                                    ),
                                  ],
                                );
                              },
                            ),
                            AppPadding.vertical(denominator: 1 / 2),
                            Button(
                              () async {
                                validateField().then((value) {
                                  if (value == true) {
                                    showLoading();
                                    AuthController.logIn(
                                      context,
                                      AuthRequest(username: usernameController.text, password: passwordController.text),
                                    ).then((value) {
                                      dismissLoading();
                                      if (responseCode(value.code)) {
                                        loginSuccess = true;
                                        if (prefs.getBool(rememberMe) == true) {
                                          prefs.setBool(rememberMe, true);
                                          prefs.setString(username, usernameController.text);
                                          prefs.setString(password, passwordController.text);
                                        }
                                        SchedulerBinding.instance.addPostFrameCallback((_) {
                                          context.read<AuthController>().setAuthenticationResponse(
                                            value.data,
                                            usernameValue: usernameController.text,
                                            passwordValue: passwordController.text,
                                          );
                                        });
                                      }
                                    });
                                  }
                                });
                              },
                              color: secondaryColor,
                              actionText: 'button'.tr(gender: 'login'),
                            ),
                            AppPadding.vertical(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  elevation: 10,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> validateField() async {
    bool temp = true;
    if (usernameController.text == '') {
      context.read<AuthController>().usernameError = ErrorMessage.required(field: 'loginPage'.tr(gender: 'username'));
      temp = false;
    }
    if (passwordController.text == '') {
      context.read<AuthController>().passwordError = ErrorMessage.required(field: 'loginPage'.tr(gender: 'password'));
      temp = false;
    }
    return temp;
  }

  forgotPassword() {
    StreamController<DateTime> rebuild = StreamController.broadcast();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<DateTime>(
          stream: rebuild.stream,
          builder: (context, snapshot) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                        },
                        child: CardContainer(
                          Padding(
                            padding: EdgeInsets.all(screenPadding),
                            child: Column(
                              children: [
                                Text(
                                  'loginPage'.tr(gender: 'forgotPassword'),
                                  style: AppTypography.displayMedium(context),
                                ),
                                AppPadding.vertical(),
                                Text(
                                  'loginPage'.tr(gender: 'enterEmailAddress'),
                                  style: AppTypography.bodyMedium(context),
                                ),
                                AppPadding.vertical(),
                                SizedBox(
                                  width: screenWidth1728(20),
                                  child: InputField(field: emailAttribute),
                                ),
                                AppPadding.vertical(),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Button(() {
                                        if (emailAttribute.controller.text == '') {
                                          emailAttribute.errorMessage = ErrorMessage.required(
                                            field: emailAttribute.hintText,
                                          );
                                          rebuild.add(DateTime.now());
                                        } else if (!RegExp(
                                          r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$",
                                        ).hasMatch(emailAttribute.controller.text)) {
                                          emailAttribute.errorMessage = 'Invalid ${emailAttribute.hintText}';
                                          rebuild.add(DateTime.now());
                                        } else {
                                          showLoading();
                                          PasswordRecoveryController.forgotPassword(
                                            context,
                                            emailAttribute.controller.text,
                                          ).then((value) {
                                            if (responseCode(value.code)) {
                                              dismissLoading();
                                              context.pop();
                                              context.pushNamed(
                                                AdminPasswordRecoveryPage.routeName,
                                                extra: value.data?.data?.token ?? '',
                                              );
                                            } else {
                                              showDialogError(context, value.message ?? value.data?.message ?? '');
                                            }
                                          });
                                        }
                                      }),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget loadingScreen() {
    return Center(child: SizedBox(width: 140, child: Lottie.asset('assets/lottie/simple-loading.json', width: 140)));
  }
}
