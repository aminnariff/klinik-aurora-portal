import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_history_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/reward/reward_history_response.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/reward_history/reward_history_detail.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
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

class RewardHistoryHomepage extends StatefulWidget {
  static const routeName = '/reward-history';
  static const displayName = 'Manage Rewards';
  const RewardHistoryHomepage({super.key});

  @override
  State<RewardHistoryHomepage> createState() => _RewardHistoryHomepageState();
}

class _RewardHistoryHomepageState extends State<RewardHistoryHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerUserNameController = TextEditingController();
  final TextEditingController _rewardNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  DropdownAttribute? _rewardHistoryStatus;
  DropdownAttribute? _rewardStatus;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue =
          Homepage.getPageId(RewardHistoryHomepage.displayName);
    });
    filtering();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customerNameController.dispose();
    _customerUserNameController.dispose();
    _rewardNameController.dispose();
    _customerPhoneController.dispose();
    rebuildDropdown.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: _mobileView(), desktop: _desktopView());
  }

  // ─── Desktop ────────────────────────────────────────────────────────────────

  Widget _desktopView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                child: _historyTable(),
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
                  _customerNameController.text = val;
                  filtering(page: 1);
                },
                decoration: InputDecoration(
                  hintText: 'Search by patient name...',
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
      builder: (_) {
        return Align(
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
                  builder: (ctx, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filter',
                              style: AppTypography.bodyLarge(context)
                                  .copyWith(fontWeight: FontWeight.w700),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close_rounded),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _filterLabel('Patient Name'),
                        const SizedBox(height: 6),
                        _filterTextField(_customerNameController, 'Search by name'),
                        const SizedBox(height: 14),
                        _filterLabel('Patient Username'),
                        const SizedBox(height: 6),
                        _filterTextField(_customerUserNameController, 'Search by username'),
                        const SizedBox(height: 14),
                        _filterLabel('Patient Contact No.'),
                        const SizedBox(height: 6),
                        _filterTextField(_customerPhoneController, 'Search by phone'),
                        const SizedBox(height: 14),
                        _filterLabel('Reward Name'),
                        const SizedBox(height: 6),
                        _filterTextField(_rewardNameController, 'Search by reward'),
                        const SizedBox(height: 14),
                        _filterLabel('Redemption Status'),
                        const SizedBox(height: 6),
                        StreamBuilder<DateTime>(
                          stream: rebuildDropdown.stream,
                          builder: (context, __) {
                            return Column(
                              children: [
                                AppDropdown(
                                  attributeList: DropdownAttributeList(
                                    [
                                      DropdownAttribute('1', 'In-Progress'),
                                      DropdownAttribute('0', 'Completed'),
                                    ],
                                    labelText: 'Redemption Status',
                                    value: _rewardHistoryStatus?.name,
                                    onChanged: (p0) {
                                      _rewardHistoryStatus = p0;
                                      rebuildDropdown.add(DateTime.now());
                                      filtering(page: 1);
                                    },
                                    width: 280,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                AppDropdown(
                                  attributeList: DropdownAttributeList(
                                    [
                                      DropdownAttribute('1', 'Active'),
                                      DropdownAttribute('0', 'Inactive'),
                                    ],
                                    labelText: 'Reward Status',
                                    value: _rewardStatus?.name,
                                    onChanged: (p0) {
                                      _rewardStatus = p0;
                                      rebuildDropdown.add(DateTime.now());
                                      filtering(page: 1);
                                    },
                                    width: 280,
                                  ),
                                ),
                              ],
                            );
                          },
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Clear Filters'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _filterLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
    );
  }

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

  // ─── Table ──────────────────────────────────────────────────────────────────

  Widget _historyTable() {
    return Consumer<RewardHistoryController>(
      builder: (context, snapshot, _) {
        if (snapshot.rewardHistoryResponse == null) {
          return const Center(child: CircularProgressIndicator(color: secondaryColor));
        }
        final items = snapshot.rewardHistoryResponse?.data?.data ?? [];
        if (items.isEmpty) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [NoRecordsWidget()],
          );
        }
        return Column(
          children: [
            Expanded(
              child: DataTable2(
                columnSpacing: 16,
                horizontalMargin: 20,
                minWidth: 900,
                isHorizontalScrollBarVisible: true,
                isVerticalScrollBarVisible: true,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                headingRowHeight: 48,
                dataRowHeight: 64,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                columns: [
                  _col('Patient', ColumnSize.L),
                  _col('Reward', ColumnSize.M),
                  _col('Points Used', ColumnSize.S, fixedWidth: 110),
                  _col('Status', ColumnSize.S, fixedWidth: 120),
                  _col('Remark', ColumnSize.M),
                  _col('Last Update', ColumnSize.S, fixedWidth: 130),
                  _col('Actions', ColumnSize.S, fixedWidth: 80),
                ],
                rows: [
                  for (int i = 0; i < items.length; i++)
                    DataRow2(
                      color: WidgetStateProperty.all(
                        i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC),
                      ),
                      cells: [
                        DataCell(_patientCell(items[i])),
                        DataCell(_rewardCell(items[i])),
                        DataCell(_pointsBadge(items[i].transactionPoint)),
                        DataCell(_statusChip(items[i])),
                        DataCell(
                          Text(
                            items[i].rewardHistoryDescription ?? '—',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          Text(
                            dateConverter(items[i].rewardHistoryModifiedDate) ??
                                dateConverter(items[i].rewardHistoryCreatedDate) ??
                                '—',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ),
                        DataCell(
                          _iconBtn(
                            Icons.edit_outlined,
                            const Color(0xFF6366F1),
                            () {
                              showDialog(
                                context: context,
                                builder: (_) => RewardHistoryDetail(
                                  data: items[i],
                                  type: 'update',
                                ),
                              );
                            },
                          ),
                        ),
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

  Widget _patientCell(Data item) {
    final name = item.userFullname ?? '—';
    final initials = name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF06B6D4),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    final color = colors[(name.codeUnitAt(0)) % colors.length];
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: color.withAlpha(40),
          child: Text(
            initials,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (item.userPhone != null && item.userPhone!.isNotEmpty)
                Text(
                  item.userPhone!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rewardCell(Data item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          item.rewardName ?? '—',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF111827),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (item.rewardDescription != null && item.rewardDescription!.isNotEmpty)
          Text(
            item.rewardDescription!,
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _pointsBadge(int? points) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Text(
        '${points ?? 0} pts',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0369A1),
        ),
      ),
    );
  }

  Widget _statusChip(Data item) {
    final isInProgress = item.rewardHistoryStatus == 1;
    final label = isInProgress ? 'In-Progress' : 'Completed';
    final bg = isInProgress ? const Color(0xFFFFF7ED) : const Color(0xFFDCFCE7);
    final textColor = isInProgress ? const Color(0xFFC2410C) : const Color(0xFF15803D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color),
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
          Expanded(
            child: Pagination(
              numOfPages: _totalPage,
              selectedPage: _page,
              pagesVisible: 5,
              spacing: 10,
              onPageChanged: (page) => filtering(page: page, enableDebounce: false),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile && !isTablet)
                Text(
                  'Rows per page: ',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              PerPageWidget(
                _pageSize.toString(),
                DropdownAttributeList(
                  [],
                  onChanged: (selected) {
                    _pageSize = int.parse((selected as DropdownAttribute).key);
                    filtering(enableDebounce: false);
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

  // ─── Mobile ──────────────────────────────────────────────────────────────────

  Widget _mobileView() {
    return Consumer<RewardHistoryController>(
      builder: (context, snapshot, _) {
        final items = snapshot.rewardHistoryResponse?.data?.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  _customerNameController.text = val;
                  filtering(page: 1);
                },
                decoration: InputDecoration(
                  hintText: 'Search by patient name...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: NoRecordsWidget())
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _mobileCard(items[i]),
                    ),
            ),
            _tableFooter(),
          ],
        );
      },
    );
  }

  Widget _mobileCard(Data item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.userFullname ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                _statusChip(item),
              ],
            ),
            const SizedBox(height: 8),
            _mobileRow('Reward', item.rewardName ?? '—'),
            _mobileRow('Points', '${item.transactionPoint ?? 0} pts'),
            if (item.userPhone != null) _mobileRow('Phone', item.userPhone!),
            _mobileRow(
              'Updated',
              dateConverter(item.rewardHistoryModifiedDate) ??
                  dateConverter(item.rewardHistoryCreatedDate) ??
                  '—',
            ),
            if (item.rewardHistoryDescription != null &&
                item.rewardHistoryDescription!.isNotEmpty)
              _mobileRow('Remark', item.rewardHistoryDescription!),
            const SizedBox(height: 8),
            _iconBtn(Icons.edit_outlined, const Color(0xFF6366F1), () {
              showDialog(
                context: context,
                builder: (_) => RewardHistoryDetail(data: item, type: 'update'),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _mobileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter / Logic ──────────────────────────────────────────────────────────

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce
        ? _debouncer.run(() => runFiltering(page: page))
        : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) _page = page;
    RewardHistoryController.getAll(
      context,
      _page,
      _pageSize,
      customerName: _customerNameController.text.isNotEmpty ? _customerNameController.text : null,
      customerUsername:
          _customerUserNameController.text.isNotEmpty ? _customerUserNameController.text : null,
      userPhone: _customerPhoneController.text.isNotEmpty ? _customerPhoneController.text : null,
      rewardName: _rewardNameController.text.isNotEmpty ? _rewardNameController.text : null,
      rewardHistoryStatus: _rewardHistoryStatus != null
          ? _rewardHistoryStatus?.key == '1'
              ? 1
              : _rewardHistoryStatus?.key == '0'
                  ? 0
                  : null
          : null,
      rewardStatus: _rewardStatus != null
          ? _rewardStatus?.key == '1'
              ? 1
              : _rewardStatus?.key == '0'
                  ? 0
                  : null
          : null,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage =
            value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        context.read<RewardHistoryController>().rewardHistoryResponse = value;
      }
      return null;
    });
  }

  void resetAllFilter() {
    _customerNameController.text = '';
    _customerUserNameController.text = '';
    _rewardNameController.text = '';
    _customerPhoneController.text = '';
    _rewardHistoryStatus = null;
    _rewardStatus = null;
    rebuildDropdown.add(DateTime.now());
  }
}
