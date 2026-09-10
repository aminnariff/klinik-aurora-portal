import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/asset/app_asset_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/doctor/doctor_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/doctor/create_doctor_request.dart';
import 'package:klinik_aurora_portal/models/doctor/doctor_branch_response.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_request.dart';
import 'package:klinik_aurora_portal/utils/image_helper.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
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
    labelText: 'Practitioner Name',
    hintText: 'e.g. Dr. Siti Aminah',
  );
  final InputFieldAttribute _doctorPhone = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Practitioner Contact No.',
    hintText: 'e.g. 0123456789',
    isNumber: true,
  );
  final InputFieldAttribute _doctorImage = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Practitioner Photo URL',
    hintText: 'https://... or upload photo above',
  );
  final InputFieldAttribute _branchId = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Branch',
  );

  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  DropdownAttribute? _selectedBranch;
  DropdownAttribute? _selectedDoctorType;
  bool _isUploading = false;

  static final List<DropdownAttribute> doctorTypeList = [
    DropdownAttribute('1', doctorType(1)),
    DropdownAttribute('2', doctorType(2)),
    DropdownAttribute('3', doctorType(3)),
    DropdownAttribute('4', doctorType(4)),
    DropdownAttribute('5', doctorType(5)),
  ];

  @override
  void initState() {
    super.initState();
    try {
      _doctorImage.controller.addListener(() {
        if (mounted) setState(() {});
      });

      if (widget.type == 'update') {
        _doctorName.controller.text = widget.doctor?.doctorName ?? '';
        _doctorPhone.controller.text = widget.doctor?.doctorPhone ?? '';
        _branchId.controller.text = widget.doctor?.branchId ?? '';
        _doctorImage.controller.text = widget.doctor?.doctorImage ?? '';
        _selectedBranch = DropdownAttribute(widget.doctor?.branchId ?? '', widget.doctor?.branchName ?? '');
        final docTypeVal = widget.doctor?.doctorType ?? 1;
        _selectedDoctorType = DropdownAttribute(docTypeVal.toString(), doctorType(docTypeVal));
        rebuildDropdown.add(DateTime.now());
      } else {
        _selectedDoctorType = DropdownAttribute('1', doctorType(1));
      }

      SchedulerBinding.instance.scheduleFrameCallback((_) {
        try {
          final auth = context.read<AuthController>();
          final isSuper = auth.isSuperAdmin;
          final userBranchId = auth.authenticationResponse?.data?.user?.branchId;

          if (!isSuper && widget.type == 'create' && userBranchId != null) {
            final branches = context.read<BranchController>().branchAllResponse?.data?.data ?? [];
            branch_model.Data? item;
            for (final b in branches) {
              if (b.branchId == userBranchId) {
                item = b;
                break;
              }
            }
            final branchName = item?.branchName ?? 'Branch';
            _selectedBranch = DropdownAttribute(userBranchId, branchName);
            _branchId.controller.text = userBranchId;
            _branchId.errorMessage = null;
            rebuildDropdown.add(DateTime.now());
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
  void dispose() {
    rebuildDropdown.close();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    try {
      final files = await FilePicker.pickFiles();
      final file = files.firstOrNull;
      if (file == null) return;

      final extension = (file.extension ?? '').toLowerCase();
      const allowedExtensions = ['png', 'jpg', 'jpeg', 'webp', 'gif'];
      if (!allowedExtensions.contains(extension)) {
        if (mounted) {
          showDialogError(context, 'Please choose an image file (${allowedExtensions.join(', ')}).');
        }
        return;
      }

      final Uint8List bytes = await file.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        showDialogError(context, 'Image exceeds 5 MB. Please compress it and try again.');
        return;
      }

      setState(() => _isUploading = true);

      final response = await AppAssetController.upload(
        bytes: bytes,
        filename: file.name,
        folder: 'doctor',
      );

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (responseCode(response.code) && response.data != null) {
        _doctorImage.controller.text = response.data!;
        setState(() {});
      } else {
        showDialogError(context, response.message ?? 'Unable to upload the image.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploading = false);
      showDialogError(context, 'Failed to pick or upload image: $e');
    }
  }

  void _clearImage() {
    _doctorImage.controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                child: _buildBody(),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: secondaryColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              widget.type == 'create' ? Icons.person_add_rounded : Icons.person_rounded,
              size: 20,
              color: secondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.type == 'create' ? 'New Practitioner' : 'Edit Practitioner',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 2),
              Text(
                widget.type == 'create'
                    ? 'Set up practitioner details, assigned branch, and photo'
                    : 'Update practitioner information, assigned branch, or photo',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6B7280)),
            tooltip: 'Close',
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final isNarrow = MediaQuery.of(context).size.width < 680;

    final leftSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('General Information', Icons.badge_outlined),
        const SizedBox(height: 12),
        InputField(field: _doctorName),
        const SizedBox(height: 14),
        InputField(field: _doctorPhone),
        const SizedBox(height: 14),
        StreamBuilder<DateTime>(
          stream: rebuildDropdown.stream,
          builder: (context, snapshot) {
            return Consumer<BranchController>(
              builder: (context, branchCtrl, _) {
                final branches = branchCtrl.branchAllResponse?.data?.data ?? [];
                final isSuper = context.read<AuthController>().isSuperAdmin;
                final userBranchId = context.read<AuthController>().authenticationResponse?.data?.user?.branchId;

                if (!isSuper && _selectedBranch == null && userBranchId != null) {
                  branch_model.Data? item;
                  for (final b in branches) {
                    if (b.branchId == userBranchId) {
                      item = b;
                      break;
                    }
                  }
                  final branchName = item?.branchName ?? 'Branch';
                  _selectedBranch = DropdownAttribute(userBranchId, branchName);
                  _branchId.controller.text = userBranchId;
                  _branchId.errorMessage = null;
                }

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
                    labelText: 'Branch',
                    isEditable: isSuper,
                    fieldColor: isSuper ? textFormFieldEditableColor : textFormFieldUneditableColor,
                    onChanged: (selected) {
                      _branchId.errorMessage = null;
                      _selectedBranch = selected;
                      _branchId.controller.text = selected?.key ?? '';
                      rebuildDropdown.add(DateTime.now());
                    },
                    errorMessage: _branchId.errorMessage,
                    value: _selectedBranch?.name,
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 14),
        StreamBuilder<DateTime>(
          stream: rebuildDropdown.stream,
          builder: (context, snapshot) {
            return AppDropdown(
              attributeList: DropdownAttributeList(
                doctorTypeList,
                labelText: 'Practitioner Type',
                isEditable: true,
                fieldColor: textFormFieldEditableColor,
                onChanged: (selected) {
                  _selectedDoctorType = selected;
                  rebuildDropdown.add(DateTime.now());
                },
                value: _selectedDoctorType?.name,
              ),
            );
          },
        ),
      ],
    );

    final rightSection = _buildPhotoSection();

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          leftSection,
          const SizedBox(height: 20),
          rightSection,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 11, child: leftSection),
        const SizedBox(width: 20),
        Expanded(flex: 9, child: rightSection),
      ],
    );
  }

  Widget _buildPhotoSection() {
    final imageUrl = _doctorImage.controller.text.trim();
    final hasImage = imageUrl.isNotEmpty;
    final resolvedUrl = resolveImageUrl(imageUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Practitioner Photo', Icons.photo_camera_outlined, isRequired: widget.type == 'create'),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: _isUploading
                    ? Container(
                        height: 140,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Uploading...',
                              style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : hasImage
                        ? Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  height: 140,
                                  width: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Image.network(
                                    resolvedUrl,
                                    height: 140,
                                    width: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: const Color(0xFFF3F4F6),
                                      alignment: Alignment.center,
                                      child: const Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image_outlined, size: 32, color: Color(0xFF9CA3AF)),
                                          SizedBox(height: 4),
                                          Text('Image error', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Tooltip(
                                  message: 'Remove photo',
                                  child: InkWell(
                                    onTap: _clearImage,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: _pickAndUpload,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFD1D5DB),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: secondaryColor.withAlpha(20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.add_a_photo_outlined, size: 24, color: secondaryColor),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Upload Photo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'PNG, JPG up to 5MB',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isUploading ? null : _pickAndUpload,
                    icon: Icon(hasImage ? Icons.cached_rounded : Icons.upload_file_rounded, size: 14),
                    label: Text(hasImage ? 'Change Photo' : 'Browse File', style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                  if (hasImage) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _clearImage,
                      icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                      label: const Text('Remove', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              InputField(field: _doctorImage),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String title, IconData icon, {bool isRequired = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF4B5563)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check_rounded, size: 16),
            label: Text(
              widget.type == 'create' ? 'Create Practitioner' : 'Save Changes',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (validate()) {
      showLoading();
      final imageVal = _doctorImage.controller.text.trim();
      final finalDoctorImage = imageVal.isEmpty ? null : imageVal;

      final isSuper = context.read<AuthController>().isSuperAdmin;
      final userBranchId = context.read<AuthController>().authenticationResponse?.data?.user?.branchId;
      final effectiveBranchId = (_selectedBranch?.key.trim().isNotEmpty == true)
          ? _selectedBranch!.key.trim()
          : (_branchId.controller.text.trim().isNotEmpty
              ? _branchId.controller.text.trim()
              : (!isSuper ? userBranchId : null));

      if (widget.type == 'create') {
        DoctorController.create(
          context,
          CreateDoctorRequest(
            doctorName: _doctorName.controller.text.trim(),
            doctorPhone: _doctorPhone.controller.text.trim(),
            doctorType: int.tryParse(_selectedDoctorType?.key ?? '1') ?? 1,
            branchId: effectiveBranchId,
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
            doctorName: _doctorName.controller.text.trim(),
            doctorPhone: _doctorPhone.controller.text.trim(),
            doctorType: int.tryParse(_selectedDoctorType?.key ?? '1') ?? 1,
            doctorStatus: widget.doctor?.doctorStatus,
            branchId: effectiveBranchId,
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
  }

  void getLatestData() {
    final isSuper = context.read<AuthController>().isSuperAdmin;
    final userBranchId = context.read<AuthController>().authenticationResponse?.data?.user?.branchId;

    DoctorController.get(
      context,
      1,
      pageSize,
      branchId: isSuper ? null : userBranchId,
      doctorStatus: 1,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<DoctorController>().doctorBranchResponse = value.data;
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated practitioner');
        } else {
          showDialogSuccess(context, 'Successfully created new practitioner');
        }
      } else {
        context.pop();
        if (widget.type == 'update') {
          showDialogSuccess(context, 'Successfully updated practitioner');
        } else {
          showDialogSuccess(context, 'Successfully created new practitioner');
        }
      }
    });
  }

  bool validate() {
    bool temp = true;
    if (_doctorName.controller.text.trim().isEmpty) {
      temp = false;
      _doctorName.errorMessage = ErrorMessage.required(field: _doctorName.labelText);
    } else {
      _doctorName.errorMessage = null;
    }

    if (_doctorPhone.controller.text.trim().isEmpty) {
      temp = false;
      _doctorPhone.errorMessage = ErrorMessage.required(field: _doctorPhone.labelText);
    } else {
      _doctorPhone.errorMessage = null;
    }

    final isSuper = context.read<AuthController>().isSuperAdmin;
    final userBranchId = context.read<AuthController>().authenticationResponse?.data?.user?.branchId;
    final selectedBranchId = _selectedBranch?.key.trim().isNotEmpty == true
        ? _selectedBranch!.key.trim()
        : _branchId.controller.text.trim();
    final effectiveBranchId = selectedBranchId.isNotEmpty ? selectedBranchId : (!isSuper ? userBranchId : null);

    if (effectiveBranchId == null || effectiveBranchId.isEmpty) {
      temp = false;
      _branchId.errorMessage = ErrorMessage.required(field: _branchId.labelText);
    } else {
      _branchId.errorMessage = null;
      _branchId.controller.text = effectiveBranchId;
    }

    if (widget.type == 'create') {
      if (_doctorImage.controller.text.trim().isEmpty) {
        temp = false;
        showDialogError(context, 'Please upload or provide a photo for the practitioner.');
      }
    }
    setState(() {});
    return temp;
  }
}
