import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/points/point_detail.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/table/table_header_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class UserPointDetail extends StatefulWidget {
  final UserResponse user;
  const UserPointDetail({super.key, required this.user});

  @override
  State<UserPointDetail> createState() => _UserPointDetailState();
}

class _UserPointDetailState extends State<UserPointDetail> {
  final List<TableHeaderAttribute> headers = [
    TableHeaderAttribute(
      attribute: 'transactionId',
      label: 'Transaction ID',
      allowSorting: false,
      columnSize: ColumnSize.M,
    ),
    TableHeaderAttribute(attribute: 'type', label: 'Type', allowSorting: false, columnSize: ColumnSize.S),
    TableHeaderAttribute(
      attribute: 'points',
      label: 'Points',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 100,
    ),
    TableHeaderAttribute(attribute: 'description', label: 'Description', allowSorting: false, columnSize: ColumnSize.L),
    TableHeaderAttribute(
      attribute: 'createdDate',
      label: 'Created Date',
      allowSorting: false,
      columnSize: ColumnSize.M,
      width: 160,
    ),
  ];
  bool? isLoading;

  @override
  void initState() {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      context.read<UserController>().userPoints = null;
      UserController.points(context, widget.user.userId ?? '').then((value) {
        setState(() => isLoading = false);
        if (responseCode(value.code)) {
          context.read<UserController>().userPoints = value.data;
        } else {
          showDialogError(context, 'Unable to fetch user\'s points history');
        }
      });
      PointManagementController.get(context, 1, userId: widget.user.userId).then((value) {
        if (responseCode(value.code)) {
          context.read<PointManagementController>().userPointsResponse = value.data;
        }
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 900, maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modern Header
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        (widget.user.userFullname ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.user.userFullname}\'s Points',
                          style: AppTypography.bodyMedium(context).copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'View and manage customer loyalty points',
                          style: AppTypography.bodyMedium(
                            context,
                          ).apply(color: Colors.grey.shade500, fontSizeDelta: -1),
                        ),
                      ],
                    ),
                  ),
                  if (context.read<AuthController>().isSuperAdmin) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => PointDetail(user: widget.user),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Add Points', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Consumer<UserController>(
                  builder: (context, snapshot, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            _buildSummaryCard(
                              context,
                              'Current Balance',
                              '${snapshot.userPoints?.data?.totalPoint ?? 0}',
                              Icons.stars_rounded,
                              const Color(0xFFFACC15), // Yellow/Gold
                            ),
                            const SizedBox(width: 20),
                            _buildSummaryCard(
                              context,
                              'Next Expiry',
                              snapshot.userPoints?.data?.nextExpiry != null
                                  ? dateConverter(snapshot.userPoints?.data?.nextExpiry, format: 'dd MMM yyyy')!
                                  : 'No expiry',
                              Icons.timer_outlined,
                              const Color(0xFFF87171), // Red
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'Transaction History',
                          style: AppTypography.bodyMedium(context).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),

                        // Table Section
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox(
                            height: 450,
                            child: isLoading != false
                                ? const Center(child: CircularProgressIndicator())
                                : ((snapshot.userPoints?.data?.history?.length ?? 0) == 0)
                                ? const NoRecordsWidget()
                                : DataTable2(
                                    columnSpacing: 16,
                                    horizontalMargin: 16,
                                    minWidth: 800,
                                    headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                                    headingRowHeight: 52,
                                    dataRowHeight: 60,
                                    columns: columns(),
                                    rows: List.generate(snapshot.userPoints?.data?.history?.length ?? 0, (index) {
                                      final item = snapshot.userPoints!.data!.history![index];
                                      final isNegative = item.pointType == 3 || item.pointType == 5; // Claim or Expired

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Text(
                                              item.transactionId ?? 'N/A',
                                              style: AppTypography.bodyMedium(
                                                context,
                                              ).copyWith(fontFamily: 'Monospace', fontSize: 12),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getTypeColor(item.pointType).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                pointType(item.pointType),
                                                style: TextStyle(
                                                  color: _getTypeColor(item.pointType),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              '${isNegative ? '-' : '+'}${item.points}',
                                              style: AppTypography.bodyMedium(context).copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: isNegative ? Colors.red : Colors.green,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              item.description ?? '—',
                                              style: AppTypography.bodyMedium(context),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              dateConverter(item.date) ?? 'N/A',
                                              style: AppTypography.bodyMedium(
                                                context,
                                              ).apply(color: Colors.grey.shade600),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium(context).apply(color: Colors.grey.shade600, fontSizeDelta: -1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.bodyMedium(context).copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(int? type) {
    switch (type) {
      case 1:
        return Colors.blue; // Referral
      case 2:
        return Colors.teal; // Voucher
      case 3:
        return Colors.orange; // Claim Reward
      case 4:
        return Colors.green; // Spending
      case 5:
        return Colors.red; // Expired
      default:
        return Colors.grey;
    }
  }

  List<DataColumn2> columns() {
    return [
      for (TableHeaderAttribute item in headers)
        DataColumn2(
          fixedWidth: item.width,
          size: item.columnSize ?? ColumnSize.M,
          label: Text(item.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
    ];
  }
}
