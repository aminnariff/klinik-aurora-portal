import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_button_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_type.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppDialog extends StatelessWidget {
  final DialogAttribute attribute;

  const AppDialog(
    this.attribute, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Dialog(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.0), boxShadow: [
                BoxShadow(
                  offset: const Offset(12, 26),
                  blurRadius: 30,
                  spreadRadius: 0,
                  color: Colors.grey.withOpacity(.1),
                ),
              ]),
              width: attribute.width,
              height: attribute.height,
              padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ElasticIn(
                      child: attribute.logo ??
                          Container(
                            constraints: BoxConstraints(maxHeight: screenHeight(20)),
                            padding: EdgeInsets.symmetric(vertical: screenPadding / 2),
                            child: SvgPicture.asset(
                              getImage(),
                              height: screenHeight(13),
                              colorFilter: ColorFilter.mode(getImageColor(), BlendMode.srcIn),
                            ),
                          ),
                    ),
                  ),
                  if (attribute.title != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: AppSelectableText(
                            attribute.title.toString(),
                            style: Theme.of(context).textTheme.bodyLarge?.apply(fontSizeDelta: 4),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    AppPadding.vertical(),
                  ],
                  if (attribute.text != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            attribute.text.toString(),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (attribute.textWidget != null) ...[
                    attribute.textWidget!,
                  ],
                  AppPadding.vertical(denominator: 1 / 1.5),
                  if (attribute.buttonAttributes != null)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (int index = 0; index < attribute.buttonAttributes!.length; index++) ...[
                            isMobile || attribute.buttonAttributes!.length > 1
                                ? Flexible(
                                    child: button(attribute.buttonAttributes![index]),
                                  )
                                : button(attribute.buttonAttributes![index]),
                            if (index % 2 == 0 && attribute.buttonAttributes!.length > 1) AppPadding.horizontal(),
                          ],
                        ],
                      ),
                    ),
                  if (attribute.cancelButton != null) ...[
                    AppPadding.vertical(denominator: 2),
                    TextButton(
                      onPressed: attribute.cancelButton!.action!,
                      child: Text(
                        attribute.cancelButton?.text ?? 'cancel'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.apply(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                  AppPadding.vertical(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget button(DialogButtonAttribute item) {
    return Button(
      item.action!,
      actionText: item.text ?? 'okay'.tr(),
      color: item.color,
      textColor: item.textColor,
      borderRadius: 8,
      containerVerticalPadding: 5,
      padding: breakpoint() == Breakpoint.mobile
          ? EdgeInsets.symmetric(horizontal: screenPadding / 1.2, vertical: 15)
          : EdgeInsets.symmetric(horizontal: screenPadding, vertical: 25),
      isFlexible: item.text?.contains(' ') ?? false,
    );
  }

  String getImage() {
    switch (attribute.type) {
      case DialogType.success:
        return 'assets/icons/success/tick-square.svg';
      case DialogType.error:
        return 'assets/icons/failed/warning.svg';
      case DialogType.info:
        return 'assets/icons/failed/warning.svg';
      default:
        return 'assets/icons/failed/warning.svg';
    }
  }

  Color getImageColor() {
    switch (attribute.type) {
      case DialogType.success:
        return const Color(0XFF50D142);
      case DialogType.error:
        return const Color(0XFFDF184A);
      case DialogType.info:
        return secondaryColor;
      default:
        return const Color(0XFFDF184A);
    }
  }
}
