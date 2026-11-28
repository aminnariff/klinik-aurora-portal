import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_history_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/reward/reward_history_response.dart' as reward_history;
import 'package:klinik_aurora_portal/models/reward/update_reward_history_request.dart';
import 'package:klinik_aurora_portal/utils/image_helper.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_form_field.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class RewardHistoryDetail extends StatefulWidget {
  final String type;
  final reward_history.Data data;

  const RewardHistoryDetail({super.key, required this.type, required this.data});

  @override
  State<RewardHistoryDetail> createState() => _RewardHistoryDetailState();
}

class _RewardHistoryDetailState extends State<RewardHistoryDetail> {
  final TextEditingController _historyDescription = TextEditingController();
  DropdownAttribute? _status;
  FileAttribute? _selectedFile;
  bool _isSubmitting = false;
  String? _commentError;

  @override
  void initState() {
    super.initState();
    final currentStatus = widget.data.rewardHistoryStatus;
    if (currentStatus == 1) {
      _status = DropdownAttribute('1', 'In-Progress');
    } else {
      _status = DropdownAttribute('0', 'Completed');
    }
    _historyDescription.text = widget.data.rewardHistoryDescription ?? '';
  }

  @override
  void dispose() {
    _historyDescription.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _commentError = null;
      if (_historyDescription.text.trim().isEmpty) {
        _commentError = 'Comments/notes are required for tracking.';
        valid = false;
      }
    });
    return valid;
  }

  void _handleSubmit() {
    if (!_validate() || _status == null) return;

    showConfirmDialog(
      context,
      'Are you sure you want to update this order?',
    ).then((confirmed) {
      if (confirmed != true) return;

      setState(() => _isSubmitting = true);
      showLoading();

      final statusCode = int.parse(_status!.key);
      RewardHistoryController.update(
        context,
        UpdateRewardHistoryRequest(
          rewardId: widget.data.rewardId,
          rewardHistoryId: widget.data.rewardHistoryId,
          pointTransactionId: widget.data.pointTransactionId,
          rewardHistoryStatus: statusCode,
          rewardHistoryDescription: _historyDescription.text.trim(),
        ),
      ).then((value) {
        if (responseCode(value.code)) {
          if (_selectedFile?.value != null) {
            RewardHistoryController.upload(
              context,
              widget.data.rewardHistoryId ?? '',
              FileAttribute(name: _selectedFile?.name, value: _selectedFile?.value),
            ).then((uploadRes) {
              dismissLoading();
              setState(() => _isSubmitting = false);
              if (responseCode(uploadRes.code)) {
                _onSuccess();
              } else {
                _onSuccess(warning: 'Order updated, but proof image failed to upload.');
              }
            }).catchError((e) {
              dismissLoading();
              setState(() => _isSubmitting = false);
              _onSuccess(warning: 'Order updated, but proof upload failed: $e');
            });
          } else {
            dismissLoading();
            setState(() => _isSubmitting = false);
            _onSuccess();
          }
        } else {
          dismissLoading();
          setState(() => _isSubmitting = false);
          showDialogError(
            context,
            value.message ?? value.data?.message ?? 'ERROR : ${value.code}',
          );
        }
      }).catchError((e) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        showDialogError(context, e.toString());
      });
    });
  }

  void _onSuccess({String? warning}) {
    RewardHistoryController.getAll(context, 1, pageSize).then((value) {
      if (responseCode(value.code)) {
        context.read<RewardHistoryController>().rewardHistoryResponse = value;
      }
    });
    context.pop();
    if (warning != null) {
      showDialogError(context, warning);
    } else {
      showDialogSuccess(context, 'Reward order updated successfully');
    }
  }

  Future<void> _pickFile() async {
    try {
      final files = await FilePicker.pickFiles();
      if (files.isNotEmpty) {
        final file = files.first;
        final extension = (file.extension ?? '').toLowerCase();
        const allowed = ['jpg', 'jpeg', 'png', 'pdf'];
        if (!allowed.contains(extension)) {
          if (mounted) {
            showDialogError(context, 'Please choose a valid file (JPG, PNG, PDF).');
          }
          return;
        }
        final Uint8List fileBytes = await file.readAsBytes();
        if (fileBytes.lengthInBytes <= 2 * 1024 * 1024) {
          setState(() {
            _selectedFile = FileAttribute(name: file.name, value: fileBytes);
          });
        } else {
          if (mounted) {
            showDialogError(context, 'File size exceeds 2MB limit.');
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 20 : 32,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 780,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Divider(height: 1, color: appBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
              ),
            ),
            Divider(height: 1, color: appBorder),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final shortId = (widget.data.rewardHistoryId != null && widget.data.rewardHistoryId!.length >= 8)
        ? widget.data.rewardHistoryId!.substring(0, 8).toUpperCase()
        : widget.data.rewardHistoryId ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: primary.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.receipt_long_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Manage Reward Order',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: appInkPrimary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: appSurfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$shortId',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: appInkSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.data.rewardName ?? 'Review redemption and update order fulfillment',
                  style: TextStyle(fontSize: 12, color: appInkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
  tooltip: 'Tutup',
            icon: Icon(Icons.close_rounded, size: 20, color: appInkMuted),
            onPressed: () => context.pop(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDetailsColumn(context)),
        const SizedBox(width: 28),
        Expanded(child: _buildProofAuditColumn(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsColumn(context),
        const SizedBox(height: 20),
        _buildProofAuditColumn(context),
      ],
    );
  }

  Widget _buildDetailsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('ORDER INFORMATION', Icons.receipt_outlined),
        const SizedBox(height: 12),
        _buildPatientCard(),
        const SizedBox(height: 12),
        _buildRewardOrderCard(),
        const SizedBox(height: 20),
        _sectionHeader('FULFILLMENT & NOTES', Icons.edit_note_rounded),
        const SizedBox(height: 14),
        _fieldLabel('Fulfillment Status', isRequired: true),
        const SizedBox(height: 6),
        _styledDropdown(
          items: [
            DropdownAttribute('1', 'In-Progress'),
            DropdownAttribute('0', 'Completed'),
          ],
          value: _status?.name,
          onChanged: (attr) {
            if (attr != null) setState(() => _status = attr);
          },
        ),
        const SizedBox(height: 14),
        _fieldLabel('Comments / Notes', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _historyDescription,
          hint: 'Tracking number, redemption notes, or shipping details...',
          maxLines: 3,
          errorText: _commentError,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appWarningSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.local_shipping_outlined, size: 15, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'If the reward is being delivered, record the postal address or courier tracking number here.',
                  style: TextStyle(fontSize: 11, color: appAmberText, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard() {
    final name = widget.data.userFullname ?? 'Customer';
    final initials = name.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withAlpha(30),
                child: Text(
                  initials,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: appInkPrimary),
                    ),
                    if (widget.data.userPhone != null && widget.data.userPhone!.isNotEmpty)
                      Text(
                        widget.data.userPhone!,
                        style: TextStyle(fontSize: 11, color: appInkMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_hasAddress) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: appBorder),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: appInkMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formattedAddress,
                    style: TextStyle(fontSize: 11, color: appInkSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool get _hasAddress {
    return (widget.data.userAddress != null && widget.data.userAddress!.isNotEmpty) ||
        (widget.data.userAddressCity != null && widget.data.userAddressCity!.isNotEmpty);
  }

  String get _formattedAddress {
    final parts = [
      widget.data.userAddress,
      widget.data.userAddressPostcode,
      widget.data.userAddressCity,
      widget.data.userAddressState,
      widget.data.userAddressCountry,
    ].where((p) => p != null && p.trim().isNotEmpty).join(', ');
    return parts.isEmpty ? 'No address on file' : parts;
  }

  Widget _buildRewardOrderCard() {
    final rewardTitle = widget.data.rewardName ?? 'Reward';
    final points = widget.data.transactionPoint ?? 0;
    final date = dateConverter(widget.data.rewardHistoryCreatedDate) ?? '—';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard_rounded, size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  rewardTitle,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: appInkPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: appInfoSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: Text(
                  '$points pts',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: appSkyText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: appInkMuted),
              const SizedBox(width: 6),
              Text(
                'Redeemed on $date',
                style: TextStyle(fontSize: 11, color: appInkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProofAuditColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('PROOF OF DELIVERY (OPTIONAL)', Icons.image_outlined),
        const SizedBox(height: 12),
        _buildProofSection(),
        const SizedBox(height: 20),
        _sectionHeader('AUDIT TRAIL', Icons.history_rounded),
        const SizedBox(height: 12),
        _buildAuditCard(),
      ],
    );
  }

  Widget _buildProofSection() {
    final existingUrl = widget.data.rewardHistoryImage;
    final hasExisting = existingUrl != null && existingUrl.isNotEmpty;
    final hasNewFile = _selectedFile != null;

    if (hasNewFile) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appBorderStrong),
        ),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.memory(_selectedFile!.value as Uint8List, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.black.withAlpha(150),
                child: IconButton(
  tooltip: 'Tutup',
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white),
                  onPressed: () => setState(() => _selectedFile = null),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (hasExisting) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: appBorder),
              color: appSurfaceSubtle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.network(
                resolveImageUrl(existingUrl), cacheWidth: 1200,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: Icon(Icons.broken_image_rounded, size: 36, color: appInkMuted),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file_rounded, size: 16),
            label: const Text('Replace Proof Image', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: appBorderStrong),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: appSurfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appBorderStrong, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 32, color: appInkMuted),
            SizedBox(height: 8),
            Text(
              'Upload proof of delivery or receipt',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: appInkSecondary),
            ),
            SizedBox(height: 2),
            Text(
              'PNG, JPG, or PDF (up to 2MB)',
              style: TextStyle(fontSize: 11, color: appInkMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditCard() {
    final updatedBy = widget.data.createdByFullname;
    final modifiedDate = widget.data.rewardHistoryModifiedDate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 15, color: appInkMuted),
              const SizedBox(width: 8),
              Text('Last updated by:', style: TextStyle(fontSize: 11, color: appInkMuted)),
              const Spacer(),
              Text(
                updatedBy ?? 'System',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: appInkPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 15, color: appInkMuted),
              const SizedBox(width: 8),
              Text('Last modified at:', style: TextStyle(fontSize: 11, color: appInkMuted)),
              const Spacer(),
              Text(
                dateConverter(modifiedDate) ?? '—',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: appInkPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton.secondary(
            text: 'Cancel',
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 12),
          AppButton.primary(
            text: 'Update Order',
            isLoading: _isSubmitting,
            icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            onPressed: _isSubmitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 14, color: appInkMuted),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: appInkSecondary,
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: appInkSecondary,
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
    int maxLines = 1,
  }) {
    return AppFormField(
      controller: controller,
      hintText: hint,
      errorText: errorText,
      maxLines: maxLines,
    );
  }

  Widget _styledDropdown({
    required List<DropdownAttribute> items,
    required String? value,
    required ValueChanged<DropdownAttribute?> onChanged,
  }) {
    final hasValue = value != null && value.trim().isNotEmpty;

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorderStrong),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DropdownAttribute>(
          isExpanded: true,
          value: hasValue ? items.cast<DropdownAttribute?>().firstWhere((e) => e?.name == value, orElse: () => null) : null,
          hint: Text(
            hasValue ? value : 'Select Status',
            style: TextStyle(
              fontSize: 13,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
              color: hasValue ? appInkPrimary : appInkMuted,
            ),
          ),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: appInkMuted),
          items: items.map((attr) {
            final isInProgress = attr.key == '1';
            return DropdownMenuItem<DropdownAttribute>(
              value: attr,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isInProgress ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    attr.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: appInkPrimary),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
