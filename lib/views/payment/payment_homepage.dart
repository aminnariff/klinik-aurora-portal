import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/payment/payment_controller.dart';
import 'package:klinik_aurora_portal/views/payment/appointment_ids.dart';
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
    print('A');
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
      case 'Custom':
        // default to full month for now, can add date picker later
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
                          'Last Month',
                          'Custom',
                        ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) async {
                          if (val == null) return;

                          if (val == 'Custom') {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2023),
                              lastDate: DateTime.now(),
                              initialDateRange: DateTimeRange(start: startDate, end: endDate),
                            );

                            if (picked != null) {
                              setState(() {
                                selectedFilter = 'Custom';
                                startDate = picked.start;
                                endDate = picked.end;
                                getData();
                              });
                            }
                          } else {
                            setState(() {
                              selectedFilter = val;
                              applyDateFilter();
                              getData();
                            });
                          }
                        },
                      ),
                      SizedBox(width: 16),
                      Text(getFormattedDateRange(), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          exportData();
                        },
                        icon: Icon(Icons.download, color: Colors.blue),
                        label: Text(
                          'Export',
                          style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1, color: Colors.blue),
                        ),
                      ),
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
                        value: '${snapshot.paymentReportResponse?.summary?.totalPayments ?? '0'}',
                      ),
                      SummaryCard(
                        title: 'Successful',
                        value: snapshot.paymentReportResponse?.summary?.successfulPayments ?? '0',
                      ),
                      SummaryCard(
                        title: 'Failed',
                        value: snapshot.paymentReportResponse?.summary?.failedPayments ?? '0',
                      ),
                      SummaryCard(
                        title: 'Paid Amount',
                        value: 'RM ${snapshot.paymentReportResponse?.summary?.totalPaidAmount ?? '0.00'}',
                      ),
                      SummaryCard(
                        title: 'Refunded',
                        value: 'RM ${snapshot.paymentReportResponse?.summary?.totalRefundAmount ?? '0.00'}',
                      ),
                      SummaryCard(
                        title: 'Net Revenue',
                        value: 'RM ${snapshot.paymentReportResponse?.summary?.netRevenue ?? '0.00'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (context.read<AuthController>().isSuperAdmin) ...[
                    const Text('Branch Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                  ],
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Branch Name')),
                            DataColumn(label: Text('Date')),
                            DataColumn(label: Text('Payments')),
                            DataColumn(label: Text('Success')),
                            DataColumn(label: Text('Failed')),
                            DataColumn(label: Text('Paid')),
                            DataColumn(label: Text('Refund')),
                            DataColumn(label: Text('Net Booking Fee')),
                          ],
                          rows: [
                            for (int index = 0; index < (snapshot.paymentReportResponse?.data?.length ?? 0); index++)
                              DataRow(
                                cells: [
                                  DataCell(Text('${snapshot.paymentReportResponse?.data?[index].branchName}')),
                                  DataCell(Text('${snapshot.paymentReportResponse?.data?[index].paymentDate}')),
                                  DataCell(Text('${snapshot.paymentReportResponse?.data?[index].totalPayments}')),
                                  DataCell(
                                    TextButton(
                                      child: Text(
                                        '${snapshot.paymentReportResponse?.data?[index].successfulPayments}',
                                        style: AppTypography.bodyMedium(context).apply(color: CupertinoColors.link),
                                      ),
                                      onPressed: () {
                                        showLoading();
                                        PaymentController.successPayment(
                                          context,
                                          date: snapshot.paymentReportResponse?.data?[index].paymentDate,
                                          branchId: snapshot.paymentReportResponse?.data?[index].branchId,
                                        ).then((value) {
                                          dismissLoading();
                                          if (responseCode(value.code)) {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AppointmentIds(response: value.data);
                                              },
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                  DataCell(Text('${snapshot.paymentReportResponse?.data?[index].failedPayments}')),
                                  DataCell(Text('${snapshot.paymentReportResponse?.data?[index].totalPaidAmount}')),
                                  DataCell(Text('${snapshot.paymentReportResponse?.data?[index].totalRefundAmount}')),
                                  DataCell(Text('${snapshot.paymentReportResponse?.data?[index].netRevenue}')),
                                ],
                              ),
                            if ((snapshot.paymentReportResponse?.data?.length ?? 0) == 0)
                              DataRow(
                                cells: [
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('No Data')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
                                  DataCell(Text('')),
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
