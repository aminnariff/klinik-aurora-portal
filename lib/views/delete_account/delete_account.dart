import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class DeleteAccountPage extends StatefulWidget {
  static const routeName = '/account-deletion';
  final String? token;
  const DeleteAccountPage({super.key, this.token});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  InputFieldAttribute emailAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'deleteAccountPage'.tr(gender: 'email'),
    isEmail: true,
  );
  StreamController<DateTime> rebuild = StreamController.broadcast();
  ValueNotifier<bool?> isSuccess = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    // if (widget.token != null) {
    //   prefs.setString(token, widget.token!);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
                        LayoutWidget(
                          mobile: Expanded(
                            child: content(),
                          ),
                          desktop: Flexible(
                            child: content(),
                          ),
                        ),
                      ],
                    ),
                    elevation: 10,
                  )
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
                          snapshot ? const Color(0XFF50D142) : const Color(0XFFDF184A), BlendMode.srcIn),
                    ),
                    AppPadding.vertical(),
                    Text(snapshot
                        ? 'Account deletion request sent for ${emailAttribute.controller.text}'
                        : 'Oops! Something went wrong on our end. Please give it another moment and then retry requesting account deletion.'),
                  ],
                ),
              );
            }
            return Column(
              children: [
                LayoutWidget(
                  mobile: auroraImage(),
                  desktop: const SizedBox(),
                ),
                AppPadding.vertical(denominator: 1 / 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutWidget(
                      mobile: const SizedBox(),
                      desktop: Row(
                        children: [
                          auroraImage(),
                          AppPadding.horizontal(),
                        ],
                      ),
                    ),
                    LayoutWidget(
                      mobile: Expanded(
                        child: fields(),
                      ),
                      desktop: Flexible(
                        child: fields(),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
    );
  }

  Widget fields() {
    return Column(
      children: [
        Text(
          'deleteAccountPage'.tr(gender: 'title'),
          style: AppTypography.displayLarge(context).apply(fontSizeDelta: 4),
        ),
        AppPadding.vertical(),
        SizedBox(
          width: screenWidth(31),
          child: Text(
            'deleteAccountPage'.tr(gender: 'description'),
            style: AppTypography.bodyMedium(context).apply(),
            textAlign: TextAlign.center,
          ),
        ),
        AppPadding.vertical(denominator: 1 / 2),
        StreamBuilder<DateTime>(
            stream: rebuild.stream,
            builder: (context, snapshot) {
              return Column(
                children: [
                  InputField(
                    field: emailAttribute,
                    width: screenHeightByBreakpoint(80, 50, 24),
                  ),
                ],
              );
            }),
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
                    // PasswordRecoveryController.changePassword(context, passwordAttribute.controller.text).then((value) {
                    //   dismissLoading();
                    //   if (responseCode(value.code)) {
                    //     isSuccess.value = true;
                    //   } else {
                    //     isSuccess.value = false;
                    //   }
                    // });
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
            color: Colors.grey.withOpacity(0.5),
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
    if (emailAttribute.controller.text == '') {
      temp = false;
      emailAttribute.errorMessage = ErrorMessage.required(field: emailAttribute.labelText);
    }
    return temp;
  }
}
