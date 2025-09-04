// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/confirmation_dialog_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_button_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/dialog_type.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class ConfirmationDialog extends StatelessWidget {
  final ConfirmationDialogAttribute attribute;

  const ConfirmationDialog(this.attribute, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Dialog(
            elevation: 10,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(12, 26),
                    blurRadius: 30,
                    spreadRadius: 0,
                    color: Colors.grey.withAlpha(opacityCalculation(.1)),
                  ),
                ],
              ),
              width: attribute.width,
              height: attribute.height,
              padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ElasticIn(
                      child:
                          attribute.logo ??
                          Container(
                            constraints: BoxConstraints(maxHeight: screenHeight(20)),
                            child: Image(image: AssetImage(getImage())),
                          ),
                    ),
                  ),
                  if (attribute.title != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
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
                    AppPadding.vertical(),
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
                  AppPadding.vertical(denominator: 1 / 1.5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      isMobile ? Flexible(child: confirm(context)) : cancel(context),
                      AppPadding.horizontal(),
                      isMobile ? Flexible(child: cancel(context)) : confirm(context),
                    ],
                  ),
                  AppPadding.vertical(denominator: 2),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget confirm(BuildContext context) {
    return button(
      DialogButtonAttribute(
        attribute.confrimButton?.action ??
            () {
              Navigator.pop(context, true);
            },
        text: attribute.confrimButton?.text ?? 'Confirm',
        color: attribute.confrimButton?.color,
        textColor: attribute.confrimButton?.textColor ?? Colors.white,
      ),
    );
  }

  Widget cancel(BuildContext context) {
    return button(
      DialogButtonAttribute(
        attribute.cancelButton?.action ??
            () {
              Navigator.pop(context, true);
            },
        color: Colors.grey.shade300,
        text: attribute.cancelButton?.text ?? 'Cancel',
        textColor: attribute.cancelButton?.textColor ?? Colors.white,
      ),
    );
  }

  Widget button(DialogButtonAttribute item) {
    return Button(
      item.action!,
      actionText: item.text ?? 'okay'.tr(),
      color: item.color,
      textColor: item.textColor,
      borderRadius: 8,
      isFlexible: item.text?.contains(' ') ?? false,
    );
  }

  String getImage() {
    switch (attribute.type) {
      case DialogType.success:
        return 'assets/images/status/success.pngg';
      case DialogType.error:
        return 'assets/images/status/warning.png';
      default:
        return 'assets/images/status/warning.png';
    }
  }
}
