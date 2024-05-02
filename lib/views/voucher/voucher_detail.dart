import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/voucher/create_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/update_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart' as voucher_model;
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
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
  final TextEditingController _voucherName = TextEditingController();
  final TextEditingController _voucherDescription = TextEditingController();
  final TextEditingController _voucherCode = TextEditingController();
  final TextEditingController _voucherPoint = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();

  @override
  void initState() {
    if (widget.type == 'update') {
      _voucherName.text = widget.voucher?.voucherName ?? '';
      _voucherDescription.text = widget.voucher?.voucherDescription ?? '';
      _voucherCode.text = widget.voucher?.voucherCode ?? '';
      _startDate.text = dateConverter(widget.voucher?.voucherStartDate, format: 'dd-MM-yyyy') ?? '';
      _endDate.text = dateConverter(widget.voucher?.voucherEndDate, format: 'dd-MM-yyyy') ?? '';
      _voucherPoint.text = widget.voucher?.voucherPoint.toString() ?? '';
      _voucherDescription.text = widget.voucher?.voucherDescription ?? '';
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return editUser();
  }

  editUser() {
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
                              'Voucher Details',
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
                                      controller: _voucherName,
                                      labelText: 'voucherPage'.tr(gender: 'voucherName'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _voucherDescription,
                                      labelText: 'voucherPage'.tr(gender: 'voucherDescription'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _voucherCode,
                                      labelText: 'voucherPage'.tr(gender: 'voucherCode'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                ],
                              ),
                            ),
                            AppPadding.horizontal(),
                            SizedBox(
                              width: screenWidth1728(30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _voucherPoint,
                                      labelText: 'voucherPage'.tr(gender: 'voucherPoints'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  GestureDetector(
                                    onTap: () async {
                                      var results = await showCalendarDatePicker2Dialog(
                                        context: context,
                                        config: CalendarDatePicker2WithActionButtonsConfig(
                                          firstDate: DateTime.now(),
                                        ),
                                        dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                        borderRadius: BorderRadius.circular(15),
                                      );
                                      _startDate.text = dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                    },
                                    child: ReadOnly(
                                      InputField(
                                        field: InputFieldAttribute(
                                            controller: _startDate,
                                            isEditable: false,
                                            labelText: 'voucherPage'.tr(gender: 'startDate'),
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
                                        config: CalendarDatePicker2WithActionButtonsConfig(
                                          firstDate: DateTime.now(),
                                        ),
                                        dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                        borderRadius: BorderRadius.circular(15),
                                      );
                                      _endDate.text = dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                    },
                                    child: ReadOnly(
                                      InputField(
                                        field: InputFieldAttribute(
                                          controller: _endDate,
                                          isEditable: false,
                                          labelText: 'voucherPage'.tr(gender: 'endDate'),
                                          suffixWidget: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.calendar_month,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      isEditable: false,
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                ],
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
                                showLoading();
                                if (widget.type == 'update') {
                                  VoucherController.update(
                                    context,
                                    UpdateVoucherRequest(
                                      voucherId: widget.voucher?.voucherId,
                                      voucherName: _voucherName.text,
                                      voucherDescription: _voucherDescription.text,
                                      voucherStartDate: convertStringToDate(_startDate.text),
                                      voucherEndDate: convertStringToDate(_endDate.text),
                                      voucherStatus: widget.voucher?.voucherStatus,
                                      voucherCode: _voucherCode.text,
                                      voucherPoint: int.parse(_voucherPoint.text),
                                    ),
                                  ).then((value) {
                                    if (responseCode(value.code)) {
                                      VoucherController.getAll(
                                        context,
                                      ).then((value) {
                                        dismissLoading();
                                        if (responseCode(value.code)) {
                                          context.read<VoucherController>().voucherAllResponse = value;
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully updated voucher voucherPage');
                                        } else {
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully updated voucher voucherPage');
                                        }
                                      });
                                    } else {
                                      showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                    }
                                  });
                                } else {
                                  VoucherController.create(
                                    context,
                                    CreateVoucherRequest(
                                      voucherName: _voucherName.text,
                                      voucherDescription: _voucherDescription.text,
                                      voucherStartDate: convertStringToDate(_startDate.text),
                                      voucherEndDate: convertStringToDate(_endDate.text),
                                      voucherCode: _voucherCode.text,
                                      voucherPoint: int.parse(_voucherPoint.text),
                                    ),
                                  ).then((value) {
                                    if (responseCode(value.code)) {
                                      VoucherController.getAll(
                                        context,
                                      ).then((value) {
                                        dismissLoading();
                                        if (responseCode(value.code)) {
                                          context.read<VoucherController>().voucherAllResponse = value;
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully created voucher');
                                        } else {
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully created customer voucherPage');
                                        }
                                      });
                                    } else {
                                      showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                    }
                                  });
                                }
                              },
                              actionText: 'button'.tr(gender: widget.type),
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
}
