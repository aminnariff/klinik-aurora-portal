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

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: const Color(0xFF9CA3AF)), const SizedBox(width: 8)],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Row rewardHistoryDetails() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CardContainer(
                  IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Header ──────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(width: 10),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Reward History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                                  Text(
                                    'Review and update this reward redemption order',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              CloseButton(onPressed: () => context.pop()),
                            ],
                          ),
                        ),
                        // ── Body ────────────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.all(screenPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left: Order Info + Action
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Order Information', Icons.receipt_outlined),
                                        const SizedBox(height: 12),
                                        _infoTile(
                                          'Reward',
                                          widget.data.rewardName ?? 'N/A',
                                          icon: Icons.card_giftcard_outlined,
                                        ),
                                        const SizedBox(height: 8),
                                        _infoTile(
                                          'Patient',
                                          widget.data.userFullname ?? 'N/A',
                                          icon: Icons.person_outline_rounded,
                                        ),
                                        const SizedBox(height: 8),
                                        _infoTile(
                                          'Contact No.',
                                          widget.data.userPhone ?? 'N/A',
                                          icon: Icons.phone_outlined,
                                        ),
                                        const SizedBox(height: 20),
                                        _sectionLabel('Update Order', Icons.edit_note_rounded),
                                        const SizedBox(height: 12),
                                        InputField(
                                          field: InputFieldAttribute(
                                            controller: historyDescription.controller,
                                            errorMessage: historyDescription.errorMessage,
                                            lineNumber: 3,
                                            maxCharacter: 120,
                                            labelText: 'Comments / Notes *',
                                            onChanged: (value) {
                                              if (historyDescription.errorMessage != null)
                                                historyDescription.errorMessage = null;
                                              enableButton.value = true;
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 12),
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
                                                value: _status?.name,
                                                width: screenWidth1728(26),
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF7ED),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFED7AA)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(
                                                Icons.local_shipping_outlined,
                                                size: 14,
                                                color: Color(0xFFD97706),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'If shipping is required, include the delivery address in the comment section above.',
                                                  style: AppTypography.bodyMedium(
                                                    context,
                                                  ).apply(color: const Color(0xFF92400E)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppPadding.horizontal(),
                                  // Right: Image + Audit
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Proof of Delivery', Icons.image_outlined),
                                        const SizedBox(height: 12),
                                        StreamBuilder<DateTime>(
                                          stream: fileRebuild.stream,
                                          builder: (context, snapshot) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (widget.type == 'create') ...[
                                                  selectedFile?.value == null
                                                      ? UploadDocumentsField(
                                                          title: 'rewardHistoryPage'.tr(gender: 'browseFile'),
                                                          fieldTitle: 'rewardHistoryPage'.tr(gender: 'rewardImage'),
                                                          action: () => addPicture(),
                                                          cancelAction: () {},
                                                        )
                                                      : Stack(
                                                          alignment: Alignment.topRight,
                                                          children: [
                                                            ClipRRect(
                                                              borderRadius: BorderRadius.circular(10),
                                                              child: GestureDetector(
                                                                onTap: () => addPicture(),
                                                                child: Image.memory(
                                                                  selectedFile?.value as Uint8List,
                                                                  height: 260,
                                                                ),
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
                                                        ),
                                                ],
                                                if (widget.type == 'update')
                                                  widget.data.rewardHistoryImage == null
                                                      ? selectedFile?.name != null
                                                            ? Stack(
                                                                alignment: Alignment.topRight,
                                                                children: [
                                                                  ClipRRect(
                                                                    borderRadius: BorderRadius.circular(10),
                                                                    child: GestureDetector(
                                                                      onTap: () => addPicture(),
                                                                      child: Image.memory(
                                                                        selectedFile?.value as Uint8List,
                                                                        height: 260,
                                                                      ),
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
                                                                action: () => addPicture(),
                                                                cancelAction: () {},
                                                              )
                                                      : ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: GestureDetector(
                                                            onTap: () => addPicture(),
                                                            child: Image.network(
                                                              '${Environment.imageUrl}${widget.data.rewardHistoryImage}',
                                                              height: 260,
                                                            ),
                                                          ),
                                                        ),
                                              ],
                                            );
                                          },
                                        ),
                                        if (widget.data.createdByFullname != null ||
                                            widget.data.rewardHistoryModifiedDate != null) ...[
                                          const SizedBox(height: 20),
                                          _sectionLabel('Audit Trail', Icons.history_rounded),
                                          const SizedBox(height: 12),
                                          if (widget.data.createdByFullname != null) ...[
                                            _infoTile(
                                              'Last updated by',
                                              widget.data.createdByFullname ?? 'N/A',
                                              icon: Icons.person_outline_rounded,
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          _infoTile(
                                            'Updated at',
                                            dateConverter(widget.data.rewardHistoryModifiedDate) ?? 'N/A',
                                            icon: Icons.access_time_rounded,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  StreamBuilder<DateTime>(
                                    stream: rebuild.stream,
                                    builder: (context, snapshot) {
                                      return ValueListenableBuilder<bool>(
                                        valueListenable: enableButton,
                                        builder: (context, enabled, _) {
                                          return Button(
                                            () {
                                              if (historyDescription.controller.text.isNotEmpty &&
                                                  _status != null &&
                                                  enabled) {
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
                                                                    'Order updated but image upload failed.',
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
                                                              'Unable to update order:\n${widget.data.rewardId}',
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
                                            color: enabled ? null : disabledColor,
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onRefresh() {
    RewardHistoryController.getAll(context, 1, pageSize).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<RewardHistoryController>().rewardHistoryResponse = value;
      } else if (value.code == 404) {}
      return null;
    });
  }

  void getLatestData() {
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

  Future<void> addPicture() async {
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
