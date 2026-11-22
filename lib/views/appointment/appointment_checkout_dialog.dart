import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_checkout_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/launcher/web_launcher.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';

const Color _purpleAccent = Color(0xFF7C3AED);
const Color _purpleSoftBg = Color(0xFFF5F3FF);

/// Signature of [AppointmentCheckoutController.fetchPreview].
typedef CheckoutPreviewLoader = Future<ApiResponse<CheckoutPreviewData>> Function(
  BuildContext context,
  String appointmentId,
);

/// Signature of [AppointmentCheckoutController.submitCheckout].
typedef CheckoutSubmitter = Future<ApiResponse<CheckoutResultData>> Function(
  BuildContext context,
  String appointmentId, {
  double? totalSpend,
  required double basePrice,
  required double bookingFeePaid,
  required List<CheckoutAddOnItem> extraItems,
  required double netCollected,
  required String paymentMethod,
  bool awardPoints,
  required int basePoints,
  required int milestoneBonusPoints,
  String? milestoneKey,
  String? milestoneName,
  String? adminNotes,
});

/// Recommendation for next scan / follow-up visit.
class NextMilestoneRecommendation {
  final String title;
  final String description;
  final String? serviceKeyword;

  const NextMilestoneRecommendation({
    required this.title,
    required this.description,
    this.serviceKeyword,
  });
}

NextMilestoneRecommendation nextMilestoneAfter(String? completedMilestoneKey) {
  return switch (completedMilestoneKey) {
    'nt_scan' => const NextMilestoneRecommendation(
        title: 'W18–24 Detail Anomaly Scan',
        description: 'Comprehensive organ anatomy & defect screening (~6–8 weeks from now).',
        serviceKeyword: 'detail',
      ),
    'detail_scan' => const NextMilestoneRecommendation(
        title: 'W26–32 4D/5D HD Live Baby Scan',
        description: 'Real-time facial features & emotional bonding ultrasound (~6–8 weeks from now).',
        serviceKeyword: '4d',
      ),
    'scan_4d5d' => const NextMilestoneRecommendation(
        title: 'W33–36 Growth & Position Doppler Scan',
        description: 'Late pregnancy fetal biometry & placental check (~4–6 weeks from now).',
        serviceKeyword: 'growth',
      ),
    'growth_scan' => const NextMilestoneRecommendation(
        title: 'Postnatal & Newborn Care Visit',
        description: '6-week maternal healing, newborn health check & lactation support.',
      ),
    _ => const NextMilestoneRecommendation(
        title: 'Next Follow-Up Appointment',
        description: 'Lock in patient\'s next clinical visit or routine scan before leaving.',
      ),
  };
}

class AppointmentCheckoutDialog extends StatefulWidget {
  final String appointmentId;
  final VoidCallback? onCompleted;

  final CheckoutPreviewLoader loadPreview;
  final CheckoutSubmitter submitCheckout;
  final AvailableServicesLoader loadRebookingServices;

  const AppointmentCheckoutDialog({
    super.key,
    required this.appointmentId,
    this.onCompleted,
    this.loadPreview = AppointmentCheckoutController.fetchPreview,
    this.submitCheckout = AppointmentCheckoutController.submitCheckout,
    this.loadRebookingServices = ServiceBranchController.available,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String appointmentId,
    VoidCallback? onCompleted,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppointmentCheckoutDialog(
        appointmentId: appointmentId,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<AppointmentCheckoutDialog> createState() => _AppointmentCheckoutDialogState();
}

class _AppointmentCheckoutDialogState extends State<AppointmentCheckoutDialog> {
  bool _loading = true;
  String? _error;
  CheckoutPreviewData? _preview;

  late TextEditingController _totalSpendCtrl;
  late TextEditingController _notesCtrl;
  bool _submitting = false;

  CheckoutResultData? _result;

  @override
  void initState() {
    super.initState();
    _totalSpendCtrl = TextEditingController(text: '0.00');
    _notesCtrl = TextEditingController();
    _loadPreview();
  }

  @override
  void dispose() {
    _totalSpendCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await widget.loadPreview(context, widget.appointmentId);
    if (!mounted) return;

    if (responseCode(res.code) && res.data != null) {
      final data = res.data!;
      setState(() {
        _preview = data;
        _totalSpendCtrl.text = data.basePrice.toStringAsFixed(2);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load appointment details.';
        _loading = false;
      });
    }
  }

  double get _totalSpend => double.tryParse(_totalSpendCtrl.text.trim()) ?? 0.0;
  int get _pointsAwarded => math.max(0, (_totalSpend / 10).floor());

  Future<void> _submitCheckout() async {
    if (_submitting) return;
    if (_totalSpend < 0) {
      AppToast.snackbar(context, 'Please enter a valid total spend amount.');
      return;
    }

    setState(() => _submitting = true);

    final res = await widget.submitCheckout(
      context,
      widget.appointmentId,
      totalSpend: _totalSpend,
      basePrice: _totalSpend,
      bookingFeePaid: _preview?.bookingFeePaid ?? 0.0,
      extraItems: const [],
      netCollected: _totalSpend,
      paymentMethod: 'other',
      awardPoints: true,
      basePoints: _pointsAwarded,
      milestoneBonusPoints: 0,
      adminNotes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (responseCode(res.code) && res.data != null) {
      setState(() => _result = res.data);
      widget.onCompleted?.call();
      AppToast.snackbar(context, 'Appointment completed & points credited!');
    } else {
      AppToast.snackbar(context, res.message ?? 'Checkout failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = math.min(520.0, screenW - 32);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogW,
          maxHeight: MediaQuery.sizeOf(context).height * 0.90,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? _buildLoading(colors)
              : _error != null
                  ? _buildError(colors)
                  : _result != null
                      ? _buildReceiptView(colors)
                      : _buildFormView(colors),
        ),
      ),
    );
  }

  Widget _buildLoading(AppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: colors.brandPrimary),
          const SizedBox(height: 14),
          Text(
            'Loading appointment...',
            style: TextStyle(fontSize: 13, color: colors.inkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildError(AppColors colors) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, size: 40, color: colors.danger),
        const SizedBox(height: 12),
        Text('Checkout Error', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
        const SizedBox(height: 6),
        Text(_error!, style: TextStyle(fontSize: 13, color: colors.inkMuted), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton.secondary(text: 'Close', onPressed: () => Navigator.of(context).pop(false)),
            const SizedBox(width: 8),
            AppButton.primary(text: 'Retry', onPressed: _loadPreview),
          ],
        ),
      ],
    );
  }

  Widget _buildFormView(AppColors colors) {
    final p = _preview!;
    final pts = _pointsAwarded;
    final newBalance = p.currentPoints + pts;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.brandSoftBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.check_circle_outline_rounded, color: colors.brandPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Complete Visit & Award Points',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Key in patient total spend to credit loyalty points.',
                      style: TextStyle(fontSize: 12, color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, size: 20, color: colors.inkMuted),
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Patient Info Card ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.patientName,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.serviceName} · ${p.branchName}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.inkSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _purpleSoftBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _purpleAccent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars_rounded, size: 14, color: _purpleAccent),
                      const SizedBox(width: 4),
                      Text(
                        '${p.currentPoints} pts',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _purpleAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Total Amount Spent Field ───────────────────────────────
          Text(
            'Total Amount Spent (RM)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _totalSpendCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.inkPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 8),
                child: Text(
                  'RM',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.brandText),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.brandPrimary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Total amount spent by patient today (including deposit if any)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colors.inkMuted),
          ),
          const SizedBox(height: 18),

          // ── Points Preview Card ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _purpleSoftBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _purpleAccent.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _purpleAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.stars_rounded, color: _purpleAccent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '+$pts Aurora Points',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: _purpleAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'RM 10 = 1 pt',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _purpleAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'New balance: $newBalance pts (Current: ${p.currentPoints} pts)',
                        style: TextStyle(fontSize: 11, color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Staff Checkout Note ────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Staff Remarks / Note (Optional)',
              hintText: 'e.g. Free supplement given, combo discount',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 22),

          // ── Action Buttons ─────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton.secondary(
                text: 'Cancel',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 10),
              AppButton.primary(
                text: _submitting ? 'Completing...' : 'Complete & Award $pts Pts',
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                onPressed: _submitting ? null : _submitCheckout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String title, String amount, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: textColor)),
          Text(
            amount,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  void _openRebooking({required String? serviceKeyword, required String note}) {
    final preview = _preview;
    final onCompleted = widget.onCompleted;
    Navigator.of(context).pop(true);
    showDialog(
      context: context,
      builder: (_) => AppointmentDetails(
        type: 'create',
        initialUserId: preview?.userId,
        initialUserName: preview?.patientName,
        initialUserPhone: preview?.patientPhone,
        initialBranchId: preview?.branchId,
        initialServiceKeyword: serviceKeyword,
        initialNote: note,
        refreshData: () => onCompleted?.call(),
        loadAvailableServices: widget.loadRebookingServices,
      ),
    );
  }

  Widget _buildReceiptView(AppColors colors) {
    final res = _result!;
    final nextMilestone = nextMilestoneAfter(_preview?.detectedMilestone?.key);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.successSoftBg,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: colors.success, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Appointment Completed!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.inkPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Total Spend RM ${res.grossTotal.toStringAsFixed(2)} · Awarded +${res.pointsAwarded} Aurora Points',
              style: TextStyle(fontSize: 13, color: colors.inkMuted),
            ),
          ),
          const SizedBox(height: 16),

          // Receipt Summary Box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _receiptRow('Patient', res.patientName, colors.inkPrimary),
                _receiptRow('Service', res.serviceName, colors.inkPrimary),
                _receiptRow('Total Spend (inc. deposit)', 'RM ${res.grossTotal.toStringAsFixed(2)}', colors.brandText),
                _receiptRow('Points Awarded', '+${res.pointsAwarded} pts', _purpleAccent),
                _receiptRow('New Patient Balance', '${res.newTotalPoints} pts', colors.success),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Gentle Next Appointment Recommendation Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.brandSoftBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.brandBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, color: colors.brandPrimary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Cadangan Imbasan Seterusnya (Pilihan)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.brandText),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  nextMilestone.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${nextMilestone.description} · Pesakit boleh memilih untuk tempah awal sekiranya berminat.',
                  style: TextStyle(fontSize: 12, color: colors.inkMuted),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppButton.primary(
                      text: 'Imbasan Seterusnya: ${nextMilestone.title}',
                      icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                      height: 36,
                      onPressed: () => _openRebooking(
                        serviceKeyword: nextMilestone.serviceKeyword,
                        note: 'Follow-up ${nextMilestone.title} after completing ${_preview?.serviceName}',
                      ),
                    ),
                    AppButton.secondary(
                      text: 'Susulan / Ulang Servis Sama (1–2 Minggu)',
                      icon: const Icon(Icons.replay_rounded, size: 14),
                      height: 36,
                      onPressed: () => _openRebooking(
                        serviceKeyword: _preview?.serviceName,
                        note: 'Routine follow-up / rescan for ${_preview?.serviceName} (Review in 1–2 weeks)',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Standard Action Buttons
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  text: 'Close Window',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
              if (res.whatsappUrl != null && res.whatsappUrl!.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton.primary(
                    text: 'Share WhatsApp Receipt',
                    icon: const Icon(Icons.send_rounded, size: 15),
                    onPressed: () {
                      launchWebUrl(res.whatsappUrl!, webOnlyWindowName: '_blank');
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
