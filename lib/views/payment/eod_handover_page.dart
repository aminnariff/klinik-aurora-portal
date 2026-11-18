import 'dart:convert';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/eod_handover_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/patient/patient_quick_drawer.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:provider/provider.dart';

/// One-Click Daily Branch Handover & EOD Cash/Fiuu Reconciliation (#3).
class EodHandoverPage extends StatefulWidget {
  static const routeName = RouteNames.eodHandover;
  static const displayName = RouteNames.eodHandoverDisplay;

  const EodHandoverPage({super.key});

  @override
  State<EodHandoverPage> createState() => _EodHandoverPageState();
}

class _EodHandoverPageState extends State<EodHandoverPage> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedBranchId;
  List<branch_model.Data> _branches = [];
  bool _loading = true;
  String? _error;
  EodHandoverData? _data;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) return;
      context.read<TopBarController>().pageValue = Homepage.getPageId(EodHandoverPage.displayName);
      final auth = context.read<AuthController>();
      if (!auth.isSuperAdmin) {
        _selectedBranchId = auth.authenticationResponse?.data?.user?.branchId;
      } else {
        _loadBranches();
      }
      _fetch();
    });
  }

  Future<void> _loadBranches() async {
    final res = await BranchController.getAll(context, 1, 100);
    if (!mounted) return;
    if (responseCode(res.code)) {
      setState(() => _branches = res.data?.data ?? []);
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await EodHandoverController.fetch(
      context,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      branchId: _selectedBranchId,
    );
    if (!mounted) return;
    if (responseCode(res.code) && res.data != null) {
      setState(() {
        _data = res.data;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Failed to load EOD handover report.';
        _loading = false;
      });
    }
  }

  void _copyShiftSummary() {
    final d = _data;
    if (d == null) return;
    final a = d.appointmentSummary;
    final text = '''
*KLINIK AURORA · EOD BRANCH HANDOVER*
Branch: ${d.branchName}
Date: ${d.date}

*Appointments*
• Total: ${a['total'] ?? 0} (Walk-in/Admin: ${a['walkInOrAdminCreated'] ?? 0})
• Completed: ${a['completed'] ?? 0} | Booked: ${a['booked'] ?? 0}
• Cancelled: ${a['cancelled'] ?? 0} | No-Show: ${a['noShow'] ?? 0}

*Payments & Reconciliation*
• Fiuu Online: RM ${d.fiuuOnlineAmount.toStringAsFixed(2)} (${d.fiuuOnlineCount} txns)
• Counter/Proof: RM ${d.counterProofAmount.toStringAsFixed(2)} (${d.counterProofCount} txns)
• Refunds: RM ${d.totalRefundAmount.toStringAsFixed(2)} (${d.refundCount})
• *Net Revenue: RM ${d.netRevenue.toStringAsFixed(2)}*

*Alerts*
• Payment Mismatches: ${d.mismatchCount}
• Unpaid Completed Visits: ${d.unpaidCompletedCount}
• Pending Payment: ${d.pendingPaymentCount}
'''.trim();
    Clipboard.setData(ClipboardData(text: text));
    AppToast.snackbar(context, 'Shift handover summary copied — ready to paste into WhatsApp!');
  }

  Future<void> _exportCsv() async {
    final d = _data;
    if (d == null) return;
    final buf = StringBuffer('Time,ReceiptNo,Patient,Service,Branch,Channel,State,Amount(RM)\n');
    for (final t in d.transactions) {
      String esc(String s) => '"${s.replaceAll('"', '""')}"';
      buf.writeln([
        esc(t.paymentTime),
        esc(t.receiptNo),
        esc(t.patientName),
        esc(t.serviceName),
        esc(t.branchName),
        esc(t.channel),
        esc(t.state),
        t.amount.toStringAsFixed(2),
      ].join(','));
    }
    await FileSaver.instance.saveFile(
      name: 'aurora_eod_${d.date}_${d.branchName.replaceAll(' ', '_')}',
      bytes: Uint8List.fromList(utf8.encode(buf.toString())),
      fileExtension: 'csv',
      mimeType: MimeType.csv,
    );
    if (mounted) AppToast.snackbar(context, 'Exported EOD handover CSV.');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = context.read<AuthController>();
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: colors.danger)),
                      const SizedBox(height: 12),
                      AppButton.primary(text: 'Retry', onPressed: _fetch),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isNarrow ? 12 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ─────────────────────────────────────────
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Branch Handover & EOD Reconciliation',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_data?.branchName ?? 'Branch'} · ${DateFormat('EEEE, dd MMM yyyy').format(_selectedDate)}',
                                style: TextStyle(fontSize: 13, color: colors.inkMuted),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              AppButton.secondary(
                                text: DateFormat('dd MMM yyyy').format(_selectedDate),
                                icon: Icon(Icons.calendar_today_rounded, size: 15, color: colors.inkSecondary),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate,
                                    firstDate: DateTime(2024),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedDate = picked);
                                    _fetch();
                                  }
                                },
                              ),
                              if (auth.isSuperAdmin && _branches.isNotEmpty)
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: _selectedBranchId,
                                      hint: Text('All Branches', style: TextStyle(fontSize: 12, color: colors.inkMuted)),
                                      dropdownColor: colors.surfaceElevated,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                                      items: [
                                        const DropdownMenuItem<String?>(value: null, child: Text('All Branches')),
                                        for (final b in _branches)
                                          DropdownMenuItem<String?>(value: b.branchId, child: Text(b.branchName ?? 'Branch')),
                                      ],
                                      onChanged: (v) {
                                        setState(() => _selectedBranchId = v);
                                        _fetch();
                                      },
                                    ),
                                  ),
                                ),
                              AppButton.secondary(
                                text: 'Copy Shift Summary',
                                icon: Icon(Icons.copy_rounded, size: 15, color: colors.inkSecondary),
                                onPressed: _copyShiftSummary,
                              ),
                              AppButton.primary(
                                text: 'Export CSV',
                                icon: const Icon(Icons.download_rounded, size: 16),
                                onPressed: _exportCsv,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Reconciliation Status Banner ───────────────────
                      _reconciliationBanner(context, _data!),
                      const SizedBox(height: 16),

                      // ── Financial KPI Cards ────────────────────────────
                      LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth >= 920 ? 4 : (c.maxWidth >= 520 ? 2 : 1);
                          return GridView.count(
                            crossAxisCount: cols,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: cols == 1 ? 3.5 : 2.3,
                            children: [
                              _metricCard(
                                context,
                                'Net Revenue',
                                'RM ${_data!.netRevenue.toStringAsFixed(2)}',
                                'Collected RM ${_data!.totalCollected.toStringAsFixed(2)}',
                                colors.brandText,
                              ),
                              _metricCard(
                                context,
                                'Fiuu Online',
                                'RM ${_data!.fiuuOnlineAmount.toStringAsFixed(2)}',
                                '${_data!.fiuuOnlineCount} online transactions',
                                colors.info,
                              ),
                              _metricCard(
                                context,
                                'Counter / Proof',
                                'RM ${_data!.counterProofAmount.toStringAsFixed(2)}',
                                '${_data!.counterProofCount} manual proofs',
                                colors.success,
                              ),
                              _metricCard(
                                context,
                                'Refunds',
                                'RM ${_data!.totalRefundAmount.toStringAsFixed(2)}',
                                '${_data!.refundCount} refunded',
                                colors.danger,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Appointment Ops + Channel Breakdown ────────────
                      LayoutBuilder(
                        builder: (context, c) {
                          final stacked = c.maxWidth < 860;
                          final apptCard = _appointmentBreakdownCard(context, _data!);
                          final channelCard = _channelBreakdownCard(context, _data!);
                          if (stacked) {
                            return Column(
                              children: [apptCard, const SizedBox(height: 12), channelCard],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: apptCard),
                              const SizedBox(width: 12),
                              Expanded(flex: 2, child: channelCard),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Itemized Transaction Ledger ────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Text(
                                    'Daily Payment Ledger (${_data!.transactions.length})',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: colors.border),
                            if (_data!.transactions.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32),
                                child: Center(
                                  child: Text('No payment transactions recorded on this date.',
                                      style: TextStyle(color: colors.inkMuted)),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _data!.transactions.length,
                                separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
                                itemBuilder: (context, idx) {
                                  final t = _data!.transactions[idx];
                                  final isPaid = t.state.toLowerCase() == 'paid';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 52,
                                          child: Text(t.paymentTime,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkMuted)),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              InkWell(
                                                onTap: t.userId.isNotEmpty
                                                    ? () => PatientQuickDrawer.show(
                                                          context,
                                                          userId: t.userId,
                                                          patientName: t.patientName,
                                                        )
                                                    : null,
                                                child: Text(
                                                  t.patientName,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: colors.brandText,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '${t.serviceName} · ${t.channel} · Receipt: ${t.receiptNo}',
                                                style: TextStyle(fontSize: 12, color: colors.inkMuted),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPaid ? colors.successSoftBg : colors.warningSoftBg,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            t.state.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isPaid ? colors.success : colors.warning,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'RM ${t.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: colors.inkPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _reconciliationBanner(BuildContext context, EodHandoverData d) {
    final colors = context.appColors;
    final hasIssues = d.mismatchCount > 0 || d.unpaidCompletedCount > 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasIssues ? colors.dangerSoftBg : colors.successSoftBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (hasIssues ? colors.danger : colors.success).withValues(alpha: 0.4),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasIssues ? Icons.warning_amber_rounded : Icons.verified_rounded,
                color: hasIssues ? colors.danger : colors.success,
                size: 22,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasIssues
                        ? 'Reconciliation Attention Needed'
                        : 'EOD Cash & Fiuu Reconciliation Clean',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                  ),
                  Text(
                    'Mismatches: ${d.mismatchCount} · Unpaid Completed Visits: ${d.unpaidCompletedCount} · Pending Payment: ${d.pendingPaymentCount}',
                    style: TextStyle(fontSize: 12, color: colors.inkSecondary),
                  ),
                ],
              ),
            ],
          ),
          if (hasIssues)
            AppButton.secondary(
              text: 'Inspect Payment Issues',
              height: 36,
              onPressed: () => context.go(RouteNames.paymentMismatch),
            ),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, String label, String value, String sub, Color accent) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkMuted)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: colors.inkMuted)),
        ],
      ),
    );
  }

  Widget _appointmentBreakdownCard(BuildContext context, EodHandoverData d) {
    final colors = context.appColors;
    final a = d.appointmentSummary;
    final rows = [
      ('Total Scheduled', a['total'] ?? 0, colors.inkPrimary),
      ('Completed', a['completed'] ?? 0, colors.success),
      ('Walk-In / Admin Booked', a['walkInOrAdminCreated'] ?? 0, colors.brandText),
      ('Booked / Active', a['booked'] ?? 0, colors.info),
      ('Rescheduled', a['rescheduled'] ?? 0, colors.warning),
      ('Cancelled', a['cancelled'] ?? 0, colors.danger),
      ('No-Show', a['noShow'] ?? 0, colors.danger),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appointment Operations Summary',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: rows
                .map(
                  (r) => Container(
                    width: 145,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.$1, style: TextStyle(fontSize: 11, color: colors.inkMuted, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('${r.$2}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: r.$3)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _channelBreakdownCard(BuildContext context, EodHandoverData d) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Channel Breakdown',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
          const SizedBox(height: 12),
          if (d.channelBreakdown.isEmpty)
            Text('No payment channels recorded today.', style: TextStyle(fontSize: 12, color: colors.inkMuted))
          else
            for (final ch in d.channelBreakdown)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ch.channel,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.inkPrimary)),
                          Text('${ch.count} transaction(s)',
                              style: TextStyle(fontSize: 11, color: colors.inkMuted)),
                        ],
                      ),
                    ),
                    Text(
                      'RM ${ch.amount.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
