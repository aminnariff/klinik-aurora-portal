import 'dart:async';
import 'dart:math' as math;

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
import 'package:klinik_aurora_portal/models/service/create_service_request.dart';
import 'package:klinik_aurora_portal/models/service/services_response.dart';
import 'package:klinik_aurora_portal/models/service/update_service_request.dart';
import 'package:klinik_aurora_portal/utils/image_helper.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_image_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
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
    labelText: 'Service Name',
  );
  final InputFieldAttribute serviceDescriptionController = InputFieldAttribute(
    controller: TextEditingController(),
    lineNumber: 4,
    maxCharacter: 500,
    labelText: 'Description',
  );
  final InputFieldAttribute servicePriceController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Price',
    isNumber: true,
  );
  final InputFieldAttribute serviceBookingFeeController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Booking Fee',
    isNumber: true,
  );
  final InputFieldAttribute serviceTimeController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Estimated Duration',
  );
  final InputFieldAttribute serviceCategoryController = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Service Category',
  );
  final InputFieldAttribute _serviceImage = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Service Image',
  );

  int _serviceStatus = 1;
  DropdownAttribute? _doctorType;
  final StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  final List<TextEditingController> whatsappTemplateControllers = List.generate(6, (_) => TextEditingController());
  int _activeTemplate = 0;
  final StreamController<DateTime> templateRebuild = StreamController.broadcast();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _serviceImage.controller.addListener(_onImageControllerChanged);

    if (widget.type == 'update') {
      serviceNameController.controller.text = widget.service?.serviceName ?? '';
      serviceDescriptionController.controller.text = widget.service?.serviceDescription ?? '';
      servicePriceController.controller.text = widget.service?.servicePrice ?? '';
      serviceBookingFeeController.controller.text = widget.service?.serviceBookingFee ?? '';
      serviceTimeController.controller.text = widget.service?.serviceTime ?? '';
      serviceCategoryController.controller.text = widget.service?.serviceCategory ?? '';
      _serviceImage.controller.text = widget.service?.serviceImage ?? '';
      _serviceStatus = widget.service?.serviceStatus ?? 1;

      if (widget.service?.serviceTemplate != null) {
        for (int i = 0; i < widget.service!.serviceTemplate!.length && i < whatsappTemplateControllers.length; i++) {
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
    } else {
      _doctorType = DropdownAttribute('1', 'Doctor');
      _serviceStatus = 1;
    }
  }

  void _onImageControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _serviceImage.controller.removeListener(_onImageControllerChanged);
    serviceNameController.controller.dispose();
    serviceDescriptionController.controller.dispose();
    servicePriceController.controller.dispose();
    serviceBookingFeeController.controller.dispose();
    serviceTimeController.controller.dispose();
    serviceCategoryController.controller.dispose();
    _serviceImage.controller.dispose();
    for (var c in whatsappTemplateControllers) {
      c.dispose();
    }
    rebuildDropdown.close();
    templateRebuild.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = screenWidth(100) < 768;
    final maxW = isMobile ? screenWidth(96) : math.min(940.0, screenWidth(92));
    final maxH = screenHeight(90);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        margin: EdgeInsets.all(isMobile ? 8 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: _buildBody(isMobile),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isCreate = widget.type == 'create';
    final title = isCreate
        ? 'New Clinical Service'
        : (serviceNameController.controller.text.isNotEmpty
            ? serviceNameController.controller.text
            : (widget.service?.serviceName ?? 'Edit Service'));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF246E7A), Color(0xFF1B545E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF246E7A).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.medical_services_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _statusBadge(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isCreate
                      ? 'Define service catalog item, pricing, doctor type, and automated WhatsApp templates'
                      : 'Update pricing, doctor type, estimated duration, and notification templates',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
            onPressed: () => context.pop(),
            hoverColor: const Color(0xFFF1F5F9),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge() {
    final isActive = _serviceStatus == 1;
    return InkWell(
      onTap: () {
        setState(() {
          _serviceStatus = isActive ? 0 : 1;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildServiceInfoSection(),
          const SizedBox(height: 24),
          _buildMediaAndTemplatesSection(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 11,
          child: _buildServiceInfoSection(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 10,
          child: _buildMediaAndTemplatesSection(),
        ),
      ],
    );
  }

  Widget _buildServiceInfoSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('SERVICE INFORMATION', Icons.info_outline_rounded),
          const SizedBox(height: 16),
          _fieldLabel('Service Name', isRequired: true),
          const SizedBox(height: 6),
          _styledTextField(
            controller: serviceNameController.controller,
            hint: 'e.g. General Consultation, Ultrasound 2D/3D',
            errorText: serviceNameController.errorMessage,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Service Category', isRequired: true),
          const SizedBox(height: 6),
          _styledTextField(
            controller: serviceCategoryController.controller,
            hint: 'e.g. Scan, Consultation, Treatment, Wellness',
            errorText: serviceCategoryController.errorMessage,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Performed By / Doctor Type', isRequired: true),
          const SizedBox(height: 6),
          StreamBuilder<DateTime>(
            stream: rebuildDropdown.stream,
            builder: (context, snapshot) {
              return _styledDropdown(
                items: [
                  DropdownAttribute('1', 'Doctor'),
                  DropdownAttribute('2', 'Sonographer'),
                  DropdownAttribute('3', 'Therapist'),
                  DropdownAttribute('4', 'Spa Therapist'),
                  DropdownAttribute('5', 'Dietitian'),
                ],
                value: _doctorType?.name,
                hint: 'Select practitioner role',
                onChanged: (p0) {
                  _doctorType = p0;
                  rebuildDropdown.add(DateTime.now());
                },
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Price (RM)'),
                    const SizedBox(height: 6),
                    _styledTextField(
                      controller: servicePriceController.controller,
                      hint: '0.00',
                      isNumber: true,
                      prefixText: 'RM ',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel('Booking Fee (RM)'),
                    const SizedBox(height: 6),
                    _styledTextField(
                      controller: serviceBookingFeeController.controller,
                      hint: '0.00',
                      isNumber: true,
                      prefixText: 'RM ',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _fieldLabel('Estimated Duration', isRequired: true),
          const SizedBox(height: 6),
          _styledTextField(
            controller: serviceTimeController.controller,
            hint: 'e.g. 30 minutes, 45 minutes, 1 hour',
            errorText: serviceTimeController.errorMessage,
            prefixIcon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Description', isRequired: true),
          const SizedBox(height: 6),
          _styledTextField(
            controller: serviceDescriptionController.controller,
            hint: 'Clinical scope, procedure overview, and instructions...',
            maxLines: 4,
            errorText: serviceDescriptionController.errorMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaAndTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('SERVICE IMAGE', Icons.image_outlined),
              const SizedBox(height: 14),
              _buildCurrentPhotoCard(),
              const SizedBox(height: 12),
              AppImageField(
                field: _serviceImage,
                folder: 'service',
                previewHeight: 120,
                previewWidth: 160,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('WHATSAPP NOTIFICATION TEMPLATES', Icons.chat_bubble_outline_rounded),
              const SizedBox(height: 12),
              _whatsAppTemplateSection(),
            ],
          ),
        ),
        if (widget.type == 'update') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('RECORD INFO', Icons.history_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _metaInfo('Created Date', dateConverter(widget.service?.createdDate) ?? '—'),
                    ),
                    Expanded(
                      child: _metaInfo('Last Modified', dateConverter(widget.service?.modifiedDate) ?? '—'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCurrentPhotoCard() {
    final rawUrl = _serviceImage.controller.text.trim();
    final resolved = resolveImageUrl(rawUrl);
    final hasImage = resolved.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFE2E8F0),
              child: hasImage
                  ? Image.network(
                      resolved,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.broken_image_rounded, color: Color(0xFF94A3B8), size: 28),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: secondaryColor),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.medical_services_outlined, color: Color(0xFF94A3B8), size: 30),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasImage ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasImage ? 'Current Photo' : 'No Photo Uploaded',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: hasImage ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasImage ? 'Displaying active image for this service' : 'Upload or paste an image URL below',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF246E7A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? const Color(0xFF246E7A) : Colors.transparent),
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
                                color: isActive ? Colors.white : const Color(0xFF246E7A),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          Text(
                            'Template ${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive ? Colors.white : const Color(0xFF475569),
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
            TextField(
              controller: activeCtrl,
              maxLines: 5,
              style: const TextStyle(fontSize: 13, height: 1.45),
              onChanged: (_) => templateRebuild.add(DateTime.now()),
              decoration: InputDecoration(
                hintText: 'Enter automated message for Template ${_activeTemplate + 1}...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Color(0xFF246E7A), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CLICK TO INSERT VARIABLE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8),
                ),
                Text(
                  '${activeCtrl.text.length} chars',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return InkWell(
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
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF246E7A).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B545E),
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            label: Text(
              _isSubmitting
                  ? 'Saving...'
                  : (widget.type == 'create' ? 'Create Service' : 'Save Changes'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF246E7A),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubmit() {
    if (!validate()) return;

    setState(() => _isSubmitting = true);
    showLoading();

    final imageVal = _serviceImage.controller.text.trim().isEmpty ? null : _serviceImage.controller.text.trim();
    final templates = whatsappTemplateControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    final priceVal = servicePriceController.controller.text.trim().isEmpty
        ? null
        : double.tryParse(servicePriceController.controller.text.trim());
    final feeVal = serviceBookingFeeController.controller.text.trim().isEmpty
        ? null
        : double.tryParse(serviceBookingFeeController.controller.text.trim());
    final docType = int.tryParse(_doctorType?.key ?? '1') ?? 1;

    if (widget.type == 'create') {
      ServiceController.create(
        context,
        CreateServiceRequest(
          serviceName: serviceNameController.controller.text.trim(),
          serviceDescription: serviceDescriptionController.controller.text.trim(),
          servicePrice: priceVal,
          serviceBookingFee: feeVal,
          serviceTime: serviceTimeController.controller.text.trim(),
          serviceCategory: serviceCategoryController.controller.text.trim(),
          serviceImage: imageVal,
          serviceStatus: _serviceStatus,
          doctorType: docType,
          serviceTemplate: templates,
        ),
      ).then((value) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        if (responseCode(value.code)) {
          getLatestData();
        } else {
          showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
        }
      }).catchError((e) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        showDialogError(context, e.toString());
      });
    } else {
      ServiceController.update(
        context,
        UpdateServiceRequest(
          serviceId: widget.service?.serviceId,
          serviceStatus: _serviceStatus,
          serviceName: serviceNameController.controller.text.trim(),
          serviceDescription: serviceDescriptionController.controller.text.trim(),
          servicePrice: priceVal,
          serviceBookingFee: feeVal,
          serviceTime: serviceTimeController.controller.text.trim(),
          serviceCategory: serviceCategoryController.controller.text.trim(),
          serviceImage: imageVal,
          doctorType: docType,
          serviceTemplate: templates,
        ),
      ).then((value) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        if (responseCode(value.code)) {
          getLatestData();
        } else {
          showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
        }
      }).catchError((e) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        showDialogError(context, e.toString());
      });
    }
  }

  void getLatestData() {
    ServiceController.getAll(context, 1, 100).then((value) {
      if (responseCode(value.code)) {
        context.read<ServiceController>().servicesResponse = value.data;
      }
      context.pop();
      if (widget.type == 'update') {
        showDialogSuccess(context, 'Successfully updated Service');
      } else {
        showDialogSuccess(context, 'Successfully created new Service');
      }
    });
  }

  bool validate() {
    bool isValid = true;
    serviceNameController.errorMessage = null;
    serviceDescriptionController.errorMessage = null;
    serviceTimeController.errorMessage = null;
    serviceCategoryController.errorMessage = null;

    if (serviceNameController.controller.text.trim().isEmpty) {
      isValid = false;
      serviceNameController.errorMessage = 'Service Name is required';
    }
    if (serviceCategoryController.controller.text.trim().isEmpty) {
      isValid = false;
      serviceCategoryController.errorMessage = 'Category is required';
    }
    if (serviceTimeController.controller.text.trim().isEmpty) {
      isValid = false;
      serviceTimeController.errorMessage = 'Duration is required';
    }
    if (serviceDescriptionController.controller.text.trim().isEmpty) {
      isValid = false;
      serviceDescriptionController.errorMessage = 'Description is required';
    }

    setState(() {});
    return isValid;
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(color: const Color(0xFF246E7A), borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
        children: isRequired
            ? [
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ]
            : [],
      ),
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    bool isNumber = false,
    String? prefixText,
    IconData? prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: maxLines == 1 ? 42 : null,
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixText: prefixText,
              prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569), fontSize: 13),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: const Color(0xFF64748B)) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF246E7A), width: 1.5),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
        ],
      ],
    );
  }

  Widget _styledDropdown({
    required List<DropdownAttribute> items,
    required String? value,
    required ValueChanged<DropdownAttribute?> onChanged,
    String hint = 'Select',
    String? errorText,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;
    final displayLabel = hasValue ? value : hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<DropdownAttribute>(
              isExpanded: true,
              isDense: true,
              hint: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              items: items
                  .map(
                    (item) => DropdownItem<DropdownAttribute>(
                      value: item,
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              iconStyleData: const IconStyleData(
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
              ),
              dropdownStyleData: DropdownStyleData(
                elevation: 4,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(errorText, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
        ],
      ],
    );
  }

  Widget _metaInfo(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
      ],
    );
  }
}
