import 'dart:async';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';
import 'package:klinik_aurora_portal/models/branch/create_branch_request.dart';
import 'package:klinik_aurora_portal/models/branch/update_branch_request.dart';
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
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
import 'package:provider/provider.dart';

class BranchDetail extends StatefulWidget {
  final Data? branch;
  final String type;
  const BranchDetail({super.key, this.branch, required this.type});

  @override
  State<BranchDetail> createState() => _BranchDetailState();
}

class _BranchDetailState extends State<BranchDetail> {
  final TextEditingController _branchName = TextEditingController();
  final TextEditingController _branchCode = TextEditingController();
  final TextEditingController _city = TextEditingController();
  final TextEditingController _branchId = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _postcode = TextEditingController();
  final TextEditingController _branchPhone = TextEditingController();
  final TextEditingController _state = TextEditingController();
  final ValueNotifier<bool> _branchStatus = ValueNotifier(false);
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  FileAttribute selectedFile = FileAttribute();

  @override
  void initState() {
    if (widget.type == 'update') {
      _branchName.text = widget.branch?.branchName ?? '';
      // _branchCode.text = widget.branch?.branchFullname ?? '';
      _branchId.text = widget.branch?.branchId ?? '';
      _postcode.text = widget.branch?.postcode?.toString() ?? '0';
      _address.text = widget.branch?.address ?? '';
      _city.text = widget.branch?.city ?? '';
      _branchPhone.text = widget.branch?.phoneNumber?.substring(1, widget.branch?.phoneNumber?.length) ?? '';
      _state.text = widget.branch?.state ?? '';
      _branchStatus.value = widget.branch?.branchStatus == 1;
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
                                      controller: _branchName,
                                      labelText: 'branchPage'.tr(gender: 'branchName'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _branchCode,
                                      labelText: 'branchPage'.tr(gender: 'branchCode'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _address,
                                      labelText: 'information'.tr(gender: 'address'),
                                      isEmail: true,
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          flex: 1,
                                          child: InputField(
                                            field: InputFieldAttribute(
                                              controller: _postcode,
                                              labelText: 'information'.tr(gender: 'postalCode'),
                                              isEmail: true,
                                            ),
                                          ),
                                        ),
                                        AppPadding.horizontal(denominator: 2),
                                        Flexible(
                                          flex: 2,
                                          child: InputField(
                                            field: InputFieldAttribute(
                                              controller: _city,
                                              labelText: 'information'.tr(gender: 'city'),
                                              isEmail: true,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  AppDropdown(
                                    attributeList: DropdownAttributeList(
                                      states,
                                      onChanged: (selected) {
                                        setState(() {
                                          _state.text = selected!.key;
                                        });
                                      },
                                      value: _state.text,
                                      width: screenWidth1728(30),
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
                                        if (widget.type == 'create') ...[
                                          selectedFile.value == null
                                              ? UploadDocumentsField(
                                                  title: 'branchImage'.tr(gender: 'browseFile'),
                                                  fieldTitle: 'branchPage'.tr(gender: 'branchImage'),
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
                                                      child: Image.memory(
                                                        selectedFile.value as Uint8List,
                                                      ),
                                                    ),
                                                    IconButton(
                                                      onPressed: () {
                                                        selectedFile = FileAttribute();
                                                        fileRebuild.add(DateTime.now());
                                                      },
                                                      icon: const Icon(
                                                        Icons.close,
                                                      ),
                                                    )
                                                  ],
                                                ),
                                        ],
                                        if (widget.type == 'update')
                                          widget.branch?.branchImage == null
                                              ? selectedFile.name != null
                                                  ? Stack(
                                                      alignment: Alignment.topRight,
                                                      children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            addPicture();
                                                          },
                                                          child: Image.memory(
                                                            selectedFile.value as Uint8List,
                                                          ),
                                                        ),
                                                        IconButton(
                                                          onPressed: () {
                                                            selectedFile = FileAttribute();
                                                            fileRebuild.add(DateTime.now());
                                                          },
                                                          icon: const Icon(
                                                            Icons.close,
                                                          ),
                                                        )
                                                      ],
                                                    )
                                                  : UploadDocumentsField(
                                                      title: 'branchImage'.tr(gender: 'browseFile'),
                                                      fieldTitle: 'branchPage'.tr(gender: 'branchImage'),
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
                                                    '${Environment.imageUrl}${widget.branch?.branchImage}',
                                                  ),
                                                ),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(
                                          field: InputFieldAttribute(
                                            controller: _branchPhone,
                                            labelText: 'branchPage'.tr(gender: 'phoneNo'),
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
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 15.0,
                                                        color: textPrimaryColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                      ],
                                    );
                                  }),
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
                                if (widget.type == 'create') {
                                  BranchController.create(
                                    CreateBranchRequest(
                                      branchName: _branchName.text,
                                      branchCode: _branchCode.text,
                                      phoneNumber: _branchPhone.text,
                                      address: _address.text,
                                      city: _city.text,
                                      postcode: _postcode.text,
                                      state: _state.text,
                                      branchImage: selectedFile,
                                    ),
                                  ).then((value) {
                                    if (responseCode(value.code)) {
                                      BranchController.getAll(
                                        context,
                                      ).then((value) {
                                        dismissLoading();
                                        if (responseCode(value.code)) {
                                          context.read<BranchController>().branchAllResponse = value;
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully created new branch');
                                        } else {
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully created new branch');
                                        }
                                      });
                                    } else {
                                      showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                    }
                                  });
                                } else {
                                  BranchController.update(
                                    UpdateBranchRequest(
                                      branchId: widget.branch?.branchId ?? '',
                                      branchName: _branchName.text,
                                      phoneNumber: _branchPhone.text,
                                      address: _address.text,
                                      city: _city.text,
                                      postcode: _postcode.text,
                                      state: _state.text,
                                      branchImage: selectedFile,
                                    ),
                                  ).then((value) {
                                    if (responseCode(value.code)) {
                                      BranchController.getAll(
                                        context,
                                      ).then((value) {
                                        dismissLoading();
                                        if (responseCode(value.code)) {
                                          context.read<BranchController>().branchAllResponse = value;
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully created new branch');
                                        } else {
                                          context.pop();
                                          showDialogSuccess(context, 'Successfully created new branch');
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
