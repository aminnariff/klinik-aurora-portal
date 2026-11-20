import 'dart:math' as math;

import 'package:flutter/material.dart';
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

/// The scan the counter should offer to book next, given the pregnancy
/// milestone the patient has just completed.
class NextMilestoneRecommendation {
  final String title;
  final String description;
  final int bonusPoints;

  /// Matched case-insensitively against branch service names to preselect the
  /// next scan in the booking form. Null when there is no specific scan to
  /// advance to, so the cashier picks the service by hand.
  final String? serviceKeyword;

  const NextMilestoneRecommendation({
    required this.title,
    required this.description,
    required this.bonusPoints,
    this.serviceKeyword,
  });
}

/// Scans advance NT/dating → Detail → 4D/5D → Growth, then postnatal care.
NextMilestoneRecommendation nextMilestoneAfter(String? completedMilestoneKey) {
  return switch (completedMilestoneKey) {
    'nt_scan' => const NextMilestoneRecommendation(
        title: 'W18–24 Detail Anomaly Scan',
        description: 'Comprehensive organ anatomy & defect screening. Ideal window: ~6–8 weeks from now.',
        bonusPoints: 100,
        serviceKeyword: 'detail',
      ),
    'detail_scan' => const NextMilestoneRecommendation(
        title: 'W26–32 4D/5D HD Live Baby Scan',
        description: 'Real-time facial features & emotional bonding ultrasound. Ideal window: ~6–8 weeks from now.',
        bonusPoints: 100,
        serviceKeyword: '4d',
      ),
    'scan_4d5d' => const NextMilestoneRecommendation(
        title: 'W33–36 Growth & Position Doppler Scan',
        description:
            'Late pregnancy fetal biometry, placental check & amniotic fluid. Ideal window: ~4–6 weeks from now.',
        bonusPoints: 50,
        serviceKeyword: 'growth',
      ),
    'growth_scan' => const NextMilestoneRecommendation(
        title: 'Postnatal & Newborn Care Visit',
        description: '6-week maternal healing, newborn health check & lactation support.',
        bonusPoints: 50,
      ),
    _ => const NextMilestoneRecommendation(
        title: 'Next Follow-Up Appointment',
        description: 'Lock in the patient\'s next clinical visit or routine scan before they leave the counter.',
        bonusPoints: 0,
      ),
  };
}

class AppointmentCheckoutDialog extends StatefulWidget {
  final String appointmentId;
  final VoidCallback? onCompleted;

  /// API seams. Default to the live controllers; tests pass fakes.
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

  late TextEditingController _basePriceCtrl;
  late TextEditingController _bookingFeeCtrl;
  late TextEditingController _customItemNameCtrl;
  late TextEditingController _customItemPriceCtrl;
  late TextEditingController _notesCtrl;

  final List<CheckoutAddOnItem> _items = [];
  String _paymentMethod = 'duitnow_qr'; // 'cash' | 'duitnow_qr' | 'card'
  bool _awardMilestoneBonus = true;
  bool _submitting = false;

  CheckoutResultData? _result;

  @override
  void initState() {
    super.initState();
    _basePriceCtrl = TextEditingController(text: '0.00');
    _bookingFeeCtrl = TextEditingController(text: '0.00');
    _customItemNameCtrl = TextEditingController();
    _customItemPriceCtrl = TextEditingController();
    _notesCtrl = TextEditingController();

    _loadPreview();
  }

  @override
  void dispose() {
    _basePriceCtrl.dispose();
    _bookingFeeCtrl.dispose();
    _customItemNameCtrl.dispose();
    _customItemPriceCtrl.dispose();
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
        _basePriceCtrl.text = data.basePrice.toStringAsFixed(2);
        _bookingFeeCtrl.text = data.bookingFeePaid.toStringAsFixed(2);
        _awardMilestoneBonus = data.detectedMilestone != null;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load appointment details.';
        _loading = false;
      });
    }
  }

  double get _basePrice => double.tryParse(_basePriceCtrl.text.trim()) ?? 0.0;
  double get _bookingFeePaid => double.tryParse(_bookingFeeCtrl.text.trim()) ?? 0.0;

  double get _extrasTotal {
    double sum = 0.0;
    for (final it in _items) {
      sum += it.price * it.quantity;
    }
    return sum;
  }

  double get _grossTotal => _basePrice + _extrasTotal;

  double get _netCollected {
    final net = _grossTotal - _bookingFeePaid;
    return net > 0 ? net : 0.0;
  }

  int get _basePoints => math.max(0, (_netCollected / 10).floor());

  // Milestone bonus points are kept inactive by default (proposal only)
  int get _milestoneBonusPoints => 0;

  int get _totalPointsToAward => _basePoints;

  void _addPresetItem(String name, double price) {
    setState(() {
      final existingIdx = _items.indexWhere((it) => it.name.toLowerCase() == name.toLowerCase());
      if (existingIdx >= 0) {
        _items[existingIdx].quantity += 1;
      } else {
        _items.add(CheckoutAddOnItem(name: name, price: price, quantity: 1));
      }
    });
  }

  void _addCustomItem() {
    final name = _customItemNameCtrl.text.trim();
    final price = double.tryParse(_customItemPriceCtrl.text.trim()) ?? 0.0;
    if (name.isEmpty || price <= 0) return;

    _addPresetItem(name, price);
    _customItemNameCtrl.clear();
    _customItemPriceCtrl.clear();
  }

  Future<void> _submitCheckout() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final res = await widget.submitCheckout(
      context,
      widget.appointmentId,
      basePrice: _basePrice,
      bookingFeePaid: _bookingFeePaid,
      extraItems: _items,
      netCollected: _netCollected,
      paymentMethod: _paymentMethod,
      awardPoints: true,
      basePoints: _basePoints,
      milestoneBonusPoints: _milestoneBonusPoints,
      milestoneKey: _awardMilestoneBonus ? _preview?.detectedMilestone?.key : null,
      milestoneName: _awardMilestoneBonus ? _preview?.detectedMilestone?.label : null,
      adminNotes: _notesCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (responseCode(res.code) && res.data != null) {
      setState(() => _result = res.data);
      widget.onCompleted?.call();
      AppToast.snackbar(context, 'Appointment checked out & points credited!');
    } else {
      AppToast.snackbar(context, res.message ?? 'Checkout failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenW = MediaQuery.sizeOf(context).width;
    final dialogW = math.min(640.0, screenW - 32);

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
          padding: const EdgeInsets.all(22),
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
            'Preparing interactive checkout...',
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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title Bar ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.brandSoftBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.point_of_sale_rounded, color: colors.brandPrimary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Counter Checkout & Points Calculator',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    Text(
                      'Transparent receipt breakdown with pregnancy milestone rewards.',
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

          // ── Patient & Clinical Banner ───────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.patientName,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.serviceName} · ${p.branchName}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.brandText),
                          ),
                          if (p.doctorName != null && p.doctorName!.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text('Attending: ${p.doctorName}', style: TextStyle(fontSize: 11, color: colors.inkMuted)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _purpleSoftBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.diamond_outlined, size: 12, color: _purpleAccent),
                              const SizedBox(width: 4),
                              Text(
                                '${p.currentPoints} pts',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _purpleAccent),
                              ),
                            ],
                          ),
                        ),
                        if (p.gestationalWeek != null && p.gestationalWeek! > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: colors.brandSoftBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Week ${p.gestationalWeek}',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.brandText),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Base Service Price & Booking Deposit ─────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Base Service (RM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _basePriceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        prefixText: 'RM ',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Online Booking Fee (RM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bookingFeeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        suffixIcon: _bookingFeePaid > 0
                            ? Tooltip(
                                message: 'Prepaid deposit deducted from balance',
                                child: Icon(Icons.check_circle_rounded, size: 16, color: colors.success),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_bookingFeePaid > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.successSoftBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_rounded, size: 13, color: colors.success),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Prepaid Online Deposit of RM ${_bookingFeePaid.toStringAsFixed(2)} automatically deducted.',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ── Additional Purchases & Add-ons ──────────────────────────
          Text(
            'Add-on Items Purchased at Counter',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _presetChip(colors, '+ Obimin Vitamins (RM 45)', 45.0, 'Obimin / Prenatal Vitamins'),
              _presetChip(colors, '+ Photo Print (RM 20)', 20.0, 'Ultrasound Glossy Photo Print'),
              _presetChip(colors, '+ Video USB (RM 35)', 35.0, 'Scan Video & USB Storage'),
              _presetChip(colors, '+ Urine Dipstick (RM 15)', 15.0, 'Urine Test / Dipstick'),
              _presetChip(colors, '+ Blood Screen (RM 60)', 60.0, 'FBC Blood Screen'),
            ],
          ),
          const SizedBox(height: 8),

          // Custom Add Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _customItemNameCtrl,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    hintText: 'Other item name (e.g. Calcium)',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _customItemPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    prefixText: 'RM ',
                    hintText: '0.00',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onSubmitted: (_) => _addCustomItem(),
                ),
              ),
              const SizedBox(width: 6),
              AppButton.secondary(
                text: 'Add',
                height: 36,
                icon: const Icon(Icons.add_rounded, size: 14),
                onPressed: _addCustomItem,
              ),
            ],
          ),

          // Line Items List
          if (_items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _items.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
                itemBuilder: (context, idx) {
                  final it = _items[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            it.name,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                          ),
                        ),
                        Text(
                          'RM ${(it.price * it.quantity).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (it.quantity > 1) {
                                it.quantity -= 1;
                              } else {
                                _items.removeAt(idx);
                              }
                            });
                          },
                          child: Icon(Icons.remove_circle_outline_rounded, size: 16, color: colors.inkMuted),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('${it.quantity}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        InkWell(
                          onTap: () => setState(() => it.quantity += 1),
                          child: Icon(Icons.add_circle_outline_rounded, size: 16, color: colors.inkMuted),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => setState(() => _items.removeAt(idx)),
                          child: Icon(Icons.delete_outline_rounded, size: 16, color: colors.danger),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),

          // ── Superb Mathematics Receipt Card ─────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.brandBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _receiptRow('Base Service Price', 'RM ${_basePrice.toStringAsFixed(2)}', colors.inkPrimary),
                if (_extrasTotal > 0)
                  _receiptRow('Add-on Items (${_items.length})', '+RM ${_extrasTotal.toStringAsFixed(2)}', colors.inkPrimary),
                _receiptRow('Gross Subtotal', 'RM ${_grossTotal.toStringAsFixed(2)}', colors.inkSecondary),
                if (_bookingFeePaid > 0)
                  _receiptRow('Less Online Deposit', '-RM ${_bookingFeePaid.toStringAsFixed(2)}', colors.success),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: colors.border),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance Payable at Counter:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                    Text(
                      'RM ${_netCollected.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: colors.brandPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Payment Method Selector ──────────────────────────────────
          Text('Counter Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _paymentMethodTile('duitnow_qr', 'DuitNow QR', Icons.qr_code_scanner_rounded, colors)),
              const SizedBox(width: 8),
              Expanded(child: _paymentMethodTile('cash', 'Cash (Tunai)', Icons.payments_outlined, colors)),
              const SizedBox(width: 8),
              Expanded(child: _paymentMethodTile('card', 'Card', Icons.credit_card_rounded, colors)),
            ],
          ),
          const SizedBox(height: 16),

          // ── Points Summary Banner ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: colors.surfaceSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.stars_rounded, size: 20, color: colors.warning),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 12.5, color: colors.inkPrimary),
                      children: [
                        const TextSpan(text: 'Mata Ganjaran (RM 10 = 1 Mata): '),
                        TextSpan(
                          text: '+$_totalPointsToAward pts ',
                          style: TextStyle(fontWeight: FontWeight.w800, color: colors.brandText),
                        ),
                        TextSpan(
                          text: '(${p.currentPoints} ➔ ${p.currentPoints + _totalPointsToAward} pts)',
                          style: TextStyle(color: colors.inkMuted, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Staff Internal Notes ─────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            style: const TextStyle(fontSize: 12),
            decoration: const InputDecoration(
              labelText: 'Staff Checkout Note (Optional)',
              hintText: 'e.g. Free vitamin sample given, paid by spouse',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 18),

          // ── Action Buttons ───────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton.secondary(
                text: 'Cancel',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(width: 10),
              AppButton.primary(
                text: _submitting ? 'Processing...' : 'Complete & Credit $_totalPointsToAward Pts',
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                onPressed: _submitting ? null : _submitCheckout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip(AppColors colors, String label, double price, String fullName) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: colors.surfaceElevated,
      side: BorderSide(color: colors.border),
      onPressed: () => _addPresetItem(fullName, price),
    );
  }

  Widget _receiptRow(String title, String amount, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: textColor)),
          Text(
            amount,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethodTile(String key, String title, IconData icon, AppColors colors) {
    final selected = _paymentMethod == key;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = key),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? colors.brandSoftBg : colors.surfaceSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.brandPrimary : colors.border,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: selected ? colors.brandPrimary : colors.inkMuted),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? colors.brandText : colors.inkSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Closes checkout and opens the booking form pre-filled for this patient.
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
              'Visit Completed & Receipt Generated',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.inkPrimary),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Collected RM ${res.netCollected.toStringAsFixed(2)} · Awarded +${res.pointsAwarded} Aurora Points',
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
                _receiptRow('Amount Paid at Counter', 'RM ${res.netCollected.toStringAsFixed(2)}', colors.brandText),
                _receiptRow('Points Awarded', '+${res.pointsAwarded} pts', _purpleAccent),
                _receiptRow('New Patient Points Balance', '${res.newTotalPoints} pts', colors.success),
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
