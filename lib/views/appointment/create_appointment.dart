import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_stars/flutter_rating_stars.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/gestational/gestational_controller.dart';
import 'package:klinik_aurora_portal/controllers/payment/payment_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/models/appointment/create_appointment_request.dart';
import 'package:klinik_aurora_portal/models/appointment/update_appointment_request.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_available_response.dart'
    as service_branch_available_model;
import 'package:klinik_aurora_portal/views/appointment/payment_details.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/button/copy_button.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/selection_calendar_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
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
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  List<FileAttribute> selectedFiles = [];
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  List<DropdownAttribute> serviceList = [];
  List<String> availableDateTime = [];
  service_branch_available_model.Data? selectedService;
  GestationalController? gestationalResult;

  bool get _isLocked =>
      widget.appointment?.appointmentStatus == 2 ||
      widget.appointment?.appointmentStatus == 4 ||
      widget.appointment?.appointmentStatus == 5;

  @override
  void initState() {
    patientNameController.controller.text = widget.appointment?.user?.userFullName?.titleCase() ?? '';
    patientContactNoController.controller.text = widget.appointment?.user?.userPhone ?? '';
    patientEmailController.controller.text = widget.appointment?.user?.userEmail ?? '';
    appointmentNoteController.controller.text = widget.appointment?.appointmentNote ?? '';
    dueDateController.controller.text = dateConverter(widget.appointment?.customerDueDate, format: 'dd-MM-yyyy') ?? '';

    if (widget.appointment?.appointmentDatetime != null) {
      dateTimeController.text =
          dateConverter(widget.appointment?.appointmentDatetime, format: 'dd-MM-yyyy HH:mm') ?? '';
      if (widget.appointment?.service?.eddRequired != null &&
          widget.appointment?.service?.dueDateToggle == 1 &&
          dueDateController.controller.text != '') {
        calculateGestational();
      }
    }

    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (context.read<AuthController>().isSuperAdmin == false && widget.type == 'create') {
        ServiceBranchController.available(
          context,
          branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
        ).then((value) {
          if (responseCode(value.code)) {
            if (value.data != null) {
              for (service_branch_available_model.Data item in value.data?.data ?? []) {
                serviceList.add(DropdownAttribute(item.serviceBranchId ?? '', item.serviceName ?? ''));
              }
            }
            serviceList.sort((a, b) => a.name.compareTo(b.name));
            context.read<ServiceBranchController>().serviceBranchAvailableResponse = value.data;
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

  void calculateGestational() {
    try {
      gestationalResult = getGestationalStatusFromString(
        eddStr: dueDateController.controller.text,
        range: widget.appointment?.service?.eddRequired ?? selectedService?.eddRequired ?? '',
        appointmentDate: DateTime.parse(convertMalaysiaTimeToUtc(dateTimeController.text, plainFormat: true)),
      );
      rebuild.add(DateTime.now());
    } catch (e) {
      debugPrint('$e');
      rebuild.add(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return editBranch();
  }

  Row editBranch() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              constraints: const BoxConstraints(maxWidth: 840, maxHeight: 860),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 24, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header bar ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_note_rounded, size: 18, color: Color(0xFF6B7280)),
                          const SizedBox(width: 8),
                          Text(
                            widget.type == 'create' ? 'New Appointment' : 'Update Appointment',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          if (widget.appointment?.appointmentId != null) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${widget.appointment!.appointmentId!.substring(0, 8).toUpperCase()}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontFamily: 'monospace'),
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (widget.type == 'update')
                            CopyButton(
                              textToCopy:
                                  'Appointment Details\n\n${patientNameController.controller.text}${notNullOrEmptyString(widget.appointment?.user?.userNric) ? '\n${widget.appointment?.user?.userNric}' : ''}\n${patientContactNoController.controller.text}\n${patientEmailController.controller.text}\n${widget.appointment?.service?.serviceName}\n${formatToDisplayDate(dateTimeController.text)}\n${formatToDisplayTime(dateTimeController.text)}\n${widget.appointment?.branch?.branchName}\nCreated Date : ${dateConverter(widget.appointment?.createdDate)}\n',
                              tooltip: 'Copy Appointment Details',
                            ),
                          const SizedBox(width: 4),
                          CloseButton(onPressed: () => context.pop()),
                        ],
                      ),
                    ),
                    // ── Scrollable body ─────────────────────────────────────
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: const BoxConstraints(maxWidth: 760, minWidth: 580),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Consumer<ServiceBranchController>(
                                    builder: (context, serviceBranchController, _) {
                                      return StreamBuilder<DateTime>(
                                        stream: rebuild.stream,
                                        builder: (context, snapshot) {
                                          return Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                labelValue(
                                                  'Patient Details',
                                                  patientNameController.controller.text,
                                                  alignStart: true,
                                                ),
                                                if (notNullOrEmptyString(widget.appointment?.user?.userNric))
                                                  AppSelectableText(
                                                    widget.appointment?.user?.userNric ?? '',
                                                    style: AppTypography.bodyMedium(context),
                                                  ),
                                                AppSelectableText(
                                                  patientContactNoController.controller.text,
                                                  style: AppTypography.bodyMedium(context),
                                                ),
                                                AppSelectableText(
                                                  patientEmailController.controller.text,
                                                  style: AppTypography.bodyMedium(context),
                                                ),
                                                AppPadding.vertical(denominator: 1),
                                                _isLocked
                                                    ? appointmentNoteController.controller.text != ''
                                                          ? labelValue(
                                                              'Notes',
                                                              appointmentNoteController.controller.text,
                                                            )
                                                          : SizedBox()
                                                    : InputField(field: appointmentNoteController),
                                                AppPadding.vertical(denominator: 2),
                                                if ((widget.appointment?.service?.dueDateToggle == 1) ||
                                                    selectedService?.dueDateToggle == 1)
                                                  _isLocked
                                                      ? dateTimeController.text != ''
                                                            ? labelValue('Due Date', dateTimeController.text)
                                                            : SizedBox()
                                                      : GestureDetector(
                                                          onTap: () async {
                                                            dueDateCalendar();
                                                          },
                                                          child: ReadOnly(
                                                            InputField(field: dueDateController),
                                                            isEditable: false,
                                                          ),
                                                        ),
                                                if (((notNullOrEmptyString(widget.appointment?.service?.eddRequired) &&
                                                            widget.appointment?.service?.dueDateToggle == 1) ||
                                                        (selectedService?.dueDateToggle == 1 &&
                                                            selectedService?.eddRequired != null)) &&
                                                    dueDateController.controller.text != '')
                                                  StreamBuilder(
                                                    stream: rebuild.stream,
                                                    builder: (context, asyncSnapshot) {
                                                      if (dateTimeController.text == '') {
                                                        return Container(
                                                          margin: const EdgeInsets.only(top: 6),
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 7,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.withAlpha(18),
                                                            borderRadius: BorderRadius.circular(8),
                                                            border: Border.all(
                                                              color: Colors.grey.withAlpha(60),
                                                            ),
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                Icons.info_outline_rounded,
                                                                size: 13,
                                                                color: Colors.grey.shade500,
                                                              ),
                                                              const SizedBox(width: 6),
                                                              Flexible(
                                                                child: Text(
                                                                  'Select appointment date to check eligibility',
                                                                  style: TextStyle(
                                                                    fontSize: 12,
                                                                    color: Colors.grey.shade600,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        );
                                                      }
                                                      if (gestationalResult == null) return const SizedBox();
                                                      final color = gestationalStatusColor(gestationalResult?.status);
                                                      final isEligible =
                                                          gestationalResult?.status == GestationalEligibility.eligible;
                                                      return Container(
                                                        margin: const EdgeInsets.only(top: 6),
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 8,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: color.withAlpha(18),
                                                          borderRadius: BorderRadius.circular(8),
                                                          border: Border.all(color: color.withAlpha(60)),
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 1),
                                                              child: Icon(
                                                                isEligible
                                                                    ? Icons.check_circle_rounded
                                                                    : Icons.warning_amber_rounded,
                                                                size: 13,
                                                                color: color,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Flexible(
                                                              child: Text(
                                                                getGestationalStatusMessage(
                                                                      result: gestationalResult,
                                                                      range:
                                                                          widget.appointment?.service?.eddRequired ??
                                                                          selectedService?.eddRequired ??
                                                                          '',
                                                                      showRange: true,
                                                                    ) ??
                                                                    '',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: color,
                                                                  height: 1.4,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                if (widget.appointment?.service?.serviceBookingFee != null ||
                                                    (_service != null &&
                                                        notNullOrEmptyString(selectedService?.serviceBookingFee) ==
                                                            true) ||
                                                    (widget.type == 'update' && _status?.key == '6'))
                                                  Container(
                                                    padding: EdgeInsets.only(bottom: 8),
                                                    width: screenWidth1728(30),
                                                    child: StreamBuilder<DateTime>(
                                                      stream: fileRebuild.stream,
                                                      builder: (context, snapshot) {
                                                        return Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                          children: [
                                                            AppPadding.vertical(),
                                                            if (_status?.key == '6' &&
                                                                widget.appointment?.payment?.any(
                                                                      (element) => element.paymentType == 4,
                                                                    ) ==
                                                                    false) ...[
                                                              Container(
                                                                margin: const EdgeInsets.only(bottom: 8),
                                                                padding: const EdgeInsets.symmetric(
                                                                  horizontal: 12,
                                                                  vertical: 8,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFFFFF7ED),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(
                                                                    color: const Color(0xFFFB923C).withAlpha(80),
                                                                  ),
                                                                ),
                                                                child: const Row(
                                                                  children: [
                                                                    Icon(
                                                                      Icons.info_outline_rounded,
                                                                      size: 14,
                                                                      color: Color(0xFFEA580C),
                                                                    ),
                                                                    SizedBox(width: 6),
                                                                    Flexible(
                                                                      child: Text(
                                                                        'Refund document required — upload proof below',
                                                                        style: TextStyle(
                                                                          fontSize: 12,
                                                                          color: Color(0xFF9A3412),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                            if ((selectedFiles.isEmpty &&
                                                                    widget.type == 'create' &&
                                                                    (_service != null &&
                                                                        notNullOrEmptyString(
                                                                              selectedService?.serviceBookingFee,
                                                                            ) ==
                                                                            true)) ||
                                                                (selectedFiles.isEmpty &&
                                                                    widget.type == 'update' &&
                                                                    _status?.key == '6' &&
                                                                    widget.appointment?.payment?.any(
                                                                          (element) => element.paymentType == 4,
                                                                        ) ==
                                                                        false)) ...[
                                                              Column(
                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                children: [
                                                                  UploadDocumentsField(
                                                                    title: 'promotionPage'.tr(gender: 'browseFile'),
                                                                    fieldTitle: _status?.key == '6'
                                                                        ? 'appointmentPage'.tr(gender: 'refundProof')
                                                                        : 'appointmentPage'.tr(gender: 'paymentProof'),
                                                                    // tooltipText: 'promotionPage'.tr(gender: 'browse'),
                                                                    action: () async {
                                                                      documentErrorMessage.add(null);
                                                                      FilePickerResult? result = await FilePicker
                                                                          .platform
                                                                          .pickFiles();

                                                                      if (result != null) {
                                                                        PlatformFile file = result.files.first;
                                                                        if (supportedExtensions.contains(
                                                                          file.extension,
                                                                        )) {
                                                                          debugPrint(bytesToMB(file.size).toString());
                                                                          debugPrint(file.name);
                                                                          if (bytesToMB(file.size) < 1.0) {
                                                                            Uint8List? fileBytes =
                                                                                result.files.first.bytes;
                                                                            String fileName = result.files.first.name;

                                                                            selectedFiles.add(
                                                                              FileAttribute(
                                                                                name: fileName,
                                                                                value: fileBytes,
                                                                              ),
                                                                            );
                                                                            fileRebuild.add(DateTime.now());
                                                                          } else {
                                                                            showDialogError(
                                                                              context,
                                                                              'error'.tr(
                                                                                gender: 'err-21',
                                                                                args: [
                                                                                  fileSizeLimit.toStringAsFixed(0),
                                                                                ],
                                                                              ),
                                                                            );
                                                                          }
                                                                        } else {
                                                                          showDialogError(
                                                                            context,
                                                                            'error'.tr(gender: 'err-22'),
                                                                          );
                                                                        }
                                                                      } else {
                                                                        // User canceled the picker
                                                                      }
                                                                    },
                                                                    cancelAction: () {},
                                                                  ),
                                                                  StreamBuilder<String?>(
                                                                    stream: documentErrorMessage.stream,
                                                                    builder: (context, snapshot) {
                                                                      return snapshot.data == null
                                                                          ? SizedBox()
                                                                          : AppSelectableText(
                                                                              snapshot.data ?? '',
                                                                              style: AppTypography.bodyMedium(context)
                                                                                  .apply(
                                                                                    color: errorColor,
                                                                                    fontSizeDelta: -1,
                                                                                  ),
                                                                            );
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                            for (int index = 0; index < selectedFiles.length; index++)
                                                              Container(
                                                                margin: const EdgeInsets.only(top: 6),
                                                                padding: const EdgeInsets.symmetric(
                                                                  horizontal: 12,
                                                                  vertical: 9,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFFF0FDF4),
                                                                  borderRadius: BorderRadius.circular(8),
                                                                  border: Border.all(
                                                                    color: const Color(0xFF86EFAC),
                                                                  ),
                                                                ),
                                                                child: Row(
                                                                  children: [
                                                                    const Icon(
                                                                      Icons.insert_drive_file_rounded,
                                                                      size: 15,
                                                                      color: Color(0xFF16A34A),
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                    Expanded(
                                                                      child: GestureDetector(
                                                                        onTap: () {
                                                                          if (selectedFiles[index].path != null ||
                                                                              selectedFiles[index].value != null) {
                                                                            showDialog(
                                                                              context: context,
                                                                              builder: (BuildContext context) {
                                                                                return GestureDetector(
                                                                                  onTap: () => context.pop(),
                                                                                  child: Center(
                                                                                    child: Flexible(
                                                                                      child: CardContainer(
                                                                                        selectedFiles[index].value !=
                                                                                                null
                                                                                            ? Image.memory(
                                                                                                selectedFiles[index]
                                                                                                    .value!,
                                                                                              )
                                                                                            : selectedFiles[index]
                                                                                                        .path !=
                                                                                                    null
                                                                                            ? Padding(
                                                                                                padding: EdgeInsets.all(
                                                                                                  screenPadding,
                                                                                                ),
                                                                                                child: Image.network(
                                                                                                  '${Environment.imageUrl}${selectedFiles[index].path}',
                                                                                                ),
                                                                                              )
                                                                                            : const SizedBox(),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              },
                                                                            );
                                                                          }
                                                                        },
                                                                        child: Text(
                                                                          selectedFiles[index].name ?? '',
                                                                          style: const TextStyle(
                                                                            fontSize: 12.5,
                                                                            color: Color(0xFF16A34A),
                                                                            decoration: TextDecoration.underline,
                                                                            decorationColor: Color(0xFF16A34A),
                                                                          ),
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 4),
                                                                    GestureDetector(
                                                                      onTap: () {
                                                                        selectedFiles.removeAt(index);
                                                                        fileRebuild.add(DateTime.now());
                                                                      },
                                                                      child: const Icon(
                                                                        Icons.close_rounded,
                                                                        size: 15,
                                                                        color: Color(0xFF6B7280),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  AppPadding.horizontal(),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        if (widget.type == 'update')
                                          labelValue(
                                            'Branch',
                                            widget.appointment?.branch?.branchName ?? '',
                                            alignStart: true,
                                          ),
                                        if (widget.type == 'create')
                                          StreamBuilder<DateTime>(
                                            stream: rebuildDropdown.stream,
                                            builder: (context, snapshot) {
                                              return Consumer<AuthController>(
                                                builder: (context, authController, _) {
                                                  return Column(
                                                    children: [
                                                      AppDropdown(
                                                        attributeList: DropdownAttributeList(
                                                          authController.isSuperAdmin ? branches : [],
                                                          labelText: 'appointmentPage'.tr(gender: 'branch'),
                                                          isEditable: authController.isSuperAdmin,
                                                          fieldColor: authController.isSuperAdmin
                                                              ? null
                                                              : textFormFieldUneditableColor,
                                                          value: _appointmentBranch?.name,
                                                          onChanged: (p0) {
                                                            _appointmentBranch = p0;
                                                            _service = null;
                                                            serviceList = [];
                                                            availableDateTime = [];
                                                            dateTimeController.clear();
                                                            if (_appointmentBranch != null) {
                                                              ServiceBranchController.available(
                                                                context,
                                                                branchId: _appointmentBranch?.key,
                                                              ).then((value) {
                                                                if (responseCode(value.code)) {
                                                                  context
                                                                          .read<ServiceBranchController>()
                                                                          .serviceBranchAvailableResponse =
                                                                      value.data;
                                                                  if (value.data != null) {
                                                                    for (service_branch_available_model.Data item
                                                                        in value.data?.data ?? []) {
                                                                      serviceList.add(
                                                                        DropdownAttribute(
                                                                          item.serviceBranchId ?? '',
                                                                          item.serviceName ?? '',
                                                                        ),
                                                                      );
                                                                    }
                                                                  }
                                                                  serviceList.sort((a, b) => a.name.compareTo(b.name));
                                                                  rebuildDropdown.add(DateTime.now());
                                                                }
                                                              });
                                                            } else {
                                                              rebuildDropdown.add(DateTime.now());
                                                            }
                                                          },
                                                          width: 331,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        AppPadding.vertical(denominator: 2),
                                        if (widget.type == 'update') ...[
                                          labelValue(
                                            'Service',
                                            widget.appointment?.service?.serviceName ?? '',
                                            alignStart: true,
                                          ),
                                          AppSelectableText('RM ${widget.appointment?.service?.servicePrice ?? 0}'),
                                        ],
                                        if (widget.type == 'create')
                                          StreamBuilder<DateTime>(
                                            stream: rebuildDropdown.stream,
                                            builder: (context, snapshot) {
                                              return Consumer<ServiceBranchController>(
                                                builder: (context, serviceBranchController, _) {
                                                  return Row(
                                                    children: [
                                                      Expanded(
                                                        child: AppDropdown(
                                                          attributeList: DropdownAttributeList(
                                                            width: 331,
                                                            serviceList,
                                                            labelText: 'appointmentPage'.tr(gender: 'service'),
                                                            value: _service?.name,
                                                            fieldColor: widget.type == 'update'
                                                                ? textFormFieldUneditableColor
                                                                : null,
                                                            isEditable: widget.type == 'create',
                                                            onChanged: (p0) {
                                                              _service = p0;
                                                              rebuild.add(DateTime.now());
                                                              try {
                                                                _status = appointmentStatus.firstWhere(
                                                                  (element) => element.key == '1',
                                                                );
                                                                try {
                                                                  selectedService = context
                                                                      .read<ServiceBranchController>()
                                                                      .serviceBranchAvailableResponse
                                                                      ?.data
                                                                      ?.firstWhere((e) => e.serviceBranchId == p0?.key);
                                                                  rebuild.add(DateTime.now());
                                                                } catch (e) {
                                                                  debugPrint(e.toString());
                                                                }
                                                              } catch (e) {
                                                                debugPrint(e.toString());
                                                              }
                                                              ServiceBranchAvailableDtController.getAvailableSlot(
                                                                context,
                                                                serviceBranchId: _service?.key,
                                                              ).then((value) {
                                                                if (responseCode(value.code)) {
                                                                  context
                                                                          .read<ServiceBranchAvailableDtController>()
                                                                          .serviceBranchAvailableTimingResponse =
                                                                      value.data;
                                                                  availableDateTime = value.data?.slots ?? [];
                                                                  rebuild.add(DateTime.now());
                                                                  rebuildDropdown.add(DateTime.now());
                                                                }
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                          ),

                                        StreamBuilder(
                                          stream: rebuild.stream,
                                          builder: (context, _) {
                                            return Consumer<ServiceBranchController>(
                                              builder: (context, serviceBranchController, _) {
                                                if (_service != null &&
                                                    notNullOrEmptyString(selectedService?.serviceBookingFee) == true) {
                                                  return Container(
                                                    margin: const EdgeInsets.only(top: 6),
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFF7ED),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: const Color(0xFFFB923C).withAlpha(80)),
                                                    ),
                                                    child: const Row(
                                                      children: [
                                                        Icon(
                                                          Icons.info_outline_rounded,
                                                          size: 14,
                                                          color: Color(0xFFEA580C),
                                                        ),
                                                        SizedBox(width: 6),
                                                        Flexible(
                                                          child: Text(
                                                            'Booking fee required — upload payment proof below',
                                                            style: TextStyle(fontSize: 12, color: Color(0xFF9A3412)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                } else {
                                                  return const SizedBox();
                                                }
                                              },
                                            );
                                          },
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        StreamBuilder<DateTime>(
                                          stream: rebuildDropdown.stream,
                                          builder: (context, snapshot) {
                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    _isLocked
                                                        ? labelValue('Status', _status?.name ?? '')
                                                        : AppDropdown(
                                                            attributeList: DropdownAttributeList(
                                                              widget.type == 'update' ? getAppointmentStatus() : [],
                                                              isEditable: widget.type == 'update',
                                                              fieldColor: widget.type == 'update'
                                                                  ? null
                                                                  : textFormFieldUneditableColor,
                                                              labelText: 'appointmentPage'.tr(gender: 'status'),
                                                              value: _status?.name,
                                                              onChanged: (p0) {
                                                                _status = p0;
                                                                rebuild.add(DateTime.now());
                                                                rebuildDropdown.add(DateTime.now());
                                                              },
                                                              width: 331,
                                                            ),
                                                          ),
                                                  ],
                                                ),
                                                if (_status?.key == '2' || _status?.key == '6') ...[
                                                  const SizedBox(height: 10),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFF7ED),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: const Color(0xFFFB923C).withAlpha(80),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            const Icon(
                                                              Icons.policy_outlined,
                                                              size: 14,
                                                              color: Color(0xFFEA580C),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              _status?.key == '6'
                                                                  ? 'Refund Policy'
                                                                  : 'Cancellation Policy',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight: FontWeight.w700,
                                                                color: Color(0xFF9A3412),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 6),
                                                        const Text(
                                                          '• Each appointment may only be rescheduled once.\n'
                                                          '• Refunds, if approved, are processed within 5–7 business days.\n'
                                                          '• Klinik Aurora reserves the right to decline refund requests based on internal review.',
                                                          style: TextStyle(
                                                            fontSize: 11.5,
                                                            color: Color(0xFF9A3412),
                                                            height: 1.6,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          },
                                        ),
                                        AppPadding.vertical(),
                                        Consumer<ServiceBranchAvailableDtController>(
                                          builder: (context, snapshot, _) {
                                            return _isLocked
                                                ? labelValue('Slots', dateTimeController.text)
                                                : GestureDetector(
                                                    onTap: () async {
                                                      if (context.read<AuthController>().hasPermission(
                                                            'c54a2d91-499c-11f0-9169-bc24115a1342',
                                                          ) ==
                                                          false) {
                                                        if (context.read<AuthController>().isSuperAdmin &&
                                                            _appointmentBranch == null) {
                                                          showDialogError(
                                                            context,
                                                            ErrorMessage.required(
                                                              field: 'appointmentPage'.tr(gender: 'branch'),
                                                            ),
                                                          );
                                                        } else if (_appointmentBranch != null &&
                                                            (availableDateTime.isNotEmpty)) {
                                                          DateTime now = DateTime.now();
                                                          availableDateTime = removePastDates(availableDateTime);
                                                          availableDateTime.sort(
                                                            (a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)),
                                                          );
                                                          String? selectedDateTime = await showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              return Row(
                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                children: [
                                                                  Column(
                                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                                    children: [
                                                                      Container(
                                                                        constraints: BoxConstraints(
                                                                          maxWidth: screenWidth(80),
                                                                        ),
                                                                        child: CardContainer(
                                                                          Padding(
                                                                            padding: EdgeInsets.all(screenPadding),
                                                                            child: SelectionCalendarView(
                                                                              startMonth: now.month,
                                                                              year: now.year,
                                                                              initialDateTimes: availableDateTime,
                                                                            ),
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
                                                              formatDateTimeToDisplay(selectedDateTime) ??
                                                              dateConverter(
                                                                widget.appointment?.appointmentDatetime,
                                                                format: 'yyyy-MM-dd HH:mm',
                                                              ) ??
                                                              '';
                                                          calculateGestational();
                                                        } else if (widget.type == 'update' &&
                                                            availableDateTime.isEmpty) {
                                                          ServiceBranchAvailableDtController.getAvailableSlot(
                                                            context,
                                                            serviceBranchId: widget.appointment?.serviceBranchId,
                                                          ).then((value) async {
                                                            if (responseCode(value.code)) {
                                                              availableDateTime = value.data?.slots ?? [];
                                                              DateTime now = DateTime.now();
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
                                                                  formatDateTimeToDisplay(selectedDateTime) ??
                                                                  dateConverter(
                                                                    widget.appointment?.appointmentDatetime,
                                                                    format: 'yyyy-MM-dd HH:mm',
                                                                  ) ??
                                                                  '';
                                                              calculateGestational();
                                                              rebuildDropdown.add(DateTime.now());
                                                            }
                                                          });
                                                        } else if (_service == null) {
                                                          showDialogError(
                                                            context,
                                                            ErrorMessage.required(
                                                              field: 'appointmentPage'.tr(gender: 'service'),
                                                            ),
                                                          );
                                                        } else if (availableDateTime.isEmpty) {
                                                          showDialogError(context, 'No available slots');
                                                        } else {
                                                          showDialogError(
                                                            context,
                                                            ErrorMessage.required(
                                                              field: 'appointmentPage'.tr(gender: 'branch'),
                                                            ),
                                                          );
                                                        }
                                                      }
                                                    },
                                                    child: ReadOnly(
                                                      isEditable: false,
                                                      InputField(
                                                        field: InputFieldAttribute(
                                                          controller: dateTimeController,
                                                          labelText: 'appointmentPage'.tr(
                                                            gender: 'appointmentDateTime',
                                                          ),
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
                                  ),
                                ],
                              ),
                            ),
                            const Divider(color: Color(0xFFF3F4F6), height: 1),
                            const SizedBox(height: 20),
                            if (widget.type == 'update') extraInformation(),
                            const SizedBox(height: 16),
                            if (!_isLocked) ...[
                              StreamBuilder<DateTime>(
                                stream: rebuild.stream,
                                builder: (context, _) {
                                  final notes = <String>[];
                                  if (widget.type == 'update') {
                                    notes.add(
                                      'Changing the appointment slot will automatically set the status to Rescheduled.',
                                    );
                                  }
                                  if (_status?.key == '6') {
                                    notes.add(
                                      'Uploading a refund document will initiate the refund review process.',
                                    );
                                  }
                                  if (widget.type == 'create' &&
                                      _service != null &&
                                      notNullOrEmptyString(selectedService?.serviceBookingFee)) {
                                    notes.add(
                                      'Payment proof must be uploaded for services with a booking fee.',
                                    );
                                  }
                                  if (notes.isEmpty) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: notes
                                          .map(
                                            (note) => Padding(
                                              padding: const EdgeInsets.only(bottom: 3),
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '* ',
                                                    style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                                  ),
                                                  Flexible(
                                                    child: Text(
                                                      note,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF9CA3AF),
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  );
                                },
                              ),
                              Center(child: button()),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void dueDateCalendar() async {
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
      dialogSize: Size(screenWidthByBreakpoint(90, 70, 50), screenHeightByBreakpoint(90, 80, 50)),
      borderRadius: BorderRadius.circular(20),
    );
    if (results != null) {
      if (dueDateController.errorMessage != null) {
        dueDateController.errorMessage = null;
      }
      dueDateController.controller.text = dateConverter('${results.first}', format: 'dd-MM-yyyy') ?? '';
      calculateGestational();
    }
  }

  String? formatDateTimeToDisplay(String? input) {
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$');

    if (!regex.hasMatch(input ?? '')) {
      return input;
    }

    try {
      final inputFormat = DateFormat("yyyy-MM-dd HH:mm");
      final outputFormat = DateFormat("dd-MM-yyyy HH:mm");
      final dateTime = inputFormat.parse(input ?? '');
      return outputFormat.format(dateTime);
    } catch (e) {
      return input;
    }
  }

  List<DropdownAttribute> getAppointmentStatus() {
    if (context.read<AuthController>().hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342') == false) {
      return appointmentStatus;
    } else {
      return [DropdownAttribute('5', 'Completed')];
    }
  }

  Widget extraInformation() {
    final isCompleted = widget.appointment?.appointmentStatus == 5;
    final hasPaidBooking =
        widget.appointment?.payment?.any((e) => e.paymentStatus == 1) == true;
    final paidBookingEntry = hasPaidBooking
        ? widget.appointment!.payment!.firstWhere((e) => e.paymentStatus == 1)
        : null;
    final servicePrice = double.tryParse(
      '${widget.appointment?.service?.servicePrice ?? 0}',
    );
    final paidAmount = double.tryParse(paidBookingEntry?.paymentAmount ?? '0');

    // If completed, remaining balance = 0 (fully paid at clinic)
    final balance = isCompleted
        ? 0.0
        : (servicePrice != null && paidAmount != null)
        ? servicePrice - paidAmount
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Fee section ──────────────────────────────────────────────────────
        if (widget.type == 'update') ...[
          _extraSectionLabel('Fees & Payment'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _extraFeeCard(
                  label: 'Booking Fee',
                  value: paidBookingEntry != null
                      ? 'RM ${paidBookingEntry.paymentAmount}'
                      : (widget.appointment?.service?.serviceBookingFee != null
                            ? 'RM ${widget.appointment!.service!.serviceBookingFee}'
                            : 'N/A'),
                  icon: Icons.payments_outlined,
                  color: const Color(0xFF0369A1),
                  badge: showPaymentStatus(
                    context,
                    isCompleted
                        ? 1
                        : hasPaidBooking
                        ? 1
                        : 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _extraFeeCard(
                  label: 'Service Price',
                  value: servicePrice != null
                      ? 'RM ${servicePrice.toStringAsFixed(2)}'
                      : '—',
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          if (balance != null) ...[
            const SizedBox(height: 10),
            _extraFeeCard(
              label: isCompleted
                  ? 'Remaining Balance (Fully Paid)'
                  : 'Remaining Balance',
              value: 'RM ${balance.toStringAsFixed(2)}',
              icon: isCompleted || balance == 0
                  ? Icons.check_circle_outline_rounded
                  : Icons.account_balance_wallet_outlined,
              color: isCompleted || balance == 0
                  ? const Color(0xFF15803D)
                  : const Color(0xFFC2410C),
              fullWidth: true,
            ),
          ],
          if (paidBookingEntry != null) ...[
            const SizedBox(height: 8),
            _metaInfoRow(
              Icons.tag_rounded,
              'Payment ID',
              '${paidBookingEntry.paymentId}',
            ),
          ],
          // Payment proof
          if (selectedFiles.isNotEmpty ||
              (widget.type == 'update' &&
                  widget.appointment?.payment
                          ?.any((e) => e.paymentType == 2 && e.paymentStatus == 1) ==
                      true)) ...[
            const SizedBox(height: 12),
            _proofButton(
              label: 'appointmentPage'.tr(gender: 'paymentProof'),
              icon: Icons.receipt_outlined,
              color: const Color(0xFF0369A1),
              onTap: () => showDialog(
                context: context,
                builder: (_) => GestureDetector(
                  onTap: () => context.pop(),
                  child: Center(
                    child: CardContainer(
                      Padding(
                        padding: EdgeInsets.all(screenPadding),
                        child: Image.network(
                          '${Environment.imageUrl}${widget.appointment?.payment?.firstWhere((e) => e.paymentType == 2 && e.paymentStatus == 1).paymentAsset}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          // Refund proof
          if (widget.type == 'update' &&
              widget.appointment?.payment
                      ?.any((e) => e.paymentType == 4 && e.paymentStatus == 1) ==
                  true) ...[
            const SizedBox(height: 8),
            _proofButton(
              label: 'appointmentPage'.tr(gender: 'refundProof'),
              icon: Icons.undo_rounded,
              color: const Color(0xFFDC2626),
              onTap: () => showDialog(
                context: context,
                builder: (_) => GestureDetector(
                  onTap: () => context.pop(),
                  child: Center(
                    child: CardContainer(
                      Padding(
                        padding: EdgeInsets.all(screenPadding),
                        child: Image.network(
                          '${Environment.imageUrl}${widget.appointment?.payment?.firstWhere((e) => e.paymentType == 4 && e.paymentStatus == 1).paymentAsset}',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 16),
        ],
        // ── Feedback + Record Info ────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.appointment?.appointmentStatus == 5) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _extraSectionLabel('Patient Feedback'),
                    const SizedBox(height: 10),
                    AbsorbPointer(
                      child: RatingStars(
                        value: double.parse(
                          '${widget.appointment?.appointmentRating ?? 0}',
                        ),
                        onValueChanged: (v) {},
                        starBuilder: (index, color) =>
                            Icon(Icons.star, color: color),
                        starCount: 5,
                        starSize: 20,
                        valueLabelColor: const Color(0xff9b9b9b),
                        valueLabelTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w400,
                          fontSize: 12.0,
                        ),
                        valueLabelRadius: 10,
                        maxValue: 5,
                        starSpacing: 2,
                        maxValueVisibility: true,
                        valueLabelVisibility: true,
                        animationDuration: Duration(milliseconds: 1000),
                        valueLabelPadding:
                            const EdgeInsets.symmetric(vertical: 1, horizontal: 8),
                        valueLabelMargin: const EdgeInsets.only(right: 8),
                        starOffColor: const Color(0xffe7e8ea),
                        starColor: Colors.amber,
                      ),
                    ),
                    if (widget.appointment?.appointmentFeedback != null &&
                        widget.appointment!.appointmentFeedback!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.appointment!.appointmentFeedback!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF374151)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 20),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _extraSectionLabel('Record Info'),
                  const SizedBox(height: 10),
                  _metaInfoRow(
                    Icons.add_circle_outline,
                    'Created',
                    dateConverter(widget.appointment?.createdDate) ?? '—',
                  ),
                  if (widget.appointment?.modifiedDate != null) ...[
                    const SizedBox(height: 6),
                    _metaInfoRow(
                      Icons.edit_outlined,
                      'Last Updated',
                      dateConverter(widget.appointment?.modifiedDate) ?? '—',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _extraSectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _extraFeeCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    Widget? badge,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280)),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      badge,
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9CA3AF))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF374151))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _proofButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withAlpha(12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded,
                size: 12, color: color.withAlpha(160)),
          ],
        ),
      ),
    );
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }

  Widget labelValue(String label, String value, {bool alignStart = true}) {
    return Column(
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        AppSelectableText(label, style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1)),
        SizedBox(height: 2),
        AppSelectableText(value, style: AppTypography.bodyMedium(context)),
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
                  appointmentDateTime: convertMalaysiaTimeToUtc(dateTimeController.text, plainFormat: true),
                  appointmentNote: appointmentNoteController.controller.text,
                  customerDueDate: (() {
                    try {
                      return DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateFormat('dd-MM-yyyy').parseStrict(dueDateController.controller.text));
                    } catch (_) {
                      return dueDateController.controller.text;
                    }
                  })(),
                  appointmentStatus: _status != null ? int.parse(_status?.key ?? '0') : 0,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  if (_service != null &&
                      notNullOrEmptyString(selectedService?.serviceBookingFee) == true &&
                      kDebugMode == false) {
                    showLoading();
                    PaymentController.upload(
                      context,
                      value.data?.id ?? '',
                      widget.appointment?.user?.userId ?? '',
                      2,
                      selectedService?.serviceBookingFee ?? '50.00',
                      [selectedFiles[0]],
                    ).then((documentUploadResponse) {
                      dismissLoading();
                      if (widget.refreshData != null) {
                        widget.refreshData!();
                      } else {
                        context.pop();
                        showDialogSuccess(context, 'Appointment successfully created for the user');
                      }
                    });
                  } else {
                    dismissLoading();
                    if (widget.refreshData != null) {
                      widget.refreshData!();
                    } else {
                      context.pop();
                      showDialogSuccess(context, 'Appointment successfully created for the user');
                    }
                  }
                } else {
                  dismissLoading();
                  if (value.code != 500) {
                    showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                  }
                }
              });
            } else {
              if (convertMalaysiaTimeToUtc(dateTimeController.text, plainFormat: true) !=
                  widget.appointment?.appointmentDatetime) {
                _status = DropdownAttribute('3', 'Rescheduled');
              }
              AppointmentController.update(
                context,
                UpdateAppointmentRequest(
                  appointmentId: widget.appointment?.appointmentId,
                  userId: widget.appointment?.user?.userId,
                  appointmentDateTime: convertMalaysiaTimeToUtc(dateTimeController.text, plainFormat: true),
                  serviceBranchId: _service?.key,
                  appointmentNote: appointmentNoteController.controller.text,
                  customerDueDate: dueDateController.controller.text,
                  appointmentStatus: _status != null ? int.parse(_status?.key ?? '0') : 0,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  if (_status?.key == "6") {
                    showLoading();
                    PaymentController.upload(
                      context,
                      value.data?.id ?? '',
                      widget.appointment?.user?.userId ?? '',
                      4,
                      selectedService?.serviceBookingFee ?? '50.00',
                      [selectedFiles[0]],
                    ).then((documentUploadResponse) {
                      dismissLoading();
                      if (widget.refreshData != null) {
                        widget.refreshData!();
                        context.pop();
                        showDialogSuccess(context, 'Appointment successfully created for the user');
                      } else {
                        context.pop();
                        showDialogSuccess(context, 'Appointment successfully created for the user');
                      }
                    });
                  } else {
                    if (widget.refreshData != null) {
                      dismissLoading();
                      widget.refreshData!();
                    }
                    context.pop();
                    if (widget.type == 'update') {
                      showDialogSuccess(context, 'Successfully updated appointment');
                    } else {
                      showDialogSuccess(context, 'Successfully created new appointment');
                    }
                  }
                } else {
                  if (value.code != 500) {
                    showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                  }
                }
              });
            }
          }
        }, actionText: 'button'.tr(gender: widget.type)),
      ],
    );
  }

  void getLatestData() {
    AppointmentController()
        .get(
          context,
          1,
          100,
          status: widget.tabs,
          branchId: context.read<AuthController>().isSuperAdmin == true
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
    } else if (kDebugMode == false &&
        widget.type == 'create' &&
        _service != null &&
        notNullOrEmptyString(selectedService?.serviceBookingFee) == true &&
        selectedFiles.isEmpty) {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'appointmentPage'.tr(gender: 'paymentProof')));
    } else if (widget.type == 'update' &&
        _status?.key == '6' &&
        selectedFiles.isEmpty &&
        widget.appointment?.payment?.any((element) => element.paymentType == 4) == false) {
      temp = false;
      showDialogError(context, ErrorMessage.required(field: 'appointmentPage'.tr(gender: 'refundProof')));
    }
    setState(() {});
    return temp;
  }
}
