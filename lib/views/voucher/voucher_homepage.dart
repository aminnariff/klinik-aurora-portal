import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/voucher/update_voucher_request.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/voucher/voucher_detail.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:provider/provider.dart';

class VoucherHomepage extends StatefulWidget {
  static const routeName = '/voucher';
  static const displayName = 'Vouchers';
  final String? orderReference;
  const VoucherHomepage({super.key, this.orderReference});

  @override
  State<VoucherHomepage> createState() => _VoucherHomepageState();
}

class _VoucherHomepageState extends State<VoucherHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _voucherNameController = TextEditingController();
  final TextEditingController _voucherCodeController = TextEditingController();
  DropdownAttribute? _voucherStatus;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue =
          Homepage.getPageId(VoucherHomepage.displayName);
    });
    filtering();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _voucherNameController.dispose();
    _voucherCodeController.dispose();
    rebuildDropdown.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: _mobileView(), desktop: _desktopView());
  }

  // ── Mobile ──────────────────────────────────────────────────────────────────

  Widget _mobileView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (int index = 0; index < 2; index++)
                  Card(
                    margin: EdgeInsets.symmetric(
                      vertical: screenPadding / 2,
                      horizontal: screenPadding,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenPadding),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Text('N/A'), Text('N/A')],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenPadding),
          child: pagination(),
        ),
      ],
    );
  }

  // ── Desktop ─────────────────────────────────────────────────────────────────

  Widget _desktopView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _topBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _table(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  _voucherNameController.text = val;
                  filtering(page: 1);
                },
                decoration: InputDecoration(
                  hintText: 'Search vouchers...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _toolbarButton(
            icon: Icons.filter_list_rounded,
            label: 'Filter',
            color: const Color(0xFF6366F1),
            onTap: _showFilterPanel,
          ),
          const SizedBox(width: 8),
          _toolbarButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            color: Colors.grey[600]!,
            onTap: () {
              _searchController.clear();
              resetAllFilter();
              filtering(enableDebounce: false, page: 1);
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const VoucherDetail(type: 'create'),
            ),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text('Add Voucher', style: TextStyle(color: Colors.white, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolbarButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 13)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        side: BorderSide(color: color.withAlpha(80)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showFilterPanel() {
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (_) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          elevation: 8,
          child: SizedBox(
            width: 320,
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: StatefulBuilder(
                builder: (ctx, setLocalState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _filterLabel('Voucher Name'),
                    const SizedBox(height: 6),
                    _filterTextField(_voucherNameController, 'Search by name'),
                    const SizedBox(height: 16),
                    _filterLabel('Voucher Code'),
                    const SizedBox(height: 6),
                    _filterTextField(_voucherCodeController, 'Search by code'),
                    const SizedBox(height: 16),
                    _filterLabel('Status'),
                    const SizedBox(height: 6),
                    AppDropdown(
                      attributeList: DropdownAttributeList(
                        [
                          DropdownAttribute('1', 'Active'),
                          DropdownAttribute('0', 'Inactive'),
                        ],
                        labelText: 'Status',
                        value: _voucherStatus?.name,
                        onChanged: (p0) {
                          _voucherStatus = p0;
                          setLocalState(() => rebuildDropdown.add(DateTime.now()));
                          filtering(page: 1);
                        },
                        width: 280,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          resetAllFilter();
                          filtering(enableDebounce: false, page: 1);
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Clear Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterLabel(String text) => Text(
    text,
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
  );

  Widget _filterTextField(TextEditingController controller, String hint) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        onChanged: (_) => filtering(page: 1),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF5F6FA),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Table ───────────────────────────────────────────────────────────────────

  Widget _table() {
    return Consumer<VoucherController>(
      builder: (context, snapshot, _) {
        if (snapshot.voucherAllResponse == null) {
          return const Center(child: CircularProgressIndicator(color: secondaryColor));
        }
        if (snapshot.voucherAllResponse?.data?.data?.isEmpty ?? true) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [NoRecordsWidget()],
          );
        }
        final items = snapshot.voucherAllResponse!.data!.data!;
        return Column(
          children: [
            Expanded(
              child: DataTable2(
                columnSpacing: 16,
                horizontalMargin: 20,
                minWidth: 750,
                isHorizontalScrollBarVisible: true,
                isVerticalScrollBarVisible: true,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                headingRowHeight: 48,
                dataRowHeight: 56,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                columns: [
                  _col('Code', ColumnSize.S, fixedWidth: 140),
                  _col('Name', ColumnSize.L),
                  _col('Points', ColumnSize.S, fixedWidth: 90),
                  _col('Status', ColumnSize.S, fixedWidth: 90),
                  _col('Created', ColumnSize.S, fixedWidth: 120),
                  _col('Actions', ColumnSize.S, fixedWidth: 80),
                ],
                rows: [
                  for (int i = 0; i < items.length; i++)
                    DataRow2(
                      color: WidgetStateProperty.all(
                        i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC),
                      ),
                      cells: [
                        DataCell(_codeCell(items[i].voucherCode)),
                        DataCell(
                          GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) =>
                                  VoucherDetail(type: 'update', voucher: items[i]),
                            ),
                            child: Text(
                              items[i].voucherName ?? '—',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            '${items[i].voucherPoint ?? '—'}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                          ),
                        ),
                        DataCell(
                          _statusChip(
                            items[i].voucherStatus == 1 &&
                                checkEndDate(items[i].voucherEndDate),
                          ),
                        ),
                        DataCell(
                          Text(
                            dateConverter(items[i].createdDate) ?? '—',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ),
                        DataCell(_actionsMenu(items[i])),
                      ],
                    ),
                ],
              ),
            ),
            _tableFooter(),
          ],
        );
      },
    );
  }

  DataColumn2 _col(String label, ColumnSize size, {double? fixedWidth}) {
    return DataColumn2(
      fixedWidth: fixedWidth,
      size: size,
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _codeCell(String? code) {
    if (code == null || code.isEmpty) {
      return const Text('—', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        code.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
        ),
      ),
    );
  }

  Widget _actionsMenu(Data data) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      color: Colors.white,
      tooltip: '',
      onSelected: (value) async {
        if (value == 'edit') {
          showDialog(
            context: context,
            builder: (_) => VoucherDetail(type: 'update', voucher: data),
          );
        } else if (value == 'toggle') {
          try {
            if (await showConfirmDialog(
              context,
              data.voucherStatus == 1
                  ? 'Are you certain you wish to deactivate this voucher? Please note, this action can be reversed at a later time.'
                  : 'Are you certain you wish to activate this voucher? Please note, this action can be reversed at a later time.',
            )) {
              Future.delayed(Duration.zero, () {
                VoucherController.update(
                  context,
                  UpdateVoucherRequest(
                    voucherId: data.voucherId ?? '',
                    voucherName: data.voucherName ?? '',
                    voucherDescription: data.voucherDescription ?? '',
                    voucherCode: data.voucherCode ?? '',
                    voucherPoint: data.voucherPoint ?? 0,
                    voucherStartDate: data.voucherStartDate ?? '',
                    voucherEndDate: data.voucherEndDate ?? '',
                    voucherStatus: data.voucherStatus == 1 ? 0 : 1,
                  ),
                ).then((res) {
                  if (responseCode(res.code)) {
                    filtering();
                    showDialogSuccess(
                      context,
                      'The voucher has been successfully ${data.voucherStatus == 1 ? 'deactivated' : 'activated'}.',
                    );
                  } else {
                    showDialogError(context, res.message ?? res.data?.message ?? '');
                  }
                });
              });
            }
          } catch (e) {
            debugPrint(e.toString());
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(children: [
            Icon(Icons.edit_rounded, size: 16, color: Color(0xFF6B7280)),
            SizedBox(width: 10),
            Text('Edit Voucher', style: TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(children: [
            Icon(
              data.voucherStatus == 1 ? Icons.block_rounded : Icons.check_circle_outline_rounded,
              size: 16,
              color: data.voucherStatus == 1 ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 10),
            Text(
              data.voucherStatus == 1 ? 'Deactivate' : 'Activate',
              style: TextStyle(fontSize: 13, color: data.voucherStatus == 1 ? Colors.red : Colors.green),
            ),
          ]),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Icon(Icons.more_horiz, color: Color(0xFF374151), size: 18),
      ),
    );
  }

  Widget _tableFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(child: pagination()),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile && !isTablet)
                Text('Rows per page: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              perPage(),
              if (!isMobile && !isTablet) ...[
                const SizedBox(width: 8),
                Text(
                  '${((_page) * _pageSize) - _pageSize + 1}–'
                  '${(_page * _pageSize < _totalCount) ? _page * _pageSize : _totalCount}'
                  ' of $_totalCount',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Logic ────────────────────────────────────────────────────────────────────

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce
        ? _debouncer.run(() => runFiltering(page: page))
        : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) _page = page;
    VoucherController.getAll(
      context,
      _page,
      _pageSize,
      voucherName: _voucherNameController.text,
      voucherCode: _voucherCodeController.text,
      voucherStatus: _voucherStatus != null
          ? _voucherStatus?.key == '1'
                ? 1
                : _voucherStatus?.key == '0'
                ? 0
                : null
          : null,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage =
            value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        context.read<VoucherController>().voucherAllResponse = value;
      } else if (value.code == 404) {}
      return null;
    });
  }

  void resetAllFilter() {
    _voucherNameController.text = '';
    _voucherCodeController.text = '';
    _voucherStatus = null;
    rebuildDropdown.add(DateTime.now());
  }

  Widget perPage() {
    return PerPageWidget(
      _pageSize.toString(),
      DropdownAttributeList(
        [],
        onChanged: (selected) {
          _pageSize = int.parse((selected as DropdownAttribute).key);
          filtering(enableDebounce: false);
        },
      ),
    );
  }

  Widget pagination() {
    return Pagination(
      numOfPages: _totalPage,
      selectedPage: _page,
      pagesVisible: 5,
      spacing: 10,
      onPageChanged: _movePage,
    );
  }

  void _movePage(int page) => filtering(page: page, enableDebounce: false);
}
