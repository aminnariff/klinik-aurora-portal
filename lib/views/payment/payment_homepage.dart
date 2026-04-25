import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/payment/payment_controller.dart';
import 'package:klinik_aurora_portal/models/payment/payment_report_response.dart';
import 'package:klinik_aurora_portal/views/payment/appointment_ids.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
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
  static const Color _dateAccent = Color(0xFF2196F3);

  static const _bgDark = Color(0xff232d37);
  static const _divider = Color(0xff37434d);
  static const _muted = Color(0xff68737d);

  @override
  void initState() {
    super.initState();
    applyDateFilter();
    getData();
  }

  void getData() {
    showLoading();
    PaymentController.report(
      context,
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(endDate),
      branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
    ).then((response) {
      dismissLoading();
      if (responseCode(response.code)) {
        context.read<PaymentController>().paymentReportResponse = response.data;
      }
    });
  }

  void exportData() {
    showLoading();
    PaymentController.exportCsvDownload(
      fileName: 'payment-report',
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(endDate),
      branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
    ).then((response) {
      dismissLoading();
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
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0);
        break;
      case 'Next Month':
        startDate = DateTime(now.year, now.month + 1, 1);
        endDate = DateTime(now.year, now.month + 2, 0);
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: screenPadding),
                _buildFilterChips(),
                SizedBox(height: screenPadding * 0.75),
                _buildExportButton(),
                SizedBox(height: screenPadding),
                _buildSummaryCards(controller),
                SizedBox(height: screenPadding),
                _buildChart(controller),
                SizedBox(height: screenPadding),
                _buildTable(controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Report', style: AppTypography.displayMedium(context)),
            const SizedBox(height: 2),
            Text(
              getFormattedDateRange(),
              style: AppTypography.bodyMedium(context).apply(color: _muted),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Today', 'Yesterday', 'This Month', 'Last Month', 'Next Month', 'Custom'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final selected = selectedFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
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
                  color: selected ? const Color(0xFF2196F3) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? const Color(0xFF2196F3) : const Color(0xFFE5E7EB),
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: const Color(0xFF2196F3).withAlpha(51), blurRadius: 8, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  f,
                  style: AppTypography.bodyMedium(context).apply(
                    color: selected ? Colors.white : const Color(0xFF374151),
                    fontWeightDelta: selected ? 1 : 0,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      height: 44,
      child: OutlinedButton.icon(
        onPressed: exportData,
        icon: const Icon(Icons.download_rounded, size: 18),
        label: const Text('Export CSV'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF059669),
          side: const BorderSide(color: Color(0xFF059669)),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(PaymentController controller) {
    final summary = controller.paymentReportResponse?.summary;

    final cards = [
      _CardConfig(
        label: 'Total Payments',
        value: '${summary?.totalPayments ?? 0}',
        icon: Icons.receipt_long_rounded,
        accent: const Color(0xFF2196F3),
        bg: const Color(0xFFE3F2FD),
        valueColor: const Color(0xFF1565C0),
      ),
      _CardConfig(
        label: 'Successful',
        value: summary?.successfulPayments ?? '0',
        icon: Icons.check_circle_rounded,
        accent: const Color(0xFF059669),
        bg: const Color(0xFFD1FAE5),
        valueColor: const Color(0xFF065F46),
      ),
      _CardConfig(
        label: 'Failed',
        value: summary?.failedPayments ?? '0',
        icon: Icons.cancel_rounded,
        accent: const Color(0xFFEF4444),
        bg: const Color(0xFFFEE2E2),
        valueColor: const Color(0xFF991B1B),
      ),
      _CardConfig(
        label: 'Paid Amount',
        value: 'RM ${summary?.totalPaidAmount ?? '0.00'}',
        icon: Icons.payments_rounded,
        accent: const Color(0xFF7C3AED),
        bg: const Color(0xFFEDE9FE),
        valueColor: const Color(0xFF4C1D95),
      ),
      _CardConfig(
        label: 'Refunded',
        value: 'RM ${summary?.totalRefundAmount ?? '0.00'}',
        icon: Icons.undo_rounded,
        accent: const Color(0xFFF59E0B),
        bg: const Color(0xFFFEF3C7),
        valueColor: const Color(0xFF92400E),
      ),
      _CardConfig(
        label: 'Net Revenue',
        value: 'RM ${summary?.netRevenue ?? '0.00'}',
        icon: Icons.trending_up_rounded,
        accent: const Color(0xFF0891B2),
        bg: const Color(0xFFCFFAFE),
        valueColor: const Color(0xFF164E63),
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
      children: cards
          .map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: _SummaryCard(config: c))))
          .toList(),
    );
  }

  Widget _buildChart(PaymentController controller) {
    final data = controller.paymentReportResponse?.data ?? [];
    if (data.isEmpty) return const SizedBox();

    // Aggregate net revenue by date
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
        color: _bgDark,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Revenue by Date',
            style: AppTypography.displayMedium(context).apply(color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            getFormattedDateRange(),
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
          SizedBox(height: screenPadding),
          AspectRatio(
            aspectRatio: isMobile ? 1.8 : 4,
            child: BarChart(
              BarChartData(
                maxY: maxY == 0 ? 10 : maxY * 1.3,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.withAlpha(opacityCalculation(.85)),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${dates[group.x]}\nRM ${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.white, fontSize: 11),
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
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == 0) return const SizedBox();
                        return Text(
                          'RM ${value.toInt()}',
                          style: const TextStyle(color: _muted, fontSize: 10),
                        );
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
                            style: const TextStyle(color: _muted, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(color: _divider, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(dates.length, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: values[i],
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF0891B2)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(screenPadding, screenPadding * 0.75, screenPadding, screenPadding * 0.75),
            child: Text(
              isSuperAdmin ? 'Branch Breakdown' : 'Daily Breakdown',
              style: AppTypography.displayMedium(context),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildDataTable(data, isSuperAdmin, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Data> data, bool isSuperAdmin, PaymentController controller) {
    const headerStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF6B7280));
    const cellStyle = TextStyle(fontSize: 13, color: Color(0xFF111827));

    Widget headerCell(String text) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(text, style: headerStyle),
      );
    }

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: TableBorder(
        horizontalInside: BorderSide(color: const Color(0xFFE5E7EB).withAlpha(128), width: 1),
      ),
      children: [
        // Header row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
          children: [
            if (isSuperAdmin) headerCell('Branch'),
            headerCell('Date'),
            headerCell('Payments'),
            headerCell('Successful'),
            headerCell('Failed'),
            headerCell('Paid (RM)'),
            headerCell('Refund (RM)'),
            headerCell('Net Revenue (RM)'),
          ],
        ),
        // Data rows
        if (data.isEmpty)
          TableRow(
            children: [
              if (isSuperAdmin)
                const Padding(padding: EdgeInsets.all(16), child: Text('—', style: cellStyle)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Text('No data available', style: AppTypography.bodyMedium(context).apply(color: _muted)),
              ),
              const Padding(padding: EdgeInsets.all(16), child: Text('—', style: cellStyle)),
              const Padding(padding: EdgeInsets.all(16), child: Text('—', style: cellStyle)),
              const Padding(padding: EdgeInsets.all(16), child: Text('—', style: cellStyle)),
              const Padding(padding: EdgeInsets.all(16), child: Text('—', style: cellStyle)),
              const Padding(padding: EdgeInsets.all(16), child: Text('—', style: cellStyle)),
              const Padding(padding: EdgeInsets.all(16), child: Text('—', style: cellStyle)),
            ],
          ),
        for (int i = 0; i < data.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xFFFAFAFA),
            ),
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
                  onTap: () {
                    showLoading();
                    PaymentController.successPayment(
                      context,
                      date: data[i].paymentDate,
                      branchId: data[i].branchId,
                    ).then((value) {
                      dismissLoading();
                      if (responseCode(value.code)) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AppointmentIds(response: value.data),
                        );
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Text(
                              data[i].successfulPayments ?? '0',
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.open_in_new_rounded, size: 12, color: CupertinoColors.link),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cancel_outlined, size: 13, color: Color(0xFFEF4444)),
                      const SizedBox(width: 4),
                      Text(
                        data[i].failedPayments ?? '0',
                        style: const TextStyle(
                          color: Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(data[i].totalPaidAmount ?? '0.00', style: cellStyle),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  data[i].totalRefundAmount ?? '0.00',
                  style: cellStyle.copyWith(
                    color: (double.tryParse(data[i].totalRefundAmount ?? '0') ?? 0) > 0
                        ? const Color(0xFFF59E0B)
                        : null,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  data[i].netRevenue ?? '0.00',
                  style: cellStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0891B2),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _CardConfig {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color bg;
  final Color valueColor;

  const _CardConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.bg,
    required this.valueColor,
  });
}

class _SummaryCard extends StatelessWidget {
  final _CardConfig config;
  const _SummaryCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: config.bg, borderRadius: BorderRadius.circular(10)),
                child: Icon(config.icon, color: config.accent, size: 18),
              ),
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: config.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            config.value,
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: config.valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            config.label,
            style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280), fontSizeDelta: -1),
          ),
        ],
      ),
    );
  }
}
