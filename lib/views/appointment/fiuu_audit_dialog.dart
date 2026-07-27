import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/fiuu_audit_response.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';

enum _AuditMode { last48h, fullHistory }

/// Loops POST admin/appointment/payment-mismatch/audit-fiuu, one small batch
/// at a time (each row costs a real network call to Fiuu), until the whole
/// requested range has been checked. "Last 48h" is for routine spot-checks —
/// the reconcile-fiuu-payments cron already self-heals that window on its
/// own. "Full History" has no date floor at all, for the one-time sweep back
/// to when Fiuu was first integrated, since nothing else ever re-checks
/// transactions older than 48h once they're marked terminal.
class FiuuAuditDialog extends StatefulWidget {
  const FiuuAuditDialog({super.key});

  @override
  State<FiuuAuditDialog> createState() => _FiuuAuditDialogState();
}

class _FiuuAuditDialogState extends State<FiuuAuditDialog> {
  _AuditMode _mode = _AuditMode.last48h;
  bool _running = false;
  bool _cancelRequested = false;
  bool _done = false;
  String? _error;

  int _scanned = 0;
  int _confirmedFailed = 0;
  int _apiErrors = 0;
  final List<FiuuAuditDiscrepancy> _discrepancies = [];

  final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);

  Future<void> _start() async {
    setState(() {
      _running = true;
      _cancelRequested = false;
      _done = false;
      _error = null;
      _scanned = 0;
      _confirmedFailed = 0;
      _apiErrors = 0;
      _discrepancies.clear();
    });

    final String? startDate = _mode == _AuditMode.last48h
        ? DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(hours: 48)))
        : null;

    int offset = 0;
    bool hasMore = true;

    while (hasMore && !_cancelRequested) {
      if (!mounted) return;
      final value = await AppointmentController.auditFiuu(
        context,
        startDate: startDate,
        offset: offset,
        limit: 40,
      );

      if (!mounted) return;

      if (!responseCode(value.code)) {
        setState(() {
          _error = value.message ?? 'Scan failed — please try again.';
          _running = false;
        });
        return;
      }

      final data = value.data;
      setState(() {
        _scanned += data?.scanned ?? 0;
        _confirmedFailed += data?.confirmedFailed ?? 0;
        _apiErrors += data?.apiErrors ?? 0;
        _discrepancies.addAll(data?.discrepancies ?? []);
      });

      hasMore = data?.hasMore ?? false;
      offset = data?.nextOffset ?? (offset + 40);
    }

    if (!mounted) return;
    setState(() {
      _running = false;
      _done = true;
    });
  }

  void _cancel() {
    setState(() => _cancelRequested = true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.fact_check_rounded, color: Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Audit Fiuu Payments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Checks every transaction we have marked as NOT paid directly against Fiuu\'s own records, and reports any Fiuu confirms as actually paid.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 16),
              if (!_running && !_done) ...[
                _modeOption(
                  _AuditMode.last48h,
                  'Last 48 hours',
                  'Routine spot-check. The reconcile cron already self-heals this window automatically — use this to check right now instead of waiting.',
                ),
                const SizedBox(height: 8),
                _modeOption(
                  _AuditMode.fullHistory,
                  'Full history (first run)',
                  'No date limit — scans everything since Fiuu was first integrated. Use this once to catch anything older than 48h that nothing else ever re-checks. Can take a while.',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Start Scan', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              if (_running || _done) ...[
                _progressRow(),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(child: _resultsList()),
                const SizedBox(height: 12),
                if (_running)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _cancelRequested ? null : _cancel,
                      child: Text(_cancelRequested ? 'Stopping…' : 'Stop Scan'),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeOption(_AuditMode mode, String title, String subtitle) {
    final selected = _mode == mode;
    return InkWell(
      onTap: () => setState(() => _mode = mode),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 18,
                color: selected ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressRow() {
    return Row(
      children: [
        if (_running)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(
            _discrepancies.isEmpty ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: _discrepancies.isEmpty ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            size: 18,
          ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _running
                ? 'Scanning… checked $_scanned so far ($_confirmedFailed confirmed still unpaid)'
                : 'Done — checked $_scanned, ${_discrepancies.length} discrepanc${_discrepancies.length == 1 ? 'y' : 'ies'} found, '
                    '$_confirmedFailed confirmed still unpaid'
                    '${_apiErrors > 0 ? ', $_apiErrors skipped (Fiuu unreachable)' : ''}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _resultsList() {
    if (_discrepancies.isEmpty) {
      if (_running) return const SizedBox.shrink();
      return const Center(
        child: Text('No discrepancies found.', style: TextStyle(color: Color(0xFF6B7280))),
      );
    }
    return ListView.separated(
      itemCount: _discrepancies.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _discrepancyTile(_discrepancies[i]),
    );
  }

  Widget _discrepancyTile(FiuuAuditDiscrepancy d) {
    final amount = double.tryParse(d.paymentAmount ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.userName ?? 'Unknown patient',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                amount != null ? currencyFormatter.format(amount) : (d.paymentAmount ?? '—'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${d.branchName ?? '—'} · ${dateConverter(d.createdDate) ?? d.createdDate}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _tag('Our state: ${d.currentState}', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
              _tag('Fiuu: paid', const Color(0xFFDCFCE7), const Color(0xFF166534)),
              _tag('bill_id: ${d.billId}', const Color(0xFFF3F4F6), const Color(0xFF374151)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
