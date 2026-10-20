import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart' as reward_model;
import 'package:klinik_aurora_portal/models/voucher/create_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/update_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart' as voucher_model;
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class VoucherDetail extends StatefulWidget {
  final voucher_model.Data? voucher;
  final String type; // 'create' or 'update'
  const VoucherDetail({super.key, this.voucher, required this.type});

  @override
  State<VoucherDetail> createState() => _VoucherDetailState();
}

class _VoucherDetailState extends State<VoucherDetail> {
  final TextEditingController _voucherNameController = TextEditingController();
  final TextEditingController _voucherDescriptionController = TextEditingController();
  final TextEditingController _voucherCodeController = TextEditingController();
  final TextEditingController _voucherPointController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  int _voucherStatus = 1; // 1 = Active, 0 = Inactive
  bool _isSubmitting = false;

  String? _nameError;
  String? _descriptionError;
  String? _codeError;
  String? _pointError;
  String? _startDateError;
  String? _endDateError;

  List<DropdownAttribute> _rewards = [];
  DropdownAttribute? _selectedReward;
  bool _isLoadingRewards = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'update' && widget.voucher != null) {
      final v = widget.voucher!;
      _voucherNameController.text = v.voucherName ?? '';
      _voucherDescriptionController.text = v.voucherDescription ?? '';
      _voucherCodeController.text = v.voucherCode ?? '';
      _voucherPointController.text = v.voucherPoint?.toString() ?? '';
      _startDateController.text = dateConverter(v.voucherStartDate, format: 'dd-MM-yyyy') ?? '';
      _endDateController.text = dateConverter(v.voucherEndDate, format: 'dd-MM-yyyy') ?? '';
      _voucherStatus = v.voucherStatus ?? 1;
      if (v.rewardId != null && v.rewardId!.isNotEmpty) {
        _selectedReward = DropdownAttribute(v.rewardId!, v.rewardId!);
      }
    }

    _fetchRewards();
  }

  void _fetchRewards() {
    setState(() => _isLoadingRewards = true);
    RewardController.getAll(context, 1, pageSize).then((value) {
      if (!mounted) return;
      setState(() => _isLoadingRewards = false);
      if (responseCode(value.code)) {
        context.read<RewardController>().rewardAllResponse = value;
        final List<DropdownAttribute> list = [];
        for (reward_model.Data item in value.data?.data ?? []) {
          if (item.rewardStatus == 1 && checkEndDate(item.rewardEndDate)) {
            list.add(DropdownAttribute(item.rewardId ?? '', item.rewardName ?? ''));
            if (_selectedReward?.key == item.rewardId) {
              _selectedReward = DropdownAttribute(item.rewardId ?? '', item.rewardName ?? '');
            }
          }
        }
        setState(() {
          _rewards = list;
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => _isLoadingRewards = false);
    });
  }

  @override
  void dispose() {
    _voucherNameController.dispose();
    _voucherDescriptionController.dispose();
    _voucherCodeController.dispose();
    _voucherPointController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _descriptionError = null;
      _codeError = null;
      _pointError = null;
      _startDateError = null;
      _endDateError = null;

      if (_voucherNameController.text.trim().isEmpty) {
        _nameError = 'Voucher name is required';
        valid = false;
      }
      if (_voucherDescriptionController.text.trim().isEmpty) {
        _descriptionError = 'Description is required';
        valid = false;
      }
      if (_voucherCodeController.text.trim().isEmpty) {
        _codeError = 'Voucher code is required';
        valid = false;
      } else if (_voucherCodeController.text.trim().length > 10) {
        _codeError = 'Code must be 10 characters or less';
        valid = false;
      }
      if (_voucherPointController.text.trim().isEmpty) {
        _pointError = 'Points required';
        valid = false;
      } else if (int.tryParse(_voucherPointController.text.trim()) == null) {
        _pointError = 'Must be a valid integer';
        valid = false;
      }
      if (_startDateController.text.trim().isEmpty) {
        _startDateError = 'Start date is required';
        valid = false;
      }
      if (_endDateController.text.trim().isEmpty) {
        _endDateError = 'End date is required';
        valid = false;
      }
    });
    return valid;
  }

  void _handleSubmit() {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    showLoading();

    final points = int.parse(_voucherPointController.text.trim());
    final rewardId = _selectedReward?.key;

    if (widget.type == 'update') {
      VoucherController.update(
        context,
        UpdateVoucherRequest(
          voucherId: widget.voucher?.voucherId,
          voucherName: _voucherNameController.text.trim(),
          voucherDescription: _voucherDescriptionController.text.trim(),
          voucherStartDate: convertStringToDate(_startDateController.text.trim()),
          voucherEndDate: convertStringToDate(_endDateController.text.trim()),
          voucherStatus: _voucherStatus,
          voucherCode: _voucherCodeController.text.trim().toUpperCase(),
          voucherPoint: points,
          rewardId: rewardId,
        ),
      ).then((value) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        if (responseCode(value.code)) {
          VoucherController.getAll(context, 1, pageSize).then((all) {
            if (responseCode(all.code)) {
              context.read<VoucherController>().voucherAllResponse = all;
            }
          });
          context.pop();
          showDialogSuccess(context, 'Successfully updated voucher');
        } else {
          showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
        }
      }).catchError((e) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        showDialogError(context, e.toString());
      });
    } else {
      VoucherController.create(
        context,
        CreateVoucherRequest(
          voucherName: _voucherNameController.text.trim(),
          voucherDescription: _voucherDescriptionController.text.trim(),
          voucherStartDate: convertStringToDate(_startDateController.text.trim()),
          voucherEndDate: convertStringToDate(_endDateController.text.trim()),
          voucherCode: _voucherCodeController.text.trim().toUpperCase(),
          voucherPoint: points,
          rewardId: rewardId,
        ),
      ).then((value) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        if (responseCode(value.code)) {
          VoucherController.getAll(context, 1, pageSize).then((all) {
            if (responseCode(all.code)) {
              context.read<VoucherController>().voucherAllResponse = all;
            }
          });
          context.pop();
          showDialogSuccess(context, 'Successfully created voucher');
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 20 : 32,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? double.infinity : 760,
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: isMobile ? _buildMobileLayout(context) : _buildDesktopLayout(context),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isCreate = widget.type == 'create';
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
            child: const Icon(Icons.confirmation_number_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCreate ? 'New Voucher' : 'Edit Voucher',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  isCreate
                      ? 'Create a customer voucher with redeemable points & perks'
                      : 'Update voucher details, validity period, and status',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
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
        Expanded(child: _buildPointsColumn(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsColumn(context),
        const SizedBox(height: 20),
        _buildPointsColumn(context),
      ],
    );
  }

  Widget _buildDetailsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('VOUCHER DETAILS', Icons.local_offer_outlined),
        const SizedBox(height: 14),
        _fieldLabel('Voucher Name', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _voucherNameController,
          hint: 'e.g. RM10 Welcome Discount',
          errorText: _nameError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Description', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _voucherDescriptionController,
          hint: 'Terms, applicable services, or redemption notes...',
          maxLines: 3,
          errorText: _descriptionError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Voucher Code', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _voucherCodeController,
          hint: 'e.g. WELCOME10',
          maxLines: 1,
          isUppercase: true,
          prefixIcon: Icons.qr_code_rounded,
          errorText: _codeError,
          maxLength: 10,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Linked Reward (Optional)'),
        const SizedBox(height: 6),
        _buildRewardDropdown(),
      ],
    );
  }

  Widget _buildPointsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('POINTS & VALIDITY', Icons.schedule_outlined),
        const SizedBox(height: 14),
        _fieldLabel('Points Required to Redeem', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _voucherPointController,
          hint: 'e.g. 50',
          isNumber: true,
          prefixIcon: Icons.stars_rounded,
          errorText: _pointError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Start Date', isRequired: true),
        const SizedBox(height: 6),
        _buildDatePickerField(
          controller: _startDateController,
          hint: 'Select start date',
          errorText: _startDateError,
          isStartDate: true,
        ),
        const SizedBox(height: 14),
        _fieldLabel('End Date', isRequired: true),
        const SizedBox(height: 6),
        _buildDatePickerField(
          controller: _endDateController,
          hint: 'Select end date',
          errorText: _endDateError,
          isStartDate: false,
        ),
        const SizedBox(height: 18),
        if (widget.type == 'update') ...[
          _buildStatusToggleCard(),
          const SizedBox(height: 14),
        ],
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildRewardDropdown() {
    if (widget.type == 'update' && _selectedReward != null) {
      return Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFF64748B)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _selectedReward!.name,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Tooltip(
              message: 'Linked reward cannot be changed after creation.',
              child: Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    if (_isLoadingRewards) {
      return Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: primary)),
            SizedBox(width: 10),
            Text('Loading rewards...', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return _styledDropdown(
      items: [
        DropdownAttribute('', 'No Linked Reward (Points Only)'),
        ..._rewards,
      ],
      value: _selectedReward?.name,
      hint: 'Select Linked Reward (Optional)',
      onChanged: (attr) {
        setState(() {
          if (attr == null || attr.key.isEmpty) {
            _selectedReward = null;
          } else {
            _selectedReward = attr;
          }
        });
      },
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    required bool isStartDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () async {
            DateTime? initial;
            if (controller.text.isNotEmpty) {
              try {
                initial = DateFormat('dd-MM-yyyy').parseStrict(controller.text);
              } catch (_) {}
            }
            final results = await showCalendarDatePicker2Dialog(
              context: context,
              config: CalendarDatePicker2WithActionButtonsConfig(
                currentDate: initial ?? DateTime.now(),
              ),
              dialogSize: const Size(360, 360),
              borderRadius: BorderRadius.circular(16),
            );
            if (results != null && results.isNotEmpty && results.first != null) {
              setState(() {
                controller.text = dateConverter('${results.first}', format: 'dd-MM-yyyy') ?? '';
                if (isStartDate) {
                  _startDateError = null;
                } else {
                  _endDateError = null;
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    controller.text.isNotEmpty ? controller.text : hint,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: controller.text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: controller.text.isNotEmpty ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                    splashRadius: 14,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => controller.clear()),
                  ),
              ],
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

  Widget _buildStatusToggleCard() {
    final isActive = _voucherStatus == 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isActive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 20,
            color: isActive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Status: Active' : 'Status: Inactive',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  isActive ? 'Visible and redeemable by patients' : 'Hidden from patient redemption catalog',
                  style: TextStyle(
                    fontSize: 11,
                    color: isActive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeTrackColor: const Color(0xFF16A34A),
            activeThumbColor: Colors.white,
            onChanged: (val) {
              setState(() => _voucherStatus = val ? 1 : 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF64748B)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'When clinic staff scan a customer QR code, linked reward vouchers are automatically verified and redeemed.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4),
            ),
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
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            label: Text(
              widget.type == 'create' ? 'Create Voucher' : 'Update Voucher',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
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
    bool isUppercase = false,
    IconData? prefixIcon,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: maxLines == 1 ? 42 : null,
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: [
              if (isNumber) FilteringTextInputFormatter.digitsOnly,
              if (isUppercase) UpperCaseTextFormatter(),
              if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
            ],
            maxLines: maxLines,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              fontFamily: isUppercase ? 'monospace' : null,
              letterSpacing: isUppercase ? 0.8 : 0,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 16, color: const Color(0xFF64748B)) : null,
              counterText: '',
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
                borderSide: BorderSide(color: primary, width: 1.5),
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
            child: DropdownButton<DropdownAttribute>(
              isExpanded: true,
              value: hasValue ? items.cast<DropdownAttribute?>().firstWhere((e) => e?.name == value, orElse: () => null) : null,
              hint: Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
              items: items.map((attr) {
                return DropdownMenuItem<DropdownAttribute>(
                  value: attr,
                  child: Text(
                    attr.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
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
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
