import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart';
import 'package:klinik_aurora_portal/models/reward/update_reward_request.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/reward/reward_detail.dart';
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
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class RewardHomepage extends StatefulWidget {
  static const routeName = '/reward';
  static const displayName = 'Rewards';
  final String? orderReference;
  const RewardHomepage({super.key, this.orderReference});

  @override
  State<RewardHomepage> createState() => _RewardHomepageState();
}

class _RewardHomepageState extends State<RewardHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _rewardNameController = TextEditingController();
  DropdownAttribute? _rewardStatus;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue =
          Homepage.getPageId(RewardHomepage.displayName);
    });
    filtering();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rewardNameController.dispose();
    rebuildDropdown.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: _mobileView(), desktop: _desktopView());
  }


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
                child: _rewardTable(),
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
                  _rewardNameController.text = val;
                  filtering(page: 1);
                },
                decoration: InputDecoration(
                  hintText: 'Search rewards...',
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
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const RewardDetail(reward: null, type: 'create'),
              );
            },
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
            label: const Text('Add Reward', style: TextStyle(color: Colors.white, fontSize: 13)),
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
                  builder: (ctx, setFilterState) {
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
                        const SizedBox(height: 24),
                        _filterLabel('Reward Name'),
                        const SizedBox(height: 6),
                        _filterTextField(_rewardNameController, 'Search by name'),
                        const SizedBox(height: 16),
                        _filterLabel('Status'),
                        const SizedBox(height: 6),
                        StreamBuilder<DateTime>(
                          stream: rebuildDropdown.stream,
                          builder: (context, _) {
                            return AppDropdown(
                              attributeList: DropdownAttributeList(
                                [
                                  DropdownAttribute('1', 'Active'),
                                  DropdownAttribute('0', 'Inactive'),
                                ],
                                labelText: 'Status',
                                value: _rewardStatus?.name,
                                onChanged: (p0) {
                                  _rewardStatus = p0;
                                  rebuildDropdown.add(DateTime.now());
                                  filtering(page: 1);
                                },
                                width: 280,
                              ),
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
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
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


  Widget _rewardTable() {
    return Consumer<RewardController>(
      builder: (context, snapshot, _) {
        if (snapshot.rewardAllResponse == null) {
          return const Center(child: CircularProgressIndicator(color: secondaryColor));
        }
        final items = snapshot.rewardAllResponse?.data?.data ?? [];
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
                minWidth: 800,
                isHorizontalScrollBarVisible: true,
                isVerticalScrollBarVisible: true,
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                headingRowHeight: 48,
                dataRowHeight: 60,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                columns: [
                  _col('Reward Name', ColumnSize.L),
                  _col('Points', ColumnSize.S, fixedWidth: 100),
                  _col('Total', ColumnSize.S, fixedWidth: 90),
                  _col('Valid Period', ColumnSize.M),
                  _col('Status', ColumnSize.S, fixedWidth: 100),
                  _col('Created', ColumnSize.S, fixedWidth: 130),
                  _col('Actions', ColumnSize.S, fixedWidth: 110),
                ],
                rows: [
                  for (int i = 0; i < items.length; i++)
                    DataRow2(
                      color: WidgetStateProperty.all(
                        i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC),
                      ),
                      cells: [
                        DataCell(_rewardNameCell(items[i])),
                        DataCell(_pointsBadge(items[i].rewardPoint)),
                        DataCell(
                          Text(
                            '${items[i].totalReward ?? 0}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
                          ),
                        ),
                        DataCell(_periodCell(items[i])),
                        DataCell(_statusChip(items[i])),
                        DataCell(
                          Text(
                            dateConverter(items[i].createdDate) ?? '—',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ),
                        DataCell(_actionsCell(items[i], snapshot)),
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

  Widget _rewardNameCell(Data reward) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: primary.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.card_giftcard_rounded, size: 18, color: primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                reward.rewardName ?? '—',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (reward.rewardDescription != null && reward.rewardDescription!.isNotEmpty)
                Text(
                  reward.rewardDescription!,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
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

  Widget _periodCell(Data reward) {
    final start = dateConverter(reward.rewardStartDate);
    final end = dateConverter(reward.rewardEndDate);
    if (start == null && end == null) {
      return const Text('—', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (start != null)
          Text(start, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        if (end != null)
          Text(
            '→ $end',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          ),
      ],
    );
  }

  Widget _statusChip(Data reward) {
    final isActive = reward.rewardStatus == 1 &&
        checkEndDate(reward.rewardEndDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEE2E2),
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

  Widget _actionsCell(Data reward, RewardController snapshot) {
    return Row(
      children: [
        _iconBtn(
          Icons.edit_outlined,
          const Color(0xFF6366F1),
          () {
            showDialog(
              context: context,
              builder: (_) => RewardDetail(reward: reward, type: 'update'),
            );
          },
        ),
        const SizedBox(width: 4),
        _iconBtn(
          reward.rewardStatus == 1 ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
          reward.rewardStatus == 1 ? const Color(0xFF16A34A) : Colors.grey,
          () async {
            try {
              if (await showConfirmDialog(
                context,
                reward.rewardStatus == 1
                    ? 'Are you certain you wish to deactivate this reward item?'
                    : 'Are you certain you wish to activate this reward item?',
              )) {
                Future.delayed(Duration.zero, () {
                  RewardController.update(
                    context,
                    UpdateRewardRequest(
                      rewardId: reward.rewardId ?? '',
                      rewardName: reward.rewardName ?? '',
                      rewardDescription: reward.rewardDescription ?? '',
                      rewardPoint: reward.rewardPoint ?? 0,
                      totalReward: reward.totalReward ?? 0,
                      rewardStartDate: reward.rewardStartDate ?? '',
                      rewardEndDate: reward.rewardEndDate ?? '',
                      rewardStatus: reward.rewardStatus == 1 ? 0 : 1,
                    ),
                  ).then((value) {
                    if (responseCode(value.code)) {
                      filtering();
                      showDialogSuccess(
                        context,
                        'The reward item has been successfully ${reward.rewardStatus == 1 ? 'deactivated' : 'activated'}.',
                      );
                    } else {
                      showDialogError(context, value.message ?? value.data?.message ?? '');
                    }
                  });
                });
              }
            } catch (e) {
              debugPrint(e.toString());
            }
          },
        ),
      ],
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


  Widget _mobileView() {
    return Consumer<RewardController>(
      builder: (context, snapshot, _) {
        final items = snapshot.rewardAllResponse?.data?.data ?? [];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  _rewardNameController.text = val;
                  filtering(page: 1);
                },
                decoration: InputDecoration(
                  hintText: 'Search rewards...',
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

  Widget _mobileCard(Data reward) {
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, size: 18, color: primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    reward.rewardName ?? '—',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                _statusChip(reward),
              ],
            ),
            const SizedBox(height: 10),
            _mobileRow('Points', '${reward.rewardPoint ?? 0} pts'),
            _mobileRow('Total', '${reward.totalReward ?? 0}'),
            _mobileRow('Created', dateConverter(reward.createdDate) ?? '—'),
            const SizedBox(height: 10),
            Row(
              children: [
                _iconBtn(Icons.edit_outlined, const Color(0xFF6366F1), () {
                  showDialog(
                    context: context,
                    builder: (_) => RewardDetail(reward: reward, type: 'update'),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }


  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce
        ? _debouncer.run(() => runFiltering(page: page))
        : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) _page = page;
    RewardController.getAll(
      context,
      _page,
      _pageSize,
      rewardName: _rewardNameController.text,
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
        context.read<RewardController>().rewardAllResponse = value;
      }
      return null;
    });
  }

  void resetAllFilter() {
    _rewardNameController.text = '';
    _rewardStatus = null;
    rebuildDropdown.add(DateTime.now());
  }
}
