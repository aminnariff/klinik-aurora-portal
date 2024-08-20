import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/voucher/create_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/update_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart' as voucher_model;
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
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
  final InputFieldAttribute _startDate = InputFieldAttribute(
    controller: TextEditingController(),
  );
  final InputFieldAttribute _endDate = InputFieldAttribute(
    controller: TextEditingController(),
  );
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();

  @override
  void initState() {
    if (widget.type == 'update') {
      _voucherName.controller.text = widget.voucher?.voucherName ?? '';
      _voucherDescription.controller.text = widget.voucher?.voucherDescription ?? '';
      _voucherCode.controller.text = widget.voucher?.voucherCode ?? '';
      _startDate.controller.text = dateConverter(widget.voucher?.voucherStartDate, format: 'dd-MM-yyyy') ?? '';
      _endDate.controller.text = dateConverter(widget.voucher?.voucherEndDate, format: 'dd-MM-yyyy') ?? '';
      _voucherPoint.controller.text = widget.voucher?.voucherPoint.toString() ?? '';
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
                                    field: _voucherName,
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: _voucherDescription,
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: _voucherCode,
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
                                    field: _voucherPoint,
                                  ),
                                  AppPadding.vertical(denominator: 2),
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
                                      if (_startDate.errorMessage != null) {
                                        setState(() {
                                          _startDate.errorMessage = null;
                                        });
                                      }
                                      _startDate.controller.text =
                                          dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                    },
                                    child: ReadOnly(
                                      InputField(
                                        field: InputFieldAttribute(
                                            controller: _startDate.controller,
                                            isEditable: false,
                                            uneditableColor: textFormFieldEditableColor,
                                            errorMessage: _startDate.errorMessage,
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
                                          currentDate: DateTime.now().add(const Duration(days: 1)),
                                        ),
                                        dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                        borderRadius: BorderRadius.circular(15),
                                      );
                                      if (_endDate.errorMessage != null) {
                                        setState(() {
                                          _endDate.errorMessage = null;
                                        });
                                      }
                                      _endDate.controller.text =
                                          dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                    },
                                    child: ReadOnly(
                                      InputField(
                                        field: InputFieldAttribute(
                                          controller: _endDate.controller,
                                          errorMessage: _endDate.errorMessage,
                                          isEditable: false,
                                          uneditableColor: textFormFieldEditableColor,
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
                                      ),
                                    ).then((value) {
                                      dismissLoading();
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
