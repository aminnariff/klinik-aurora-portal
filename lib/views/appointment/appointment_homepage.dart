import 'dart:async';
import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/appointment_dashboard_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_exception_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/service_branch/service_branch_response.dart' as service_branch_model;
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/appointment/date_range_dashboard.dart';
import 'package:klinik_aurora_portal/views/appointment/whatsapp_feature.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/selection_calendar_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:klinik_aurora_portal/views/widgets/table/table_header_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class AppointmentHomepage extends StatefulWidget {
  static const routeName = '/appointment';
  static const displayName = 'Appointments';
  final String? orderReference;
  const AppointmentHomepage({super.key, this.orderReference});

  @override
  State<AppointmentHomepage> createState() => _AppointmentHomepageState();
}

class _AppointmentHomepageState extends State<AppointmentHomepage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Upcoming', 'Completed', 'No-Show', 'Cancelled'];

  static const List<Color> _tabColors = [
    Color(0xFF2196F3), // Upcoming – blue
    Color(0xFF059669), // Completed – green
    Color(0xFFF59E0B), // No-Show – amber
    Color(0xFFEF4444), // Cancelled – red
  ];

  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  String? startDate;
  String? endDate;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _serviceNameController = TextEditingController();
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);
  final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  int _selectedTabIndex = 0;
  DropdownAttribute? _appointmentBranch;
  List<DropdownAttribute> branches = [];
  List<DropdownAttribute> serviceList = [];

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(
        AppointmentHomepage.displayName,
      );
      if (context.read<AuthController>().isSuperAdmin == false) {
        getService();
      }
      if (context.read<AuthController>().isSuperAdmin == true) {
        BranchController.getAll(context, 1, 100).then((value) {
          if (responseCode(value.code)) {
            context.read<BranchController>().branchAllResponse = value;
            for (branch_model.Data item in value.data?.data ?? []) {
              branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
            }
            branches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            rebuildDropdown.add(DateTime.now());
          }
        });
      }
      _defaultThisMonth();
      getDashboard();
      filtering();
    });
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _selectedTabIndex = _tabController.index);
      _page = 1;
      filtering(enableDebounce: false);
    });
    super.initState();
  }

  void getDashboard() {
    if (context.read<AuthController>().hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342') == false) {
      bool temp = true;
      if (context.read<AuthController>().isSuperAdmin == true && _appointmentBranch?.key != null) {
        temp = true;
      } else if (context.read<AuthController>().authenticationResponse?.data?.user?.branchId != null) {
        temp = true;
      }
      if (temp) {
        context.read<AppointmentDashboardController>().appointmentDashboardResponse = null;
        AppointmentDashboardController.get(
          context,
          branchId: context.read<AuthController>().isSuperAdmin == true
              ? _appointmentBranch?.key
              : context.read<AuthController>().branchId ??
                    context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
          startDate: startDate,
          endDate: endDate,
        ).then((value) {
          if (responseCode(value.code)) {
            context.read<AppointmentDashboardController>().appointmentDashboardResponse = value.data;
          }
        });
      }
    }
  }

  void getService() {
    if (serviceList.isEmpty) {
      ServiceBranchController.getAll(
        context,
        1,
        100,
        branchId: context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
      ).then((value) {
        if (responseCode(value.code)) {
          if (value.data != null) {
            for (service_branch_model.Data item in value.data?.data ?? []) {
              if (item.serviceBranchStatus == 1) {
                serviceList.add(DropdownAttribute(item.serviceBranchId ?? '', item.serviceName ?? ''));
              }
            }
          }
          serviceList.sort((a, b) => a.name.compareTo(b.name));
          context.read<ServiceBranchController>().serviceBranchResponse = value.data;
          rebuildDropdown.add(DateTime.now());
        }
      });
    }
  }

  void getServiceForBranch(String? branchId) {
    ServiceBranchController.getAll(context, 1, 100, branchId: branchId).then((value) {
      if (responseCode(value.code)) {
        if (value.data != null) {
          for (service_branch_model.Data item in value.data?.data ?? []) {
            if (item.serviceBranchStatus == 1) {
              serviceList.add(DropdownAttribute(item.serviceBranchId ?? '', item.serviceName ?? ''));
            }
          }
        }
        serviceList.sort((a, b) => a.name.compareTo(b.name));
        context.read<ServiceBranchController>().serviceBranchResponse = value.data;
        rebuildDropdown.add(DateTime.now());
      }
    });
  }

  DateRange _defaultThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    startDate = getDateOnly(startOfMonth.toString());
    endDate = getDateOnly(endOfMonth.toString());
    return DateRange(
      label: 'This month (${DateFormat('MMMM yyyy').format(now)})',
      shortLabel: 'This Month',
      start: startOfMonth,
      end: endOfMonth,
    );
  }

  String getDateOnly(String value) {
    final dt = DateTime.parse(value);
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  List<String>? getAppointmentStatus() {
    if (_tabs[_selectedTabIndex] == 'Upcoming') return ['1', '3', '4'];
    if (_tabs[_selectedTabIndex] == 'Completed') return ['5'];
    if (_tabs[_selectedTabIndex] == 'No-Show') return ['7'];
    if (_tabs[_selectedTabIndex] == 'Cancelled') return ['2', '6'];
    return null;
  }

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce ? _debouncer.run(() => runFiltering(page: page)) : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) _page = page;
    context.read<AppointmentController>().appointmentResponse = null;
    AppointmentController()
        .get(
          context,
          _page,
          _pageSize,
          status: getAppointmentStatus(),
          branchId: context.read<AuthController>().isSuperAdmin
              ? _appointmentBranch?.key
              : context.read<AuthController>().authenticationResponse?.data?.user?.isSuperadmin == true
              ? null
              : context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
          startDate: startDate,
          endDate: endDate,
        )
        .then((value) {
          dismissLoading();
          context.read<AppointmentController>().appointmentResponse = value;
          setState(() {
            _totalPage = value.data?.totalPage ?? 0;
            _totalCount = value.data?.totalCount ?? 0;
          });
        });
  }

  void _movePage(int page) => filtering(page: page, enableDebounce: false);

  void resetAllFilter() {
    _serviceNameController.text = '';
    _searchController.text = '';
    rebuildDropdown.add(DateTime.now());
  }

  List<String> removePastDates(List<String> dateList) {
    return dateList.where((dateStr) {
      try {
        return DateTime.parse(dateStr).isAfter(DateTime.now().toUtc());
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void _handleMenuSelection(String value, Data appointment) async {
    if (value == 'update') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AppointmentDetails(
            type: 'update',
            appointment: appointment,
            tabs: getAppointmentStatus(),
            refreshData: () {
              getDashboard();
              filtering();
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: _buildBody(), tablet: _buildBody(), desktop: _buildBody());
  }

  Widget _buildBody() {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F6FA),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (authController.isSuperAdmin) _buildBranchBar(),
              _buildDateFilterBar(),
              if (authController.hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342') == false)
                _buildStatsStrip(authController),
              _buildTabAndActions(),
              Expanded(child: _buildTableArea()),
              _buildPaginationBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBranchBar() {
    return StreamBuilder<DateTime>(
      stream: rebuildDropdown.stream,
      builder: (context, _) {
        return Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.location_city_rounded, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Text('Branch', style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280))),
              const SizedBox(width: 12),
              AppDropdown(
                attributeList: DropdownAttributeList(
                  branches,
                  isEditable: true,
                  value: _appointmentBranch?.name,
                  onChanged: (p0) {
                    _appointmentBranch = p0;
                    context.read<AppointmentDashboardController>().appointmentDashboardResponse = null;
                    serviceList = [];
                    if (p0 != null) getServiceForBranch(p0.key);
                    rebuildDropdown.add(DateTime.now());
                    getDashboard();
                    filtering();
                  },
                  width: screenWidthByBreakpoint(90, 70, 280, useAbsoluteValueDesktop: true),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateFilterBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(screenPadding, 10, screenPadding, 10),
      child: DateFilterDropdown(
        onSelected: (range) {
          startDate = range.start != null ? getDateOnly('${range.start}') : null;
          endDate = range.end != null ? getDateOnly('${range.end}') : null;
          getDashboard();
          filtering();
        },
      ),
    );
  }

  Widget _buildStatsStrip(AuthController authController) {
    return Consumer<AppointmentDashboardController>(
      builder: (context, dashController, _) {
        final dash = dashController.appointmentDashboardResponse?.data;

        final stats = [
          _StatConfig(
            label: 'Upcoming',
            value: dash?.totalUpcoming?.toString() ?? '–',
            color: const Color(0xFF2196F3),
            bg: const Color(0xFFE3F2FD),
            icon: Icons.pending_actions_rounded,
          ),
          _StatConfig(
            label: 'Completed',
            value: dash?.totalCompleted?.toString() ?? '–',
            color: const Color(0xFF059669),
            bg: const Color(0xFFD1FAE5),
            icon: Icons.check_circle_rounded,
          ),
          _StatConfig(
            label: 'No-Show',
            value: dash?.totalNoShow?.toString() ?? '–',
            color: const Color(0xFFF59E0B),
            bg: const Color(0xFFFEF3C7),
            icon: Icons.person_off_rounded,
          ),
          _StatConfig(
            label: 'Cancelled',
            value: dash?.totalCanceled?.toString() ?? '–',
            color: const Color(0xFFEF4444),
            bg: const Color(0xFFFEE2E2),
            icon: Icons.cancel_rounded,
          ),
          _StatConfig(
            label: 'Potential Sales',
            value: dash?.potentialSales != null ? currencyFormatter.format(dash!.potentialSales) : '–',
            color: const Color(0xFF7C3AED),
            bg: const Color(0xFFEDE9FE),
            icon: Icons.monetization_on_rounded,
          ),
        ];

        return Container(
          padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: stats.map((s) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(s.icon, color: s.color, size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            s.value,
                            style: AppTypography.bodyMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.bold, color: s.color),
                          ),
                          Text(
                            s.label,
                            style: AppTypography.bodyMedium(
                              context,
                            ).apply(fontSizeDelta: -3, color: s.color.withAlpha(180)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabAndActions() {
    return Consumer<AppointmentDashboardController>(
      builder: (context, dashController, _) {
        final dash = dashController.appointmentDashboardResponse?.data;
        final counts = [dash?.totalUpcoming, dash?.totalCompleted, dash?.totalNoShow, dash?.totalCanceled];

        return Container(
          padding: EdgeInsets.fromLTRB(screenPadding, 10, screenPadding, 10),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(_tabs.length, (i) {
                      final selected = _selectedTabIndex == i;
                      final color = _tabColors[i];
                      final count = counts[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _tabController.animateTo(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? color : const Color(0xFFE5E7EB)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _tabs[i],
                                  style: AppTypography.bodyMedium(context).copyWith(
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    color: selected ? Colors.white : const Color(0xFF6B7280),
                                  ),
                                ),
                                if (count != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: selected ? Colors.white.withAlpha(60) : color.withAlpha(25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: AppTypography.bodyMedium(
                                        context,
                                      ).copyWith(fontWeight: FontWeight.bold, color: selected ? Colors.white : color),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                color: const Color(0xFF2196F3),
                onTap: () {
                  resetAllFilter();
                  filtering(enableDebounce: false, page: 1);
                },
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.calendar_month_rounded,
                tooltip: 'Check Slots',
                color: const Color(0xFF059669),
                onTap: checkSlots,
              ),
              const SizedBox(width: 4),
              _ActionButton(
                icon: Icons.menu_book_rounded,
                tooltip: 'Guideline',
                color: const Color(0xFFDF6E98),
                onTap: () => showAppointmentGuidelineDialog(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableArea() {
    return TabBarView(
      controller: _tabController,
      children: [_buildTabContent(), _buildTabContent(), _buildTabContent(), _buildTabContent()],
    );
  }

  Widget _buildTabContent() {
    return Consumer2<AppointmentController, AuthController>(
      builder: (context, apptController, authController, _) {
        final data = apptController.appointmentResponse?.data?.data ?? [];
        final isLoading = apptController.appointmentResponse == null;

        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator(color: secondaryColor))
                      : data.isEmpty
                      ? _buildEmptyState()
                      : DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 16,
                          isHorizontalScrollBarVisible: true,
                          isVerticalScrollBarVisible: false,
                          columns: columns(),
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                          headingRowHeight: 44,
                          decoration: const BoxDecoration(),
                          border: TableBorder(
                            horizontalInside: BorderSide(width: 1, color: const Color(0xFFE5E7EB)),
                            top: BorderSide(width: 1, color: const Color(0xFFE5E7EB)),
                            bottom: BorderSide(width: 1, color: const Color(0xFFE5E7EB)),
                          ),
                          rows: [
                            for (int i = 0; i < data.length; i++) _buildDataRow(context, data[i], i, authController),
                          ],
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchToolbar() {
    return Container(
      color: const Color(0xFFF5F6FA),
      padding: EdgeInsets.fromLTRB(screenPadding, 10, screenPadding, 10),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => filtering(page: 1),
        style: AppTypography.bodyMedium(context),
        decoration: InputDecoration(
          hintText: 'Search by patient name…',
          hintStyle: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  onPressed: () {
                    _searchController.clear();
                    filtering(enableDebounce: false, page: 1);
                    setState(() {});
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: secondaryColor, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: _tabColors[_selectedTabIndex].withAlpha(25), shape: BoxShape.circle),
            child: Icon(Icons.event_busy_rounded, size: 30, color: _tabColors[_selectedTabIndex]),
          ),
          const SizedBox(height: 14),
          Text(
            'No ${_tabs[_selectedTabIndex].toLowerCase()} appointments',
            style: AppTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting the date range or filters',
            style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(BuildContext context, Data item, int index, AuthController authController) {
    return DataRow(
      color: WidgetStateProperty.all(index.isEven ? Colors.white : const Color(0xFFFAFAFA)),
      cells: [
        DataCell(
          Tooltip(
            message: 'Phone: ${item.user?.userPhone ?? 'N/A'}\nEmail: ${item.user?.userEmail ?? 'N/A'}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.user?.userFullName?.titleCase() ?? 'N/A',
                  style: AppTypography.bodyMedium(context).copyWith(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (item.user?.userPhone != null)
                  Text(
                    item.user!.userPhone!,
                    style: AppTypography.bodyMedium(context).apply(fontSizeDelta: -3, color: const Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          ),
        ),
        DataCell(
          Tooltip(
            message:
                '${item.service?.serviceDescription ?? 'N/A'}\n\nBooking Fee: RM ${item.service?.serviceBookingFee ?? 'N/A'}',
            child: Text(
              item.service?.serviceName ?? 'N/A',
              style: AppTypography.bodyMedium(context).copyWith(fontSize: 13),
            ),
          ),
        ),
        if (authController.isSuperAdmin)
          DataCell(
            AppSelectableText(
              item.branch?.branchName ?? 'N/A',
              style: AppTypography.bodyMedium(context).copyWith(fontSize: 13),
            ),
          ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(6)),
            child: Text(
              doctorType(item.service?.doctorType),
              style: AppTypography.bodyMedium(context).apply(fontSizeDelta: -1, color: const Color(0xFF374151)),
            ),
          ),
        ),
        DataCell(_buildStatusBadge(item.appointmentStatus)),
        DataCell(
          (item.service?.serviceBookingFee != null ||
                  (double.tryParse(item.service?.serviceBookingFee ?? '0') ?? 0) > 0)
              ? _buildPaymentBadge(
                  item.appointmentStatus == 5
                      ? 1
                      : (isBookingFeePaid(item.appointmentNote, payments: item.payment) ? 1 : 0),
                )
              : Text('–', style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF9CA3AF))),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: () {
              final raw = convertUtcToMalaysiaTime(item.appointmentDatetime);
              if (raw == null) return [const Text('N/A')];
              final parts = raw.split('\n');
              return [
                Text(parts[0], style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w500)),
                if (parts.length > 1)
                  Text(
                    parts[1],
                    style: AppTypography.bodyMedium(context).apply(fontSizeDelta: -3, color: const Color(0xFF9CA3AF)),
                  ),
              ];
            }(),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () async {
                  if (context.read<ServiceController>().servicesResponse == null) {
                    await ServiceController.getAll(context, 1, 100).then((value) {
                      context.read<ServiceController>().servicesResponse = value.data;
                    });
                  }
                  List<String>? templates = context
                      .read<ServiceController>()
                      .servicesResponse
                      ?.data
                      ?.firstWhere(
                        (element) => element.serviceId == item.service?.serviceId,
                        orElse: () => context.read<ServiceController>().servicesResponse!.data!.first,
                      )
                      .serviceTemplate;
                  showWhatsAppTemplateDialog(
                    context: context,
                    templates: templates ?? [],
                    name: item.user?.userFullName ?? '',
                    phone: item.user?.userPhone ?? '',
                    service: item.service?.serviceName ?? '',
                    branchName: item.branch?.branchName ?? '',
                    branchPhone: item.branch?.branchPhone ?? '',
                    dateTime: DateTime.parse(item.appointmentDatetime ?? ''),
                  );
                },
                icon: const Icon(FontAwesomeIcons.whatsapp, size: 24),
                color: const Color(0xFF25D366),
                tooltip: 'WhatsApp',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                offset: const Offset(0, 32),
                color: Colors.white,
                tooltip: '',
                onSelected: (value) => _handleMenuSelection(value, item),
                itemBuilder: (_) => [
                  PopupMenuItem<String>(
                    value: 'update',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF374151)),
                        const SizedBox(width: 8),
                        Text('Update', style: AppTypography.bodyMedium(context)),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                  child: const Icon(Icons.more_horiz, color: Color(0xFF374151), size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(int? status) {
    final color = appointmentStatusColors[status] ?? Colors.grey;
    final label = getAppointmentStatusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: AppTypography.bodyMedium(context).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildPaymentBadge(int status) {
    switch (status) {
      case 1:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF059669)),
              const SizedBox(width: 4),
              Text(
                'Paid',
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF065F46)),
              ),
            ],
          ),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text(
                'Failed',
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B)),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty_rounded, size: 18, color: Color(0xFFD97706)),
              const SizedBox(width: 4),
              Text(
                'Unpaid',
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF92400E)),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPaginationBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Pagination(
              numOfPages: _totalPage,
              selectedPage: _page,
              pagesVisible: 5,
              spacing: 8,
              onPageChanged: _movePage,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile)
                Text('Rows: ', style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280))),
              PerPageWidget(
                _pageSize.toString(),
                DropdownAttributeList(
                  [],
                  onChanged: (selected) {
                    _pageSize = int.parse(selected!.key);
                    filtering(enableDebounce: false);
                  },
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                Text(
                  '${((_page) * _pageSize) - _pageSize + 1}–${(_page * _pageSize < _totalCount) ? _page * _pageSize : _totalCount} of $_totalCount',
                  style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<DataColumn2> columns() {
    List<TableHeaderAttribute> headers = [
      TableHeaderAttribute(attribute: 'userFullName', label: 'Patient', allowSorting: false, columnSize: ColumnSize.L),
      TableHeaderAttribute(attribute: 'serviceName', label: 'Service', allowSorting: false, columnSize: ColumnSize.M),
      if (context.read<AuthController>().isSuperAdmin)
        TableHeaderAttribute(attribute: 'branchName', label: 'Branch', allowSorting: false, columnSize: ColumnSize.S),
      TableHeaderAttribute(attribute: 'doctorType', label: 'Type', allowSorting: false, columnSize: ColumnSize.S),
      TableHeaderAttribute(
        attribute: 'appointmentStatus',
        label: 'Status',
        allowSorting: false,
        columnSize: ColumnSize.S,
      ),
      TableHeaderAttribute(attribute: 'paymentStatus', label: 'Payment', allowSorting: false, columnSize: ColumnSize.S),
      TableHeaderAttribute(
        attribute: 'appointmentDatetime',
        label: 'Date & Time',
        allowSorting: false,
        columnSize: ColumnSize.S,
      ),
      TableHeaderAttribute(
        attribute: 'actions',
        label: 'Actions',
        allowSorting: false,
        columnSize: ColumnSize.S,
        width: 90,
      ),
    ];
    return [
      for (TableHeaderAttribute item in headers)
        DataColumn2(
          fixedWidth: item.width,
          label: Text(
            item.label,
            style: AppTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
          ),
          size: item.columnSize ?? ColumnSize.M,
        ),
    ];
  }

  Widget sortingIcon(TableHeaderAttribute header) {
    Widget child = Icon(
      header.isSort ? Icons.sort : Icons.menu,
      color: header.isSort ? (header.sort == SortType.asc ? Colors.green : Colors.red) : Colors.grey,
    );
    return header.isSort
        ? header.sort == SortType.desc
              ? Transform.rotate(angle: -math.pi, child: child)
              : child
        : child;
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

  void checkSlots() {
    final authController = context.read<AuthController>();
    if (authController.isSuperAdmin && _appointmentBranch == null) {
      showDialogError(context, 'Please select a branch first.');
      return;
    }
    final branchLabel = authController.isSuperAdmin
        ? (_appointmentBranch?.name ?? '')
        : (authController.authenticationResponse?.data?.user?.userFullname ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 500,
            height: screenHeight(80),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: Color(0xFF059669), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check Available Slots', style: AppTypography.bodyLarge(context)),
                            Text(
                              'Branch: $branchLabel',
                              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(foregroundColor: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${serviceList.length} service(s) available',
                        style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: serviceList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, i) {
                      final item = serviceList[i];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.medical_services_rounded, size: 16, color: Color(0xFF0284C7)),
                        ),
                        title: Text(item.name, style: AppTypography.bodyMedium(context)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
                        onTap: () async {
                          showLoading();
                          DateTime now = DateTime.now();
                          List<String> availableDateTime = [];
                          List<String> tempExceptionDateTime = [];
                          ServiceBranchAvailableDtController.get(
                            context,
                            1,
                            200,
                            branchId: authController.isSuperAdmin
                                ? _appointmentBranch?.key
                                : authController.authenticationResponse?.data?.user?.branchId,
                            serviceBranchId: item.key,
                          ).then((value) {
                            if (responseCode(value.code)) {
                              context.read<ServiceBranchAvailableDtController>().serviceBranchAvailableDtResponse =
                                  value.data;
                              availableDateTime = value.data?.data?.isNotEmpty == true
                                  ? (value.data?.data?.first.availableDatetimes ?? [])
                                  : [];
                              ServiceBranchExceptionController.get(context, 1, 999, serviceBranchId: item.key).then((
                                value,
                              ) async {
                                dismissLoading();
                                if (responseCode(value.code)) {
                                  context.read<ServiceBranchExceptionController>().serviceBranchExceptionResponse =
                                      value.data;
                                  value.data?.data?.forEach((element) {
                                    tempExceptionDateTime.add(element.exceptionDatetime ?? '');
                                  });
                                  final result = availableDateTime
                                      .toSet()
                                      .difference(tempExceptionDateTime.toSet())
                                      .toList();
                                  availableDateTime = removePastDates(result);
                                  availableDateTime.sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

                                  if (availableDateTime.isEmpty) {
                                    showDialogError(context, 'No available slots for this service.');
                                    return;
                                  }

                                  showDialog(
                                    context: context,
                                    builder: (_) => Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              constraints: BoxConstraints(maxWidth: screenWidth(80)),
                                              child: CardContainer(
                                                Container(
                                                  constraints: const BoxConstraints(maxWidth: 600),
                                                  padding: EdgeInsets.all(screenPadding),
                                                  child: SelectionCalendarView(
                                                    startMonth: now.month,
                                                    year: now.year,
                                                    initialDateTimes: availableDateTime,
                                                    readOnly: true,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              });
                            } else {
                              dismissLoading();
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void showAppointmentGuidelineDialog(BuildContext context) {
    final sections = [
      _GuidelineSection(
        icon: Icons.refresh_rounded,
        iconColor: const Color(0xFF059669),
        title: 'Get Latest Appointment List',
        body: 'Click "Refresh" in the top-right or use the date filter to reload the latest appointments.',
      ),
      _GuidelineSection(
        icon: Icons.swap_horiz_rounded,
        iconColor: const Color(0xFF2196F3),
        title: 'Rescheduling Appointments',
        body:
            'Branch staff can reschedule same-day appointments.\nPatients can only reschedule via the app if more than 24 hours remain.\n\nExample:\n• Now 1:00 PM, appointment tomorrow 2:00 PM → ✅ Patient can reschedule.\n• Now 1:00 PM, appointment today 1:00 PM → ❌ Staff must handle.',
      ),
      _GuidelineSection(
        icon: Icons.bedtime_rounded,
        iconColor: const Color(0xFFF59E0B),
        title: 'No-Show Auto-Update',
        body:
            'The system automatically marks un-updated appointments as "No-Show" at 12:00 AM daily. Update statuses promptly.',
      ),
      _GuidelineSection(
        icon: Icons.compare_arrows_rounded,
        iconColor: const Color(0xFF7C3AED),
        title: 'Changing Appointment Service',
        body: '1. Process a refund.\n2. Create a new appointment with the desired service.',
      ),
      _GuidelineSection(
        icon: Icons.person_add_rounded,
        iconColor: const Color(0xFF0891B2),
        title: 'Patients Without Accounts',
        body:
            'Create an internal user account (do not inform the patient). Make the appointment from the Users tab. Upload proof of payment if booking fee applies.',
      ),
      _GuidelineSection(
        icon: Icons.attach_money_rounded,
        iconColor: const Color(0xFFEF4444),
        title: 'Cancellation vs Refund',
        body:
            'Mark as "Cancelled" only if the service has no booking fee.\nIf payment was made, use "Refunded" instead.',
      ),
      _GuidelineSection(
        icon: FontAwesomeIcons.whatsapp,
        iconColor: const Color(0xFF25D366),
        title: 'Contacting Patients via WhatsApp',
        body: 'Click the WhatsApp icon beside an appointment to send reminders, follow-ups, or assist with changes.',
      ),
    ];

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: 40),
        child: SizedBox(
          width: 640,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                decoration: const BoxDecoration(
                  color: Color(0xFFDF6E98),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book_rounded, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Appointment Guidelines',
                        style: AppTypography.bodyLarge(context).apply(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(children: sections.map((s) => _buildGuidelineItem(context, s)).toList()),
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📋 Daily Checklist',
                      style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    for (final item in [
                      'Refresh to load latest data',
                      'Update appointment status post-session',
                      'Reschedule only under proper conditions',
                      'Process refund before creating new if changing service',
                      'Collect & upload proof of booking fee',
                      'Use WhatsApp for reminders',
                      'Use "Refunded" (not Cancelled) if payment was involved',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_box_outline_blank_rounded, size: 16, color: Color(0xFF059669)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item, style: AppTypography.bodyMedium(context))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineItem(BuildContext context, _GuidelineSection section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(color: section.iconColor.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(section.icon, color: section.iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(section.title, style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(section.body, style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatConfig {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;
  const _StatConfig({
    required this.label,
    required this.value,
    required this.color,
    required this.bg,
    required this.icon,
  });
}

class _GuidelineSection {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  const _GuidelineSection({required this.icon, required this.iconColor, required this.title, required this.body});
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.tooltip, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
