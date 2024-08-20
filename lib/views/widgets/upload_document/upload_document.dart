import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class UploadDocumentsField extends StatelessWidget {
  final Function() action;
  final String fieldTitle;
  final String? tooltipText;
  final String title;
  final String? description;
  final bool cancelIcon;
  final double? width;
  final Function() cancelAction;

  const UploadDocumentsField({
    super.key,
    required this.title,
    this.width,
    this.tooltipText,
    this.description,
    required this.action,
    this.cancelIcon = false,
    required this.cancelAction,
    required this.fieldTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: isMobile ? const EdgeInsets.all(2) : EdgeInsets.zero,
      width: width,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fieldTitle != '')
                  Row(
                    children: [
                      Expanded(
                        child: AppSelectableText(
                          fieldTitle,
                        ),
                      ),
                      if (tooltipText != null) ...[
                        AppPadding.horizontal(denominator: 2),
                        Tooltip(
                          message: tooltipText,
                        )
                      ],
                    ],
                  ),
                AppPadding.vertical(denominator: 2),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    DottedBorder(
                      radius: const Radius.circular(12),
                      strokeWidth: 0.5,
                      borderType: BorderType.RRect,
                      dashPattern: const [3, 4],
                      child: InkWell(
                        onTap: action,
                        radius: 15,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 0 : 8),
                          child: Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                AppPadding.horizontal(denominator: 2),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 0),
                                  child: Image(
                                    image: const AssetImage('images/button/upload.png'),
                                    color: CupertinoColors.activeBlue,
                                    height: isMobile ? 35 : 40,
                                  ),
                                ),
                                AppPadding.horizontal(),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (!cancelIcon && description != null)
                                        Text(
                                          description.toString(),
                                        ),
                                    ],
                                  ),
                                ),
                                AppPadding.horizontal(denominator: 1 / 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (cancelIcon)
                      GestureDetector(
                        onTap: cancelAction,
                        child: Padding(
                          padding: EdgeInsets.only(right: screenPadding / 2),
                          child: const Icon(
                            Icons.close,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class UploadDocumentAttribute {
  final Function() action;
  final String fieldTitle;
  final String title;
  final String description;
  final bool cancelIcon;
  final Function() cancelAction;
  final ValueNotifier<String> value;

  UploadDocumentAttribute({
    required this.title,
    required this.description,
    required this.action,
    this.cancelIcon = false,
    required this.cancelAction,
    required this.fieldTitle,
    required this.value,
  });
}

class UploadDocumentItemAttribute {
  final List<String> fileNameList;
  final List<String> docPathList;

  UploadDocumentItemAttribute({
    required this.fileNameList,
    required this.docPathList,
  });
}
