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
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/reward/create_reward_request.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart';
import 'package:klinik_aurora_portal/models/reward/update_reward_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
import 'package:provider/provider.dart';

class RewardDetail extends StatefulWidget {
  final Data? reward;
  final String type;

  const RewardDetail({super.key, required this.reward, required this.type});

  @override
  State<RewardDetail> createState() => _RewardDetailState();
}

class _RewardDetailState extends State<RewardDetail> {
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);
  final TextEditingController _rewardName = TextEditingController();
  final TextEditingController _rewardDescription = TextEditingController();
  final TextEditingController _rewardPoint = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();
  final TextEditingController _rewardTotal = TextEditingController();
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  FileAttribute? selectedFile;

  @override
  void initState() {
    if (widget.type == 'update') {
      _rewardName.text = widget.reward?.rewardName ?? '';
      _rewardDescription.text = widget.reward?.rewardDescription ?? '';
      _rewardPoint.text = widget.reward!.rewardPoint.toString();
      _startDate.text = dateConverter(widget.reward?.rewardStartDate, format: 'dd-MM-yyyy') ?? '';
      _endDate.text = dateConverter(widget.reward?.rewardEndDate, format: 'dd-MM-yyyy') ?? '';
      _rewardTotal.text = widget.reward!.totalReward.toString();
      selectedFile = FileAttribute(path: widget.reward?.rewardImage, name: widget.reward?.rewardImage);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return rewardDetails();
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

  Row rewardDetails() {
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
                                child: const Icon(Icons.redeem_rounded, size: 16, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.type == 'create' ? 'New Reward' : 'Edit Reward',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    widget.type == 'create'
                                        ? 'Create a new redeemable reward for customers'
                                        : 'Update reward details, points, and availability',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
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
                                  // Left: Reward Info + Schedule
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Reward Details', Icons.card_giftcard_outlined),
                                        const SizedBox(height: 12),
                                        InputField(
                                          field: InputFieldAttribute(controller: _rewardName, labelText: 'Name'),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        TextField(
                                          maxLines: null,
                                          style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                          controller: _rewardDescription,
                                          decoration: appInputDecoration(context, 'Description'),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(
                                          field: InputFieldAttribute(
                                            controller: _rewardPoint,
                                            isNumber: true,
                                            maxCharacter: 6,
                                            labelText: 'Redemption Points',
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(
                                          field: InputFieldAttribute(
                                            controller: _rewardTotal,
                                            isNumber: true,
                                            maxCharacter: 7,
                                            labelText: 'No. of Items',
                                            tooltip: 'Enter \'0\' for the item count if it is infinite.',
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        _sectionLabel('Availability', Icons.date_range_outlined),
                                        const SizedBox(height: 12),
                                        GestureDetector(
                                          onTap: () async {
                                            var results = await showCalendarDatePicker2Dialog(
                                              context: context,
                                              config: CalendarDatePicker2WithActionButtonsConfig(
                                                currentDate: DateTime.now(),
                                              ),
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
                                                labelText: 'rewardPage'.tr(gender: 'startDate'),
                                                suffixWidget: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [Icon(Icons.calendar_month)],
                                                ),
                                              ),
                                            ),
                                            isEditable: false,
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        GestureDetector(
                                          onTap: () async {
                                            var results = await showCalendarDatePicker2Dialog(
                                              context: context,
                                              config: CalendarDatePicker2WithActionButtonsConfig(
                                                currentDate: DateTime.now().add(const Duration(days: 1)),
                                              ),
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
                                                labelText: 'rewardPage'.tr(gender: 'endDate'),
                                                suffixWidget: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [Icon(Icons.calendar_month)],
                                                ),
                                              ),
                                            ),
                                            isEditable: false,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFF3F4F6)),
                                          ),
                                          child: const Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF9CA3AF)),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Leave Start/End Date blank to make this reward available indefinitely.',
                                                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppPadding.horizontal(),
                                  // Right: Image
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Reward Image', Icons.image_outlined),
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
                                                          title: 'rewardPage'.tr(gender: 'browseFile'),
                                                          fieldTitle: 'rewardPage'.tr(gender: 'rewardImage'),
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
                                                                  height: 300,
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
                                                  widget.reward?.rewardImage == null
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
                                                                        height: 300,
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
                                                              '${Environment.imageUrl}${widget.reward?.rewardImage}',
                                                              height: 300,
                                                            ),
                                                          ),
                                                        ),
                                              ],
                                            );
                                          },
                                        ),
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
                                  Button(() {
                                    if (widget.type == 'update') {
                                      RewardController.update(
                                        context,
                                        UpdateRewardRequest(
                                          rewardId: widget.reward?.rewardId ?? '',
                                          rewardName: _rewardName.text,
                                          rewardDescription: _rewardDescription.text,
                                          rewardPoint: int.parse(_rewardPoint.text),
                                          rewardStartDate: convertStringToDate(_startDate.text),
                                          rewardEndDate: convertStringToDate(_endDate.text),
                                          totalReward: int.parse(_rewardTotal.text),
                                          rewardStatus: widget.reward?.rewardStatus,
                                        ),
                                      ).then((value) {
                                        if (responseCode(value.code)) {
                                          if (selectedFile?.value != null) {
                                            RewardController.upload(
                                              context,
                                              widget.reward!.rewardId!,
                                              selectedFile!,
                                            ).then((value) {
                                              if (responseCode(value.code)) {
                                                getLatestData();
                                              } else {
                                                showDialogError(
                                                  context,
                                                  value.message ?? value.data?.message ?? 'ERROR : ${value.code}',
                                                );
                                              }
                                            });
                                          } else {
                                            context.pop();
                                            getLatestData();
                                          }
                                        } else {
                                          showDialogError(
                                            context,
                                            value.message ?? value.data?.message ?? 'ERROR : ${value.code}',
                                          );
                                        }
                                      });
                                    } else if (widget.type == 'create') {
                                      RewardController.create(
                                        context,
                                        CreateRewardRequest(
                                          rewardName: _rewardName.text,
                                          rewardDescription: _rewardDescription.text,
                                          rewardPoint: int.parse(_rewardPoint.text),
                                          rewardStartDate: convertStringToDate(_startDate.text),
                                          rewardEndDate: convertStringToDate(_endDate.text),
                                          totalReward: _rewardTotal.text != '' ? int.parse(_rewardTotal.text) : null,
                                        ),
                                      ).then((value) {
                                        if (responseCode(value.code)) {
                                          context.pop();
                                          RewardController.upload(context, value.data!.id!, selectedFile!).then((
                                            value,
                                          ) {
                                            if (responseCode(value.code)) getLatestData();
                                          });
                                        } else {
                                          showDialogError(
                                            context,
                                            value.message ?? value.data?.message ?? 'ERROR : ${value.code}',
                                          );
                                        }
                                      });
                                    }
                                  }, actionText: 'button'.tr(gender: widget.type)),
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

  void getLatestData() {
    RewardController.getAll(context, 1, pageSize).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<RewardController>().rewardAllResponse = value;
        if (widget.type == 'update') {
          showDialogSuccess(
            context,
            'We\'ve just whipped up an amazing new reward that\'s sure to bring endless joy to our customers! 🎉',
          );
        } else {
          showDialogSuccess(context, 'Successfully created a new reward');
        }
      } else {
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
