import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/payment/payment_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/payment/payment_report_response.dart';
import 'package:klinik_aurora_portal/views/payment/appointment_ids.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class PaymentSummaryPage extends StatefulWidget {
  static const routeName = '/payment-summary';
  static const displayName = 'Payment Report';
  const PaymentSummaryPage({super.key});

  @override
  State<PaymentSummaryPage> createState() => _PaymentSummaryPageState();
}

class _PaymentSummaryPageState extends State<PaymentSummaryPage> {
  String selectedFilter = 'Yesterday';
  late DateTime startDate;
  late DateTime endDate;
  bool _channelExpanded = false;
  bool _branchExpanded = false;
  String? _selectedBranchId;
  String? _selectedBranchName;
  bool _branchesLoaded = false;
  static const Color _dateAccent = Color(0xFF2196F3);

  static const _muted = Color(0xff68737d);

  @override
  void initState() {
    super.initState();
    applyDateFilter();
    getData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthController>();
      if (auth.isSuperAdmin && !_branchesLoaded) {
        if (context.read<BranchController>().branchAllResponse == null) {
          BranchController.getAll(context, 1, 1000).then((value) {
            if (mounted && responseCode(value.code)) {
              context.read<BranchController>().branchAllResponse = value;
              setState(() => _branchesLoaded = true);
            }
          });
        } else {
          setState(() => _branchesLoaded = true);
        }
      }
    });
  }

  void getData() {
    showLoading();
    final auth = context.read<AuthController>();
    final effectiveBranchId = auth.isSuperAdmin
        ? _selectedBranchId
        : auth.authenticationResponse?.data?.user?.branchId;

    PaymentController.report(
      context,
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(endDate),
      branchId: effectiveBranchId,
    ).then((response) {
      dismissLoading();
      if (responseCode(response.code)) {
        context.read<PaymentController>().paymentReportResponse = response.data;
      }
    }).catchError((e) {
      dismissLoading();
    });
  }

  void exportData() {
    showLoading();
    final auth = context.read<AuthController>();
    final effectiveBranchId = auth.isSuperAdmin
        ? _selectedBranchId
        : auth.authenticationResponse?.data?.user?.branchId;

    PaymentController.exportCsvDownload(
          fileName: 'payment-report',
          startDate: DateFormat('yyyy-MM-dd').format(startDate),
          endDate: DateFormat('yyyy-MM-dd').format(endDate),
          branchId: effectiveBranchId,
        )
        .then((_) {
          dismissLoading();
          AppToast.snackbar(context, 'CSV exported successfully.');
        })
        .catchError((_) {
          dismissLoading();
          AppToast.snackbar(context, 'Export failed. Please try again.');
        });
  }

  void applyDateFilter() {
    final now = DateTime.now();
    switch (selectedFilter) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate;
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
        endDate = startDate;
        break;
      case 'Last 7 Days':
        startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'Custom':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        break;
    }
  }

  String getFormattedDateRange() {
    final df = DateFormat('dd MMM yyyy');
    if (startDate == endDate) {
      return df.format(startDate);
    } else {
      return '${df.format(startDate)} – ${df.format(endDate)}';
    }
  }

  void _openAppointmentsDialog({String? date, String? branchId, String? status}) {
    showLoading();
    final auth = context.read<AuthController>();
    final effectiveBranchId = branchId ?? (auth.isSuperAdmin
        ? _selectedBranchId
        : auth.authenticationResponse?.data?.user?.branchId);

    PaymentController.successPayment(
      context,
      date: date ?? DateFormat('yyyy-MM-dd').format(startDate),
      branchId: effectiveBranchId,
      status: status,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        showDialog(
          context: context,
          builder: (ctx) => AppointmentIds(response: value.data),
        );
      } else {
        showDialogError(context, value.message ?? 'Failed to load appointments');
      }
    }).catchError((e) {
      dismissLoading();
      showDialogError(context, e.toString());
    });
  }

  Future<DateTimeRange?> _showCustomDateRangePicker() async {
    final initialStart = DateTime(startDate.year, startDate.month, startDate.day);
    final initialEnd = DateTime(endDate.year, endDate.month, endDate.day);
    final now = DateTime.now();
    return showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Select date range',
      confirmText: 'Apply',
      cancelText: 'Cancel',
      saveText: 'Apply',
      fieldStartHintText: 'Start date',
      fieldEndHintText: 'End date',
      currentDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      switchToInputEntryModeIcon: const Icon(Icons.edit_calendar_rounded),
      switchToCalendarEntryModeIcon: const Icon(Icons.calendar_month_rounded),
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: base.colorScheme.copyWith(
              primary: _dateAccent,
              onPrimary: Colors.white,
              secondary: _dateAccent,
              onSecondary: Colors.white,
              surface: Colors.white,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: const Color(0xFFF9FAFB),
              headerForegroundColor: const Color(0xFF374151),
              rangeSelectionBackgroundColor: _dateAccent.withAlpha(45),
              rangeSelectionOverlayColor: WidgetStateProperty.all(_dateAccent.withAlpha(24)),
              todayBorder: const BorderSide(color: _dateAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _dateAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenPadding),
        child: Consumer<PaymentController>(
          builder: (context, controller, _) {
            final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
            final data = controller.paymentReportResponse?.data ?? [];
            final channels = controller.paymentReportResponse?.channelBreakdown ?? [];
            final branchCount = data.map((d) => d.branchId).toSet().length;
            final dateCount = data.map((d) => d.paymentDate).toSet().length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller),
                SizedBox(height: screenPadding),
                _buildFilterRow(),
                SizedBox(height: screenPadding),
                _buildSummaryCards(controller),
                if (channels.isNotEmpty || (isSuperAdmin && branchCount >= 2)) ...[
                  SizedBox(height: screenPadding),
                  if (channels.isNotEmpty && isSuperAdmin && branchCount >= 2)
                    isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildChannelBreakdown(controller),
                              SizedBox(height: screenPadding),
                              _buildBranchOverview(controller),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildChannelBreakdown(controller)),
                              SizedBox(width: screenPadding),
                              Expanded(child: _buildBranchOverview(controller)),
                            ],
                          )
                  else if (channels.isNotEmpty)
                    _buildChannelBreakdown(controller)
                  else
                    _buildBranchOverview(controller),
                ],
                if (dateCount >= 2) ...[SizedBox(height: screenPadding), _buildChart(controller)],
                SizedBox(height: screenPadding),
                _buildTable(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(PaymentController controller) {
    final auth = context.read<AuthController>();
    final isSuperAdmin = auth.isSuperAdmin;
    final branchName = !isSuperAdmin
        ? (controller.paymentReportResponse?.data?.isNotEmpty == true
              ? controller.paymentReportResponse!.data!.first.branchName
              : null)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment Report', style: AppTypography.displayMedium(context)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(getFormattedDateRange(), style: AppTypography.bodyMedium(context).apply(color: _muted)),
                  if (!isSuperAdmin) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF2196F3).withAlpha(60)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.store_rounded, size: 11, color: Color(0xFF1565C0)),
                          const SizedBox(width: 4),
                          Text(
                            branchName ?? 'Your Branch',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (isSuperAdmin) ...[
                    Consumer<BranchController>(
                      builder: (context, branchCtrl, _) {
                        final branchList = branchCtrl.branchAllResponse?.data?.data ?? [];
                        final branchItems = [
                          DropdownAttribute('', 'All Branches'),
                          ...branchList.map((b) => DropdownAttribute(b.branchId ?? '', b.branchName ?? '')),
                        ];
                        return Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedBranchId != null ? const Color(0xFF2196F3) : const Color(0xFFE5E7EB),
                            ),
                            boxShadow: _selectedBranchId != null
                                ? [BoxShadow(color: const Color(0xFF2196F3).withAlpha(30), blurRadius: 4, offset: const Offset(0, 1))]
                                : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedBranchId ?? '',
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B7280)),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                              onChanged: (val) {
                                setState(() {
                                  _selectedBranchId = (val == null || val.isEmpty) ? null : val;
                                  final match = branchList.firstWhere(
                                    (b) => b.branchId == _selectedBranchId,
                                    orElse: () => branch_model.Data(branchName: 'All Branches'),
                                  );
                                  _selectedBranchName = _selectedBranchId == null ? null : match.branchName;
                                });
                                getData();
                              },
                              items: branchItems.map((item) {
                                return DropdownMenuItem<String>(
                                  value: item.key,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        item.key.isEmpty ? Icons.domain_rounded : Icons.store_rounded,
                                        size: 13,
                                        color: item.key == (_selectedBranchId ?? '') ? const Color(0xFF2196F3) : const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(item.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                    if (_selectedBranchId != null) ...[
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBranchId = null;
                            _selectedBranchName = null;
                          });
                          getData();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF93C5FD)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.clear_rounded, size: 12, color: Color(0xFF1D4ED8)),
                              const SizedBox(width: 4),
                              Text(
                                _selectedBranchName != null ? 'Clear ($_selectedBranchName)' : 'Clear filter',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: getData,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          style: IconButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
            backgroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterRow() {
    final filters = ['Today', 'Yesterday', 'Last 7 Days', 'This Month', 'Last Month', 'Custom'];
    final chips = filters.map((f) {
      final selected = selectedFilter == f;
      return GestureDetector(
        onTap: () async {
          if (f == 'Custom') {
            final picked = await _showCustomDateRangePicker();
            if (picked != null) {
              setState(() {
                selectedFilter = 'Custom';
                startDate = picked.start;
                endDate = picked.end;
              });
              getData();
            }
          } else {
            setState(() {
              selectedFilter = f;
              applyDateFilter();
            });
            getData();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFF0F172A).withAlpha(40), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Text(
            f,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
          ),
        ),
      );
    }).toList();

    final exportButton = SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        onPressed: exportData,
        icon: const Icon(Icons.file_download_outlined, size: 16),
        label: const Text('Export CSV'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0F172A),
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );

    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [...chips, exportButton],
      );
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: chips.map((chip) => Padding(padding: const EdgeInsets.only(right: 8), child: chip)).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        exportButton,
      ],
    );
  }

  Widget _buildSummaryCards(PaymentController controller) {
    final summary = controller.paymentReportResponse?.summary;
    final total = summary?.totalPayments ?? 0;
    final successful = int.tryParse(summary?.successfulPayments ?? '0') ?? 0;
    final failed = int.tryParse(summary?.failedPayments ?? '0') ?? 0;
    final successRate = total > 0 ? ((successful / total) * 100).toStringAsFixed(1) : '0.0';
    final netRev = double.tryParse(summary?.netRevenue ?? '0') ?? 0.0;
    final atv = successful > 0 ? (netRev / successful).toStringAsFixed(2) : '0.00';

    final cards = [
      _CardConfig(
        label: 'Total Checkouts',
        value: '$total',
        icon: Icons.receipt_long_rounded,
        accent: const Color(0xFF3B82F6),
        bg: const Color(0xFFEFF6FF),
        valueColor: const Color(0xFF0F172A),
      ),
      _CardConfig(
        label: 'Successful',
        value: '$successful',
        subtitle: '$successRate% conv.',
        icon: Icons.check_circle_rounded,
        accent: const Color(0xFF10B981),
        bg: const Color(0xFFECFDF5),
        valueColor: const Color(0xFF0F172A),
        onTap: successful > 0 ? () => _openAppointmentsDialog() : null,
      ),
      _CardConfig(
        label: 'Needs Rescue',
        value: '$failed',
        subtitle: failed > 0 ? 'Click to rescue ↗' : null,
        icon: Icons.warning_amber_rounded,
        accent: const Color(0xFFEF4444),
        bg: const Color(0xFFFEF2F2),
        valueColor: const Color(0xFF0F172A),
        onTap: failed > 0 ? () => _openAppointmentsDialog(status: 'failed') : null,
      ),
      _CardConfig(
        label: 'Paid Amount',
        value: 'RM ${summary?.totalPaidAmount ?? '0.00'}',
        icon: Icons.payments_rounded,
        accent: const Color(0xFF8B5CF6),
        bg: const Color(0xFFF5F3FF),
        valueColor: const Color(0xFF0F172A),
      ),
      _CardConfig(
        label: 'Refunded',
        value: 'RM ${summary?.totalRefundAmount ?? '0.00'}',
        icon: Icons.undo_rounded,
        accent: const Color(0xFFF59E0B),
        bg: const Color(0xFFFFFBEB),
        valueColor: const Color(0xFF0F172A),
      ),
      _CardConfig(
        label: 'Net Revenue',
        value: 'RM ${summary?.netRevenue ?? '0.00'}',
        subtitle: 'ATV RM $atv',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFFDF6E98),
        bg: const Color(0xFFFDF2F8),
        valueColor: const Color(0xFF0F172A),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _SummaryCard(config: cards[0])),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(config: cards[1])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(config: cards[2])),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(config: cards[3])),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SummaryCard(config: cards[4])),
              const SizedBox(width: 12),
              Expanded(child: _SummaryCard(config: cards[5])),
            ],
          ),
        ],
      );
    }

    return Row(
      children: cards.asMap().entries.map((e) {
        final isLast = e.key == cards.length - 1;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 12),
            child: _SummaryCard(config: e.value),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChannelBreakdown(PaymentController controller) {
    final channels = controller.paymentReportResponse?.channelBreakdown ?? [];
    if (channels.isEmpty) return const SizedBox();

    final totalCount = channels.fold<int>(0, (sum, c) => sum + (c.count ?? 0));
    final displayChannels = _channelExpanded ? channels : channels.take(6).toList();

    IconData channelIcon(String? ch) {
      switch (ch) {
        case 'credit':
          return Icons.credit_card_rounded;
        case 'fpx':
          return Icons.account_balance_rounded;
        case 'GRAB':
          return Icons.account_balance_wallet_rounded;
        case 'TNG-EWALLET':
          return Icons.account_balance_wallet_outlined;
        case 'BOOST':
          return Icons.bolt_rounded;
        case 'ShopeePay':
          return Icons.shopping_bag_rounded;
        case 'DUITNOWQR':
          return Icons.qr_code_2_rounded;
        case 'APPLEPAY':
          return Icons.phone_iphone_rounded;
        case 'GOOGLEPAY':
          return Icons.android_rounded;
        default:
          return Icons.payments_rounded;
      }
    }

    final channelColors = [
      const Color(0xFF6366F1),
      const Color(0xFF0891B2),
      const Color(0xFF059669),
      const Color(0xFF7C3AED),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF0369A1),
      const Color(0xFF15803D),
      const Color(0xFFD97706),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(screenPadding, screenPadding * 0.75, screenPadding, screenPadding * 0.75),
            child: Row(
              children: [
                const Icon(Icons.donut_small_rounded, size: 16, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                Text('Payment Channel Breakdown', style: AppTypography.displayMedium(context)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: EdgeInsets.all(screenPadding * 0.75),
            child: Column(
              children: [
                ...displayChannels.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final color = channelColors[i % channelColors.length];
                  final count = c.count ?? 0;
                  final fraction = totalCount > 0 ? count / totalCount : 0.0;
                  final amount = double.tryParse(c.totalAmount ?? '0') ?? 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: color.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(channelIcon(c.channel), size: 14, color: color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.channelLabel,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                            Text(
                              '$count txn${count != 1 ? 's' : ''}',
                              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 90,
                              child: Text(
                                'RM ${amount.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF374151),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const SizedBox(width: 38),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: fraction,
                                  minHeight: 6,
                                  backgroundColor: color.withAlpha(20),
                                  valueColor: AlwaysStoppedAnimation<Color>(color),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${(fraction * 100).toStringAsFixed(0)}%',
                                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                if (channels.length > 6)
                  _buildShowMoreButton(
                    expanded: _channelExpanded,
                    count: channels.length,
                    label: 'channel',
                    onToggle: () => setState(() => _channelExpanded = !_channelExpanded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const List<Color> _branchColors = [
    Color(0xFF2196F3),
    Color(0xFFDF6E98),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFF5722),
    Color(0xFF8BC34A),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
  ];

  Widget _buildBranchOverview(PaymentController controller) {
    final data = controller.paymentReportResponse?.data ?? [];
    if (data.isEmpty) return const SizedBox();

    // Aggregate per-branch from the already-fetched report data
    final Map<String, _BranchTotals> agg = {};
    for (final row in data) {
      final id = row.branchId ?? 'unknown';
      agg.putIfAbsent(id, () => _BranchTotals(branchId: id, branchName: row.branchName ?? id));
      agg[id]!.totalPayments += row.totalPayments ?? 0;
      agg[id]!.successful += int.tryParse(row.successfulPayments ?? '0') ?? 0;
      agg[id]!.failed += int.tryParse(row.failedPayments ?? '0') ?? 0;
      agg[id]!.paid += double.tryParse(row.totalPaidAmount ?? '0') ?? 0;
      agg[id]!.refund += double.tryParse(row.totalRefundAmount ?? '0') ?? 0;
      agg[id]!.revenue += double.tryParse(row.netRevenue ?? '0') ?? 0;
    }

    if (agg.length < 2) return const SizedBox();

    final branches = agg.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
    final maxRevenue = branches.first.revenue;
    final displayBranches = _branchExpanded ? branches : branches.take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(screenPadding, screenPadding * 0.75, screenPadding, screenPadding * 0.75),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, size: 16, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Text('Branch Overview', style: AppTypography.displayMedium(context)),
                const Spacer(),
                Text('${branches.length} branches', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: EdgeInsets.all(screenPadding * 0.75),
            child: Column(
              children: [
                ...displayBranches.asMap().entries.map((entry) {
                  final i = entry.key;
                  final b = entry.value;
                  final color = _branchColors[i % _branchColors.length];
                  final fraction = maxRevenue > 0 ? b.revenue / maxRevenue : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setState(() {
                          _selectedBranchId = b.branchId;
                          _selectedBranchName = b.branchName;
                        });
                        getData();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    b.branchName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ),
                                _miniStatChip('✓ ${b.successful}', const Color(0xFFD1FAE5), const Color(0xFF065F46)),
                                const SizedBox(width: 6),
                                _miniStatChip('✗ ${b.failed}', const Color(0xFFFEE2E2), const Color(0xFF991B1B)),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 100,
                                  child: Text(
                                    'RM ${b.revenue.toStringAsFixed(2)}',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF9CA3AF)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const SizedBox(width: 16),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: fraction,
                                      minHeight: 6,
                                      backgroundColor: color.withAlpha(20),
                                      valueColor: AlwaysStoppedAnimation<Color>(color),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 38,
                                  child: Text(
                                    '${(fraction * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (branches.length > 6)
                  _buildShowMoreButton(
                    expanded: _branchExpanded,
                    count: branches.length,
                    label: 'branch',
                    onToggle: () {
                      setState(() => _branchExpanded = !_branchExpanded);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatChip(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildShowMoreButton({
    required bool expanded,
    required int count,
    required String label,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              size: 16,
              color: const Color(0xFF2196F3),
            ),
            const SizedBox(width: 4),
            Text(
              expanded ? 'Show less' : 'Show all $count $label${count != 1 ? 's' : ''}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2196F3)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(PaymentController controller) {
    final data = controller.paymentReportResponse?.data ?? [];
    if (data.isEmpty) return const SizedBox();

    final Map<String, double> byDate = {};
    for (final row in data) {
      final date = row.paymentDate ?? 'N/A';
      final revenue = double.tryParse(row.netRevenue ?? '0') ?? 0;
      byDate[date] = (byDate[date] ?? 0) + revenue;
    }

    if (byDate.length < 2) return const SizedBox();

    final dates = byDate.keys.toList();
    final values = dates.map((d) => byDate[d]!).toList();
    final maxY = values.reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.all(screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Net Revenue Trend',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(getFormattedDateRange(), style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFBCFE8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 14, color: Color(0xFFDF6E98)),
                    SizedBox(width: 4),
                    Text(
                      'Daily Total (MYT)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF9D174D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenPadding),
          AspectRatio(
            aspectRatio: isMobile ? 1.8 : 3.8,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 10 : maxY * 1.25,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${dates[group.x]}\n',
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(
                            text: 'RM ${rod.toY.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == 0) return const SizedBox();
                        return Text('RM ${value.toInt()}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) return const SizedBox();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            convertToDayMonth(dates[index]),
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dates.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDF6E98), Color(0xFF7E2D40)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        width: isMobile ? 12 : 24,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(PaymentController controller) {
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
    final data = controller.paymentReportResponse?.data ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(screenPadding, screenPadding * 0.75, screenPadding, screenPadding * 0.75),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isSuperAdmin ? 'Branch Breakdown' : 'Daily Breakdown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                if (data.isNotEmpty)
                  Text(
                    '${data.length} row${data.length != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          data.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildDataTable(data, isSuperAdmin, controller),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenPadding * 2),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No payment data for this period',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text('Try selecting a different date range', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Data> data, bool isSuperAdmin, PaymentController controller) {
    const headerStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B));
    const cellStyle = TextStyle(fontSize: 13, color: Color(0xFF0F172A));

    Widget headerCell(String text, {bool alignRight = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: headerStyle,
        ),
      );
    }

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder(horizontalInside: BorderSide(color: const Color(0xFFE2E8F0).withAlpha(128), width: 1)),
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
          children: [
            if (isSuperAdmin) headerCell('Branch'),
            headerCell('Date'),
            headerCell('Checkouts'),
            headerCell('Successful'),
            headerCell('Needs Rescue'),
            headerCell('Paid (RM)', alignRight: true),
            headerCell('Refund (RM)', alignRight: true),
            headerCell('Net Revenue (RM)', alignRight: true),
          ],
        ),
        for (int i = 0; i < data.length; i++)
          TableRow(
            decoration: BoxDecoration(color: i.isEven ? Colors.white : const Color(0xFFFAFAFA)),
            children: [
              if (isSuperAdmin)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(data[i].branchName ?? '—', style: cellStyle.copyWith(fontWeight: FontWeight.w500)),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(data[i].paymentDate ?? '—', style: cellStyle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('${data[i].totalPayments ?? 0}', style: cellStyle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () => _openAppointmentsDialog(
                    date: data[i].paymentDate,
                    branchId: data[i].branchId,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              data[i].successfulPayments ?? '0',
                              style: const TextStyle(
                                color: Color(0xFF047857),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF10B981)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: (int.tryParse(data[i].failedPayments ?? '0') ?? 0) > 0
                      ? () => _openAppointmentsDialog(
                            date: data[i].paymentDate,
                            branchId: data[i].branchId,
                            status: 'failed',
                          )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (int.tryParse(data[i].failedPayments ?? '0') ?? 0) > 0
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (int.tryParse(data[i].failedPayments ?? '0') ?? 0) > 0
                                ? const Color(0xFFFECACA)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (int.tryParse(data[i].failedPayments ?? '0') ?? 0) > 0
                                  ? Icons.warning_amber_rounded
                                  : Icons.remove_circle_outline_rounded,
                              size: 12,
                              color: (int.tryParse(data[i].failedPayments ?? '0') ?? 0) > 0
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF9CA3AF),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              data[i].failedPayments ?? '0',
                              style: TextStyle(
                                color: (int.tryParse(data[i].failedPayments ?? '0') ?? 0) > 0
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF6B7280),
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if ((int.tryParse(data[i].failedPayments ?? '0') ?? 0) > 0) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFFDC2626)),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  data[i].totalPaidAmount ?? '0.00',
                  textAlign: TextAlign.right,
                  style: cellStyle.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  data[i].totalRefundAmount ?? '0.00',
                  textAlign: TextAlign.right,
                  style: cellStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: (double.tryParse(data[i].totalRefundAmount ?? '0') ?? 0) > 0
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  data[i].netRevenue ?? '0.00',
                  textAlign: TextAlign.right,
                  style: cellStyle.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _BranchTotals {
  final String branchId;
  final String branchName;
  int totalPayments = 0;
  int successful = 0;
  int failed = 0;
  double paid = 0;
  double refund = 0;
  double revenue = 0;

  _BranchTotals({required this.branchId, required this.branchName});
}

class _CardConfig {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Color bg;
  final Color valueColor;
  final VoidCallback? onTap;

  const _CardConfig({
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accent,
    required this.bg,
    required this.valueColor,
    this.onTap,
  });
}

class _SummaryCard extends StatelessWidget {
  final _CardConfig config;
  const _SummaryCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: config.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: config.bg, borderRadius: BorderRadius.circular(10)),
                      child: Icon(config.icon, color: config.accent, size: 18),
                    ),
                    if (config.subtitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config.bg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: config.accent.withAlpha(40)),
                        ),
                        child: Text(
                          config.subtitle!,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: config.accent),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  config.value,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      config.label,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    if (config.onTap != null) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 9, color: config.accent),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
