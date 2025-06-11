import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_exception_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/models/appointment/create_appointment_request.dart';
import 'package:klinik_aurora_portal/models/appointment/update_appointment_request.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/views/appointment/payment_details.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/selection_calendar_view.dart';
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
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class AppointmentDetails extends StatefulWidget {
  final Data? appointment;
  final String type;
  final List<String>? tabs;
  final Function? refreshData;
  const AppointmentDetails({super.key, this.appointment, required this.type, this.tabs, this.refreshData});

  @override
  State<AppointmentDetails> createState() => _AppointmentDetailsState();
}

class _AppointmentDetailsState extends State<AppointmentDetails> {
  final InputFieldAttribute patientNameController = InputFieldAttribute(
    controller: TextEditingController(),
    isEditable: false,
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
  List<DropdownAttribute> branches = [];
  final TextEditingController dateTimeController = TextEditingController();
  DropdownAttribute? _appointmentBranch;
  DropdownAttribute? _status;
  DropdownAttribute? _service;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> rebuild = StreamController.broadcast();

  @override
  void initState() {
    patientNameController.controller.text = widget.appointment?.user?.userFullName ?? '';
    patientContactNoController.controller.text = widget.appointment?.user?.userPhone ?? '';
    patientEmailController.controller.text = widget.appointment?.user?.userEmail ?? '';
    appointmentNoteController.controller.text = widget.appointment?.appointmentNote ?? '';
    dueDateController.controller.text = dateConverter(widget.appointment?.customerDueDate, format: 'dd-MM-yyyy') ?? '';

    if (widget.appointment?.appointmentDatetime != null) {
      dateTimeController.text =
          dateConverter(widget.appointment?.appointmentDatetime, format: 'yyyy-MM-dd HH:mm') ?? '';
    }
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (context.read<AuthController>().isSuperAdmin == false && widget.type == 'create') {
        ServiceBranchController.getAll(
          context,
          1,
          100,
          branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
        ).then((value) {
          if (responseCode(value.code)) {
            context.read<ServiceBranchController>().serviceBranchResponse = value.data;
            rebuildDropdown.add(DateTime.now());
          }
        });
      }
      if (context.read<AuthController>().isSuperAdmin == false && widget.type == 'create') {
        try {
          branch_model.Data? item = context.read<BranchController>().branchAllResponse?.data?.data?.firstWhere(
            (element) =>
                element.branchId == context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
          );
          if (item != null) {
            _appointmentBranch = DropdownAttribute(item.branchId ?? '', item.branchName ?? '');
          }
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      if (widget.type == 'update') {
        _appointmentBranch = DropdownAttribute(
          widget.appointment?.branch?.branchId ?? '',
          widget.appointment?.branch?.branchName ?? '',
        );
        _service = DropdownAttribute(
          widget.appointment?.serviceBranchId ?? '',
          widget.appointment?.service?.serviceName ?? '',
        );
        rebuildDropdown.add(DateTime.now());
      }
      try {
        _status = appointmentStatus.firstWhere(
          (element) => element.key == widget.appointment?.appointmentStatus.toString(),
        );
      } catch (e) {
        debugPrint(e.toString());
      }

      if (widget.type == 'update') {
        ServiceBranchAvailableDtController.get(
          context,
          1,
          100,
          serviceBranchId: widget.appointment?.serviceBranchId,
          serviceBranchStatus: 1,
        ).then((value) {
          if (responseCode(value.code)) {
            context.read<ServiceBranchAvailableDtController>().serviceBranchAvailableDtResponse = value.data;
            ServiceBranchExceptionController.get(
              context,
              1,
              999,
              serviceBranchId: widget.appointment?.serviceBranchId,
            ).then((value) {
              if (responseCode(value.code)) {
                context.read<ServiceBranchExceptionController>().serviceBranchExceptionResponse = value.data;
                rebuildDropdown.add(DateTime.now());
              }
            });
          }
        });
      }

      // if (widget.appointment?.doctorType == 1) {
      //   _status = DropdownAttribute('1', 'General');
      // } else if (widget.appointment?.doctorType == 2) {
      //   _status = DropdownAttribute('2', 'Sonographer');
      // }
      if (widget.type == 'create') {
        branches = [];
        if (context.read<BranchController>().branchAllResponse?.data?.data == null) {
          BranchController.getAll(context, 1, 100).then((value) {
            if (responseCode(value.code)) {
              context.read<BranchController>().branchAllResponse = value;
              for (branch_model.Data item in value.data?.data ?? []) {
                branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
              }
            }
          });
        } else {
          for (branch_model.Data item in context.read<BranchController>().branchAllResponse?.data?.data ?? []) {
            branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
          }
        }
        branches.sort((a, b) {
          final nameA = a.name.toLowerCase();
          final nameB = b.name.toLowerCase();
          return nameA.compareTo(nameB);
        });
        rebuildDropdown.add(DateTime.now());
      }
      if (widget.type == 'update') {}
    });
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
                            AppSelectableText('Appointment Details', style: AppTypography.bodyLarge(context)),
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
                            StreamBuilder<DateTime>(
                              stream: rebuild.stream,
                              builder: (context, snapshot) {
                                return SizedBox(
                                  width: screenWidth(26),
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
                                      GestureDetector(
                                        onTap: () async {
                                          var results = await showCalendarDatePicker2Dialog(
                                            context: context,
                                            barrierDismissible: true,
                                            dialogBackgroundColor: Colors.white,
                                            config: CalendarDatePicker2WithActionButtonsConfig(
                                              calendarType: CalendarDatePicker2Type.single,
                                              firstDate: DateTime.now(),
                                              lastDate: DateTime.now().add(Duration(days: 365)),
                                              selectedDayHighlightColor: Colors.blue,
                                              weekdayLabelTextStyle: TextStyle(color: Colors.grey.shade600),
                                              controlsTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              selectedDayTextStyle: TextStyle(color: Colors.white),
                                              dayTextStyle: TextStyle(color: Colors.black87),
                                              disableModePicker: false,
                                              // okButtonText: '', // hide default buttons
                                              // cancelButtonText: '',
                                              openedFromDialog: true,
                                            ),
                                            dialogSize: Size(
                                              screenWidthByBreakpoint(90, 70, 50),
                                              screenHeightByBreakpoint(90, 80, 50),
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                          );
                                          if (results != null) {
                                            if (dueDateController.errorMessage != null) {
                                              dueDateController.errorMessage = null;
                                              rebuild.add(DateTime.now());
                                            }
                                            dueDateController.controller.text =
                                                dateConverter('${results.first}', format: 'dd-MM-yyyy') ?? '';
                                          }
                                        },
                                        child: ReadOnly(InputField(field: dueDateController), isEditable: false),
                                      ),

                                      AppPadding.vertical(denominator: 2),
                                    ],
                                  ),
                                );
                              },
                            ),
                            AppPadding.horizontal(),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                StreamBuilder<DateTime>(
                                  stream: rebuildDropdown.stream,
                                  builder: (context, snapshot) {
                                    return Consumer<AuthController>(
                                      builder: (context, authController, _) {
                                        return AppDropdown(
                                          attributeList: DropdownAttributeList(
                                            authController.isSuperAdmin && widget.type == 'create' ? branches : [],
                                            labelText: 'appointmentPage'.tr(gender: 'branch'),
                                            isEditable: authController.isSuperAdmin && widget.type == 'create',
                                            fieldColor:
                                                authController.isSuperAdmin && widget.type == 'create'
                                                    ? null
                                                    : textFormFieldUneditableColor,
                                            value: _appointmentBranch?.name,
                                            onChanged: (p0) {
                                              _appointmentBranch = p0;
                                              if (_appointmentBranch != null) {
                                                ServiceBranchController.getAll(
                                                  context,
                                                  1,
                                                  100,
                                                  branchId: _appointmentBranch?.key,
                                                  serviceBranchStatus: 1,
                                                ).then((value) {
                                                  if (responseCode(value.code)) {
                                                    context.read<ServiceBranchController>().serviceBranchResponse =
                                                        value.data;
                                                    rebuildDropdown.add(DateTime.now());
                                                  }
                                                });
                                              }
                                            },
                                            width: screenWidthByBreakpoint(90, 70, 30),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                AppPadding.vertical(denominator: 2),
                                StreamBuilder<DateTime>(
                                  stream: rebuildDropdown.stream,
                                  builder: (context, snapshot) {
                                    return Consumer<ServiceBranchController>(
                                      builder: (context, serviceBranchController, _) {
                                        return AppDropdown(
                                          attributeList: DropdownAttributeList(
                                            [
                                              if (serviceBranchController.serviceBranchResponse?.data != null)
                                                for (service_branch_model.Data item
                                                    in serviceBranchController.serviceBranchResponse?.data ?? [])
                                                  DropdownAttribute(item.serviceBranchId ?? '', item.serviceName ?? ''),
                                            ],
                                            labelText: 'appointmentPage'.tr(gender: 'service'),
                                            value: _service?.name,
                                            fieldColor: widget.type == 'update' ? textFormFieldUneditableColor : null,
                                            isEditable: widget.type == 'create',
                                            onChanged: (p0) {
                                              _service = p0;
                                              try {
                                                if (notNullOrEmptyString(
                                                  serviceBranchController.serviceBranchResponse?.data
                                                      ?.firstWhere((element) => element.serviceBranchId == p0?.key)
                                                      .serviceBookingFee,
                                                )) {
                                                  _status = appointmentStatus.firstWhere(
                                                    (element) => element.key == '4',
                                                  );
                                                } else {
                                                  _status = appointmentStatus.firstWhere(
                                                    (element) => element.key == '1',
                                                  );
                                                }
                                              } catch (e) {
                                                debugPrint(e.toString());
                                              }
                                              ServiceBranchAvailableDtController.get(
                                                context,
                                                1,
                                                200,
                                                branchId: _appointmentBranch?.key,
                                                serviceBranchId: _service?.key,
                                              ).then((value) {
                                                if (responseCode(value.code)) {
                                                  context
                                                      .read<ServiceBranchAvailableDtController>()
                                                      .serviceBranchAvailableDtResponse = value.data;
                                                  rebuildDropdown.add(DateTime.now());
                                                  ServiceBranchExceptionController.get(
                                                    context,
                                                    1,
                                                    999,
                                                    serviceBranchId:
                                                        widget.appointment?.serviceBranchId ?? _service?.key,
                                                  ).then((value) {
                                                    if (responseCode(value.code)) {
                                                      context
                                                          .read<ServiceBranchExceptionController>()
                                                          .serviceBranchExceptionResponse = value.data;
                                                    }
                                                  });
                                                }
                                              });
                                            },
                                            width: screenWidthByBreakpoint(90, 70, 30),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                AppPadding.vertical(denominator: 2),
                                StreamBuilder<DateTime>(
                                  stream: rebuildDropdown.stream,
                                  builder: (context, snapshot) {
                                    return Row(
                                      children: [
                                        AppDropdown(
                                          attributeList: DropdownAttributeList(
                                            widget.type == 'update' ? appointmentStatus : [],
                                            isEditable: widget.type == 'update',
                                            fieldColor: widget.type == 'update' ? null : textFormFieldUneditableColor,
                                            labelText: 'appointmentPage'.tr(gender: 'status'),
                                            value: _status?.name,
                                            onChanged: (p0) {
                                              _status = p0;
                                              rebuildDropdown.add(DateTime.now());
                                            },
                                            width: screenWidthByBreakpoint(90, 70, 30),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                AppPadding.vertical(),
                                Consumer<ServiceBranchAvailableDtController>(
                                  builder: (context, snapshot, _) {
                                    return GestureDetector(
                                      onTap: () async {
                                        if (_appointmentBranch != null &&
                                            (snapshot.serviceBranchAvailableDtResponse?.data != null &&
                                                (snapshot.serviceBranchAvailableDtResponse?.data?.length ?? 0) > 0)) {
                                          DateTime now = DateTime.now();
                                          List<String> availableDateTime =
                                              snapshot
                                                  .serviceBranchAvailableDtResponse
                                                  ?.data
                                                  ?.first
                                                  .availableDatetimes ??
                                              [];
                                          List<String> exceptionDateTime = [];
                                          for (
                                            int index = 0;
                                            index <
                                                (context
                                                        .read<ServiceBranchExceptionController>()
                                                        .serviceBranchExceptionResponse
                                                        ?.data
                                                        ?.length ??
                                                    0);
                                            index++
                                          ) {
                                            exceptionDateTime.add(
                                              ServiceBranchExceptionController.convertToUtcIsoString(
                                                context
                                                        .read<ServiceBranchExceptionController>()
                                                        .serviceBranchExceptionResponse
                                                        ?.data?[index]
                                                        .exceptionDate ??
                                                    '',
                                                context
                                                        .read<ServiceBranchExceptionController>()
                                                        .serviceBranchExceptionResponse
                                                        ?.data?[index]
                                                        .exceptionTime ??
                                                    '',
                                              ),
                                            );
                                          }

                                          for (int index = 0; index < exceptionDateTime.length; index++) {
                                            availableDateTime.removeWhere(
                                              (element) => element == exceptionDateTime[index],
                                            );
                                          }
                                          availableDateTime = removePastDates(availableDateTime);
                                          String? selectedDateTime = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      CardContainer(
                                                        Padding(
                                                          padding: EdgeInsets.all(screenPadding),
                                                          child: SelectionCalendarView(
                                                            startMonth: now.month,
                                                            year: now.year,
                                                            initialDateTimes: availableDateTime,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          dateTimeController.text =
                                              selectedDateTime ??
                                              dateConverter(
                                                widget.appointment?.appointmentDatetime,
                                                format: 'yyyy-MM-dd HH:mm',
                                              ) ??
                                              '';
                                        } else if (_service == null) {
                                          showDialogError(
                                            context,
                                            ErrorMessage.required(field: 'appointmentPage'.tr(gender: 'service')),
                                          );
                                        } else if ((snapshot.serviceBranchAvailableDtResponse?.data?.length ?? 0) ==
                                            0) {
                                          showDialogError(context, 'No available slots');
                                        } else {
                                          showDialogError(
                                            context,
                                            ErrorMessage.required(field: 'appointmentPage'.tr(gender: 'branch')),
                                          );
                                        }
                                      },
                                      child: ReadOnly(
                                        isEditable: false,
                                        InputField(
                                          field: InputFieldAttribute(
                                            controller: dateTimeController,
                                            labelText: 'appointmentPage'.tr(gender: 'appointmentDateTime'),
                                            isEditable: false,
                                            uneditableColor: textFormFieldEditableColor,
                                            suffixWidget: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [Icon(Icons.date_range)],
                                            ),
                                          ),
                                          width: screenWidthByBreakpoint(90, 70, 30),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                AppPadding.vertical(denominator: 2),
                              ],
                            ),
                          ],
                        ),
                        Divider(),
                        if (widget.type == 'update') extraInformation(),
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

  Widget extraInformation() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.type == 'update')
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text('Booking Fee', style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1)),
                showPaymentStatus(
                  context,
                  (widget.appointment?.appointmentStatus == 5)
                      ? 1
                      : (widget.appointment?.payment?.length ?? 0) > 0
                      ? widget.appointment?.payment?.any((element) => element.paymentStatus == 1) == true
                          ? 1
                          : 0
                      : 0,
                ),
                SizedBox(height: 4),
                if (widget.appointment?.payment?.any((element) => element.paymentStatus == 1) == true) ...[
                  labelValue(
                    'Payment ID',
                    widget.appointment?.payment?.any((element) => element.paymentStatus == 1) == true
                        ? '${widget.appointment?.payment?.firstWhere((element) => element.paymentStatus == 1).paymentId}'
                        : '',
                    alignStart: true,
                  ),
                  SizedBox(height: 4),
                  //TODO: get from the paid ID, wait for Rahman to add in the response
                  labelValue(
                    'Paid Amount',
                    widget.appointment?.payment?.any((element) => element.paymentStatus == 1) == true
                        ? 'RM ${widget.appointment?.service?.serviceBookingFee}'
                        : '',
                    alignStart: true,
                  ),
                ],
              ],
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.appointment?.appointmentStatus == 5) ...[
                labelValue('Feedback', dateConverter(widget.appointment?.appointmentFeedback) ?? 'Pending Feedback'),
                SizedBox(height: 4),
                AbsorbPointer(
                  child: RatingStars(
                    value: double.parse('${widget.appointment?.appointmentRating ?? 0}'),
                    onValueChanged: (v) {},
                    starBuilder: (index, color) => Icon(Icons.star, color: color),
                    starCount: 5,
                    starSize: 20,
                    valueLabelColor: const Color(0xff9b9b9b),
                    valueLabelTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                      fontSize: 12.0,
                    ),
                    valueLabelRadius: 10,
                    maxValue: 5,
                    starSpacing: 2,
                    maxValueVisibility: true,
                    valueLabelVisibility: true,
                    animationDuration: Duration(milliseconds: 1000),
                    valueLabelPadding: const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                    valueLabelMargin: const EdgeInsets.only(right: 8),
                    starOffColor: const Color(0xffe7e8ea),
                    starColor: Colors.amber,
                  ),
                ),
              ],
              SizedBox(height: 4),
              labelValue('Created Date', dateConverter(widget.appointment?.createdDate) ?? ''),
              if (widget.appointment?.modifiedDate != null)
                labelValue('Updated Date', dateConverter(widget.appointment?.modifiedDate) ?? ''),
            ],
          ),
        ),
      ],
    );
  }

  Widget labelValue(String label, String value, {bool alignStart = true}) {
    return Column(
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(label, style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1)),
        SizedBox(height: 2),
        Text(value, style: AppTypography.bodyMedium(context)),
      ],
    );
  }

  List<String> removePastDates(List<String> dateList) {
    return dateList.where((dateStr) {
      try {
        final dateTime = DateTime.parse(dateStr);
        return dateTime.isAfter(DateTime.now().toUtc());
      } catch (e) {
        debugPrint('Invalid date format: $dateStr');
        return false; // Or keep it if preferred
      }
    }).toList();
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
                  userId: widget.appointment?.user?.userId,
                  serviceBranchId: _service?.key,
                  appointmentDateTime: dateTimeController.text,
                  appointmentNote: appointmentNoteController.controller.text,
                  customerDueDate: dueDateController.controller.text,
                  appointmentStatus: _status != null ? int.parse(_status?.key ?? '0') : 0,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  showLoading();
                  if (widget.refreshData != null) {
                    widget.refreshData!();
                  }
                } else {
                  showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            } else {
              AppointmentController.update(
                context,
                UpdateAppointmentRequest(
                  appointmentId: widget.appointment?.appointmentId,
                  userId: widget.appointment?.user?.userId,
                  appointmentDateTime: dateTimeController.text,
                  serviceBranchId: _service?.key,
                  appointmentNote: appointmentNoteController.controller.text,
                  customerDueDate: dueDateController.controller.text,
                  appointmentStatus: _status != null ? int.parse(_status?.key ?? '0') : 0,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  if (widget.refreshData != null) {
                    widget.refreshData!();
                  }
                  context.pop();
                  if (widget.type == 'update') {
                    showDialogSuccess(context, 'Successfully updated appointment');
                  } else {
                    showDialogSuccess(context, 'Successfully created new appointment');
                  }
                } else {
                  showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            }
          }
        }, actionText: 'button'.tr(gender: widget.type)),
      ],
    );
  }

  getLatestData() {
    AppointmentController()
        .get(
          context,
          1,
          100,
          status: widget.tabs,
          branchId:
              context.read<AuthController>().isSuperAdmin == true
                  ? null
                  : context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
        )
        .then((value) {
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
    if (_appointmentBranch == null) {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Branch'));
    } else if (_status == null) {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Appointment Status'));
    } else if (_service == null) {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Service'));
    } else if (dateTimeController.text == "") {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'Slots'));
    }
    setState(() {});
    return temp;
  }
}
