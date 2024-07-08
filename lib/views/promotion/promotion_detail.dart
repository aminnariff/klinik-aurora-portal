import 'dart:async';
import 'dart:typed_data';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/promotion/promotion_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/promotion/promotion_all_response.dart';
import 'package:klinik_aurora_portal/models/promotion/update_promotion_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/checkbox/checkbox.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
import 'package:provider/provider.dart';

class PromotionDetail extends StatefulWidget {
  final Data promotion;
  const PromotionDetail({super.key, required this.promotion});

  @override
  State<PromotionDetail> createState() => _PromotionDetailState();
}

class _PromotionDetailState extends State<PromotionDetail> {
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);
  final TextEditingController _promotionName = TextEditingController();
  final TextEditingController _promotionDescription = TextEditingController();
  final TextEditingController _promotionTnc = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();
  final ValueNotifier<bool> _showOnStart = ValueNotifier(false);
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  List<FileAttribute> selectedFiles = [];

  @override
  void initState() {
    _promotionName.text = widget.promotion.promotionName ?? '';
    _promotionDescription.text = widget.promotion.promotionDescription ?? '';
    _promotionTnc.text = widget.promotion.promotionTnc ?? '';
    _startDate.text = dateConverter(widget.promotion.promotionStartDate, format: 'dd-MM-yyyy') ?? '';
    _endDate.text = dateConverter(widget.promotion.promotionEndDate, format: 'dd-MM-yyyy') ?? '';
    _promotionName.text = widget.promotion.promotionName ?? '';
    _showOnStart.value = widget.promotion.showOnStart == 1;
    for (String item in widget.promotion.promotionImage ?? []) {
      selectedFiles.add(
        FileAttribute(
          path: item,
          name: item,
        ),
      );
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return editPromotion();
  }

  editPromotion() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CardContainer(
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AppSelectableText(
                              'Promotion',
                              style: AppTypography.bodyLarge(context),
                            ),
                            CloseButton(
                              onPressed: () {
                                context.pop();
                              },
                            )
                          ],
                        ),
                        AppPadding.vertical(denominator: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: screenWidth1728(26),
                              child: Column(
                                children: [
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _promotionName,
                                      labelText: 'Name',
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  TextField(
                                    maxLines: null,
                                    style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                    controller: _promotionDescription,
                                    decoration: appInputDecoration(context, 'Description'),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  TextField(
                                    maxLines: null,
                                    style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                    controller: _promotionTnc,
                                    decoration: appInputDecoration(context, "Terms and Conditions"),
                                  ),
                                ],
                              ),
                            ),
                            AppPadding.horizontal(),
                            SizedBox(
                              width: screenWidth1728(30),
                              child: StreamBuilder<DateTime>(
                                stream: fileRebuild.stream,
                                builder: (context, snapshot) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      if (selectedFiles.length < 3) ...[
                                        UploadDocumentsField(
                                          title: 'promotionPage'.tr(gender: 'browseFile'),
                                          fieldTitle: 'promotionPage'.tr(gender: 'promotionImage'),
                                          // tooltipText: 'promotionPage'.tr(gender: 'browse'),
                                          action: () async {
                                            documentErrorMessage.add(null);
                                            FilePickerResult? result = await FilePicker.platform.pickFiles();

                                            if (result != null) {
                                              PlatformFile file = result.files.first;
                                              if (supportedExtensions.contains(file.extension)) {
                                                debugPrint(bytesToMB(file.size).toString());
                                                debugPrint(file.name);
                                                if (bytesToMB(file.size) < 5.0) {
                                                  Uint8List? fileBytes = result.files.first.bytes;
                                                  String fileName = result.files.first.name;

                                                  selectedFiles.add(FileAttribute(name: fileName, value: fileBytes));
                                                  fileRebuild.add(DateTime.now());
                                                } else {
                                                  documentErrorMessage.add('error'
                                                      .tr(gender: 'err-21', args: [fileSizeLimit.toStringAsFixed(0)]));
                                                }
                                              } else {
                                                documentErrorMessage.add('error'.tr(gender: 'err-22'));
                                              }
                                            } else {
                                              // User canceled the picker
                                            }
                                          },
                                          cancelAction: () {},
                                        ),
                                      ],
                                      for (int index = 0; index < selectedFiles.length; index++)
                                        ListTile(
                                          title: GestureDetector(
                                            onTap: () {
                                              if (selectedFiles[index].path != null ||
                                                  selectedFiles[index].value != null) {
                                                showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return GestureDetector(
                                                        onTap: () {
                                                          context.pop();
                                                        },
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Flexible(
                                                              child: CardContainer(
                                                                selectedFiles[index].value != null
                                                                    ? Image.memory(selectedFiles[index].value!)
                                                                    : selectedFiles[index].path != null
                                                                        ? Padding(
                                                                            padding: EdgeInsets.all(screenPadding),
                                                                            child: Image.network(
                                                                                '${Environment.imageUrl}${selectedFiles[index].path}'),
                                                                          )
                                                                        : const SizedBox(),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    });
                                              }
                                            },
                                            child: Row(
                                              children: [
                                                Text(
                                                  '${index + 1}. ',
                                                  style: AppTypography.bodyMedium(context),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    '  ${selectedFiles[index].name ?? ''}',
                                                    style: AppTypography.bodyMedium(context).apply(color: Colors.blue),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          enableFeedback: true,
                                          enabled: true,
                                          trailing: IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                            ),
                                            tooltip: 'button'.tr(gender: 'remove'),
                                            onPressed: () {
                                              selectedFiles.removeAt(index);
                                              fileRebuild.add(DateTime.now());
                                            },
                                          ),
                                        ),
                                      AppPadding.vertical(),
                                      GestureDetector(
                                        onTap: () async {
                                          var results = await showCalendarDatePicker2Dialog(
                                            context: context,
                                            config: CalendarDatePicker2WithActionButtonsConfig(),
                                            dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                            borderRadius: BorderRadius.circular(15),
                                          );
                                          _startDate.text =
                                              dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                        },
                                        child: ReadOnly(
                                          InputField(
                                            field: InputFieldAttribute(
                                                controller: _startDate,
                                                isEditable: false,
                                                labelText: 'promotionPage'.tr(gender: 'startDate'),
                                                suffixWidget: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_month,
                                                    ),
                                                  ],
                                                )),
                                          ),
                                          isEditable: false,
                                        ),
                                      ),
                                      AppPadding.vertical(denominator: 2),
                                      GestureDetector(
                                        onTap: () async {
                                          var results = await showCalendarDatePicker2Dialog(
                                            context: context,
                                            config: CalendarDatePicker2WithActionButtonsConfig(),
                                            dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                            borderRadius: BorderRadius.circular(15),
                                          );
                                          _endDate.text =
                                              dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                        },
                                        child: ReadOnly(
                                          InputField(
                                            field: InputFieldAttribute(
                                              controller: _endDate,
                                              isEditable: false,
                                              labelText: 'promotionPage'.tr(gender: 'endDate'),
                                            ),
                                          ),
                                          isEditable: false,
                                        ),
                                      ),
                                      AppPadding.vertical(denominator: 2),
                                      ValueListenableBuilder<bool>(
                                          valueListenable: _showOnStart,
                                          builder: (context, snapshot, _) {
                                            return Row(
                                              children: [
                                                CheckBoxWidget(
                                                  (p0) {
                                                    _showOnStart.value = !snapshot;
                                                  },
                                                  value: snapshot,
                                                ),
                                                AppPadding.horizontal(denominator: 2),
                                                Flexible(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      _showOnStart.value = !snapshot;
                                                    },
                                                    child: Text(
                                                      'promotionPage'.tr(gender: 'showOnStart'),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        AppPadding.vertical(denominator: 1 / 1.5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Button(
                              () {
                                if (validate()) {
                                  showLoading();
                                  PromotionController.update(
                                    context,
                                    UpdatePromotionRequest(
                                      promotionId: widget.promotion.promotionId ?? '',
                                      promotionName: _promotionName.text,
                                      promotionDescription: _promotionDescription.text,
                                      promotionTnc: _promotionTnc.text,
                                      promotionStartDate: convertStringToDate(_startDate.text),
                                      promotionEndDate: convertStringToDate(_endDate.text),
                                      showOnStart: _showOnStart.value,
                                      promotionStatus: widget.promotion.promotionStatus == 1 ? true : false,
                                    ),
                                  ).then((value) {
                                    dismissLoading();
                                    if (responseCode(value.code)) {
                                      if (isAnyFileChange()) {
                                        bool showError = false;
                                        for (FileAttribute item in selectedFiles) {
                                          if (item.name!.contains('images/promotion')) {
                                            showError = true;
                                            break;
                                          }
                                        }
                                        if (showError) {
                                          showDialogError(context,
                                              'Please delete the outdated images and upload the updated versions.');
                                        } else {
                                          showLoading();
                                          PromotionController.upload(
                                                  context, widget.promotion.promotionId!, selectedFiles)
                                              .then((value) {
                                            dismissLoading();
                                            if (responseCode(value.code)) {
                                              context.pop();
                                              PromotionController.getAll(context).then((value) =>
                                                  context.read<PromotionController>().promotionAllResponse = value);
                                              showDialogSuccess(context,
                                                  'We\'ve just whipped up an amazing new promotion that\'s sure to bring endless joy to our customers! 🎉');
                                            } else {
                                              showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                            }
                                          });
                                        }
                                      } else {
                                        context.pop();
                                        showDialogSuccess(context,
                                            'We\'ve just whipped up an amazing new promotion that\'s sure to bring endless joy to our customers! 🎉');
                                      }
                                    } else {
                                      showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                    }
                                  });
                                }
                              },
                              actionText: 'button'.tr(gender: 'update'),
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
  }

  bool isAnyFileChange() {
    bool temp = false;

    for (FileAttribute item in selectedFiles) {
      if (item.value != null) {
        temp = true;
        break;
      }
    }
    return temp;
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }

  bool validate() {
    bool temp = true;
    if (_promotionName.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Name'));
    } else if (_promotionDescription.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Description'));
    }
    if (_startDate.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'promotionPage'.tr(gender: 'startDate')));
    } else if (_endDate.text == '') {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'promotionPage'.tr(gender: 'endDate')));
    }
    setState(() {});
    return temp;
  }
}
