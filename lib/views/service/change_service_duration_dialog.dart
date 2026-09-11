import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/models/service_branch/update_service_branch_request.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';

class ChangeServiceDurationDialog extends StatefulWidget {
  final service_branch_model.Data serviceBranch;
  final VoidCallback onSuccess;

  const ChangeServiceDurationDialog({
    super.key,
    required this.serviceBranch,
    required this.onSuccess,
  });

  @override
  State<ChangeServiceDurationDialog> createState() => _ChangeServiceDurationDialogState();
}

class _ChangeServiceDurationDialogState extends State<ChangeServiceDurationDialog> {
  final TextEditingController _numberController = TextEditingController();
  String _selectedUnit = 'minutes'; // 'minutes' or 'hours'
  bool _isResetToHq = false;
  bool _isSubmitting = false;

  final List<String> _presets = [
    '15 minutes',
    '20 minutes',
    '30 minutes',
    '45 minutes',
    '1 hour',
    '1 hour 15 minutes',
    '1 hour 30 minutes',
  ];

  String get _hqTime {
    final hq = widget.serviceBranch.hqServiceTime;
    if (hq != null && hq.trim().isNotEmpty) return hq.trim();
    final effective = widget.serviceBranch.serviceTime;
    if (effective != null && effective.trim().isNotEmpty) return effective.trim();
    return '30 minutes';
  }

  bool get _hasCustomOverride {
    final branchTime = widget.serviceBranch.branchServiceTime;
    return branchTime != null && branchTime.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _initFromCurrentDuration();
  }

  void _initFromCurrentDuration() {
    final currentTime = widget.serviceBranch.branchServiceTime ?? widget.serviceBranch.serviceTime ?? _hqTime;
    _parseAndSetDuration(currentTime);
  }

  void _parseAndSetDuration(String timeStr) {
    final lower = timeStr.toLowerCase().trim();
    final hourMatch = RegExp(r'(\d+)\s*hour').firstMatch(lower);
    final minuteMatch = RegExp(r'(\d+)\s*min').firstMatch(lower);

    if (hourMatch != null && minuteMatch == null) {
      _numberController.text = hourMatch.group(1) ?? '1';
      _selectedUnit = 'hours';
    } else if (minuteMatch != null && hourMatch == null) {
      _numberController.text = minuteMatch.group(1) ?? '30';
      _selectedUnit = 'minutes';
    } else if (hourMatch != null && minuteMatch != null) {
      // e.g. "1 hour 30 minutes" -> convert to total minutes for custom input
      final totalMins = (int.tryParse(hourMatch.group(1)!) ?? 0) * 60 + (int.tryParse(minuteMatch.group(1)!) ?? 0);
      _numberController.text = '$totalMins';
      _selectedUnit = 'minutes';
    } else {
      final numbersOnly = lower.replaceAll(RegExp(r'[^0-9]'), '');
      _numberController.text = numbersOnly.isNotEmpty ? numbersOnly : '30';
      _selectedUnit = 'minutes';
    }
    _isResetToHq = false;
  }

  String _formatDuration(String numberStr, String unit) {
    final num = int.tryParse(numberStr.trim()) ?? 0;
    if (num <= 0) return _hqTime;
    if (unit == 'hours') {
      return num == 1 ? '1 hour' : '$num hours';
    } else {
      if (num >= 60 && num % 60 == 0) {
        final hrs = num ~/ 60;
        return hrs == 1 ? '1 hour' : '$hrs hours';
      } else if (num > 60) {
        final hrs = num ~/ 60;
        final mins = num % 60;
        final hrStr = hrs == 1 ? '1 hour' : '$hrs hours';
        return '$hrStr $mins minutes';
      }
      return '$num minutes';
    }
  }

  String get _currentConfiguredDuration {
    if (_isResetToHq) return _hqTime;
    return _formatDuration(_numberController.text, _selectedUnit);
  }

  bool _isPresetSelected(String preset) {
    if (_isResetToHq) return false;
    final current = _currentConfiguredDuration.toLowerCase();
    final target = preset.toLowerCase();
    return current == target;
  }

  void _applyPreset(String preset) {
    setState(() {
      _parseAndSetDuration(preset);
      _isResetToHq = false;
    });
  }

  void _revertToHq() {
    setState(() {
      _isResetToHq = true;
      _parseAndSetDuration(_hqTime);
    });
  }

  Future<void> _handleSave() async {
    final serviceBranchId = widget.serviceBranch.serviceBranchId;
    if (serviceBranchId == null || serviceBranchId.isEmpty) {
      showDialogError(context, 'Missing service branch identifier.');
      return;
    }

    setState(() => _isSubmitting = true);
    showLoading();

    final request = UpdateServiceBranchRequest(
      serviceBranchId: serviceBranchId,
      resetToHqDefault: _isResetToHq,
      serviceTime: _isResetToHq ? null : _currentConfiguredDuration,
    );

    try {
      final res = await ServiceBranchController.update(context, request);
      dismissLoading();
      setState(() => _isSubmitting = false);

      if (responseCode(res.code)) {
        if (mounted) {
          context.pop();
          widget.onSuccess();
          showDialogSuccess(
            context,
            _isResetToHq
                ? 'Duration reverted to HQ standard ($_hqTime).'
                : 'Service duration updated to $_currentConfiguredDuration for ${widget.serviceBranch.branchName}.',
          );
        }
      } else {
        if (mounted) {
          showDialogError(context, res.message ?? res.data?.message ?? 'Failed to update duration');
        }
      }
    } catch (e) {
      dismissLoading();
      setState(() => _isSubmitting = false);
      if (mounted) {
        showDialogError(context, e.toString());
      }
    }
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serviceName = widget.serviceBranch.serviceName ?? 'Service';
    final branchName = widget.serviceBranch.branchName ?? 'Branch';
    final isOverridden = _hasCustomOverride;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: CardContainer(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: secondaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.timer_outlined, size: 20, color: secondaryColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Change Service Duration',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$serviceName • $branchName',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                      onPressed: () => context.pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Context Card: HQ Standard vs Branch Status
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.business_rounded, size: 16, color: Color(0xFF64748B)),
                              const SizedBox(width: 8),
                              Text(
                                'HQ Standard Duration:',
                                style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _hqTime,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                isOverridden ? Icons.tune_rounded : Icons.check_circle_outline_rounded,
                                size: 16,
                                color: isOverridden ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Current Status:',
                                style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isOverridden ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isOverridden ? const Color(0xFFFDE68A) : const Color(0xFFBBF7D0),
                                  ),
                                ),
                                child: Text(
                                  isOverridden
                                      ? 'Branch Custom: ${widget.serviceBranch.branchServiceTime}'
                                      : 'Using HQ Default',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isOverridden ? const Color(0xFFB45309) : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Preset chips
                    const Text(
                      'Quick Presets',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _presets.map((preset) {
                        final isSelected = _isPresetSelected(preset);
                        return InkWell(
                          onTap: () => _applyPreset(preset),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? primary.withAlpha(25) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? primary : const Color(0xFFD1D5DB),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.check_rounded, size: 14, color: primary),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  preset,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? primary : const Color(0xFF374151),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Custom input
                    const Text(
                      'Or Set Custom Duration',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _numberController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() => _isResetToHq = false),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '30',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 11),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnit,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
                                items: const [
                                  DropdownMenuItem(value: 'minutes', child: Text('Minutes', style: TextStyle(fontSize: 13))),
                                  DropdownMenuItem(value: 'hours', child: Text('Hours', style: TextStyle(fontSize: 13))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedUnit = val;
                                      _isResetToHq = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Preview pill
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right_alt_rounded, size: 16, color: Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Text(
                            'Will be set to: ',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            _currentConfiguredDuration,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary),
                          ),
                          if (_isResetToHq) ...[
                            const SizedBox(width: 6),
                            const Text(
                              '(HQ Standard)',
                              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Reset button if custom override is present or modified
                    if (isOverridden || _isResetToHq) ...[
                      InkWell(
                        onTap: _revertToHq,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isResetToHq ? const Color(0xFFEFF6FF) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isResetToHq ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.restart_alt_rounded,
                                size: 16,
                                color: _isResetToHq ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Reset to HQ Default ($_hqTime)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isResetToHq ? const Color(0xFF2563EB) : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting ? null : () => context.pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text('Cancel', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Duration',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
