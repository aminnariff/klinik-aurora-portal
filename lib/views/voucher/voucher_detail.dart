import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart' as reward_model;
import 'package:klinik_aurora_portal/models/voucher/create_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/update_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart' as voucher_model;
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class VoucherDetail extends StatefulWidget {
  final voucher_model.Data? voucher;
  final String type;
  const VoucherDetail({super.key, this.voucher, required this.type});

  @override
  State<VoucherDetail> createState() => _VoucherDetailState();
}

class _VoucherDetailState extends State<VoucherDetail> {
  final InputFieldAttribute _voucherName = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'voucherPage'.tr(gender: 'voucherName'),
  );
  final InputFieldAttribute _voucherDescription = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'voucherPage'.tr(gender: 'voucherDescription'),
  );
  final InputFieldAttribute _voucherCode = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'voucherPage'.tr(gender: 'voucherCode'),
    hintText: 'Max (10 characters)',
    maxCharacter: 10,
  );
  final InputFieldAttribute _voucherPoint = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'voucherPage'.tr(gender: 'voucherPoints'),
    maxCharacter: 7,
    isNumber: true,
  );
  final InputFieldAttribute _startDate = InputFieldAttribute(controller: TextEditingController());
  final InputFieldAttribute _endDate = InputFieldAttribute(controller: TextEditingController());
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  List<DropdownAttribute> rewards = [];
  DropdownAttribute? selectedReward;

  @override
  void initState() {
    if (widget.type == 'update') {
      _voucherName.controller.text = widget.voucher?.voucherName ?? '';
      _voucherDescription.controller.text = widget.voucher?.voucherDescription ?? '';
      _voucherCode.controller.text = widget.voucher?.voucherCode ?? '';
      _startDate.controller.text = dateConverter(widget.voucher?.voucherStartDate, format: 'dd-MM-yyyy') ?? '';
      _endDate.controller.text = dateConverter(widget.voucher?.voucherEndDate, format: 'dd-MM-yyyy') ?? '';
      _voucherPoint.controller.text = widget.voucher?.voucherPoint.toString() ?? '';
      if (widget.voucher?.rewardId != null) {
        selectedReward = DropdownAttribute(widget.voucher?.rewardId ?? '', widget.voucher?.rewardId ?? '');
      }
    }
    RewardController.getAll(context, 1, pageSize).then((value) {
      rewards = [];
      if (responseCode(value.code)) {
        context.read<RewardController>().rewardAllResponse = value;
        for (reward_model.Data item in value.data?.data ?? []) {
          if (item.rewardStatus == 1 && checkEndDate(item.rewardEndDate)) {
            rewards.add(DropdownAttribute(item.rewardId ?? '', item.rewardName ?? ''));
            if (selectedReward?.key == item.rewardId) {
              selectedReward = DropdownAttribute(item.rewardId ?? '', item.rewardName ?? '');
            }
          }
        }
        rebuildDropdown.add(DateTime.now());
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return editUser();
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 3, height: 13, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 1.0)),
      ],
    );
  }

  Row editUser() {
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
                                decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.confirmation_number_rounded, size: 16, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.type == 'create' ? 'New Voucher' : 'Edit Voucher',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    widget.type == 'create' ? 'Create a new redeemable voucher' : 'Update voucher details and validity',
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
                                  // Left: Voucher Details
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Voucher Details', Icons.local_offer_outlined),
                                        const SizedBox(height: 12),
                                        InputField(field: _voucherName),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(field: _voucherDescription),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(field: _voucherCode),
                                        AppPadding.vertical(denominator: 2),
                                        const SizedBox(height: 8),
                                        _sectionLabel('Linked Reward', Icons.card_giftcard_outlined),
                                        const SizedBox(height: 12),
                                        Consumer<RewardController>(
                                          builder: (context, snap, _) {
                                            return StreamBuilder<DateTime>(
                                              stream: rebuildDropdown.stream,
                                              builder: (context, snapshot) {
                                                if (widget.type == 'update') {
                                                  return selectedReward?.name != null
                                                      ? InputField(
                                                          field: InputFieldAttribute(
                                                            controller: TextEditingController(text: selectedReward?.name ?? ''),
                                                            isEditable: false,
                                                          ),
                                                        )
                                                      : const SizedBox();
                                                }
                                                if (rewards.isEmpty) {
                                                  return Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFF7ED),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFFED7AA)),
                                                    ),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFD97706)),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            'No rewards available. Vouchers without a linked reward will grant points only.',
                                                            style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF92400E)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                                return Row(
                                                  children: [
                                                    AppDropdown(
                                                      attributeList: DropdownAttributeList(
                                                        rewards,
                                                        hintText: 'Select Reward (Optional)',
                                                        value: selectedReward?.name,
                                                        onChanged: (a) {
                                                          if (a != null) setState(() => selectedReward = a);
                                                        },
                                                        width: screenWidth1728(23),
                                                      ),
                                                    ),
                                                    const Tooltip(
                                                      message: 'Adding a reward is optional. Without one, the customer receives points only.',
                                                      child: Padding(padding: EdgeInsets.only(left: 12), child: Icon(Icons.info_outline, size: 18)),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppPadding.horizontal(),
                                  // Right: Points & Schedule
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Points & Schedule', Icons.schedule_outlined),
                                        const SizedBox(height: 12),
                                        InputField(field: _voucherPoint),
                                        AppPadding.vertical(denominator: 2),
                                        GestureDetector(
                                          onTap: () async {
                                            var results = await showCalendarDatePicker2Dialog(
                                              context: context,
                                              config: CalendarDatePicker2WithActionButtonsConfig(currentDate: DateTime.now()),
                                              dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                              borderRadius: BorderRadius.circular(15),
                                            );
                                            if (_startDate.errorMessage != null) setState(() => _startDate.errorMessage = null);
                                            _startDate.controller.text = dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                          },
                                          child: ReadOnly(
                                            InputField(
                                              field: InputFieldAttribute(
                                                controller: _startDate.controller,
                                                isEditable: false,
                                                uneditableColor: textFormFieldEditableColor,
                                                errorMessage: _startDate.errorMessage,
                                                labelText: 'voucherPage'.tr(gender: 'startDate'),
                                                suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month)]),
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
                                              config: CalendarDatePicker2WithActionButtonsConfig(currentDate: DateTime.now().add(const Duration(days: 1))),
                                              dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                              borderRadius: BorderRadius.circular(15),
                                            );
                                            if (_endDate.errorMessage != null) setState(() => _endDate.errorMessage = null);
                                            _endDate.controller.text = dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                          },
                                          child: ReadOnly(
                                            InputField(
                                              field: InputFieldAttribute(
                                                controller: _endDate.controller,
                                                errorMessage: _endDate.errorMessage,
                                                isEditable: false,
                                                uneditableColor: textFormFieldEditableColor,
                                                labelText: 'voucherPage'.tr(gender: 'endDate'),
                                                suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month)]),
                                              ),
                                            ),
                                            isEditable: false,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9FAFB),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFF3F4F6)),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.lightbulb_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'When staff scan a customer\'s QR code, linked reward vouchers are auto-redeemed — no manual action needed.',
                                                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                                ),
                                              ),
                                            ],
                                          ),
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
                                    if (validate()) {
                                      showLoading();
                                      if (widget.type == 'update') {
                                        VoucherController.update(
                                          context,
                                          UpdateVoucherRequest(
                                            voucherId: widget.voucher?.voucherId,
                                            voucherName: _voucherName.controller.text,
                                            voucherDescription: _voucherDescription.controller.text,
                                            voucherStartDate: convertStringToDate(_startDate.controller.text),
                                            voucherEndDate: convertStringToDate(_endDate.controller.text),
                                            voucherStatus: widget.voucher?.voucherStatus,
                                            voucherCode: _voucherCode.controller.text,
                                            voucherPoint: int.parse(_voucherPoint.controller.text),
                                            rewardId: selectedReward?.key,
                                          ),
                                        ).then((value) {
                                          if (responseCode(value.code)) {
                                            VoucherController.getAll(context, 1, pageSize).then((value) {
                                              dismissLoading();
                                              if (responseCode(value.code)) {
                                                context.read<VoucherController>().voucherAllResponse = value;
                                                context.pop();
                                                showDialogSuccess(context, 'Successfully updated voucher');
                                              } else {
                                                context.pop();
                                                showDialogSuccess(context, 'Successfully updated voucher');
                                              }
                                            });
                                          } else {
                                            showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                                          }
                                        });
                                      } else {
                                        showLoading();
                                        VoucherController.create(
                                          context,
                                          CreateVoucherRequest(
                                            voucherName: _voucherName.controller.text,
                                            voucherDescription: _voucherDescription.controller.text,
                                            voucherStartDate: convertStringToDate(_startDate.controller.text),
                                            voucherEndDate: convertStringToDate(_endDate.controller.text),
                                            voucherCode: _voucherCode.controller.text,
                                            voucherPoint: int.parse(_voucherPoint.controller.text),
                                            rewardId: selectedReward?.key,
                                          ),
                                        ).then((value) {
                                          dismissLoading();
                                          if (responseCode(value.code)) {
                                            VoucherController.getAll(context, 1, pageSize).then((value) {
                                              dismissLoading();
                                              if (responseCode(value.code)) {
                                                context.read<VoucherController>().voucherAllResponse = value;
                                                context.pop();
                                                showDialogSuccess(context, 'Successfully created voucher');
                                              } else {
                                                context.pop();
                                                showDialogSuccess(context, 'Successfully created voucher');
                                              }
                                            });
                                          } else {
                                            showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                                          }
                                        });
                                      }
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

  bool validate() {
    bool temp = true;
    if (_voucherName.controller.text == '') {
      temp = false;
      _voucherName.errorMessage = ErrorMessage.required(field: _voucherName.labelText);
    }
    if (_voucherDescription.controller.text == '') {
      temp = false;
      _voucherDescription.errorMessage = ErrorMessage.required(field: _voucherDescription.labelText);
    }
    if (_voucherCode.controller.text == '') {
      temp = false;
      _voucherCode.errorMessage = ErrorMessage.required(field: _voucherCode.labelText);
    }
    if (_voucherPoint.controller.text == '') {
      temp = false;
      _voucherPoint.errorMessage = ErrorMessage.required(field: _voucherPoint.labelText);
    }
    if (_startDate.controller.text == '') {
      temp = false;
      _startDate.errorMessage = ErrorMessage.required(field: _startDate.labelText);
    }
    if (_endDate.controller.text == '') {
      temp = false;
      _endDate.errorMessage = ErrorMessage.required(field: _endDate.labelText);
    }
    setState(() {});
    return temp;
  }
}
