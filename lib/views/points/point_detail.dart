import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_request.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart' as reward;
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart' as voucher;
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:provider/provider.dart';

class PointDetail extends StatefulWidget {
  final UserResponse? user;
  const PointDetail({super.key, required this.user});

  @override
  State<PointDetail> createState() => _PointDetailState();
}

class _PointDetailState extends State<PointDetail> {
  // 'points' = manual points, 'voucher' = award voucher, 'reward' = claim reward
  String _actionType = 'points';

  final TextEditingController _pointsController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  voucher.Data? _selectedVoucher;
  reward.Data? _selectedReward;

  String? _pointsError;
  String? _voucherError;
  String? _rewardError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-load vouchers and rewards if not cached
    if (context.read<VoucherController>().voucherAllResponse == null) {
      VoucherController.getAll(context, 1, pageSize).then((value) {
        if (mounted) context.read<VoucherController>().voucherAllResponse = value;
      });
    }
    if (context.read<RewardController>().rewardAllResponse == null) {
      RewardController.getAll(context, 1, pageSize).then((value) {
        if (mounted) context.read<RewardController>().rewardAllResponse = value;
      });
    }
  }

  @override
  void dispose() {
    _pointsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'PT';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool _validate() {
    setState(() {
      _pointsError = null;
      _voucherError = null;
      _rewardError = null;
    });

    if (_actionType == 'points') {
      final val = int.tryParse(_pointsController.text.trim());
      if (val == null || val <= 0) {
        setState(() => _pointsError = 'Please enter a valid points amount greater than 0');
        return false;
      }
    } else if (_actionType == 'voucher') {
      if (_selectedVoucher == null) {
        setState(() => _voucherError = 'Please select a voucher to issue');
        return false;
      }
    } else if (_actionType == 'reward') {
      if (_selectedReward == null) {
        setState(() => _rewardError = 'Please select a reward to redeem');
        return false;
      }
      final userPts = widget.user?.totalPoint ?? 0;
      final reqPts = _selectedReward?.rewardPoint ?? 0;
      if (reqPts > userPts) {
        setState(() => _rewardError = 'Insufficient balance ($userPts pts). Requires $reqPts pts.');
        return false;
      }
    }
    return true;
  }

  void _submit() {
    if (!_validate() || _isSaving) return;

    final userId = widget.user?.userId;
    if (userId == null) {
      showDialogError(context, 'User ID not found');
      return;
    }

    setState(() => _isSaving = true);
    showLoading();

    int? pointType;
    int? totalPoint;
    String? voucherId;
    String? rewardId;

    if (_actionType == 'points') {
      pointType = null; // Backend defaults to SPENDING (adds points)
      totalPoint = int.parse(_pointsController.text.trim());
    } else if (_actionType == 'voucher') {
      pointType = 2; // Voucher
      voucherId = _selectedVoucher?.voucherId;
      totalPoint = _selectedVoucher?.voucherPoint;
    } else if (_actionType == 'reward') {
      pointType = 3; // Reward
      rewardId = _selectedReward?.rewardId;
      totalPoint = _selectedReward?.rewardPoint;
    }

    final req = CreatePointRequest(
      userId: userId,
      pointType: pointType,
      totalPoint: totalPoint,
      voucherId: voucherId,
      rewardId: rewardId,
      pointDescription: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
    );

    PointManagementController.create(context, req).then((value) {
      if (responseCode(value.code)) {
        // Refresh points data in both controllers
        PointManagementController.get(context, 1, userId: userId).then((val) {
          if (mounted && responseCode(val.code)) {
            context.read<PointManagementController>().userPointsResponse = val.data;
          }
        });
        UserController.points(context, userId).then((val) {
          dismissLoading();
          if (mounted) {
            setState(() => _isSaving = false);
            if (responseCode(val.code)) {
              context.read<UserController>().userPoints = val.data;
            }
            context.pop(true);
            showDialogSuccess(context, 'Successfully updated customer\'s points');
          }
        }).catchError((_) {
          dismissLoading();
          if (mounted) {
            setState(() => _isSaving = false);
            context.pop(true);
            showDialogSuccess(context, 'Successfully updated customer\'s points');
          }
        });
      } else {
        dismissLoading();
        if (mounted) {
          setState(() => _isSaving = false);
          showDialogError(context, value.message ?? value.data?.message ?? 'Failed to update points');
        }
      }
    }).catchError((e) {
      dismissLoading();
      if (mounted) {
        setState(() => _isSaving = false);
        showDialogError(context, e.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPatientCard(),
                    const SizedBox(height: 18),
                    _fieldLabel('Adjustment Action', isRequired: true),
                    const SizedBox(height: 8),
                    _buildActionTypeSelector(),
                    const SizedBox(height: 16),
                    _buildDynamicFields(),
                  ],
                ),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.stars_rounded, size: 20, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Points Management',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Adjust points, issue voucher, or redeem reward',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF94A3B8)),
            splashRadius: 18,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientCard() {
    final name = widget.user?.userFullname ?? 'Patient';
    final username = widget.user?.userName ?? '—';
    final points = widget.user?.totalPoint ?? 0;
    final initials = _getInitials(name);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: primary.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: TextStyle(color: primary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  '$points pts',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _actionTabItem(
              type: 'points',
              label: 'Manual Points',
              icon: Icons.add_circle_outline_rounded,
            ),
          ),
          Expanded(
            child: _actionTabItem(
              type: 'voucher',
              label: 'Voucher',
              icon: Icons.confirmation_number_outlined,
            ),
          ),
          Expanded(
            child: _actionTabItem(
              type: 'reward',
              label: 'Reward Claim',
              icon: Icons.redeem_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTabItem({required String type, required String label, required IconData icon}) {
    final isSelected = _actionType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _actionType = type;
          _pointsError = null;
          _voucherError = null;
          _rewardError = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? primary : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primary : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicFields() {
    if (_actionType == 'points') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Points to Award *'),
          const SizedBox(height: 6),
          _styledInput(
            controller: _pointsController,
            hint: 'e.g. 50',
            isNumber: true,
            prefixIcon: Icons.stars_rounded,
            errorText: _pointsError,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Reason / Remarks (Optional)'),
          const SizedBox(height: 6),
          _styledInput(
            controller: _descriptionController,
            hint: 'e.g. In-clinic consultation, Goodwill bonus',
            prefixIcon: Icons.notes_rounded,
          ),
        ],
      );
    } else if (_actionType == 'voucher') {
      final vouchers = context.watch<VoucherController>().voucherAllResponse?.data?.data ?? [];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Select Voucher to Issue *'),
          const SizedBox(height: 6),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _voucherError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<voucher.Data>(
                isExpanded: true,
                isDense: true,
                hint: Text(
                  _selectedVoucher != null
                      ? '${_selectedVoucher?.voucherName ?? '—'} (${_selectedVoucher?.voucherPoint ?? 0} pts)'
                      : 'Select an active voucher...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedVoucher != null ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedVoucher != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                items: vouchers
                    .map(
                      (item) => DropdownItem<voucher.Data>(
                        value: item,
                        child: Text(
                          '${item.voucherName ?? '—'} (${item.voucherPoint ?? 0} pts)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedVoucher = val;
                    _voucherError = null;
                  });
                },
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                ),
                dropdownStyleData: DropdownStyleData(
                  elevation: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          if (_voucherError != null) ...[
            const SizedBox(height: 4),
            Text(_voucherError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
          ],
          if (_selectedVoucher != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Awards ${_selectedVoucher?.voucherPoint ?? 0} points to patient upon claiming.',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      // Reward claim
      final rewards = context.watch<RewardController>().rewardAllResponse?.data?.data ?? [];
      final userPts = widget.user?.totalPoint ?? 0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Select Reward to Redeem *'),
          const SizedBox(height: 6),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _rewardError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton2<reward.Data>(
                isExpanded: true,
                isDense: true,
                hint: Text(
                  _selectedReward != null
                      ? '${_selectedReward?.rewardName ?? '—'} (Cost: ${_selectedReward?.rewardPoint ?? 0} pts)'
                      : 'Select a reward catalog item...',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: _selectedReward != null ? FontWeight.w600 : FontWeight.normal,
                    color: _selectedReward != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                items: rewards
                    .map(
                      (item) => DropdownItem<reward.Data>(
                        value: item,
                        child: Text(
                          '${item.rewardName ?? '—'} (Cost: ${item.rewardPoint ?? 0} pts)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedReward = val;
                    _rewardError = null;
                  });
                },
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                ),
                dropdownStyleData: DropdownStyleData(
                  elevation: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          if (_rewardError != null) ...[
            const SizedBox(height: 4),
            Text(_rewardError!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11)),
          ],
          if (_selectedReward != null) ...[
            const SizedBox(height: 10),
            Builder(
              builder: (_) {
                final req = _selectedReward?.rewardPoint ?? 0;
                final isSufficient = userPts >= req;
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSufficient ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isSufficient ? const Color(0xFFBFDBFE) : const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSufficient ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
                        size: 16,
                        color: isSufficient ? const Color(0xFF1D4ED8) : const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSufficient
                              ? 'Deducts $req points from customer balance (Remaining: ${userPts - req} pts).'
                              : 'Insufficient points! Customer needs $req pts but only has $userPts pts.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSufficient ? const Color(0xFF1E40AF) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      );
    }
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

  Widget _styledInput({
    required TextEditingController controller,
    required String hint,
    String? errorText,
    bool isNumber = false,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded, size: 16, color: Colors.white),
            label: Text(
              _isSaving ? 'Submitting...' : 'Confirm Points',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
