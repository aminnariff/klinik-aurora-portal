import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/payment/payment_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class BranchPaymentSummaryPage extends StatefulWidget {
  static const routeName = '/branch-payment-summary';
  static const displayName = 'Branch Payment Summary';
  const BranchPaymentSummaryPage({super.key});

  @override
  State<BranchPaymentSummaryPage> createState() => _BranchPaymentSummaryPageState();
}

class _BranchPaymentSummaryPageState extends State<BranchPaymentSummaryPage> {
  String selectedFilter = 'Today';
  late DateTime startDate;
  late DateTime endDate;

  @override
  void initState() {
    super.initState();
    applyDateFilter();
    getData();
  }

  void getData() {
    showLoading();
    PaymentController.branchReport(
      context,
      startDate: DateFormat('yyyy-MM-dd').format(startDate),
      endDate: DateFormat('yyyy-MM-dd').format(endDate),
    ).then((response) {
      dismissLoading();
      if (responseCode(response.code)) {
        context.read<PaymentController>().branchPaymentReportResponse = response.data;
      }
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
      return '${df.format(startDate)} - ${df.format(endDate)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Consumer<PaymentController>(
            builder: (context, snapshot, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: selectedFilter,
                        items: [
                          'Today',
                          'Yesterday',
                          'This Month',
                          'Custom',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedFilter = val;
                              applyDateFilter();
                              getData();
                            });
                          }
                        },
                      ),
                      const Spacer(),
                      Text(getFormattedDateRange(), style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SummaryCard(
                        title: 'Total Payments',
                        value: '${snapshot.branchPaymentReportResponse?.summaryTotals?.totalPayments ?? 'N/A'}',
                      ),
                      SummaryCard(
                        title: 'Successful',
                        value: '${snapshot.branchPaymentReportResponse?.summaryTotals?.successfulPayments ?? 'N/A'}',
                      ),
                      SummaryCard(
                        title: 'Failed',
                        value: '${snapshot.branchPaymentReportResponse?.summaryTotals?.failedPayments ?? 'N/A'}',
                      ),
                      SummaryCard(
                        title: 'Paid Amount',
                        value: 'RM ${snapshot.branchPaymentReportResponse?.summaryTotals?.totalPaidAmount ?? 'N/A'}',
                      ),
                      SummaryCard(
                        title: 'Refunded',
                        value: 'RM ${snapshot.branchPaymentReportResponse?.summaryTotals?.totalRefundAmount ?? 'N/A'}',
                      ),
                      SummaryCard(
                        title: 'Net Revenue',
                        value: 'RM ${snapshot.branchPaymentReportResponse?.summaryTotals?.netRevenue ?? 'N/A'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Branch Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 400,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Branch Name')),
                            DataColumn(label: Text('Payments')),
                            DataColumn(label: Text('Success')),
                            DataColumn(label: Text('Failed')),
                            DataColumn(label: Text('Paid')),
                            DataColumn(label: Text('Refund')),
                            DataColumn(label: Text('Net Revenue')),
                          ],
                          rows: [
                            for (
                              int index = 0;
                              index < (snapshot.branchPaymentReportResponse?.data?.length ?? 0);
                              index++
                            )
                              DataRow(
                                cells: [
                                  DataCell(Text('${snapshot.branchPaymentReportResponse?.data?[index].branchName}')),
                                  DataCell(Text('${snapshot.branchPaymentReportResponse?.data?[index].totalPayments}')),
                                  DataCell(
                                    Text('${snapshot.branchPaymentReportResponse?.data?[index].successfulPayments}'),
                                  ),
                                  DataCell(
                                    Text('${snapshot.branchPaymentReportResponse?.data?[index].failedPayments}'),
                                  ),
                                  DataCell(
                                    Text('${snapshot.branchPaymentReportResponse?.data?[index].totalPaidAmount}'),
                                  ),
                                  DataCell(
                                    Text('${snapshot.branchPaymentReportResponse?.data?[index].totalRefundAmount}'),
                                  ),
                                  DataCell(Text('${snapshot.branchPaymentReportResponse?.data?[index].netRevenue}')),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  const SummaryCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.displayMedium(context)),
        const SizedBox(height: 4),
        Text(title, style: AppTypography.bodyMedium(context)),
      ],
    );
  }
}
