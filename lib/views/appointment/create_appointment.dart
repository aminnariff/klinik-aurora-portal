import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/models/appointment/create_appointment_request.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class AppointmentDetails extends StatefulWidget {
  final Data? appointment;
  final String type;
  const AppointmentDetails({super.key, this.appointment, required this.type});

  @override
  State<AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {
  final InputFieldAttribute patientNameController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'appointmentPage'.tr(gender: 'patientName'),
  );
  final InputFieldAttribute patientContactNoController = InputFieldAttribute(
    controller: TextEditingController(),
    isEditable: false,
    labelText: 'appointmentPage'.tr(gender: 'patientContactNo'),
  );
  final InputFieldAttribute patientEmailController = InputFieldAttribute(
    controller: TextEditingController(),
    isEditable: false,
    labelText: 'appointmentPage'.tr(gender: 'patientEmail'),
  );
  final InputFieldAttribute appointmentNoteController = InputFieldAttribute(
    controller: TextEditingController(),
    lineNumber: 3,
    maxCharacter: 500,
    labelText: 'appointmentPage'.tr(gender: 'appointmentNote'),
  );
  final InputFieldAttribute dueDateController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'appointmentPage'.tr(gender: 'dueDate'),
    isNumber: true,
  );
  String? _userId;
  String? _appointmentBranchId;
  String? _selectedDate;
  String? _selectedTime;
  DropdownAttribute? _status;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    if (widget.type == 'update') {
      // appointmentNameController.controller.text = widget.appointment?.appointmentName ?? '';
      // appointmentDescriptionController.controller.text = widget.appointment?.appointmentDescription ?? '';
      // appointmentPriceController.controller.text = widget.appointment?.appointmentPrice ?? '';
      // appointmentBookingFeeController.controller.text = widget.appointment?.appointmentBookingFee ?? '';
      // appointmentTimeController.controller.text = widget.appointment?.appointmentTime ?? '';
      // appointmentCategoryController.controller.text = widget.appointment?.appointmentCategory ?? '';
      // if (widget.appointment?.doctorType == 1) {
      //   _status = DropdownAttribute('1', 'General');
      // } else if (widget.appointment?.doctorType == 2) {
      //   _status = DropdownAttribute('2', 'Sonographer');
      // }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return editBranch();
  }

  editBranch() {
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
                            AppSelectableText('appointment Details', style: AppTypography.bodyLarge(context)),
                            CloseButton(
                              onPressed: () {
                                context.pop();
                              },
                            ),
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
                                  InputField(field: patientNameController),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: patientContactNoController),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: patientEmailController),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: appointmentNoteController),
                                  AppPadding.vertical(denominator: 2),
                                  StreamBuilder<DateTime>(
                                    stream: rebuildDropdown.stream,
                                    builder: (context, snapshot) {
                                      return AppDropdown(
                                        attributeList: DropdownAttributeList(
                                          appointmentStatus,
                                          labelText: 'appointmentPage'.tr(gender: 'status'),
                                          value: _status?.name,
                                          onChanged: (p0) {
                                            _status = p0;
                                            rebuildDropdown.add(DateTime.now());
                                          },
                                          width: screenWidthByBreakpoint(90, 70, 26),
                                        ),
                                      );
                                    },
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
                                children: [AppPadding.vertical(denominator: 2)],
                              ),
                            ),
                          ],
                        ),
                        AppPadding.vertical(denominator: 1 / 1.5),
                        button(),
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

  String checkTime(String value) {
    if (value.length == 1) {
      return '0$value';
    } else {
      return value;
    }
  }

  Widget button() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(() {
          if (validate()) {
            showLoading();
            if (widget.type == 'create') {
              AppointmentController.create(
                context,
                CreateAppointmentRequest(
                  userId: _userId,
                  // appointmentBranchId: _appointmentBranchId,
                  appointmentDateTime: '$_selectedDate $_selectedTime',
                  appointmentNote: appointmentNoteController.controller.text,
                  customerDueDate: dueDateController.controller.text,
                  appointmentStatus: _status != null ? int.parse(_status?.key ?? '0') : 0,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  showLoading();
                  getLatestData();
                } else {
                  showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            }
            // else {
            //   AppointmentController.update(
            //     context,
            //     UpdateappointmentRequest(
            //       appointmentId: widget.appointment?.appointmentId,
            //       appointmentStatus: widget.appointment?.appointmentStatus,
            //       appointmentName: appointmentNameController.controller.text,
            //       appointmentDescription: appointmentDescriptionController.controller.text,
            //       appointmentPrice:
            //           appointmentPriceController.controller.text == ''
            //               ? null
            //               : double.parse(appointmentPriceController.controller.text),
            //       appointmentBookingFee:
            //           appointmentBookingFeeController.controller.text == ''
            //               ? null
            //               : double.parse(appointmentBookingFeeController.controller.text),
            //       appointmentTime: appointmentTimeController.controller.text,
            //       appointmentCategory: appointmentCategoryController.controller.text,
            //       doctorType: int.parse(_doctorType?.key ?? "1"),
            //     ),
            //   ).then((value) {
            //     dismissLoading();
            //     if (responseCode(value.code)) {
            //       showLoading();
            //       if (selectedFile.value != null) {
            //         appointmentController.upload(context, widget.appointment!.appointmentId!, selectedFile).then((value) {
            //           dismissLoading();
            //           if (responseCode(value.code)) {
            //             getLatestData();
            //           } else {
            //             showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
            //           }
            //         });
            //       } else {
            //         getLatestData();
            //       }
            //     } else {
            //       showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
            //     }
            //   });
            // }
          }
        }, actionText: 'button'.tr(gender: widget.type)),
      ],
    );
  }

  getLatestData() {
    AppointmentController().get(context, 1, 100).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<AppointmentController>().appointmentResponse = value;
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated appointment');
        } else {
          showDialogSuccess(context, 'Successfully created new appointment');
        }
      } else {
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated appointment');
        } else {
          showDialogSuccess(context, 'Successfully created new appointment');
        }
      }
    });
  }

  bool validate() {
    bool temp = true;
    if (patientNameController.controller.text == '') {
      temp = false;
      patientNameController.errorMessage = ErrorMessage.required(field: patientNameController.labelText);
    }
    if (_appointmentBranchId == null) {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Branch'));
    } else if (_selectedDate == null) {
      temp = false;

      showDialogError(context, ErrorMessage.required(field: 'Date'));
    } else if (_selectedTime == null) {
      temp = false;

      showDialogError(context, ErrorMessage.required(field: 'Time'));
    } else if (_status == null) {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Appointment Status'));
    }
    setState(() {});
    return temp;
  }
}
