import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/service/services_response.dart';
import 'package:klinik_aurora_portal/models/service/update_service_request.dart';
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/models/service_branch/update_service_branch_request.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/service/service_branch.dart';
import 'package:klinik_aurora_portal/views/service/service_details.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/multi_time_calendar.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
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

class ServiceHomepage extends StatefulWidget {
  static const routeName = '/service';
  static const displayName = 'Services';
  final String? orderReference;
  const ServiceHomepage({super.key, this.orderReference});

  @override
  State<ServiceHomepage> createState() => _ServiceHomepageState();
}

class _ServiceHomepageState extends State<ServiceHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _serviceNameController = TextEditingController();
  DropdownAttribute? _selectedServiceStatus;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(ServiceHomepage.displayName);
    });
    _page = 1;
    filtering();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _serviceNameController.dispose();
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
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: context.read<AuthController>().isSuperAdmin == true ? _superadminTable() : _adminTable(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin == true;
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
                  _serviceNameController.text = val;
                  filtering(page: 1);
                },
                decoration: InputDecoration(
                  hintText: 'Search services...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (isSuperAdmin) ...[
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
                  builder: (_) => const ServiceDetails(type: 'create'),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text('Add Service', style: TextStyle(color: Colors.white, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ] else ...[
            _toolbarButton(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
              color: Colors.grey[600]!,
              onTap: () => filtering(enableDebounce: false, page: 1),
            ),
          ],
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
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
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
                              style: AppTypography.bodyLarge(context).copyWith(fontWeight: FontWeight.w700),
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
                        _filterLabel('Service Name'),
                        const SizedBox(height: 6),
                        _filterTextField(_serviceNameController, 'Search by name'),
                        const SizedBox(height: 16),
                        _filterLabel('Status'),
                        const SizedBox(height: 6),
                        StreamBuilder<DateTime>(
                          stream: rebuildDropdown.stream,
                          builder: (context, _) {
                            return AppDropdown(
                              attributeList: DropdownAttributeList(
                                [DropdownAttribute('1', 'Active'), DropdownAttribute('0', 'Inactive')],
                                labelText: 'Status',
                                value: _selectedServiceStatus?.name,
                                onChanged: (p0) {
                                  _selectedServiceStatus = p0;
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
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
      ),
    );
  }


  Widget _superadminTable() {
    return Consumer<ServiceController>(
      builder: (context, snapshot, _) {
        if (snapshot.servicesResponse == null) {
          return const Center(child: CircularProgressIndicator(color: secondaryColor));
        }
        final items = snapshot.servicesResponse?.data ?? [];
        if (items.isEmpty) {
          return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [NoRecordsWidget()]);
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                columns: _superadminColumns(),
                rows: [
                  for (int i = 0; i < items.length; i++)
                    DataRow2(
                      color: WidgetStateProperty.all(i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC)),
                      cells: [
                        DataCell(_serviceNameCell(items[i].serviceName, items[i].serviceDescription)),
                        DataCell(_categoryChip(items[i].serviceCategory)),
                        DataCell(_timeBadge(items[i].serviceTime)),
                        DataCell(_priceCell(items[i].servicePrice, items[i].serviceBookingFee)),
                        DataCell(_doctorTypeChip(items[i].doctorType)),
                        DataCell(_statusChip(items[i].serviceStatus == 1)),
                        DataCell(
                          Text(
                            dateConverter(items[i].createdDate) ?? '—',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ),
                        DataCell(_superadminActions(items[i])),
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

  List<DataColumn2> _superadminColumns() {
    return [
      _col('Service', ColumnSize.L),
      _col('Category', ColumnSize.S),
      _col('Time', ColumnSize.S, fixedWidth: 100),
      _col('Price', ColumnSize.S, fixedWidth: 120),
      _col('Type', ColumnSize.S, fixedWidth: 100),
      _col('Status', ColumnSize.S, fixedWidth: 90),
      _col('Created', ColumnSize.S, fixedWidth: 120),
      _col('Actions', ColumnSize.S, fixedWidth: 80),
    ];
  }

  Widget _superadminActions(Data service) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      color: Colors.white,
      tooltip: '',
      onSelected: (value) => _handleMenuSelection(value, service),
      itemBuilder: (_) => [
        const PopupMenuItem<String>(value: 'update', child: Text('Edit Service')),
        const PopupMenuItem<String>(value: 'updateBranchesStatus', child: Text('Update Branch Service')),
        PopupMenuItem<String>(
          value: 'enableDisable',
          child: Text(service.serviceStatus == 1 ? 'Deactivate' : 'Re-Activate'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.more_horiz, color: Color(0xFF374151), size: 18),
      ),
    );
  }


  Widget _adminTable() {
    return Consumer<ServiceBranchController>(
      builder: (context, snapshot, _) {
        if (snapshot.serviceBranchResponse == null) {
          return const Center(child: CircularProgressIndicator(color: secondaryColor));
        }
        final items = snapshot.serviceBranchResponse?.data ?? [];
        if (items.isEmpty) {
          return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [NoRecordsWidget()]);
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                columns: _adminColumns(),
                rows: [
                  for (int i = 0; i < items.length; i++)
                    DataRow2(
                      color: WidgetStateProperty.all(i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC)),
                      cells: [
                        DataCell(_serviceNameCell(items[i].serviceName, items[i].serviceDescription)),
                        DataCell(_categoryChip(items[i].serviceCategory)),
                        DataCell(_timeBadge(items[i].serviceTime)),
                        DataCell(_priceCell(items[i].servicePrice, items[i].serviceBookingFee)),
                        DataCell(_doctorTypeChip(items[i].doctorType)),
                        DataCell(_statusChip(items[i].serviceBranchStatus == 1)),
                        DataCell(
                          Text(
                            dateConverter(items[i].createdDate) ?? '—',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          ),
                        ),
                        DataCell(_adminActions(items[i])),
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

  List<DataColumn2> _adminColumns() {
    return [
      _col('Service', ColumnSize.L),
      _col('Category', ColumnSize.S),
      _col('Time', ColumnSize.S, fixedWidth: 100),
      _col('Price', ColumnSize.S, fixedWidth: 120),
      _col('Type', ColumnSize.S, fixedWidth: 100),
      _col('Status', ColumnSize.S, fixedWidth: 90),
      _col('Created', ColumnSize.S, fixedWidth: 120),
      _col('Actions', ColumnSize.S, fixedWidth: 80),
    ];
  }

  Widget _adminActions(service_branch_model.Data serviceBranch) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 36),
      color: Colors.white,
      tooltip: '',
      onSelected: (value) => _handleAdminMenuSelection(value, serviceBranch),
      itemBuilder: (_) => [
        const PopupMenuItem<String>(value: 'update', child: Text('Update Timing')),
        PopupMenuItem<String>(
          value: 'enableDisable',
          child: Text(serviceBranch.serviceBranchStatus == 1 ? 'Deactivate' : 'Re-Activate'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(6)),
        child: const Icon(Icons.more_horiz, color: Color(0xFF374151), size: 18),
      ),
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

  Widget _serviceNameCell(String? name, String? description) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: secondaryColor.withAlpha(40), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.medical_services_outlined, size: 18, color: secondaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Tooltip(
                message: (description != null && description.isNotEmpty) ? description : null,
                child: Text(
                  name ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(String? category) {
    if (category == null || category.isEmpty) {
      return const Text('—', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13));
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
      child: Text(
        category,
        style: const TextStyle(fontSize: 11, color: Color(0xFF374151), fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _timeBadge(String? time) {
    if (time == null || time.isEmpty) {
      return const Text('—', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13));
    }
    return Row(
      children: [
        const Icon(Icons.schedule_outlined, size: 13, color: Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(time, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
      ],
    );
  }

  Widget _priceCell(String? price, String? bookingFee) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          price != null ? 'RM $price' : '—',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
        ),
        if (bookingFee != null && bookingFee.isNotEmpty)
          Text('Fee: RM $bookingFee', style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ],
    );
  }

  Widget _doctorTypeChip(int? type) {
    final label = doctorType(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(6)),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF4338CA), fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
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
                Text('Rows per page: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin == true;
    if (isSuperAdmin) {
      return Consumer<ServiceController>(
        builder: (context, snapshot, _) {
          final items = snapshot.servicesResponse?.data ?? [];
          return _mobileList(
            items
                .map<Widget>(
                  (s) => _mobileServiceCard(
                    name: s.serviceName,
                    category: s.serviceCategory,
                    time: s.serviceTime,
                    price: s.servicePrice,
                    isActive: s.serviceStatus == 1,
                    onTap: () => _handleMenuSelection('update', s),
                  ),
                )
                .toList(),
          );
        },
      );
    } else {
      return Consumer<ServiceBranchController>(
        builder: (context, snapshot, _) {
          final items = snapshot.serviceBranchResponse?.data ?? [];
          return _mobileList(
            items
                .map<Widget>(
                  (s) => _mobileServiceCard(
                    name: s.serviceName,
                    category: s.serviceCategory,
                    time: s.serviceTime,
                    price: s.servicePrice,
                    isActive: s.serviceBranchStatus == 1,
                    onTap: () => _handleAdminMenuSelection('update', s),
                  ),
                )
                .toList(),
          );
        },
      );
    }
  }

  Widget _mobileList(List<Widget> cards) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              _serviceNameController.text = val;
              filtering(page: 1);
            },
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: cards.isEmpty
              ? const Center(child: NoRecordsWidget())
              : ListView(padding: const EdgeInsets.symmetric(horizontal: 12), children: cards),
        ),
        _tableFooter(),
      ],
    );
  }

  Widget _mobileServiceCard({
    String? name,
    String? category,
    String? time,
    String? price,
    bool isActive = false,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                      color: secondaryColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medical_services_outlined, size: 18, color: secondaryColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name ?? '—', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  _statusChip(isActive),
                ],
              ),
              const SizedBox(height: 10),
              if (category != null) _mobileRow('Category', category),
              if (time != null) _mobileRow('Time', time),
              if (price != null) _mobileRow('Price', 'RM $price'),
            ],
          ),
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
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ),
          Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  void _handleMenuSelection(String value, Data service) async {
    if (value == 'update') {
      showDialog(
        context: context,
        builder: (_) => ServiceDetails(service: service, type: 'update'),
      );
    } else if (value == 'updateBranchesStatus') {
      ServiceBranchController.getAll(
        context,
        1,
        100,
        serviceId: service.serviceId ?? '',
        serviceBranchStatus: null,
      ).then((value) {
        if (responseCode(value.code)) {
          context.read<ServiceBranchController>().serviceBranchResponse = value.data;
          showDialog(
            context: context,
            builder: (_) => ServiceBranch(serviceBranch: value.data),
          );
        }
      });
    } else if (value == 'enableDisable') {
      try {
        if (await showConfirmDialog(
          context,
          service.serviceStatus == 1
              ? 'Are you certain you wish to deactivate this service for all branch? Please note, this action can be reversed at a later time.'
              : 'Are you certain you wish to activate this service for all branch? Please note, this action can be reversed at a later time.',
        )) {
          Future.delayed(Duration.zero, () {
            ServiceController.update(
              context,
              UpdateServiceRequest(
                serviceId: service.serviceId,
                serviceName: service.serviceName,
                serviceDescription: service.serviceDescription,
                servicePrice: service.servicePrice != null ? double.parse(service.servicePrice ?? '0') : null,
                serviceBookingFee: service.serviceBookingFee != null
                    ? double.parse(service.serviceBookingFee ?? '0')
                    : null,
                doctorType: service.doctorType,
                serviceTime: service.serviceTime,
                serviceCategory: service.serviceCategory,
                serviceStatus: service.serviceStatus == 1 ? 0 : 1,
              ),
            ).then((value) {
              if (responseCode(value.code)) {
                filtering();
                showDialogSuccess(
                  context,
                  'The service has been successfully ${service.serviceStatus == 1 ? 'deactivated' : 'activated'}.',
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
    }
  }

  void _handleAdminMenuSelection(String value, service_branch_model.Data serviceBranch) async {
    if (value == 'update') {
      showLoading();
      ServiceBranchAvailableDtController.get(context, 1, 100, serviceBranchId: serviceBranch.serviceBranchId).then((
        value,
      ) {
        dismissLoading();
        DateTime now = DateTime.now();
        String? updateId;
        bool haveElements = false;
        try {
          updateId = value.data?.data
              ?.firstWhere((e) => e.serviceBranchId == serviceBranch.serviceBranchId)
              .serviceBranchAvailableDatetimeId;
        } catch (e) {
          debugPrint(e.toString());
        }
        try {
          if ((value.data?.data?.first.availableDatetimes?.length ?? 0) > 0) {
            haveElements = true;
          }
        } catch (e) {
          debugPrint(e.toString());
        }
        showDialog(
          context: context,
          builder: (_) => Row(
            children: [
              Expanded(
                child: CardContainer(
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenPadding),
                        child: MultiTimeCalendarPage(
                          serviceBranchId: serviceBranch.serviceBranchId ?? '',
                          serviceTiming: serviceBranch.serviceTime ?? '',
                          serviceBranchAvailableDatetimeId: updateId,
                          startMonth: now.month,
                          year: now.year,
                          totalMonths: 3,
                          branchId: serviceBranch.branchId,
                          initialDateTimes: haveElements ? value.data?.data?.first.availableDatetimes : null,
                        ),
                      ),
                      const CloseButton(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      });
    } else if (value == 'enableDisable') {
      try {
        if (await showConfirmDialog(
          context,
          serviceBranch.serviceBranchStatus == 1
              ? 'Are you certain you wish to deactivate ${serviceBranch.serviceName} for ${serviceBranch.branchName}? Please note, this action can be reversed at a later time.'
              : 'Are you certain you wish to activate ${serviceBranch.serviceName} for ${serviceBranch.branchName}? Please note, this action can be reversed at a later time.',
        )) {
          Future.delayed(Duration.zero, () {
            ServiceBranchController.update(
              context,
              UpdateServiceBranchRequest(
                serviceBranchId: serviceBranch.serviceBranchId,
                serviceBranchAvailableTime: serviceBranch.serviceBranchAvailableTime,
                serviceBranchStatus: serviceBranch.serviceBranchStatus == 1 ? 0 : 1,
              ),
            ).then((value) {
              if (responseCode(value.code)) {
                showLoading();
                ServiceBranchController.getAll(
                  context,
                  1,
                  100,
                  branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
                ).then((value) {
                  dismissLoading();
                  context.read<ServiceBranchController>().serviceBranchResponse = value.data;
                  showDialogSuccess(
                    context,
                    '${serviceBranch.serviceName} has been successfully ${serviceBranch.serviceBranchStatus == 1 ? 'deactivated' : 'activated'} for ${serviceBranch.branchName}.',
                  );
                });
              } else {
                showDialogError(context, value.message ?? value.data?.message ?? '');
              }
            });
          });
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }


  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce ? _debouncer.run(() => runFiltering(page: page)) : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) _page = page;
    if (context.read<AuthController>().isSuperAdmin == false) {
      ServiceBranchController.getAll(
        context,
        _page,
        _pageSize,
        branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
      ).then((value) {
        dismissLoading();
        if (responseCode(value.code)) {
          context.read<ServiceBranchController>().serviceBranchResponse = value.data;
          _totalCount = value.data?.totalCount ?? 0;
          _totalPage = value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        }
      });
    } else {
      ServiceController.getAll(
        context,
        _page,
        _pageSize,
        serviceName: _serviceNameController.text,
        serviceStatus: _selectedServiceStatus != null
            ? _selectedServiceStatus?.key == '1'
                  ? 1
                  : _selectedServiceStatus?.key == '0'
                  ? 0
                  : null
            : null,
      ).then((value) {
        dismissLoading();
        if (responseCode(value.code)) {
          _totalCount = value.data?.totalCount ?? 0;
          _totalPage = value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
          context.read<ServiceController>().servicesResponse = value.data;
        }
      });
    }
  }

  void resetAllFilter() {
    _serviceNameController.text = '';
    _selectedServiceStatus = null;
    rebuildDropdown.add(DateTime.now());
  }
}
