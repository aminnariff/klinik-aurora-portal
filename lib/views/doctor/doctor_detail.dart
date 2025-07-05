import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
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
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
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
    maxCharacter: 10,
    prefixIcon: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: screenPadding / 2, left: 12),
          child: const Text(
            '+60',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.0, color: textPrimaryColor),
          ),
        ),
      ],
    ),
  );
  final InputFieldAttribute _branchId = InputFieldAttribute(controller: TextEditingController());
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  DropdownAttribute? _selectedBranch;
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  FileAttribute selectedFile = FileAttribute();

  @override
  void initState() {
    if (widget.type == 'update') {
      _doctorName.controller.text = widget.doctor?.doctorName ?? '';
      _doctorPhone.controller.text = widget.doctor?.doctorPhone?.substring(1, widget.doctor?.doctorPhone?.length) ?? '';
      _branchId.controller.text = widget.doctor?.branchId ?? '';
      selectedFile = FileAttribute(path: widget.doctor?.doctorImage, name: widget.doctor?.doctorImage);
      try {
        branch_model.Data? branch = context.read<BranchController>().branchAllResponse?.data?.data?.firstWhere(
          (element) => element.branchId == _branchId.controller.text,
        );
        _selectedBranch = DropdownAttribute(_branchId.controller.text, branch?.branchName ?? '');
        rebuildDropdown.add(DateTime.now());
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (context.read<AuthController>().isSuperAdmin == false && widget.type == 'create') {
        try {
          branch_model.Data? item = context.read<BranchController>().branchAllResponse?.data?.data?.firstWhere(
            (element) =>
                element.branchId == context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
          );
          if (item != null) {
            _selectedBranch = DropdownAttribute(item.branchId ?? '', item.branchName ?? '');
            rebuildDropdown.add(DateTime.now());
          }
        } catch (e) {
          debugPrint(e.toString());
        }
      }
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
                            AppSelectableText('PIC Details', style: AppTypography.bodyLarge(context)),
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
                                  InputField(field: _doctorName),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: _doctorPhone),
                                  AppPadding.vertical(denominator: 2),
                                  Row(
                                    children: [
                                      StreamBuilder<DateTime>(
                                        stream: rebuildDropdown.stream,
                                        builder: (context, snapshot) {
                                          return AppDropdown(
                                            attributeList: DropdownAttributeList(
                                              [
                                                if (context.read<BranchController>().branchAllResponse?.data?.data !=
                                                    null)
                                                  for (branch_model.Data item
                                                      in context
                                                              .read<BranchController>()
                                                              .branchAllResponse
                                                              ?.data
                                                              ?.data ??
                                                          [])
                                                    DropdownAttribute(item.branchId ?? '', item.branchName ?? ''),
                                              ],
                                              isEditable: context.read<AuthController>().isSuperAdmin,
                                              fieldColor:
                                                  context.read<AuthController>().isSuperAdmin
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
                                      ),
                                    ],
                                  ),
                                  AppPadding.vertical(denominator: 2),
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
                                        selectedFile.value == null
                                            ? UploadDocumentsField(
                                              title: 'doctorPage'.tr(gender: 'browseFile'),
                                              fieldTitle: 'doctorPage'.tr(gender: 'doctorImage'),
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
                                                  child: Image.memory(selectedFile.value as Uint8List, height: 410),
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
                                        widget.doctor?.doctorImage == null
                                            ? selectedFile.name != null
                                                ? Stack(
                                                  alignment: Alignment.topRight,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () {
                                                        addPicture();
                                                      },
                                                      child: Image.memory(selectedFile.value as Uint8List, height: 410),
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
                                                  title: 'doctorPage'.tr(gender: 'browseFile'),
                                                  fieldTitle: 'bdoctorPage'.tr(gender: 'doctorImage'),
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
                                                '${Environment.imageUrl}${widget.doctor?.doctorImage}',
                                                height: 410,
                                                loadingBuilder: (
                                                  BuildContext context,
                                                  Widget child,
                                                  ImageChunkEvent? loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child; // The image is fully loaded
                                                  }
                                                  return Center(
                                                    child: CircularProgressIndicator(
                                                      // You can use any loading indicator
                                                      value:
                                                          loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded /
                                                                  (loadingProgress.expectedTotalBytes ?? 1)
                                                              : null,
                                                    ),
                                                  );
                                                },
                                                errorBuilder: (
                                                  BuildContext context,
                                                  Object error,
                                                  StackTrace? stackTrace,
                                                ) {
                                                  return Container(
                                                    padding: EdgeInsets.all(screenPadding),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      color: disabledColor,
                                                    ),
                                                    child: const Center(child: Icon(Icons.error, color: errorColor)),
                                                  );
                                                },
                                              ),
                                            ),
                                      AppPadding.vertical(denominator: 2),
                                    ],
                                  );
                                },
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
              DoctorController.create(
                context,
                CreateDoctorRequest(
                  doctorName: _doctorName.controller.text,
                  doctorPhone: '0${_doctorPhone.controller.text}',
                  branchId: _selectedBranch?.key,
                  // doctorImage: selectedFile,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  showLoading();
                  DoctorController.upload(context, value.data!.id!, selectedFile).then((value) {
                    dismissLoading();
                    if (responseCode(value.code)) {
                      getLatestData();
                    } else {
                      showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                    }
                  });
                } else {
                  showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            } else {
              DoctorController.update(
                context,
                UpdateDoctorRequest(
                  doctorId: widget.doctor?.doctorId,
                  doctorName: _doctorName.controller.text,
                  doctorPhone: '0${_doctorPhone.controller.text}',
                  doctorStatus: widget.doctor?.doctorStatus,
                  branchId: _selectedBranch?.key,
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  showLoading();
                  if (selectedFile.value != null) {
                    DoctorController.upload(context, widget.doctor!.doctorId!, selectedFile).then((value) {
                      dismissLoading();
                      if (responseCode(value.code)) {
                        getLatestData();
                      } else {
                        showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                      }
                    });
                  } else {
                    getLatestData();
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
        showDialogError(context, 'error'.tr(gender: 'err-22', args: [fileSizeLimit.toStringAsFixed(0)]));
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
      if (selectedFile.value == null) {
        temp = false;
        showDialogError(context, 'Please upload an image for the person in charge (PIC).');
      }
    }
    setState(() {});
    return temp;
  }
}
