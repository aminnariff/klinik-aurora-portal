import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/payment_mismatch_response.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/views/appointment/date_range_dashboard.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

/// Troubleshooting view: appointments where the payment succeeded but the
/// appointment record is soft-deleted (appointment_is_deleted = 1) — i.e.
/// the patient paid but the booking isn't actually in the schedule. Lets an
/// admin retry the automatic slot-reclaim (book the slot + clear the delete
/// flag) if it's still free, or confirms it needs manual rescheduling.
/// See admin/appointment/get-payment-mismatch.ts and
/// admin/appointment/resolve-payment-mismatch.ts on the backend.
class PaymentMismatchPage extends StatefulWidget {
  static const routeName = '/appointment/payment-mismatch';
  static const displayName = 'Payment Issues';

  const PaymentMismatchPage({super.key});

  @override
  State<PaymentMismatchPage> createState() => _PaymentMismatchPageState();
}

class _PaymentMismatchPageState extends State<PaymentMismatchPage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;

  List<PaymentMismatchData> _items = [];
  bool _isLoading = true;
  String? _resolvingAppointmentId;

  DropdownAttribute? _branch;
  List<DropdownAttribute> _branches = [];
  bool _branchesLoaded = false;
  DateRange? _currentDateRange;
  String? _startDate;
  String? _endDate;

  final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(
        PaymentMismatchPage.displayName,
      );
    });
    _loadBranchesIfSuperAdmin();
    _fetch();
  }

  void _loadBranchesIfSuperAdmin() {
    if (!context.read<AuthController>().isSuperAdmin) return;
    BranchController.getAll(context, 1, 100).then((value) {
      if (!mounted || !responseCode(value.code)) return;
      final loaded = <DropdownAttribute>[];
      for (branch_model.Data item in value.data?.data ?? []) {
        loaded.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
      }
      loaded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _branches = loaded;
        _branchesLoaded = true;
      });
    });
  }

  void _fetch({int? page}) {
    if (page != null) _page = page;
    setState(() => _isLoading = true);
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
    AppointmentController.getPaymentMismatch(
      context,
      _page,
      _pageSize,
      branchId: isSuperAdmin ? _branch?.key : null,
      startDate: _startDate,
      endDate: _endDate,
    ).then((value) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (responseCode(value.code)) {
          _items = value.data?.data ?? [];
          _totalCount = value.data?.totalCount ?? 0;
          _totalPage = value.data?.totalPage ?? 1;
        }
      });
    });
  }

  Future<void> _reclaimSlot(PaymentMismatchData item) async {
    if (item.appointmentId == null) return;

    final confirmed = await showConfirmDialog(
      context,
      'This will book the slot for ${item.userName ?? 'this patient'} at ${item.appointmentDatetime != null ? '${formatToDisplayDate(item.appointmentDatetime!)} ${formatToDisplayTime(item.appointmentDatetime!)}' : 'the original time'} '
      'if it is still free, and restore the appointment. If someone else has since taken the slot, nothing will be overwritten — you will be told to reschedule manually instead.',
      title: 'Reclaim Slot?',
    );
    if (!confirmed) return;

    setState(() => _resolvingAppointmentId = item.appointmentId);
    final value = await AppointmentController.resolvePaymentMismatch(context, item.appointmentId!);
    if (!mounted) return;
    setState(() => _resolvingAppointmentId = null);

    final reclaimed = value.data?['reclaimed'] == true;
    final message = value.data?['message'] as String? ?? value.message ?? 'Something went wrong.';

    if (responseCode(value.code)) {
      if (reclaimed) {
        showDialogSuccess(context, message);
      } else {
        showDialogError(context, message);
      }
      _fetch(page: _page);
    } else {
      showDialogError(context, message);
    }
  }

  void _onDateRangeSelected(DateRange range) {
    _currentDateRange = range;
    _startDate = range.start != null ? DateFormat('yyyy-MM-dd').format(range.start!) : null;
    _endDate = range.end != null ? DateFormat('yyyy-MM-dd').format(range.end!) : null;
    _fetch(page: 1);
  }

  void _resetFilters() {
    setState(() {
      _branch = null;
      _currentDateRange = null;
      _startDate = null;
      _endDate = null;
    });
    _fetch(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: _body(), tablet: _body(), desktop: _body());
  }

  Widget _body() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          Consumer<AuthController>(
            builder: (context, authController, _) => authController.isSuperAdmin ? _branchBar() : const SizedBox.shrink(),
          ),
          _filterBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: _table(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 14),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Payment Issues', style: AppTypography.bodyLarge(context).copyWith(fontWeight: FontWeight.w700)),
                Text(
                  'Payment succeeded but the appointment is not in the schedule — needs manual follow-up.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _fetch(page: 1),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _branchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 10),
      margin: const EdgeInsets.only(bottom: 1),
      child: Row(
        children: [
          const Icon(Icons.location_city_rounded, size: 16, color: Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text('Branch', style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280))),
          const SizedBox(width: 12),
          Flexible(
            child: _branchesLoaded
                ? AppDropdown(
                    attributeList: DropdownAttributeList(
                      _branches,
                      isEditable: true,
                      value: _branch?.name,
                      hintText: 'All branches',
                      onChanged: (p0) {
                        setState(() => _branch = p0);
                        _fetch(page: 1);
                      },
                      width: screenWidthByBreakpoint(90, 70, 280, useAbsoluteValueDesktop: true),
                    ),
                  )
                : const Text('Loading branches...', style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(screenPadding, 10, screenPadding, 10),
      child: Row(
        children: [
          Expanded(
            child: DateFilterDropdown(
              key: ValueKey('mismatch-bar-${_currentDateRange?.label}'),
              initial: _currentDateRange,
              onSelected: _onDateRangeSelected,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6B7280)),
            tooltip: 'Reset filters',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _table() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: secondaryColor));
    }
    if (_items.isEmpty) {
      return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [NoRecordsWidget()]);
    }
    return Column(
      children: [
        Expanded(
          child: DataTable2(
            columnSpacing: 16,
            horizontalMargin: 20,
            minWidth: 1100,
            isHorizontalScrollBarVisible: true,
            isVerticalScrollBarVisible: true,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
            headingRowHeight: 48,
            dataRowHeight: 64,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            columns: [
              _col('Patient', ColumnSize.L),
              _col('Branch', ColumnSize.M),
              _col('Service', ColumnSize.M),
              _col('Appointment Time', ColumnSize.M),
              _col('Payment', ColumnSize.M),
              _col('Flagged Since', ColumnSize.S, fixedWidth: 140),
              _col('Actions', ColumnSize.S, fixedWidth: 130),
            ],
            rows: [
              for (int i = 0; i < _items.length; i++)
                DataRow2(
                  color: WidgetStateProperty.all(i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC)),
                  cells: [
                    DataCell(_patientCell(_items[i])),
                    DataCell(_branchCell(_items[i])),
                    DataCell(
                      Text(
                        _items[i].serviceName ?? '—',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    DataCell(
                      Text(
                        formatToDisplayDate(_items[i].appointmentDatetime ?? '') +
                            (_items[i].appointmentDatetime != null
                                ? ' ${formatToDisplayTime(_items[i].appointmentDatetime!)}'
                                : ''),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                      ),
                    ),
                    DataCell(_paymentCell(_items[i])),
                    DataCell(
                      Text(
                        dateConverter(_items[i].appointmentModifiedDate) ?? '—',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ),
                    DataCell(_actionsCell(_items[i])),
                  ],
                ),
            ],
          ),
        ),
        _footer(),
      ],
    );
  }

  DataColumn2 _col(String label, ColumnSize size, {double? fixedWidth}) {
    return DataColumn2(
      fixedWidth: fixedWidth,
      size: size,
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), letterSpacing: 0.3),
      ),
    );
  }

  Widget _patientCell(PaymentMismatchData item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.userName ?? '—',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          overflow: TextOverflow.ellipsis,
        ),
        if (item.userPhone != null && item.userPhone!.isNotEmpty)
          Text(item.userPhone!, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ],
    );
  }

  Widget _branchCell(PaymentMismatchData item) {
    return Text(
      item.branchName ?? '—',
      style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _paymentCell(PaymentMismatchData item) {
    final amount = double.tryParse(item.paymentAmount ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          amount != null ? currencyFormatter.format(amount) : (item.paymentAmount ?? '—'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
        ),
        Text(
          '${item.gatewayLabel}${item.paymentReceiptNo != null && item.paymentReceiptNo!.isNotEmpty ? ' · ${item.paymentReceiptNo}' : ''}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        children: [
          Expanded(
            child: Pagination(
              numOfPages: _totalPage,
              selectedPage: _page,
              pagesVisible: 5,
              spacing: 10,
              onPageChanged: (page) => _fetch(page: page),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile && !isTablet)
                Text('Rows per page: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              PerPageWidget(
                _pageSize.toString(),
                DropdownAttributeList(
                  [],
                  onChanged: (selected) {
                    _pageSize = int.parse((selected as DropdownAttribute).key);
                    _fetch(page: 1);
                  },
                ),
              ),
              if (!isMobile && !isTablet) ...[
                const SizedBox(width: 8),
                Text(
                  '${((_page) * _pageSize) - _pageSize + 1}–${((_page) * _pageSize < _totalCount) ? ((_page) * _pageSize) : _totalCount} of $_totalCount',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
