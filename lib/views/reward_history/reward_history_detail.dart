import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_history_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/reward/reward_history_response.dart' as reward_history;
import 'package:klinik_aurora_portal/models/reward/update_reward_history_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
import 'package:provider/provider.dart';

class RewardHistoryDetail extends StatefulWidget {
  final String type;
  final reward_history.Data data;

  const RewardHistoryDetail({super.key, required this.type, required this.data});

  @override
  State<RewardHistoryDetail> createState() => _RewardHistoryDetailState();
}

class _RewardHistoryDetailState extends State<RewardHistoryDetail> {
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> rebuild = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  ValueNotifier<bool> enableButton = ValueNotifier<bool>(false);
  FileAttribute? document;
  bool status = false;
  DropdownAttribute? _status;
  InputFieldAttribute historyDescription = InputFieldAttribute(
    controller: TextEditingController(),
    lineNumber: 3,
    maxCharacter: 120,
    labelText: 'Comments/Notes',
  );
  FileAttribute? selectedFile;

  @override
  void initState() {
    if (widget.type == 'update') {
      _status = DropdownAttribute(
        widget.data.rewardHistoryStatus == 1 ? '1' : '0',
        widget.data.rewardHistoryStatus == 1 ? 'In-Progress' : 'Completed',
      );
      historyDescription.controller.text = widget.data.rewardHistoryDescription ?? '';
      // selectedFile = FileAttribute(path: widget.reward?.rewardImage, name: widget.reward?.rewardImage);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return rewardHistoryDetails();
  }

  rewardHistoryDetails() {
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
                            AppSelectableText('Reward History Information', style: AppTypography.bodyLarge(context)),
                            CloseButton(
                              onPressed: () {
                                context.pop();
                              },
                            ),
                          ],
                        ),
                        AppPadding.vertical(denominator: 1),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: screenWidth1728(26),
                              child: Column(
                                children: [
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: TextEditingController(text: widget.data.rewardHistoryId),
                                      isNumber: true,
                                      maxCharacter: 6,
                                      labelText: 'ID *',
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 1),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: TextEditingController(text: widget.data.rewardName),
                                      labelText: 'Reward Name *',
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 1),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: TextEditingController(text: widget.data.userFullname),
                                      labelText: 'Patient Name *',
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 1),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: TextEditingController(text: widget.data.userPhone),
                                      labelText: 'Patient Contact No *',
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 1),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: historyDescription.controller,
                                      errorMessage: historyDescription.errorMessage,
                                      lineNumber: 3,
                                      maxCharacter: 120,
                                      labelText: 'Comments/Notes *',
                                      onChanged: (value) {
                                        if (historyDescription.errorMessage != null) {
                                          historyDescription.errorMessage = null;
                                        }
                                        enableButton.value = true;
                                      },
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 1),
                                  StreamBuilder<DateTime>(
                                    stream: rebuildDropdown.stream,
                                    builder: (context, snapshot) {
                                      return AppDropdown(
                                        attributeList: DropdownAttributeList(
                                          [
                                            for (DropdownAttribute item in rewardHistoryStatus)
                                              DropdownAttribute(item.key, item.name),
                                          ],
                                          onChanged: (selected) {
                                            _status = selected;
                                            enableButton.value = true;
                                            rebuildDropdown.add(DateTime.now());
                                          },
                                          // errorMessage: _branchId.errorMessage,
                                          value: _status?.name,
                                          width: screenWidth1728(26),
                                        ),
                                      );
                                    },
                                  ),
                                  AppPadding.vertical(denominator: 1),
                                  Text(
                                    'Note: If an item needs to be shipped, please enter the address in the comment section. Update the status once it has been completed.',
                                    style: AppTypography.bodyMedium(context).apply(),
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
                                      if (widget.type == 'create') ...[
                                        selectedFile?.value == null
                                            ? UploadDocumentsField(
                                              title: 'rewardHistoryPage'.tr(gender: 'browseFile'),
                                              fieldTitle: 'rewardHistoryPage'.tr(gender: 'rewardImage'),
                                              // tooltipText: 'promotionPage'.tr(gender: 'browse'),
                                              action: () {
                                                addPicture();
                                              },
                                              cancelAction: () {},
                                            )
                                            : Stack(
                                              alignment: Alignment.topRight,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    addPicture();
                                                  },
                                                  child: Image.memory(selectedFile?.value as Uint8List, height: 410),
                                                ),
                                                IconButton(
                                                  onPressed: () {
                                                    selectedFile = FileAttribute();
                                                    fileRebuild.add(DateTime.now());
                                                  },
                                                  icon: const Icon(Icons.close),
                                                ),
                                              ],
                                            ),
                                      ],
                                      if (widget.type == 'update')
                                        widget.data.rewardHistoryImage == null
                                            ? selectedFile?.name != null
                                                ? Stack(
                                                  alignment: Alignment.topRight,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        addPicture();
                                                      },
                                                      child: Image.memory(
                                                        selectedFile?.value as Uint8List,
                                                        height: 410,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        selectedFile = FileAttribute();
                                                        fileRebuild.add(DateTime.now());
                                                      },
                                                      icon: const Icon(Icons.close),
                                                    ),
                                                  ],
                                                )
                                                : UploadDocumentsField(
                                                  title: 'branchImage'.tr(gender: 'browseFile'),
                                                  fieldTitle: 'branchPage'.tr(gender: 'branchImage'),
                                                  // tooltipText: 'promotionPage'.tr(gender: 'browse'),
                                                  action: () {
                                                    addPicture();
                                                  },
                                                  cancelAction: () {},
                                                )
                                            : GestureDetector(
                                              onTap: () {
                                                addPicture();
                                              },
                                              child: Image.network(
                                                '${Environment.imageUrl}${widget.data.rewardHistoryImage}',
                                                height: 410,
                                              ),
                                            ),
                                      if (widget.data.createdByFullname != null) ...[
                                        AppPadding.vertical(denominator: 1),
                                        InputField(
                                          field: InputFieldAttribute(
                                            controller: TextEditingController(text: widget.data.createdByFullname),
                                            isEditable: false,
                                            labelText: 'Updated by',
                                          ),
                                        ),
                                      ],
                                      AppPadding.vertical(denominator: 1),
                                      InputField(
                                        field: InputFieldAttribute(
                                          controller: TextEditingController(
                                            text: dateConverter(widget.data.rewardHistoryModifiedDate),
                                          ),
                                          isEditable: false,
                                          labelText: 'Updated At',
                                        ),
                                      ),
                                      AppPadding.vertical(denominator: 1),
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
                            StreamBuilder<DateTime>(
                              stream: rebuild.stream,
                              builder: (context, snapshot) {
                                return ValueListenableBuilder<bool>(
                                  valueListenable: enableButton,
                                  builder: (context, snapshot, _) {
                                    return Button(
                                      () {
                                        if (historyDescription.controller.text.isNotEmpty &&
                                            _status != null &&
                                            snapshot) {
                                          showConfirmDialog(
                                            context,
                                            'Are you sure you want to update this order?',
                                          ).then((updating) {
                                            if (updating == true) {
                                              RewardHistoryController.update(
                                                context,
                                                UpdateRewardHistoryRequest(
                                                  rewardId: widget.data.rewardId,
                                                  rewardHistoryId: widget.data.rewardHistoryId,
                                                  pointTransactionId: widget.data.pointTransactionId,
                                                  rewardHistoryStatus: int.parse(_status?.key ?? '0'),
                                                  rewardHistoryDescription: historyDescription.controller.text,
                                                  // userAddress: userAddress.text,
                                                  // userAddressPostcode: userAddressPostcode.text,
                                                  // userAddressCity: userAddressCity.text,
                                                  // userAddressState: userAddressState.text,
                                                  // userAddressCountry: 'Malaysia',
                                                ),
                                              ).then((value) {
                                                if (responseCode(value.code)) {
                                                  if (document?.value != null) {
                                                    RewardHistoryController.upload(
                                                      context,
                                                      widget.data.rewardHistoryId ?? '',
                                                      FileAttribute(name: document?.name, value: document?.value),
                                                    ).then((uploadResponse) {
                                                      if (responseCode(uploadResponse.code)) {
                                                        _onRefresh();
                                                      } else {
                                                        showDialogError(
                                                          context,
                                                          value.data?.message ??
                                                              value.message ??
                                                              'Order successfully updated but unable to update the image:\n${widget.data.rewardId}',
                                                        );
                                                      }
                                                    });
                                                  } else {
                                                    _onRefresh();
                                                  }
                                                } else {
                                                  showDialogError(
                                                    context,
                                                    value.data?.message ??
                                                        value.message ??
                                                        'Unable to update the order:\n${widget.data.rewardId}',
                                                  );
                                                }
                                              });
                                            }
                                          });
                                        } else {
                                          setState(() {
                                            historyDescription.errorMessage =
                                                'Please update the comments for reference and tracking purposes.';
                                          });
                                        }
                                      },
                                      color: snapshot ? null : disabledColor,
                                      actionText: 'button'.tr(gender: 'update'),
                                    );
                                  },
                                );
                              },
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

  _onRefresh() {
    RewardHistoryController.getAll(context, 1, pageSize).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<RewardHistoryController>().rewardHistoryResponse = value;
      } else if (value.code == 404) {}
      return null;
    });
  }

  getLatestData() {
    RewardController.getAll(context, 1, pageSize).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<RewardController>().rewardAllResponse = value;
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(
            context,
            'We\'ve just whipped up an amazing new reward that\'s sure to bring endless joy to our customers! 🎉',
          );
        } else {
          showDialogSuccess(context, 'Successfully created a new reward');
        }
      } else {
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(
            context,
            'We\'ve just whipped up an amazing new reward that\'s sure to bring endless joy to our customers! 🎉',
          );
        } else {
          showDialogSuccess(context, 'Successfully created a new reward');
        }
      }
    });
  }

  addPicture() async {
    documentErrorMessage.add(null);
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      if (supportedExtensions.contains(file.extension)) {
        debugPrint(bytesToMB(file.size).toString());
        debugPrint(file.name);
        if (bytesToMB(file.size) < 1.0) {
          Uint8List? fileBytes = result.files.first.bytes;
          String fileName = result.files.first.name;

          selectedFile = FileAttribute(name: fileName, value: fileBytes);
          fileRebuild.add(DateTime.now());
        } else {
          showDialogError(context, 'error'.tr(gender: 'err-21', args: [fileSizeLimit.toStringAsFixed(0)]));
        }
      } else {
        showDialogError(context, 'error'.tr(gender: 'err-22'));
      }
    } else {
      // User canceled the picker
    }
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }
}
