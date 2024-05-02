import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
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
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class DoctorDetails extends StatefulWidget {
  final Data? doctor;
  final String type;
  const DoctorDetails({super.key, this.doctor, required this.type});

  @override
  State<DoctorDetails> createState() => _DoctorDetailsState();
}

class _DoctorDetailsState extends State<DoctorDetails> {
  final TextEditingController _doctorName = TextEditingController();
  final TextEditingController _doctorPhone = TextEditingController();
  final TextEditingController _branchId = TextEditingController();
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  DropdownAttribute? _selectedBranch;
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  FileAttribute selectedFile = FileAttribute();

  @override
  void initState() {
    if (widget.type == 'update') {
      _doctorName.text = widget.doctor?.doctorName ?? '';
      _doctorPhone.text = widget.doctor?.doctorPhone?.substring(1, widget.doctor?.doctorPhone?.length) ?? '';
      try {
        branch_model.Data? branch = context
            .read<BranchController>()
            .branchAllResponse
            ?.data
            ?.data
            ?.firstWhere((element) => element.branchId == _branchId.text);
        setState(() {
          _selectedBranch = DropdownAttribute(branch?.branchId ?? '', branch?.branchName ?? '');
        });
      } catch (e) {
        debugPrint(e.toString());
      }
      // selectedFile = FileAttribute(path: widget.branch?.branchImage, name: widget.branch?.branchImage);
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
                            AppSelectableText(
                              'Branch Details',
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
                                      controller: _doctorName,
                                      labelText: 'doctorPage'.tr(gender: 'doctorName'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _doctorPhone,
                                      labelText: 'information'.tr(gender: 'phoneNo'),
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
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 15.0, color: textPrimaryColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                        // if (widget.type == 'create') ...[
                                        //   selectedFile.value == null
                                        //       ? UploadDocumentsField(
                                        //           title: 'branchImage'.tr(gender: 'browseFile'),
                                        //           fieldTitle: 'branchPage'.tr(gender: 'branchImage'),
                                        //           // tooltipText: 'promotionPage'.tr(gender: 'browse'),
                                        //           action: () {
                                        //             addPicture();
                                        //           },
                                        //           cancelAction: () {},
                                        //         )
                                        //       : Stack(
                                        //           alignment: Alignment.topRight,
                                        //           children: [
                                        //             GestureDetector(
                                        //               onTap: () {
                                        //                 addPicture();
                                        //               },
                                        //               child: Image.memory(
                                        //                 selectedFile.value as Uint8List,
                                        //               ),
                                        //             ),
                                        //             IconButton(
                                        //               onPressed: () {
                                        //                 selectedFile = FileAttribute();
                                        //                 fileRebuild.add(DateTime.now());
                                        //               },
                                        //               icon: const Icon(
                                        //                 Icons.close,
                                        //               ),
                                        //             )
                                        //           ],
                                        //         ),
                                        // ],
                                        // if (widget.type == 'update')
                                        //   widget.branch?.branchImage == null
                                        //       ? selectedFile.name != null
                                        //           ? Stack(
                                        //               alignment: Alignment.topRight,
                                        //               children: [
                                        //                 GestureDetector(
                                        //                   onTap: () {
                                        //                     addPicture();
                                        //                   },
                                        //                   child: Image.memory(
                                        //                     selectedFile.value as Uint8List,
                                        //                   ),
                                        //                 ),
                                        //                 IconButton(
                                        //                   onPressed: () {
                                        //                     selectedFile = FileAttribute();
                                        //                     fileRebuild.add(DateTime.now());
                                        //                   },
                                        //                   icon: const Icon(
                                        //                     Icons.close,
                                        //                   ),
                                        //                 )
                                        //               ],
                                        //             )
                                        //           : UploadDocumentsField(
                                        //               title: 'branchImage'.tr(gender: 'browseFile'),
                                        //               fieldTitle: 'branchPage'.tr(gender: 'branchImage'),
                                        //               // tooltipText: 'promotionPage'.tr(gender: 'browse'),
                                        //               action: () {
                                        //                 addPicture();
                                        //               },
                                        //               cancelAction: () {},
                                        //             )
                                        //       : GestureDetector(
                                        //           onTap: () {
                                        //             addPicture();
                                        //           },
                                        //           child: Image.network(
                                        //             '${Environment.imageUrl}${widget.branch?.branchImage}',
                                        //           ),
                                        //         ),
                                        // AppPadding.vertical(denominator: 2),
                                        Row(
                                          children: [
                                            AppDropdown(
                                              attributeList: DropdownAttributeList(
                                                [
                                                  if (context.read<BranchController>().branchAllResponse?.data?.data !=
                                                      null)
                                                    for (branch_model.Data item in context
                                                            .read<BranchController>()
                                                            .branchAllResponse
                                                            ?.data
                                                            ?.data ??
                                                        [])
                                                      DropdownAttribute(item.branchId ?? '', item.branchName ?? ''),
                                                ],
                                                onChanged: (selected) {
                                                  setState(() {
                                                    _selectedBranch = selected;
                                                    _branchId.text = selected!.name;
                                                  });
                                                },
                                                value: _selectedBranch?.name,
                                                width: screenWidth1728(30),
                                              ),
                                            ),
                                          ],
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                      ],
                                    );
                                  }),
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
        Button(
          () {
            showLoading();
            if (widget.type == 'create') {
              DoctorController.create(
                context,
                CreateDoctorRequest(
                  doctorName: _doctorName.text,
                  doctorPhone: _doctorPhone.text,
                  // branchImage: selectedFile,
                ),
              ).then((value) {
                if (responseCode(value.code)) {
                  DoctorController.get(context).then((value) {
                    dismissLoading();
                    if (responseCode(value.code)) {
                      context.read<DoctorController>().doctorBranchResponse = value.data;
                      context.pop();
                      showDialogSuccess(context, 'Successfully created new PIC');
                    } else {
                      context.pop();
                      showDialogSuccess(context, 'Successfully created new PIC');
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
                  doctorName: _doctorName.text,
                  doctorPhone: _doctorPhone.text,
                  // branchImage: selectedFile,
                ),
              ).then((value) {
                if (responseCode(value.code)) {
                  DoctorController.get(context).then((value) {
                    dismissLoading();
                    if (responseCode(value.code)) {
                      context.read<DoctorController>().doctorBranchResponse = value.data;
                      context.pop();
                      showDialogSuccess(context, 'Successfully created new PIC');
                    } else {
                      context.pop();
                      showDialogSuccess(context, 'Successfully created new PIC');
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
    );
  }

  addPicture() async {
    documentErrorMessage.add(null);
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      if (supportedExtensions.contains(file.extension)) {
        debugPrint(bytesToMB(file.size).toString());
        debugPrint(file.name);
        if (bytesToMB(file.size) < 5.0) {
          Uint8List? fileBytes = result.files.first.bytes;
          String fileName = result.files.first.name;

          selectedFile = FileAttribute(name: fileName, value: fileBytes);
          fileRebuild.add(DateTime.now());
        } else {
          documentErrorMessage.add('error'.tr(gender: 'err-21', args: [fileSizeLimit.toStringAsFixed(0)]));
        }
      } else {
        documentErrorMessage.add('error'.tr(gender: 'err-22'));
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
