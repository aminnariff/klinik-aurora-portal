import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/doctor/doctor_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/doctor/create_doctor_request.dart';
import 'package:klinik_aurora_portal/models/doctor/doctor_branch_response.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_request.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_image_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class DoctorDetails extends StatefulWidget {
  final Data? doctor;
  final String type;
  const DoctorDetails({super.key, this.doctor, required this.type});

  @override
  State<DoctorDetails> createState() => _DoctorDetailsState();
}

class _DoctorDetailsState extends State<DoctorDetails> {
  final InputFieldAttribute _doctorName = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'doctorPage'.tr(gender: 'doctorName'),
  );
  final InputFieldAttribute _doctorPhone = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'doctorPage'.tr(gender: 'phoneNo'),
    isNumber: true,
  );
  final InputFieldAttribute _doctorImage = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'doctorPage'.tr(gender: 'doctorImage'),
    hintText: 'https://... or upload photo',
  );
  final InputFieldAttribute _branchId = InputFieldAttribute(controller: TextEditingController());
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  DropdownAttribute? _selectedBranch;
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  FileAttribute selectedFile = FileAttribute();

  @override
  void initState() {
    super.initState();
    try {
      if (widget.type == 'update') {
        _doctorName.controller.text = widget.doctor?.doctorName ?? '';
        _doctorPhone.controller.text = widget.doctor?.doctorPhone ?? '';
        _branchId.controller.text = widget.doctor?.branchId ?? '';
        _doctorImage.controller.text = widget.doctor?.doctorImage ?? '';
        selectedFile = FileAttribute(path: widget.doctor?.doctorImage, name: widget.doctor?.doctorImage);
        _selectedBranch = DropdownAttribute(widget.doctor?.branchId ?? '', widget.doctor?.branchName ?? '');
        rebuildDropdown.add(DateTime.now());
      }

      SchedulerBinding.instance.scheduleFrameCallback((_) {
        try {
          if (context.read<AuthController>().isSuperAdmin == false && widget.type == 'create') {
            branch_model.Data? item = context.read<BranchController>().branchAllResponse?.data?.data?.firstWhere(
              (element) =>
                  element.branchId == context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
            );
            if (item != null) {
              _selectedBranch = DropdownAttribute(item.branchId ?? '', item.branchName ?? '');
              rebuildDropdown.add(DateTime.now());
            }
          }
        } catch (e) {
          debugPrint('DoctorDetails scheduleFrameCallback error: $e');
        }
      });
    } catch (e) {
      debugPrint('DoctorDetails initState error: $e');
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
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 18, color: Color(0xFF6B7280)),
                              const SizedBox(width: 8),
                              Text(
                                widget.type == 'create' ? 'New PIC' : 'Edit PIC',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              const Spacer(),
                              CloseButton(onPressed: () => context.pop()),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppPadding.vertical(denominator: 2),
                              Wrap(
                                spacing: screenPadding,
                                runSpacing: screenPaddingVertical(),
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: [
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      children: [
                                        InputField(field: _doctorName),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(field: _doctorPhone),
                                        AppPadding.vertical(denominator: 2),
                                        Row(
                                          children: [
                                            StreamBuilder<DateTime>(
                                              stream: rebuildDropdown.stream,
                                              builder: (context, snapshot) {
                                                return Consumer<BranchController>(
                                                  builder: (context, branchCtrl, _) {
                                                    final branches = branchCtrl.branchAllResponse?.data?.data ?? [];
                                                    return AppDropdown(
                                                      attributeList: DropdownAttributeList(
                                                        branches
                                                            .map(
                                                              (item) => DropdownAttribute(
                                                                item.branchId ?? '',
                                                                item.branchName ?? '',
                                                              ),
                                                            )
                                                            .toList(),
                                                        isEditable: context.read<AuthController>().isSuperAdmin,
                                                        fieldColor: context.read<AuthController>().isSuperAdmin
                                                            ? textFormFieldEditableColor
                                                            : textFormFieldUneditableColor,
                                                        onChanged: (selected) {
                                                          if (_branchId.errorMessage != null) {
                                                            _branchId.errorMessage = null;
                                                          }
                                                          _selectedBranch = selected;
                                                          _branchId.controller.text = selected!.name;
                                                          rebuildDropdown.add(DateTime.now());
                                                        },
                                                        errorMessage: _branchId.errorMessage,
                                                        value: _selectedBranch?.name,
                                                        width: screenWidth1728(26),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: AppImageField(
                                      field: _doctorImage,
                                      folder: 'doctor',
                                      previewHeight: 180,
                                      previewWidth: 180,
                                    ),
                                  ),
                                ],
                              ),
                              AppPadding.vertical(denominator: 1 / 1.5),
                              button(),
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
            final imageVal = _doctorImage.controller.text.trim();
            final finalDoctorImage = imageVal.isEmpty ? null : imageVal;

            if (widget.type == 'create') {
              DoctorController.create(
                context,
                CreateDoctorRequest(
                  doctorName: _doctorName.controller.text,
                  doctorPhone: _doctorPhone.controller.text.trim(),
                  branchId: _selectedBranch?.key,
                  doctorImage: finalDoctorImage,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  getLatestData();
                } else {
                  showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                }
              }).catchError((e) {
                dismissLoading();
                showDialogError(context, e.toString());
              });
            } else {
              DoctorController.update(
                context,
                UpdateDoctorRequest(
                  doctorId: widget.doctor?.doctorId,
                  doctorName: _doctorName.controller.text,
                  doctorPhone: _doctorPhone.controller.text.trim(),
                  doctorStatus: widget.doctor?.doctorStatus,
                  branchId: _selectedBranch?.key,
                  doctorImage: finalDoctorImage,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  getLatestData();
                } else {
                  showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                }
              }).catchError((e) {
                dismissLoading();
                showDialogError(context, e.toString());
              });
            }
          }
        }, actionText: 'button'.tr(gender: widget.type)),
      ],
    );
  }

  void getLatestData() {
    DoctorController.get(context, 1, pageSize).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<DoctorController>().doctorBranchResponse = value.data;
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated PIC');
        } else {
          showDialogSuccess(context, 'Successfully created new PIC');
        }
      } else {
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated PIC');
        } else {
          showDialogSuccess(context, 'Successfully created new PIC');
        }
      }
    });
  }

  bool validate() {
    bool temp = true;
    if (_doctorName.controller.text == '') {
      temp = false;
      _doctorName.errorMessage = ErrorMessage.required(field: _doctorName.labelText);
    }
    if (_doctorPhone.controller.text == '') {
      temp = false;
      _doctorPhone.errorMessage = ErrorMessage.required(field: _doctorPhone.labelText);
    }
    if (_branchId.controller.text == '') {
      temp = false;
      _branchId.errorMessage = ErrorMessage.required(field: _branchId.labelText);
    }
    if (widget.type == 'create') {
      if (_doctorImage.controller.text.trim().isEmpty) {
        temp = false;
        showDialogError(context, 'Please upload or provide an image for the person in charge (PIC).');
      }
    }
    setState(() {});
    return temp;
  }
}
