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
import 'package:klinik_aurora_portal/views/widgets/size.dart';
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
    labelText: 'servicesHomepage'.tr(gender: 'estimatedDuration'),
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
  int _activeTemplate = 0;
  final StreamController<DateTime> templateRebuild = StreamController.broadcast();
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
      } else if (widget.service?.doctorType == 3) {
        _doctorType = DropdownAttribute('3', 'Therapist');
      } else if (widget.service?.doctorType == 4) {
        _doctorType = DropdownAttribute('4', 'Spa Therapist');
      } else if (widget.service?.doctorType == 5) {
        _doctorType = DropdownAttribute('5', 'Dietitian');
      }
    }
    super.initState();
  }

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 13,
          decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
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
                        // ── Header ──────────────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.medical_services_rounded, size: 16, color: Color(0xFF6366F1)),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.type == 'create' ? 'New Service' : 'Edit Service',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    widget.type == 'create'
                                        ? 'Set up a new service with pricing & templates'
                                        : 'Update service details, pricing, and templates',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              CloseButton(onPressed: () => context.pop()),
                            ],
                          ),
                        ),
                        // ── Body ────────────────────────────────────────────────
                        Padding(
                          padding: EdgeInsets.all(screenPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Left column ───────────────────────────────
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _sectionLabel('Service Details', Icons.medical_services_outlined),
                                        const SizedBox(height: 12),
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
                                                [
                                                  DropdownAttribute('1', 'Doctor'),
                                                  DropdownAttribute('2', 'Sonographer'),
                                                  DropdownAttribute('3', 'Therapist'),
                                                  DropdownAttribute('4', 'Spa Therapist'),
                                                  DropdownAttribute('5', 'Dietitian'),
                                                ],
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
                                        const SizedBox(height: 20),
                                        _sectionLabel('WhatsApp Templates', Icons.message_outlined),
                                        const SizedBox(height: 10),
                                        _whatsAppTemplateSection(),
                                      ],
                                    ),
                                  ),
                                  AppPadding.horizontal(),
                                  // ── Right column ──────────────────────────────
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: StreamBuilder<DateTime>(
                                      stream: fileRebuild.stream,
                                      builder: (context, snapshot) {
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _sectionLabel('Service Image', Icons.image_outlined),
                                            const SizedBox(height: 12),
                                            if (widget.type == 'create') ...[
                                              selectedFile.value == null
                                                  ? UploadDocumentsField(
                                                      title: 'servicesHomepage'.tr(gender: 'browseFile'),
                                                      fieldTitle: 'servicesHomepage'.tr(gender: 'doctorImage'),
                                                      action: () => addPicture(),
                                                      cancelAction: () {},
                                                    )
                                                  : Stack(
                                                      alignment: Alignment.topRight,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(10),
                                                          child: GestureDetector(
                                                            onTap: addPicture,
                                                            child: Image.memory(
                                                              selectedFile.value as Uint8List,
                                                              height: 300,
                                                              width: double.infinity,
                                                              fit: BoxFit.cover,
                                                            ),
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
                                                    ),
                                            ],
                                            if (widget.type == 'update') ...[
                                              widget.service?.serviceImage == null
                                                  ? selectedFile.name != null
                                                        ? Stack(
                                                            alignment: Alignment.topRight,
                                                            children: [
                                                              ClipRRect(
                                                                borderRadius: BorderRadius.circular(10),
                                                                child: GestureDetector(
                                                                  onTap: addPicture,
                                                                  child: Image.memory(
                                                                    selectedFile.value as Uint8List,
                                                                    height: 300,
                                                                    width: double.infinity,
                                                                    fit: BoxFit.cover,
                                                                  ),
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
                                                            action: addPicture,
                                                            cancelAction: () {},
                                                          )
                                                  : ClipRRect(
                                                      borderRadius: BorderRadius.circular(10),
                                                      child: GestureDetector(
                                                        onTap: addPicture,
                                                        child: Image.network(
                                                          '${Environment.imageUrl}${widget.service?.serviceImage}',
                                                          height: 300,
                                                          width: double.infinity,
                                                          fit: BoxFit.cover,
                                                          loadingBuilder: (context, child, loadingProgress) {
                                                            if (loadingProgress == null) return child;
                                                            return SizedBox(
                                                              height: 300,
                                                              child: Center(
                                                                child: CircularProgressIndicator(
                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                                            (loadingProgress.expectedTotalBytes ?? 1)
                                                                      : null,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                          errorBuilder: (context, error, stackTrace) => Container(
                                                            height: 300,
                                                            decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(10),
                                                              color: disabledColor,
                                                            ),
                                                            child: const Center(
                                                              child: Icon(Icons.error, color: errorColor),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                              const SizedBox(height: 20),
                                              _sectionLabel('Record Info', Icons.info_outline_rounded),
                                              const SizedBox(height: 12),
                                              _metaRow(
                                                Icons.add_circle_outline,
                                                'Created Date',
                                                '${dateConverter(widget.service?.createdDate)}',
                                              ),
                                              const SizedBox(height: 8),
                                              _metaRow(
                                                Icons.edit_outlined,
                                                'Last Updated',
                                                '${dateConverter(widget.service?.modifiedDate)}',
                                              ),
                                            ],
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

  Widget _whatsAppTemplateSection() {
    const tags = [
      '{{name}}',
      '{{service}}',
      '{{branchName}}',
      '{{branchPhone}}',
      '{{formattedDate}}',
      '{{formattedTime}}',
    ];

    return StreamBuilder<DateTime>(
      stream: templateRebuild.stream,
      builder: (context, _) {
        final activeCtrl = whatsappTemplateControllers[_activeTemplate];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Template tabs ──────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(6, (i) {
                  final hasContent = whatsappTemplateControllers[i].text.trim().isNotEmpty;
                  final isActive = _activeTemplate == i;
                  return GestureDetector(
                    onTap: () {
                      _activeTemplate = i;
                      templateRebuild.add(DateTime.now());
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF6366F1) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? const Color(0xFF6366F1) : Colors.transparent),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasContent) ...[
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : const Color(0xFF6366F1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Text(
                            'T${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 10),
            // ── Text area ──────────────────────────────────────────────
            TextField(
              controller: activeCtrl,
              maxLines: 8,
              style: const TextStyle(fontSize: 13, height: 1.5),
              onChanged: (_) => templateRebuild.add(DateTime.now()),
              decoration: InputDecoration(
                hintText: 'Type your WhatsApp message for Template ${_activeTemplate + 1}...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB)),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${activeCtrl.text.length} chars',
                style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(height: 10),
            // ── Variable chips ─────────────────────────────────────────
            const Text(
              'TAP TO INSERT',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF), letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return GestureDetector(
                  onTap: () {
                    final ctrl = whatsappTemplateControllers[_activeTemplate];
                    final sel = ctrl.selection;
                    final text = ctrl.text;
                    final start = sel.isValid && sel.start >= 0 ? sel.start : text.length;
                    final end = sel.isValid && sel.end >= 0 ? sel.end : text.length;
                    final newText = text.replaceRange(start, end, tag);
                    ctrl.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(offset: start + tag.length),
                    );
                    templateRebuild.add(DateTime.now());
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF6366F1).withAlpha(60)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF9CA3AF)),
            ),
            Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
          ],
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

  void getLatestData() {
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

  Future<void> addPicture() async {
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
    // if (widget.type == 'create') {
    //   if (selectedFile.value == null) {
    //     temp = false;
    //     showDialogError(context, 'Please upload an image for the Service.');
    //   }
    // }
    setState(() {});
    return temp;
  }
}
