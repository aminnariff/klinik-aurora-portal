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
import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/service/create_service_request.dart';
import 'package:klinik_aurora_portal/models/service/services_response.dart';
import 'package:klinik_aurora_portal/models/service/update_service_request.dart';
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
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
import 'package:provider/provider.dart';

class ServiceDetails extends StatefulWidget {
  final Data? service;
  final String type;
  const ServiceDetails({super.key, this.service, required this.type});

  @override
  State<ServiceDetails> createState() => _ServiceDetailsState();
}

class _ServiceDetailsState extends State<ServiceDetails> {
  final InputFieldAttribute serviceNameController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'servicesHomepage'.tr(gender: 'serviceName'),
  );
  final InputFieldAttribute serviceDescriptionController = InputFieldAttribute(
    controller: TextEditingController(),
    lineNumber: 5,
    maxCharacter: 500,
    labelText: 'servicesHomepage'.tr(gender: 'serviceDescription'),
  );
  final InputFieldAttribute servicePriceController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'servicesHomepage'.tr(gender: 'servicePrice'),
    isNumber: true,
  );
  final InputFieldAttribute serviceBookingFeeController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'servicesHomepage'.tr(gender: 'serviceBookingFee'),
    isNumber: true,
  );
  final InputFieldAttribute serviceTimeController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'servicesHomepage'.tr(gender: 'serviceTime'),
  );
  final InputFieldAttribute serviceCategoryController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'servicesHomepage'.tr(gender: 'serviceCategory'),
  );
  DropdownAttribute? _doctorType;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  FileAttribute selectedFile = FileAttribute();
  final List<TextEditingController> whatsappTemplateControllers = List.generate(6, (_) => TextEditingController());
  @override
  void initState() {
    if (widget.type == 'update') {
      serviceNameController.controller.text = widget.service?.serviceName ?? '';
      serviceDescriptionController.controller.text = widget.service?.serviceDescription ?? '';
      servicePriceController.controller.text = widget.service?.servicePrice ?? '';
      serviceBookingFeeController.controller.text = widget.service?.serviceBookingFee ?? '';
      serviceTimeController.controller.text = widget.service?.serviceTime ?? '';
      serviceCategoryController.controller.text = widget.service?.serviceCategory ?? '';
      selectedFile = FileAttribute(path: widget.service?.serviceImage, name: widget.service?.serviceImage);
      if (widget.service?.serviceTemplate != null) {
        for (int i = 0; i < widget.service!.serviceTemplate!.length && i < 3; i++) {
          whatsappTemplateControllers[i].text = widget.service!.serviceTemplate![i];
        }
      }
      if (widget.service?.doctorType == 1) {
        _doctorType = DropdownAttribute('1', 'Doctor');
      } else if (widget.service?.doctorType == 2) {
        _doctorType = DropdownAttribute('2', 'Sonographer');
      }
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
                            AppSelectableText('Service Details', style: AppTypography.bodyLarge(context)),
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
                                  InputField(field: serviceNameController),
                                  AppPadding.vertical(denominator: 2),
                                  TextField(
                                    maxLines: null,
                                    style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                    controller: serviceDescriptionController.controller,
                                    decoration: appInputDecoration(context, 'Description'),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: servicePriceController),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: serviceBookingFeeController),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: serviceTimeController),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(field: serviceCategoryController),
                                  AppPadding.vertical(denominator: 2),
                                  StreamBuilder<DateTime>(
                                    stream: rebuildDropdown.stream,
                                    builder: (context, snapshot) {
                                      return AppDropdown(
                                        attributeList: DropdownAttributeList(
                                          [DropdownAttribute('1', 'Doctor'), DropdownAttribute('2', 'Sonographer')],
                                          labelText: 'servicesHomepage'.tr(gender: 'doctorType'),
                                          value: _doctorType?.name,
                                          onChanged: (p0) {
                                            _doctorType = p0;
                                            rebuildDropdown.add(DateTime.now());
                                          },
                                          width: screenWidthByBreakpoint(90, 70, 26),
                                        ),
                                      );
                                    },
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "WhatsApp Templates (max 6)",
                                        style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                                      ),
                                      RichText(
                                        text: TextSpan(
                                          style: AppTypography.bodyMedium(context).apply(),
                                          children: [
                                            const TextSpan(text: "Tip: Use "),
                                            TextSpan(
                                              text:
                                                  "{{name}}, {{service}}, {{branchName}}, {{formattedDate}}, {{formattedTime}}",
                                              style: AppTypography.bodyMedium(
                                                context,
                                              ).apply(color: primary, fontWeightDelta: 1),
                                            ),
                                            const TextSpan(
                                              text: " to auto-fill appointment info. Click a tag below to insert.",
                                            ),
                                          ],
                                        ),
                                      ),
                                      ...List.generate(6, (index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: TextFormField(
                                            controller: whatsappTemplateControllers[index],
                                            maxLines: 6,
                                            style: AppTypography.bodyMedium(context),
                                            decoration: appInputDecoration(context, "Template ${index + 1}"),
                                          ),
                                        );
                                      }),
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
                                                title: 'servicesHomepage'.tr(gender: 'browseFile'),
                                                fieldTitle: 'servicesHomepage'.tr(gender: 'doctorImage'),
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
                                      if (widget.type == 'update') ...[
                                        widget.service?.serviceImage == null
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
                                                            height: 410,
                                                          ),
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
                                                      title: 'servicesHomepage'.tr(gender: 'browseFile'),
                                                      fieldTitle: 'bservicesHomepage'.tr(gender: 'doctorImage'),
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
                                                  '${Environment.imageUrl}${widget.service?.serviceImage}',
                                                  height: 410,
                                                  loadingBuilder:
                                                      (
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
                                                            value: loadingProgress.expectedTotalBytes != null
                                                                ? loadingProgress.cumulativeBytesLoaded /
                                                                      (loadingProgress.expectedTotalBytes ?? 1)
                                                                : null,
                                                          ),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (BuildContext context, Object error, StackTrace? stackTrace) {
                                                        return Container(
                                                          padding: EdgeInsets.all(screenPadding),
                                                          decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(12),
                                                            color: disabledColor,
                                                          ),
                                                          child: const Center(
                                                            child: Icon(Icons.error, color: errorColor),
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                        AppPadding.vertical(denominator: 2),
                                        Row(
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Created Date',
                                                  style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                                                ),
                                                Text(
                                                  '${dateConverter(widget.service?.createdDate)}',
                                                  style: AppTypography.bodyMedium(context).apply(),
                                                ),
                                                AppPadding.vertical(denominator: 2),
                                                Text(
                                                  'Last Updated Date',
                                                  style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                                                ),
                                                Text(
                                                  '${dateConverter(widget.service?.modifiedDate)}',
                                                  style: AppTypography.bodyMedium(context).apply(),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
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
              ServiceController.create(
                context,
                CreateServiceRequest(
                  serviceName: serviceNameController.controller.text,
                  serviceDescription: serviceDescriptionController.controller.text,
                  servicePrice: servicePriceController.controller.text == ''
                      ? null
                      : double.parse(servicePriceController.controller.text),
                  serviceBookingFee: serviceBookingFeeController.controller.text == ''
                      ? null
                      : double.parse(serviceBookingFeeController.controller.text),
                  serviceTime: serviceTimeController.controller.text,
                  serviceCategory: serviceCategoryController.controller.text,
                  serviceStatus: 1,
                  doctorType: int.parse(_doctorType?.key ?? "1"),
                  serviceTemplate: whatsappTemplateControllers
                      .map((c) => c.text.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  showLoading();
                  if (selectedFile.name != null) {
                    ServiceController.upload(context, value.data!.id!, selectedFile).then((value) {
                      dismissLoading();
                      if (responseCode(value.code)) {
                        getLatestData();
                      } else {
                        showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                      }
                    });
                  } else {
                    getLatestData();
                  }
                } else {
                  showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            } else {
              ServiceController.update(
                context,
                UpdateServiceRequest(
                  serviceId: widget.service?.serviceId,
                  serviceStatus: widget.service?.serviceStatus,
                  serviceName: serviceNameController.controller.text,
                  serviceDescription: serviceDescriptionController.controller.text,
                  servicePrice: servicePriceController.controller.text == ''
                      ? null
                      : double.parse(servicePriceController.controller.text),
                  serviceBookingFee: serviceBookingFeeController.controller.text == ''
                      ? null
                      : double.parse(serviceBookingFeeController.controller.text),
                  serviceTime: serviceTimeController.controller.text,
                  serviceCategory: serviceCategoryController.controller.text,
                  doctorType: int.parse(_doctorType?.key ?? "1"),
                  serviceTemplate: whatsappTemplateControllers
                      .map((c) => c.text.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                ),
              ).then((value) {
                dismissLoading();
                if (responseCode(value.code)) {
                  showLoading();
                  if (selectedFile.value != null) {
                    ServiceController.upload(context, widget.service!.serviceId!, selectedFile).then((value) {
                      dismissLoading();
                      if (responseCode(value.code)) {
                        getLatestData();
                      } else {
                        showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                      }
                    });
                  } else {
                    getLatestData();
                  }
                } else {
                  showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            }
          }
        }, actionText: 'button'.tr(gender: widget.type)),
      ],
    );
  }

  getLatestData() {
    ServiceController.getAll(context, 1, 100).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<ServiceController>().servicesResponse = value.data;
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated Service');
        } else {
          showDialogSuccess(context, 'Successfully created new Service');
        }
      } else {
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated Service');
        } else {
          showDialogSuccess(context, 'Successfully created new Service');
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
        showDialogError(context, 'error'.tr(gender: 'err-22'));
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
    if (serviceNameController.controller.text == '') {
      temp = false;
      serviceNameController.errorMessage = ErrorMessage.required(field: serviceNameController.labelText);
    }
    if (serviceDescriptionController.controller.text == '') {
      temp = false;
      serviceDescriptionController.errorMessage = ErrorMessage.required(field: serviceDescriptionController.labelText);
    }
    // if (servicePriceController.controller.text == '') {
    //   temp = false;
    //   servicePriceController.errorMessage = ErrorMessage.required(field: servicePriceController.labelText);
    // }
    if (serviceTimeController.controller.text == '') {
      temp = false;
      serviceTimeController.errorMessage = ErrorMessage.required(field: serviceTimeController.labelText);
    }
    if (serviceCategoryController.controller.text == '') {
      temp = false;
      serviceCategoryController.errorMessage = ErrorMessage.required(field: serviceCategoryController.labelText);
    }
    if (widget.type == 'create') {
      if (selectedFile.value == null) {
        temp = false;
        showDialogError(context, 'Please upload an image for the Service.');
      }
    }
    setState(() {});
    return temp;
  }
}
