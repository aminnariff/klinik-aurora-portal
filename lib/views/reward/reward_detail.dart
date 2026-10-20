import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/models/reward/create_reward_request.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart';
import 'package:klinik_aurora_portal/models/reward/update_reward_request.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/app_image_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class RewardDetail extends StatefulWidget {
  final Data? reward;
  final String type; // 'create' or 'update'

  const RewardDetail({super.key, required this.reward, required this.type});

  @override
  State<RewardDetail> createState() => _RewardDetailState();
}

class _RewardDetailState extends State<RewardDetail> {
  final TextEditingController _rewardName = TextEditingController();
  final TextEditingController _rewardDescription = TextEditingController();
  final TextEditingController _rewardPoint = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();
  final TextEditingController _rewardTotal = TextEditingController();
  final InputFieldAttribute _rewardImageField = InputFieldAttribute(
    controller: TextEditingController(),
  );

  int _rewardStatus = 1; // 1 = Active, 0 = Inactive
  bool _isSubmitting = false;

  String? _nameError;
  String? _descError;
  String? _pointError;
  String? _totalError;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'update' && widget.reward != null) {
      final r = widget.reward!;
      _rewardName.text = r.rewardName ?? '';
      _rewardDescription.text = r.rewardDescription ?? '';
      _rewardPoint.text = r.rewardPoint?.toString() ?? '';
      _startDate.text = dateConverter(r.rewardStartDate, format: 'dd-MM-yyyy') ?? '';
      _endDate.text = dateConverter(r.rewardEndDate, format: 'dd-MM-yyyy') ?? '';
      _rewardTotal.text = r.totalReward?.toString() ?? '0';
      _rewardImageField.controller.text = r.rewardImage ?? '';
      _rewardStatus = r.rewardStatus ?? 1;
    } else {
      _rewardTotal.text = '0'; // default unlimited
    }
  }

  @override
  void dispose() {
    _rewardName.dispose();
    _rewardDescription.dispose();
    _rewardPoint.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _rewardTotal.dispose();
    _rewardImageField.controller.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    setState(() {
      _nameError = null;
      _descError = null;
      _pointError = null;
      _totalError = null;

      if (_rewardName.text.trim().isEmpty) {
        _nameError = 'Reward name is required';
        valid = false;
      }
      if (_rewardDescription.text.trim().isEmpty) {
        _descError = 'Description is required';
        valid = false;
      }
      if (_rewardPoint.text.trim().isEmpty) {
        _pointError = 'Points required';
        valid = false;
      } else if (int.tryParse(_rewardPoint.text.trim()) == null) {
        _pointError = 'Must be a valid number';
        valid = false;
      }
      if (_rewardTotal.text.trim().isEmpty) {
        _totalError = 'Quantity is required (enter 0 for unlimited)';
        valid = false;
      } else if (int.tryParse(_rewardTotal.text.trim()) == null) {
        _totalError = 'Must be a valid integer';
        valid = false;
      }
    });
    return valid;
  }

  void _handleSubmit() {
    if (!_validate()) return;

    setState(() => _isSubmitting = true);
    showLoading();

    final imgVal = _rewardImageField.controller.text.trim().isEmpty
        ? null
        : _rewardImageField.controller.text.trim();
    final points = int.parse(_rewardPoint.text.trim());
    final total = int.parse(_rewardTotal.text.trim());

    if (widget.type == 'update') {
      RewardController.update(
        context,
        UpdateRewardRequest(
          rewardId: widget.reward?.rewardId ?? '',
          rewardName: _rewardName.text.trim(),
          rewardDescription: _rewardDescription.text.trim(),
          rewardPoint: points,
          rewardStartDate: _startDate.text.trim().isNotEmpty
              ? convertStringToDate(_startDate.text.trim())
              : null,
          rewardEndDate: _endDate.text.trim().isNotEmpty
              ? convertStringToDate(_endDate.text.trim())
              : null,
          totalReward: total,
          rewardStatus: _rewardStatus,
          rewardImage: imgVal,
        ),
      ).then((value) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        if (responseCode(value.code)) {
          context.pop();
          _refreshAndShowToast(isUpdate: true);
        } else {
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
    } else {
      RewardController.create(
        context,
        CreateRewardRequest(
          rewardName: _rewardName.text.trim(),
          rewardDescription: _rewardDescription.text.trim(),
          rewardPoint: points,
          rewardStartDate: _startDate.text.trim().isNotEmpty
              ? convertStringToDate(_startDate.text.trim())
              : null,
          rewardEndDate: _endDate.text.trim().isNotEmpty
              ? convertStringToDate(_endDate.text.trim())
              : null,
          totalReward: total,
          rewardImage: imgVal,
        ),
      ).then((value) {
        dismissLoading();
        setState(() => _isSubmitting = false);
        if (responseCode(value.code)) {
          context.pop();
          _refreshAndShowToast(isUpdate: false);
        } else {
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
    }
  }

  void _refreshAndShowToast({required bool isUpdate}) {
    RewardController.getAll(context, 1, pageSize).then((value) {
      if (responseCode(value.code)) {
        context.read<RewardController>().rewardAllResponse = value;
      }
      if (isUpdate) {
        showDialogSuccess(context, 'Successfully updated reward');
      } else {
        showDialogSuccess(context, 'Successfully created new reward');
      }
    });
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
            child: const Icon(Icons.card_giftcard_rounded, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isCreate ? 'New Reward' : 'Edit Reward',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  isCreate
                      ? 'Create a redeemable reward item for customers'
                      : 'Update reward details, points, stock, and availability',
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
        Expanded(child: _buildImageScheduleColumn(context)),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailsColumn(context),
        const SizedBox(height: 20),
        _buildImageScheduleColumn(context),
      ],
    );
  }

  Widget _buildDetailsColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('REWARD DETAILS', Icons.card_giftcard_outlined),
        const SizedBox(height: 14),
        _fieldLabel('Reward Name', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _rewardName,
          hint: 'e.g. Complimentary Facial Treatment',
          errorText: _nameError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Description', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _rewardDescription,
          hint: 'Describe reward perks, terms, or clinic redemption...',
          maxLines: 4,
          errorText: _descError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Points Required to Redeem', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _rewardPoint,
          hint: 'e.g. 500',
          isNumber: true,
          prefixIcon: Icons.stars_rounded,
          errorText: _pointError,
        ),
        const SizedBox(height: 14),
        _fieldLabel('Total Quantity / Stock', isRequired: true),
        const SizedBox(height: 6),
        _styledTextField(
          controller: _rewardTotal,
          hint: '0 for unlimited inventory',
          isNumber: true,
          prefixIcon: Icons.inventory_2_outlined,
          errorText: _totalError,
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter "0" if stock is infinite / unlimited.',
          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
        ),
      ],
    );
  }

  Widget _buildImageScheduleColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('REWARD IMAGE', Icons.image_outlined),
        const SizedBox(height: 12),
        AppImageField(
          field: _rewardImageField,
          folder: 'reward',
          previewHeight: 140,
          previewWidth: 220,
        ),
        const SizedBox(height: 20),
        _sectionHeader('AVAILABILITY & SCHEDULE', Icons.schedule_outlined),
        const SizedBox(height: 14),
        _fieldLabel('Start Date (Optional)'),
        const SizedBox(height: 6),
        _buildDatePickerField(
          controller: _startDate,
          hint: 'Select start date (optional)',
        ),
        const SizedBox(height: 14),
        _fieldLabel('End Date (Optional)'),
        const SizedBox(height: 6),
        _buildDatePickerField(
          controller: _endDate,
          hint: 'Select end date (optional)',
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leave dates blank to keep this reward available indefinitely.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                ),
              ),
            ],
          ),
        ),
        if (widget.type == 'update') ...[
          const SizedBox(height: 16),
          _buildStatusToggleCard(),
        ],
      ],
    );
  }

  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String hint,
  }) {
    return InkWell(
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
          border: Border.all(color: const Color(0xFFCBD5E1)),
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
    );
  }

  Widget _buildStatusToggleCard() {
    final isActive = _rewardStatus == 1;
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
                  isActive ? 'Patients can redeem this item' : 'Hidden from patient reward catalog',
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
              setState(() => _rewardStatus = val ? 1 : 0);
            },
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _handleSubmit,
            icon: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
            label: Text(
              widget.type == 'create' ? 'Create Reward' : 'Update Reward',
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
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: [
              if (isNumber) FilteringTextInputFormatter.digitsOnly,
            ],
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
}
