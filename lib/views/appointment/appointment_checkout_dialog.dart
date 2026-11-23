import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
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

/// The scan to recommend after [completedMilestoneKey]. Titles come from the
/// checkout preview's [milestones] (labels like "W18–24 Detail Anomaly Scan",
/// with the clinic's windows for this patient, single or twins); without them
/// the title has no weeks rather than guessing.
NextMilestoneRecommendation nextMilestoneAfter(
  String? completedMilestoneKey, {
  List<CheckoutMilestoneRule> milestones = const [],
}) {
  String titleFor(String key, String fallback) {
    for (final m in milestones) {
      if (m.key == key && m.label.isNotEmpty) return m.label;
    }
    return fallback;
  }

  return switch (completedMilestoneKey) {
    'nt_scan' => NextMilestoneRecommendation(
        title: titleFor('detail_scan', 'Detail Anomaly Scan'),
        description: 'Comprehensive organ anatomy & defect screening.',
        serviceKeyword: 'detail',
      ),
    'detail_scan' => NextMilestoneRecommendation(
        title: titleFor('scan_4d5d', '4D/5D HD Live Baby Scan'),
        description: 'Real-time facial features & emotional bonding ultrasound.',
        serviceKeyword: '4d',
      ),
    'scan_4d5d' => NextMilestoneRecommendation(
        title: titleFor('growth_scan', 'Growth & Position Scan'),
        description: 'Late pregnancy fetal biometry & placental check.',
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
  final BabyTrackerProfileLoader loadBabyTrackerProfile;

  const AppointmentCheckoutDialog({
    super.key,
    required this.appointmentId,
    this.onCompleted,
    this.loadPreview = AppointmentCheckoutController.fetchPreview,
    this.submitCheckout = AppointmentCheckoutController.submitCheckout,
    this.loadRebookingServices = ServiceBranchController.available,
    this.loadBabyTrackerProfile = UserController.babyTracker,
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

  late TextEditingController _counterPaidCtrl;
  late TextEditingController _notesCtrl;
  bool _submitting = false;

  CheckoutResultData? _result;

  @override
  void initState() {
    super.initState();
    _counterPaidCtrl = TextEditingController(text: '0.00');
    _notesCtrl = TextEditingController();
    _loadPreview();
  }

  @override
  void dispose() {
    _counterPaidCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _basePrice => _preview?.basePrice ?? 0.0;
  double get _deposit {
    if (_preview == null) return 0.0;
    return _preview!.serviceBookingFee > 0 ? _preview!.serviceBookingFee : _preview!.bookingFeePaid;
  }

  double get _expectedBalance => math.max(0.0, _basePrice - _deposit);
  double get _counterPaid => double.tryParse(_counterPaidCtrl.text.trim()) ?? 0.0;
  double get _totalSpend => math.max(0.0, _counterPaid + _deposit);
  double get _extraAmount => _counterPaid > _expectedBalance ? (_counterPaid - _expectedBalance) : 0.0;
  double get _discountAmount =>
      (_expectedBalance > _counterPaid && _counterPaid > 0) ? (_expectedBalance - _counterPaid) : 0.0;
  int get _pointsAwarded => math.max(0, _totalSpend.floor());

  Future<void> _loadPreview() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await widget.loadPreview(context, widget.appointmentId);
    if (!mounted) return;

    if (responseCode(res.code) && res.data != null) {
      final data = res.data!;
      final deposit = data.serviceBookingFee > 0 ? data.serviceBookingFee : data.bookingFeePaid;
      final expected = math.max(0.0, data.basePrice - deposit);

      setState(() {
        _preview = data;
        _counterPaidCtrl.text = expected.toStringAsFixed(2);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load appointment details.';
        _loading = false;
      });
    }
  }

  Future<void> _submitCheckout() async {
    if (_submitting) return;
    if (_counterPaid < 0) {
      AppToast.snackbar(context, 'Please enter a valid counter payment amount.');
      return;
    }

    setState(() => _submitting = true);

    final res = await widget.submitCheckout(
      context,
      widget.appointmentId,
      totalSpend: _totalSpend,
      basePrice: _basePrice,
      bookingFeePaid: _deposit,
      extraItems: const [],
      netCollected: _counterPaid,
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
    final dialogW = math.min(540.0, screenW - 32);

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogW,
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
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
    final deposit = _deposit;
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
                      'Verify counter payment & award patient points.',
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
          const SizedBox(height: 16),

          // ── Service & Deposit Context Breakdown ───────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _breakdownRow(
                  'Service Price',
                  'RM ${_basePrice.toStringAsFixed(2)}',
                  colors.inkPrimary,
                ),
                if (deposit > 0) ...[
                  _breakdownRow(
                    'Deposit (Paid Online / Booked)',
                    '-RM ${deposit.toStringAsFixed(2)}',
                    colors.brandText,
                  ),
                  const Divider(height: 12),
                  _breakdownRow(
                    'Expected Counter Balance',
                    'RM ${_expectedBalance.toStringAsFixed(2)}',
                    colors.inkPrimary,
                    isBold: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Counter Payment Input Field ───────────────────────────
          Text(
            deposit > 0 ? 'Amount Paid at Counter Today (RM)' : 'Total Amount Paid (RM)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _counterPaidCtrl,
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
          const SizedBox(height: 4),
          Text(
            deposit > 0
                ? 'Pre-populated with expected balance RM ${_expectedBalance.toStringAsFixed(2)}. If patient bought extra items (e.g. vitamins), key in the actual amount paid at counter.'
                : 'Pre-populated with service price RM ${_basePrice.toStringAsFixed(2)}. Key in total paid today.',
            style: TextStyle(fontSize: 11, color: colors.inkMuted),
          ),
          const SizedBox(height: 14),

          // ── Live Spend Breakdown Card ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.brandSoftBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.brandBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (deposit > 0)
                  _breakdownRow(
                    'Online Booking Deposit',
                    'RM ${deposit.toStringAsFixed(2)}',
                    colors.inkSecondary,
                  ),
                _breakdownRow(
                  'Paid at Counter Today',
                  'RM ${_counterPaid.toStringAsFixed(2)}',
                  colors.inkSecondary,
                ),
                if (_extraAmount > 0)
                  _breakdownRow(
                    'Extra Add-ons / Items',
                    '+RM ${_extraAmount.toStringAsFixed(2)}',
                    colors.success,
                    isBold: true,
                  ),
                if (_discountAmount > 0)
                  _breakdownRow(
                    'Discount / Adjustment',
                    '-RM ${_discountAmount.toStringAsFixed(2)}',
                    colors.danger,
                  ),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Patient Spend Today',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    Text(
                      'RM ${_totalSpend.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: colors.brandText,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                              'RM 1 = 1 pt',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _purpleAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Points calculated on Total Spend RM ${_totalSpend.toStringAsFixed(2)} · New balance: $newBalance pts',
                        style: TextStyle(fontSize: 11, color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Staff Checkout Note ────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: 'Staff Remarks / Note (Optional)',
              hintText: 'e.g. Free supplement given, extra printout',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 20),

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

  Widget _breakdownRow(String title, String amount, Color textColor, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
              fontFamily: 'monospace',
            ),
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
        loadBabyTrackerProfile: widget.loadBabyTrackerProfile,
      ),
    );
  }

  Widget _buildReceiptView(AppColors colors) {
    final res = _result!;
    final nextMilestone = nextMilestoneAfter(
      _preview?.detectedMilestone?.key,
      milestones: _preview?.milestones ?? const [],
    );
    final deposit = _deposit;
    final counterPaid = _counterPaid;
    final extra = _extraAmount;

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
                if (deposit > 0) _receiptRow('Deposit (Included)', 'RM ${deposit.toStringAsFixed(2)}', colors.inkSecondary),
                _receiptRow('Paid at Counter Today', 'RM ${counterPaid.toStringAsFixed(2)}', colors.inkSecondary),
                if (extra > 0) _receiptRow('Extra Add-ons', '+RM ${extra.toStringAsFixed(2)}', colors.success),
                const Divider(height: 12),
                _receiptRow('Total Spend', 'RM ${res.grossTotal.toStringAsFixed(2)}', colors.brandText),
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
