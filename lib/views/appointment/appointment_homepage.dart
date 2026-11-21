import '../widgets/motion/aurora_table_hover.dart';
import '../../config/app_colors.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
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
import 'package:klinik_aurora_portal/views/appointment/appointment_calendar_view.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_checkout_dialog.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/appointment/date_range_dashboard.dart';
import 'package:klinik_aurora_portal/views/appointment/payment_mismatch_view.dart';
import 'package:klinik_aurora_portal/views/appointment/transfer_appointment_dialog.dart';
import 'package:klinik_aurora_portal/views/appointment/whatsapp_feature.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/break_ui/break_ui_harness.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/selection_calendar_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/global/status.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/patient/patient_quick_drawer.dart';
import 'package:klinik_aurora_portal/views/widgets/shimmer/table_skeleton.dart';
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
  BreakUiMode _breakUiMode = BreakUiMode.live;
  int _totalCount = 0;
  String? startDate;
  String? endDate;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  final TextEditingController _customerNricController = TextEditingController();
  final TextEditingController _appointmentIdController = TextEditingController();
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);
  final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  int _selectedTabIndex = 0;
  bool _isCalendarView = false;
  Map<String, int> _appointmentCounts = {};
  List<Data> _selectedDayAppointments = [];
  bool _isLoadingDay = false;
  DropdownAttribute? _appointmentBranch;
  DropdownAttribute? _appointmentService;
  DropdownAttribute? _appointmentDoctorType;
  static final List<DropdownAttribute> doctorTypeList = [
    DropdownAttribute('1', doctorType(1)),
    DropdownAttribute('2', doctorType(2)),
    DropdownAttribute('3', doctorType(3)),
    DropdownAttribute('4', doctorType(4)),
    DropdownAttribute('5', doctorType(5)),
  ];
  List<DropdownAttribute> branches = [];
  bool _branchesLoaded = false;
  List<DropdownAttribute> serviceList = [];
  String? _sortBy;
  String? _sortOrder;
  DateRange? _currentDateRange;

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
          if (responseCode(value.code) && mounted && !_branchesLoaded) {
            context.read<BranchController>().branchAllResponse = value;
            for (branch_model.Data item in value.data?.data ?? []) {
              branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
            }
            branches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            if (mounted) setState(() => _branchesLoaded = true);
          }
        });
      }
      final savedView = prefs.getBool('calendarView');
      if (savedView == true && mounted) {
        setState(() {
          _isCalendarView = true;
        });
        _initCalendarView();
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
    _currentDateRange = DateRange(
      label: 'This month (${DateFormat('MMMM yyyy').format(now)})',
      shortLabel: 'This Month',
      start: startOfMonth,
      end: endOfMonth,
    );
    return _currentDateRange!;
  }

  String getDateOnly(String value) {
    final dt = DateTime.parse(value);
    return DateFormat('yyyy-MM-dd').format(dt);
  }

  String? _selectedServiceBranchId() {
    if (_appointmentService == null || _appointmentService!.key.isEmpty) return null;
    return _appointmentService!.key;
  }

  List<String>? getAppointmentStatus() {
    if (_tabs[_selectedTabIndex] == 'Upcoming') return ['1', '3', '4'];
    if (_tabs[_selectedTabIndex] == 'Completed') return ['5'];
    if (_tabs[_selectedTabIndex] == 'No-Show') return ['7'];
    if (_tabs[_selectedTabIndex] == 'Cancelled') return ['2', '6', '8'];
    return null;
  }

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce ? _debouncer.run(() => runFiltering(page: page)) : runFiltering(page: page);
  }

  int _filterRequest = 0;
  bool _filterLoading = true;

  void runFiltering({bool enableDebounce = true, int? page}) {
    if (!mounted) return;
    final request = ++_filterRequest;
    if (!_filterLoading) setState(() => _filterLoading = true);
    if (page != null) _page = page;
    final searchText = _searchController.text.trim();
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
          serviceBranchId: _selectedServiceBranchId(),
          // When searching, ignore the date range so results aren't hidden by it
          startDate: searchText.isEmpty ? startDate : null,
          endDate: searchText.isEmpty ? endDate : null,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          search: searchText.isEmpty ? null : searchText,
          customerName: _customerNameController.text.trim().isEmpty ? null : _customerNameController.text.trim(),
          customerPhone: _customerPhoneController.text.trim().isEmpty ? null : _customerPhoneController.text.trim(),
          customerNric: _customerNricController.text.trim().isEmpty ? null : _customerNricController.text.trim(),
          appointmentId: _appointmentIdController.text.trim().isEmpty ? null : _appointmentIdController.text.trim(),
          doctorType: _appointmentDoctorType?.key,
        )
        .then((value) {
          if (!mounted || request != _filterRequest) return;
          setState(() => _filterLoading = false);
          context.read<AppointmentController>().appointmentResponse = value;
          setState(() {
            _totalPage = value.data?.totalPage ?? 0;
            _totalCount = value.data?.totalCount ?? 0;
          });
        }).catchError((e) {
          if (!mounted || request != _filterRequest) return;
          setState(() => _filterLoading = false);
        });
  }

  void _movePage(int page) => filtering(page: page, enableDebounce: false);

  void _toggleDateSort() {
    setState(() {
      if (_sortBy != 'appointmentDatetime') {
        _sortBy = 'appointmentDatetime';
        _sortOrder = 'desc';
      } else {
        _sortOrder = _sortOrder == 'asc' ? 'desc' : 'asc';
      }
      _page = 1;
    });
    filtering(enableDebounce: false, page: 1);
  }

  void resetAllFilter() {
    _serviceNameController.text = '';
    _searchController.text = '';
    _customerNameController.text = '';
    _customerPhoneController.text = '';
    _customerNricController.text = '';
    _appointmentIdController.text = '';
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
    if (value == 'book_next') {
      showDialog(
        context: context,
        builder: (_) => AppointmentDetails(
          type: 'create',
          initialUserId: appointment.user?.userId,
          initialUserName: appointment.user?.userFullName,
          initialUserPhone: appointment.user?.userPhone,
          initialUserEmail: appointment.user?.userEmail,
          initialBranchId: appointment.branch?.branchId,
          initialNote: 'Follow-up booking after completing ${appointment.service?.serviceName ?? 'consultation'}',
          refreshData: () {
            getDashboard();
            filtering();
          },
        ),
      );
      return;
    }
    if (value == 'checkout') {
      final appointmentId = appointment.appointmentId;
      if (appointmentId == null) return;
      AppointmentCheckoutDialog.show(
        context,
        appointmentId: appointmentId,
        onCompleted: () {
          getDashboard();
          filtering();
        },
      );
      return;
    }
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
    } else if (value == 'transfer') {
      final appointmentId = appointment.appointmentId;
      if (appointmentId == null) return;
      showLoading();
      AppointmentController.detail(context, appointmentId: appointmentId).then((detailRes) {
        dismissLoading();
        if (responseCode(detailRes.code) && detailRes.data != null) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return TransferAppointmentDialog(
                appointment: detailRes.data,
                onTransferSuccess: () {
                  getDashboard();
                  filtering();
                  if (_isCalendarView && mounted) {
                    _refreshCalendarCounts();
                  }
                },
              );
            },
          );
        } else {
          if (mounted) {
            showDialogError(context, detailRes.message ?? 'Failed to load appointment details');
          }
        }
      }).catchError((e) {
        dismissLoading();
        if (mounted) {
          showDialogError(context, e.toString());
        }
      });
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
          backgroundColor: appCanvas,
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildControlBar(authController),
                  _buildTabAndActions(),
                  Expanded(child: _isCalendarView ? _buildCalendarArea() : _buildTableArea()),
                  if (!_isCalendarView) _buildPaginationBar(),
                ],
              ),
              BreakUiDevHarness(currentMode: _breakUiMode, onModeChanged: (m) => setState(() => _breakUiMode = m)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlBar(AuthController authController) {
    if (authController.isSuperAdmin && !_branchesLoaded && branches.isEmpty && mounted) {
      BranchController.getAll(context, 1, 100).then((value) {
        if (responseCode(value.code) && mounted && !_branchesLoaded) {
          context.read<BranchController>().branchAllResponse = value;
          for (branch_model.Data item in value.data?.data ?? []) {
            branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
          }
          branches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          setState(() => _branchesLoaded = true);
        }
      });
    }

    return Container(
      color: appSurface,
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 8),
      child: Row(
        children: [
          if (authController.isSuperAdmin) ...[
            Text(
              'Branch',
              style: AppTypography.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w600, color: const Color(0xFF4B5563)),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: isMobile ? 150 : 220,
              child: !_branchesLoaded && branches.isEmpty
                  ? Center(
                      child: Text('Loading...', style: TextStyle(fontSize: 12, color: appInkMuted)),
                    )
                  : AppDropdown(
                      attributeList: DropdownAttributeList(
                        branches,
                        prefixIcon: Icon(Icons.store_rounded, size: 16, color: appInkMuted),
                        isEditable: true,
                        value: _appointmentBranch?.name,
                        onChanged: (p0) {
                          setState(() {
                            _appointmentBranch = p0;
                            _appointmentService = null;
                          });
                          context.read<AppointmentDashboardController>().appointmentDashboardResponse = null;
                          serviceList = [];
                          if (p0 != null) getServiceForBranch(p0.key);
                          getDashboard();
                          filtering();
                          if (_isCalendarView && mounted) {
                            _refreshCalendarCounts();
                          }
                        },
                        width: isMobile ? 150 : 220,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Container(height: 20, width: 1, color: appBorder),
            const SizedBox(width: 12),
          ],
          if (!_isCalendarView && !isMobile) ...[
            Expanded(
              child: DateFilterDropdown(
                key: ValueKey('bar-${_currentDateRange?.label}'),
                initial: _currentDateRange,
                onSelected: _onDateRangeSelected,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (isMobile) const Spacer(),
          OutlinedButton.icon(
            onPressed: _showFilterPanel,
            icon: const Icon(Icons.tune_rounded, size: 15),
            label: Text(
              _hasActiveFilters() ? 'Filter •' : 'Filter',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _hasActiveFilters() ? primary : appInkSecondary,
              side: BorderSide(color: _hasActiveFilters() ? primary : appBorderStrong),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 14, vertical: isMobile ? 8 : 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.rotate_left_rounded, size: 16),
            color: appInkMuted,
            tooltip: 'Reset filters',
            style: IconButton.styleFrom(
              backgroundColor: appSurfaceSubtle,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _appointmentService != null ||
        _appointmentDoctorType != null ||
        _customerNameController.text.trim().isNotEmpty ||
        _customerPhoneController.text.trim().isNotEmpty ||
        _customerNricController.text.trim().isNotEmpty ||
        _appointmentIdController.text.trim().isNotEmpty;
  }

  void _onDateRangeSelected(DateRange range) {
    _currentDateRange = range;
    startDate = range.start != null ? getDateOnly('${range.start}') : null;
    endDate = range.end != null ? getDateOnly('${range.end}') : null;
    setState(() {});
    getDashboard();
    filtering();
  }

  String _dateRangeSummary() {
    final range = _currentDateRange;
    if (range == null || range.start == null || range.end == null) return 'All dates';
    final df = DateFormat('dd MMM yyyy');
    final start = df.format(range.start!);
    final end = df.format(range.end!);
    return start == end ? start : '$start – $end';
  }

  void _resetFilters() {
    resetAllFilter();
    _appointmentService = null;
    _appointmentDoctorType = null;
    _defaultThisMonth();
    setState(() {});
    getDashboard();
    filtering(enableDebounce: false, page: 1);
    if (_isCalendarView && mounted) {
      _refreshCalendarCounts();
    }
  }

  void _showFilterPanel() {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              color: appSurface,
              elevation: 8,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: math.min(320, MediaQuery.of(context).size.width * 0.92),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter Appointments',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: primary.withAlpha(18),
                                border: Border.all(color: primary.withAlpha(90)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.event_rounded, size: 15, color: primary),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _currentDateRange?.shortLabel ?? 'All Time',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 21),
                                    child: Text(
                                      _dateRangeSummary(),
                                      style: TextStyle(fontSize: 12, color: appInkMuted),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  DateFilterDropdown(
                                    key: ValueKey('panel-${_currentDateRange?.label}'),
                                    initial: _currentDateRange,
                                    onSelected: (range) {
                                      _onDateRangeSelected(range);
                                      setDialogState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _filterField(_appointmentIdController, 'Appointment ID'),
                            const SizedBox(height: 12),
                            _filterField(_customerNameController, 'Patient Name'),
                            const SizedBox(height: 12),
                            _filterField(_customerPhoneController, 'Mobile Number'),
                            const SizedBox(height: 12),
                            _filterField(_customerNricController, 'IC Number (NRIC/Passport)'),
                            const SizedBox(height: 16),
                            Text(
                              'Service',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: appInkMuted),
                            ),
                            const SizedBox(height: 8),
                            _buildServiceFilter(),
                            const SizedBox(height: 16),
                            Text(
                              'Practitioner Type',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: appInkMuted),
                            ),
                            const SizedBox(height: 8),
                            _buildDoctorTypeFilter(),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  setState(() {});
                                  filtering(enableDebounce: false, page: 1);
                                  if (_isCalendarView && mounted) {
                                    _refreshCalendarCounts();
                                  }
                                },
                                icon: const Icon(Icons.search_rounded, size: 16),
                                label: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  _resetFilters();
                                  Navigator.of(context).pop();
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: appBorderStrong),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text('Clear Filters'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(top: 8, right: 8, child: CloseButton()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _buildServiceFilter() {
    return StreamBuilder<DateTime>(
      stream: rebuildDropdown.stream,
      builder: (context, snapshot) {
        return AppDropdown(
          attributeList: DropdownAttributeList(
            [DropdownAttribute('', 'All Services'), ...serviceList],
            prefixIcon: Icon(Icons.medical_services_outlined, size: 18, color: appInkMuted),
            isEditable: true,
            hintText: 'All Services',
            value: _appointmentService?.name,
            onChanged: (p0) {
              // Applied on "Apply Filters" — no query fired here
              setState(() {
                _appointmentService = (p0 == null || p0.key.isEmpty) ? null : p0;
              });
              rebuildDropdown.add(DateTime.now());
            },
          ),
        );
      },
    );
  }

  Widget _buildDoctorTypeFilter() {
    return StreamBuilder<DateTime>(
      stream: rebuildDropdown.stream,
      builder: (context, snapshot) {
        return AppDropdown(
          attributeList: DropdownAttributeList(
            [DropdownAttribute('', 'All Practitioner Types'), ...doctorTypeList],
            prefixIcon: Icon(Icons.badge_outlined, size: 18, color: appInkMuted),
            isEditable: true,
            hintText: 'All Practitioner Types',
            value: _appointmentDoctorType?.name,
            onChanged: (p0) {
              // Applied on "Apply Filters" — no query fired here
              setState(() {
                _appointmentDoctorType = (p0 == null || p0.key.isEmpty) ? null : p0;
              });
              rebuildDropdown.add(DateTime.now());
            },
          ),
        );
      },
    );
  }

  Widget _filterField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      onSubmitted: (_) {
        Navigator.of(context).pop();
        setState(() {});
        filtering(enableDebounce: false, page: 1);
      },
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: appCanvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: appBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: appBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
    );
  }


  Widget _buildTabAndActions() {
    return Consumer<AppointmentDashboardController>(
      builder: (context, dashController, _) {
        final dash = dashController.appointmentDashboardResponse?.data;
        final counts = [dash?.totalUpcoming, dash?.totalCompleted, dash?.totalNoShow, dash?.totalCanceled];

        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              icon: _isCalendarView ? Icons.table_chart_rounded : Icons.calendar_month_rounded,
              tooltip: _isCalendarView ? 'Table View' : 'Calendar View',
              color: const Color(0xFF7C3AED),
              onTap: () {
                final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
                if (!_isCalendarView && isSuperAdmin && _appointmentBranch == null) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      title: const Text('Select Branch', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      content: Text(
                        'Please select a branch from the dropdown above before switching to Calendar view.',
                        style: TextStyle(fontSize: 13, color: appInkMuted),
                      ),
                      actions: [TextButton(onPressed: () => context.pop(), child: const Text('OK'))],
                    ),
                  );
                  return;
                }
                setState(() {
                  final enteringCalendar = !_isCalendarView;
                  _isCalendarView = !_isCalendarView;
                  prefs.setBool('calendarView', _isCalendarView);
                  if (enteringCalendar && _appointmentCounts.isEmpty) {
                    _initCalendarView();
                  }
                });
              },
            ),
            const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.menu_book_rounded,
              tooltip: 'Guideline',
              color: primary,
              onTap: () => showAppointmentGuidelineDialog(context),
            ),
            const SizedBox(width: 4),
            _ActionButton(
              icon: Icons.warning_amber_rounded,
              tooltip: 'Payment Issues (paid but not in schedule)',
              color: const Color(0xFFEF4444),
              onTap: () => context.pushNamed(PaymentMismatchPage.routeName),
            ),
          ],
        );

        if (isMobile) {
          return Container(
            padding: EdgeInsets.fromLTRB(screenPadding, 6, screenPadding, 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Row(
                    children: List.generate(_tabs.length, (i) {
                      final selected = _selectedTabIndex == i;
                      final color = _tabColors[i];
                      final count = counts[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: '${_tabs[i]} appointments tab',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _tabController.animateTo(i),
                            child: AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? color : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? color : appBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _tabs[i],
                                    style: AppTypography.bodyMedium(context).copyWith(
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                      color: selected ? Colors.white : appInkMuted,
                                    ),
                                  ),
                                  if (count != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: selected ? Colors.white.withAlpha(60) : color.withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
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
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 6),
                  Container(height: 20, width: 1, color: appBorder),
                  const SizedBox(width: 8),
                  actionButtons,
                ],
              ),
            ),
          );
        }

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
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: '${_tabs[i]} appointments tab',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => _tabController.animateTo(i),
                            child: AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? color : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: selected ? color : appBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _tabs[i],
                                    style: AppTypography.bodyMedium(context).copyWith(
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                      color: selected ? Colors.white : appInkMuted,
                                    ),
                                  ),
                                  if (count != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: selected ? Colors.white.withAlpha(60) : color.withAlpha(25),
                                        borderRadius: BorderRadius.circular(8),
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
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              actionButtons,
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

  Widget _buildCalendarArea() {
    return AppointmentCalendarView(
      appointmentCounts: _appointmentCounts,
      dayAppointments: _selectedDayAppointments,
      isLoadingDay: _isLoadingDay,
      onMonthChanged: (first, last) {
        final branchId = context.read<AuthController>().isSuperAdmin ? _appointmentBranch?.key : null;
        final start = DateFormat('yyyy-MM-dd').format(first);
        final end = DateFormat('yyyy-MM-dd').format(last);
        AppointmentController.getCounts(
          context,
          startDate: start,
          endDate: end,
          branchId: branchId,
          serviceBranchId: _selectedServiceBranchId(),
          doctorType: _appointmentDoctorType?.key,
        ).then((counts) {
          if (mounted) setState(() => _appointmentCounts = counts);
        });
        // Also fetch today's appointments for the new month
        _fetchDayAppointments(DateTime.now());
      },
      onDaySelected: (day) => _fetchDayAppointments(day),
      onRefresh: () {
        getDashboard();
        filtering();
      },
    );
  }

  void _fetchDayAppointments(DateTime day) {
    if (!mounted) return;
    setState(() => _isLoadingDay = true);
    final branchId = context.read<AuthController>().isSuperAdmin ? _appointmentBranch?.key : null;
    final dateStr = DateFormat('yyyy-MM-dd').format(day);

    AppointmentController()
        .get(
          context,
          1,
          100,
          startDate: dateStr,
          endDate: dateStr,
          branchId: branchId,
          serviceBranchId: _selectedServiceBranchId(),
          doctorType: _appointmentDoctorType?.key,
        )
        .then((value) {
          if (!mounted) return;
          setState(() {
            _selectedDayAppointments = value.data?.data ?? [];
            _isLoadingDay = false;
          });
        })
        .catchError((_) {
          if (!mounted) return;
          setState(() {
            _selectedDayAppointments = [];
            _isLoadingDay = false;
          });
        });
  }

  /// Called when calendar mode is first entered.
  void _initCalendarView() {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final last = DateTime(now.year, now.month + 1, 0);
    final branchId = context.read<AuthController>().isSuperAdmin ? _appointmentBranch?.key : null;

    AppointmentController.getCounts(
      context,
      startDate: DateFormat('yyyy-MM-dd').format(first),
      endDate: DateFormat('yyyy-MM-dd').format(last),
      branchId: branchId,
      serviceBranchId: _selectedServiceBranchId(),
    ).then((counts) {
      if (mounted) setState(() => _appointmentCounts = counts);
    });

    _fetchDayAppointments(now);
  }

  /// Re-fetches calendar counts and day appointments for the currently visible month.
  void _refreshCalendarCounts() {
    // We don't have direct access to the calendar's focusedDay here,
    // so use the current month based on today.
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    final last = DateTime(now.year, now.month + 1, 0);
    final branchId = context.read<AuthController>().isSuperAdmin ? _appointmentBranch?.key : null;

    AppointmentController.getCounts(
      context,
      startDate: DateFormat('yyyy-MM-dd').format(first),
      endDate: DateFormat('yyyy-MM-dd').format(last),
      branchId: branchId,
      serviceBranchId: _selectedServiceBranchId(),
    ).then((counts) {
      if (mounted) setState(() => _appointmentCounts = counts);
    });

    _fetchDayAppointments(DateTime.now());
  }

  Widget _buildTabContent() {
    return Consumer2<AppointmentController, AuthController>(
      builder: (context, apptController, authController, _) {
        final List<Data> data;
        switch (_breakUiMode) {
          case BreakUiMode.worstCase:
            data = BreakUiDataFactory.getWorstCaseAppointments();
            break;
          case BreakUiMode.empty:
            data = BreakUiDataFactory.getEmptyAppointments();
            break;
          case BreakUiMode.single:
            data = BreakUiDataFactory.getSingleAppointment();
            break;
          case BreakUiMode.live:
            data = apptController.appointmentResponse?.data?.data ?? [];
            break;
        }
        final isLoading = _breakUiMode == BreakUiMode.live && _filterLoading && apptController.appointmentResponse == null;

        return Column(
          children: [
            if (_filterLoading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isMobile ? Colors.transparent : appSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: isMobile ? null : Border.all(color: appBorder),
                  ),
                  child: isLoading
                      ? const AppTableSkeleton(rows: 8)
                      : data.isEmpty
                      ? _buildEmptyState()
                      : isMobile
                      ? _buildMobileAppointmentList(context, data, authController)
                      : DataTable2(
                          minWidth: 760,
                          columnSpacing: 12,
                          horizontalMargin: 16,
                          isHorizontalScrollBarVisible: true,
                          isVerticalScrollBarVisible: false,
                          fixedLeftColumns: 1,
                          fixedColumnsColor: appSurface,
                          fixedCornerColor: appCanvas,
                          columns: columns(),
                          headingRowColor: WidgetStateProperty.all(appCanvas),
                          headingRowHeight: 44,
                          decoration: const BoxDecoration(),
                          border: TableBorder(
                            horizontalInside: BorderSide(width: 1, color: appBorder),
                            top: BorderSide(width: 1, color: appBorder),
                            bottom: BorderSide(width: 1, color: appBorder),
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

  Widget _buildMobileAppointmentList(BuildContext context, List<Data> data, AuthController authController) {
    return RefreshIndicator(
      color: primary,
      onRefresh: () async => filtering(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        itemCount: data.length,
        itemBuilder: (context, i) {
          return _mobileAppointmentCard(context, data[i], i, authController);
        },
      ),
    );
  }

  Color _getStatusAccentColor(int? status) {
    switch (status) {
      case 1:
      case 3:
      case 4:
        return const Color(0xFF3B82F6);
      case 5:
        return const Color(0xFF10B981);
      case 7:
        return appInkMuted;
      case 2:
      case 6:
        return const Color(0xFFEF4444);
      case 8:
        return const Color(0xFF8B5CF6);
      default:
        return appInkMuted;
    }
  }

  Widget _mobileAppointmentCard(BuildContext context, Data apt, int index, AuthController authController) {
    final statusColor = _getStatusAccentColor(apt.appointmentStatus);
    final patientName = notNullOrEmptyString(apt.user?.userFullName)
        ? apt.user!.userFullName!.titleCase()
        : (apt.user?.userName ?? '—');
    final serviceName = apt.service?.serviceName ?? '—';
    final branchName = apt.branch?.branchName ?? '—';
    final rawTime = convertUtcToMalaysiaTimeRange(apt.appointmentDatetime, apt.service?.serviceTime);
    final dateDisplay = rawTime != null ? rawTime.replaceAll('\n', '  •  ') : (dateConverter(apt.appointmentDatetime, format: 'dd MMM yyyy HH:mm') ?? '—');
    final bookingFee = apt.service?.serviceBookingFee;
    final hasBookingFee = bookingFee != null && (double.tryParse(bookingFee) ?? 0) > 0;
    final isFeePaid = apt.appointmentStatus == 5 || isBookingFeePaid(apt.appointmentNote, payments: apt.payment);
    final appointmentId = apt.appointmentId != null
        ? '#${apt.appointmentId!.substring(0, math.min(8, apt.appointmentId!.length)).toUpperCase()}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _handleMenuSelection('update', apt),
          borderRadius: BorderRadius.circular(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        patientName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: appInkPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (deriveAgeFromNric(apt.user?.userNric) != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: appSurfaceSubtle,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: appBorder, width: 0.8),
                                        ),
                                        child: Text(
                                          deriveAgeFromNric(apt.user?.userNric)!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (appointmentId.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: appSurfaceSubtle,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    appointmentId,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: appInkMuted,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.event_rounded, size: 14, color: appInkMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  dateDisplay,
                                  style: TextStyle(fontSize: 12.5, color: appInkSecondary, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.medical_services_outlined, size: 14, color: appInkMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  serviceName,
                                  style: TextStyle(fontSize: 12.5, color: appInkSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: appInkMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  branchName,
                                  style: TextStyle(fontSize: 12.5, color: appInkMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _buildStatusBadge(apt.appointmentStatus),
                              if (hasBookingFee) ...[const SizedBox(width: 8), _buildPaymentBadge(isFeePaid ? 1 : 0)],
                              const Spacer(),
                              Icon(Icons.chevron_right_rounded, size: 20, color: appInkMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
            style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, color: appInkSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting the date range or filters',
            style: AppTypography.bodyMedium(context).apply(color: appInkMuted),
          ),
        ],
      ),
    );
  }

  DataRow2 _buildDataRow(BuildContext context, Data item, int index, AuthController authController) {
    return withAuroraRowHover(context, DataRow2(
      onTap: () => _handleMenuSelection('update', item),
      color: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.hovered)
            ? context.appColors.tableRowHover
            : index.isEven
            ? appSurface
            : appTableRowAlt,
      ),
      cells: [
        DataCell(
          Builder(
            builder: (context) {
              final ageStr = deriveAgeFromNric(item.user?.userNric);
              return Tooltip(
                message:
                    'IC: ${item.user?.userNric ?? 'N/A'}${ageStr != null ? ' ($ageStr)' : ''}\nPhone: ${item.user?.userPhone ?? 'N/A'}\nEmail: ${item.user?.userEmail ?? 'N/A'}',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: (item.user?.userId ?? '').isNotEmpty
                                ? () => PatientQuickDrawer.show(
                                      context,
                                      userId: item.user!.userId!,
                                      patientName: item.user?.userFullName?.titleCase(),
                                    )
                                : null,
                            child: Text(
                              item.user?.userFullName?.titleCase() ?? 'N/A',
                              style: AppTypography.bodyMedium(context).copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryAccessibleText,
                                decoration: TextDecoration.underline,
                                decorationColor: primaryAccessibleText.withValues(alpha: 0.35),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (ageStr != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: appSurfaceSubtle,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: appBorder, width: 0.8),
                            ),
                            child: Text(
                              ageStr,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: appInkSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.user?.userPhone != null)
                      Text(
                        item.user!.userPhone!,
                        style: AppTypography.bodyMedium(context).apply(fontSizeDelta: -3, color: appInkMuted),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        DataCell(
          Tooltip(
            message:
                '${item.service?.serviceTime ?? 'N/A'}\nBooking Fee: RM ${(double.tryParse(item.service?.serviceBookingFee ?? '') ?? 0) > 0 ? item.service!.serviceBookingFee! : '0'}',
            child: Text(
              item.service?.serviceName ?? 'N/A',
              style: AppTypography.bodyMedium(context).copyWith(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (authController.isSuperAdmin)
          DataCell(
            Tooltip(
              message: item.branch?.branchName ?? 'N/A',
              child: Text(
                item.branch?.branchName ?? 'N/A',
                style: AppTypography.bodyMedium(context).copyWith(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.rosterConflict == true ? appDangerSoft : appSurfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: item.rosterConflict == true ? Border.all(color: const Color(0xFFEF4444), width: 1) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doctorType(item.service?.doctorType),
                  style: AppTypography.bodyMedium(context).apply(fontSizeDelta: -1, color: appInkSecondary),
                ),
                if (notNullOrEmptyString(item.doctor?.doctorName))
                  Text(
                    item.doctor!.doctorName!,
                    style: TextStyle(color: primary, fontWeight: FontWeight.w600, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (item.rosterConflict == true)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      notNullOrEmptyString(item.doctor?.doctorName)
                          ? '⚠️ Off Duty / Reassign'
                          : '⚠️ No Staff on Duty',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
        ),
        DataCell(_buildStatusBadge(item.appointmentStatus)),
        DataCell(
          ((double.tryParse(item.service?.serviceBookingFee ?? '0') ?? 0) > 0)
              ? _buildPaymentBadge(
                  item.appointmentStatus == 5
                      ? 1
                      : (isBookingFeePaid(item.appointmentNote, payments: item.payment) ? 1 : 0),
                )
              : _buildNoPaymentBadge(),
        ),
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: () {
              final raw = convertUtcToMalaysiaTimeRange(item.appointmentDatetime, item.service?.serviceTime);
              if (raw == null) return [const Text('N/A')];
              final parts = raw.split('\n');
              return [
                Text(parts[0], style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w500)),
                if (parts.length > 1)
                  Text(parts[1], style: AppTypography.bodyMedium(context).apply(fontSizeDelta: -3, color: appInkMuted)),
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
                  final matchedService = context
                      .read<ServiceController>()
                      .servicesResponse
                      ?.data
                      ?.firstWhere(
                        (element) => element.serviceId == item.service?.serviceId,
                        orElse: () => context.read<ServiceController>().servicesResponse!.data!.first,
                      );
                  List<String>? templates = matchedService?.serviceTemplate;
                  showWhatsAppTemplateDialog(
                    context: context,
                    templates: templates ?? [],
                    name: item.user?.userFullName ?? '',
                    phone: item.user?.userPhone ?? '',
                    service: item.service?.serviceName ?? '',
                    branchName: item.branch?.branchName ?? '',
                    branchPhone: item.branch?.branchPhone ?? '',
                    dateTime: DateTime.parse(item.appointmentDatetime ?? ''),
                    serviceTime: item.service?.serviceTime ?? matchedService?.serviceTime,
                  );
                },
                icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 24),
                color: const Color(0xFF25D366),
                tooltip: 'WhatsApp',
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                offset: const Offset(0, 32),
                color: appSurfaceElevated,
                tooltip: '',
                onSelected: (value) => _handleMenuSelection(value, item),
                itemBuilder: (_) {
                  final isLocked = [2, 6, 8].contains(item.appointmentStatus);
                  final canTransfer = item.appointmentStatus == 1 || item.appointmentStatus == 3;
                  return [
                    if (!isLocked)
                      PopupMenuItem<String>(
                        value: 'checkout',
                        child: Row(
                          children: [
                            const Icon(Icons.point_of_sale_rounded, size: 20, color: Color(0xFF059669)),
                            const SizedBox(width: 8),
                            Text('Counter Checkout & Points', style: AppTypography.bodyMedium(context)),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'book_next',
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF2563EB)),
                          const SizedBox(width: 8),
                          Text('Book Next Appointment', style: AppTypography.bodyMedium(context)),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'update',
                      child: Row(
                        children: [
                          Icon(
                            isLocked ? Icons.visibility_rounded : Icons.edit_rounded,
                            size: 20,
                            color: appInkSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(isLocked ? 'View Details' : 'Update', style: AppTypography.bodyMedium(context)),
                        ],
                      ),
                    ),
                    if (canTransfer)
                      PopupMenuItem<String>(
                        value: 'transfer',
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 20, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Text('Transfer Branch', style: AppTypography.bodyMedium(context)),
                          ],
                        ),
                      ),
                  ];
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.grey.withAlpha(25), borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.more_horiz, color: appInkSecondary, size: 18),
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }

  Widget _buildStatusBadge(int? status) {
    return AppointmentStatusBadge(status: status);
  }

  Widget _buildPaymentBadge(int status) {
    switch (status) {
      case 1:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: appSuccessSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 18, color: accessibleAccent(const Color(0xFF059669))),
              const SizedBox(width: 4),
              Text(
                'Paid',
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: appSuccessText),
              ),
            ],
          ),
        );
      case 2:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: appDangerSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_rounded, size: 18, color: accessibleAccent(const Color(0xFFEF4444))),
              const SizedBox(width: 4),
              Text(
                'Failed',
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: appDangerText),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: appWarningSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty_rounded, size: 18, color: accessibleAccent(const Color(0xFFD97706))),
              const SizedBox(width: 4),
              Text(
                'Unpaid',
                style: AppTypography.bodyMedium(
                  context,
                ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: appWarningText),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNoPaymentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: appInfoSoft, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_rounded, size: 18, color: accessibleAccent(const Color(0xFF2563EB))),
          const SizedBox(width: 4),
          Text(
            'No Payment',
            style: AppTypography.bodyMedium(
              context,
            ).copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: appInfoText),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBar() {
    return Container(
      color: appSurface,
      padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Pagination(
              numOfPages: _totalPage,
              selectedPage: _page,
              pagesVisible: isMobile ? 3 : 5,
              spacing: isMobile ? 4 : 8,
              onPageChanged: _movePage,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMobile)
                Text('Rows: ', style: AppTypography.bodyMedium(context).apply(color: appInkMuted)),
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
                  style: AppTypography.bodyMedium(context).apply(color: appInkMuted),
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
        allowSorting: true,
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
          label: item.allowSorting && item.attribute == 'appointmentDatetime'
              ? InkWell(
                  onTap: _toggleDateSort,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label,
                        style: AppTypography.bodyMedium(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600, color: appInkMuted),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _sortBy == 'appointmentDatetime'
                            ? (_sortOrder == 'asc'
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded)
                            : Icons.unfold_more_rounded,
                        size: 16,
                        color: _sortBy == 'appointmentDatetime' ? const Color(0xFF2196F3) : appInkMuted,
                      ),
                    ],
                  ),
                )
              : Text(
                  item.label,
                  style: AppTypography.bodyMedium(context).copyWith(fontWeight: FontWeight.w600, color: appInkMuted),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: math.min(500, MediaQuery.of(context).size.width * 0.92),
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
                          color: appSuccessSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.calendar_month_rounded, color: accessibleAccent(const Color(0xFF059669)), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Check Available Slots', style: AppTypography.bodyLarge(context)),
                            Text(
                              'Branch: $branchLabel',
                              style: AppTypography.bodyMedium(context).apply(color: appInkMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
  tooltip: 'Tutup',
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(foregroundColor: appInkMuted),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: appBorder),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${serviceList.length} service(s) available',
                        style: AppTypography.bodyMedium(context).apply(color: appInkMuted),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: serviceList.length,
                    separatorBuilder: (_, _) => Divider(height: 1, color: appSurfaceSubtle),
                    itemBuilder: (context, i) {
                      final item = serviceList[i];
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: appInfoSoft, borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.medical_services_rounded, size: 16, color: accessibleAccent(const Color(0xFF0284C7))),
                        ),
                        title: Text(item.name, style: AppTypography.bodyMedium(context)),
                        trailing: Icon(Icons.chevron_right_rounded, color: appInkMuted),
                        onTap: () async {
                          showLoading();
                          DateTime now = DateTime.now();
                          List<String> availableDateTime = [];
                          List<String> tempExceptionDateTime = [];
                          ServiceBranchAvailableDtController.getAvailableSlot(context, serviceBranchId: item.key)
                              .then((value) {
                            if (responseCode(value.code)) {
                              context.read<ServiceBranchAvailableDtController>().serviceBranchAvailableTimingResponse =
                                  value.data;
                              availableDateTime = value.data?.slots?.isNotEmpty == true
                                  ? (value.data?.slots ?? [])
                                  : [];
                                  ServiceBranchExceptionController.get(context, 1, 999, serviceBranchId: item.key)
                                      .then((value) async {
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
                                          availableDateTime.sort(
                                            (a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)),
                                          );

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
                                } else {
                                          showDialogError(
                                            context,
                                            value.message ?? 'Failed to load schedule exceptions',
                                          );
                                }
                              }).catchError((e) {
                                dismissLoading();
                                showDialogError(context, e.toString());
                              });
                            } else {
                              dismissLoading();
                              showDialogError(context, value.message ?? 'Failed to load available slots');
                            }
                          }).catchError((e) {
                            dismissLoading();
                            showDialogError(context, e.toString());
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
    showDialog(context: context, builder: (_) => const _AppointmentGuidelineDialog());
  }
}

class _SopStep {
  final int number;
  final String title;
  final String shortTitle;
  final String description;
  final IconData icon;
  final Color accentColor;
  final List<_SopTask> tasks;
  final String? ruleTitle;
  final String? ruleCallout;
  final bool isWarningRule;

  const _SopStep({
    required this.number,
    required this.title,
    required this.shortTitle,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.tasks,
    this.ruleTitle,
    this.ruleCallout,
    this.isWarningRule = false,
  });
}

class _SopTask {
  final String title;
  final String description;
  final IconData icon;
  final String? badge;

  const _SopTask({
    required this.title,
    required this.description,
    required this.icon,
    this.badge,
  });
}

class _AppointmentGuidelineDialog extends StatefulWidget {
  const _AppointmentGuidelineDialog();

  @override
  State<_AppointmentGuidelineDialog> createState() => _AppointmentGuidelineDialogState();
}

class _AppointmentGuidelineDialogState extends State<_AppointmentGuidelineDialog> {
  int _currentStep = 0;
  final Set<int> _checkedChecklist = {};
  bool _viewingAllSteps = false;

  static const List<_SopStep> _steps = [
    _SopStep(
      number: 1,
      shortTitle: '1. Check-In',
      title: 'Patient Arrival & Queue Verification',
      description: 'Verify appointments, handle walk-in registrations, and keep the clinic queue moving.',
      icon: Icons.how_to_reg_rounded,
      accentColor: Color(0xFF2563EB),
      tasks: [
        _SopTask(
          title: 'Sync Latest Bookings',
          description: 'Tap "Refresh" in the top-right toolbar to fetch newly created mobile app bookings for today.',
          icon: Icons.sync_rounded,
          badge: 'SYNC',
        ),
        _SopTask(
          title: 'Walk-In Registration',
          description: 'Always search Phone Number or IC/Passport first to prevent duplicate accounts. Record counter payment (Cash, QR, Terminal) in remarks.',
          icon: Icons.person_add_alt_1_rounded,
          badge: 'WALK-IN',
        ),
        _SopTask(
          title: '1-Tap WhatsApp Ping',
          description: 'If the doctor is running behind schedule, tap the green WhatsApp icon to notify the waiting patient with an updated time without saving their number.',
          icon: Icons.chat_rounded,
          badge: 'FAST NOTIFY',
        ),
      ],
      ruleTitle: 'Doctor Schedule Check',
      ruleCallout: 'Always confirm the assigned practitioner is on duty for today\'s branch roster before sending the patient to the consultation room.',
      isWarningRule: false,
    ),
    _SopStep(
      number: 2,
      shortTitle: '2. Consultation',
      title: 'Doctor Hand-Off & Status Flow',
      description: 'Track real-time patient progress from the waiting area into the consultation room.',
      icon: Icons.medical_services_rounded,
      accentColor: Color(0xFF7C3AED),
      tasks: [
        _SopTask(
          title: 'Call Patient & Room Hand-off',
          description: 'Doctor calls patient into room. Clinical ultrasound scans and medical records are completed in the consult room.',
          icon: Icons.meeting_room_rounded,
          badge: 'IN-PROGRESS',
        ),
        _SopTask(
          title: 'Real-Time Queue Tracking',
          description: 'Frontdesk monitors queue status on the live board. Mark status promptly to ensure accurate waiting times.',
          icon: Icons.query_builder_rounded,
          badge: 'QUEUE',
        ),
      ],
      ruleTitle: 'Midnight Auto No-Show Rule',
      ruleCallout: '⚠️ Crucial Rule: The system automatically marks any un-updated "Booked" appointments as "No-Show" at 12:00 AM daily. Update all statuses before ending your shift!',
      isWarningRule: true,
    ),
    _SopStep(
      number: 3,
      shortTitle: '3. Checkout & Rebook',
      title: 'Payment Collection & Milestone Rebooking',
      description: 'Balance settlement, loyalty points auto-crediting, and pregnant milestone next scan rebooking.',
      icon: Icons.point_of_sale_rounded,
      accentColor: Color(0xFF10B981),
      tasks: [
        _SopTask(
          title: 'Collect Balance Payment',
          description: 'Click "Checkout" in appointment details. System automatically deducts the online booking deposit (e.g. RM 20) from the gross bill to calculate collectable balance.',
          icon: Icons.payments_rounded,
          badge: 'BALANCE BILL',
        ),
        _SopTask(
          title: 'Auto Loyalty Points',
          description: 'Every RM 10 spent automatically credits 1 Aurora Point to the patient\'s mobile app account.',
          icon: Icons.stars_rounded,
          badge: 'POINTS',
        ),
        _SopTask(
          title: 'Milestone Rebooking',
          description: 'Offer patient the next scan in their pregnancy journey: Dating/NT Scan → W18–24 Detail Anomaly → W26–32 4D/5D HD Live → W33–36 Growth & Doppler → Postnatal.',
          icon: Icons.child_care_rounded,
          badge: 'SCAN CHAIN',
        ),
        _SopTask(
          title: 'Mark Completed & Send WhatsApp Receipt',
          description: 'Mark status as "Completed" immediately after counter payment. Tap WhatsApp to send the patient their digital receipt and next booking confirmation.',
          icon: Icons.receipt_long_rounded,
          badge: 'RECEIPT',
        ),
      ],
      ruleTitle: 'Shift Settlement',
      ruleCallout: 'Marking "Completed" locks the booking and ensures daily counter collections match the branch financial summary.',
      isWarningRule: false,
    ),
    _SopStep(
      number: 4,
      shortTitle: '4. Reschedule & Transfer',
      title: 'Schedule Changes & Inter-Branch Transfers',
      description: 'Protect slot allocations with the 24-hour rule and the 3-step branch transfer protocol.',
      icon: Icons.swap_horiz_rounded,
      accentColor: Color(0xFF0284C7),
      tasks: [
        _SopTask(
          title: '24-Hour Reschedule Policy',
          description: '> 24 hours away: Patient can self-reschedule in their Aurora App.\n< 24 hours (Same-Day): Patient app is locked; only clinic staff can reschedule from this portal after verifying doctor availability.',
          icon: Icons.schedule_rounded,
          badge: '24H RULE',
        ),
        _SopTask(
          title: '3-Step Branch Transfer Protocol',
          description: '1. Contact receiving branch to verify doctor slot.\n2. Receiving branch creates new appointment.\n3. Origin branch updates existing appointment to "Transferred".',
          icon: Icons.storefront_rounded,
          badge: 'TRANSFER',
        ),
        _SopTask(
          title: 'Preserve Audit Trail',
          description: 'Never delete an appointment when transferring — "Transferred" status preserves historical booking logs for both branches.',
          icon: Icons.history_edu_rounded,
          badge: 'AUDIT',
        ),
      ],
      ruleTitle: 'Service / Treatment Changes',
      ruleCallout: 'If changing to a different service with differing fees, refund the existing booking and create a new booking to keep financial reports and commissions balanced.',
      isWarningRule: false,
    ),
    _SopStep(
      number: 5,
      shortTitle: '5. Closing & Audit',
      title: 'Financial Accounting & Daily Closing Checklist',
      description: 'Distinguish refunds from cancellations and complete the frontdesk closing checklist.',
      icon: Icons.fact_check_rounded,
      accentColor: Color(0xFF059669),
      tasks: [
        _SopTask(
          title: 'Refunded vs Cancelled (Golden Rule)',
          description: 'If money was collected (including online deposit), ALWAYS choose "Refunded" with reason. Choose "Cancelled" ONLY if RM 0.00 was paid and no money was collected.',
          icon: Icons.account_balance_wallet_rounded,
          badge: 'GOLDEN RULE',
        ),
        _SopTask(
          title: 'Accounting Credit Notes',
          description: 'Choosing "Refunded" automatically generates a ledger credit note, adjusts daily net revenue, and keeps Payment Reports audit-ready.',
          icon: Icons.receipt_rounded,
          badge: 'LEDGER',
        ),
      ],
      ruleTitle: 'Audit Invariant',
      ruleCallout: '⚠️ In Payment Report, refunded bookings are cleanly separated from actual clinic revenue.',
      isWarningRule: true,
    ),
  ];

  static const List<String> _checklistItems = [
    'Morning Sync: Clicked "Refresh" to load latest online bookings from app.',
    'WhatsApp Reminders: Sent reminder alerts to today\'s scheduled afternoon patients.',
    'Doctor Hand-Off: Verified doctor and room allocations for today\'s roster.',
    'Counter Checkout: Processed balance payments and marked attended visits as "Completed".',
    'Milestone Rebooking: Offered next pregnancy scan milestone during patient checkout.',
    'Accounting Rule: Marked all paid cancellations as "Refunded" (not "Cancelled").',
    'Zero Leftovers: Ensured 0 appointments remain in "Booked" status before closing shift.',
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final currentStepData = _steps[_currentStep];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: isMobile ? double.infinity : 760,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        color: appSurfaceSubtle,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Executive Gradient Header
            Container(
              padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFDF6E98), Color(0xFF7E2D40)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clinic Appointment Playbook',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Frontdesk Standard Operating Procedures (SOP) & Stepper Flow',
                          style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(220)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Stepper Navigation Tabs Bar + Progress Track
            Container(
              color: appSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _steps.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final step = entry.value;
                              final isActive = _currentStep == idx && !_viewingAllSteps;
                              final isCompleted = _currentStep > idx && !_viewingAllSteps;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _viewingAllSteps = false;
                                      _currentStep = idx;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? primary
                                          : (isCompleted ? appSuccessSoft : appSurfaceSubtle),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isActive
                                            ? primary
                                            : (isCompleted
                                                ? (appIsDarkMode ? const Color(0xFF166534) : const Color(0xFF86EFAC))
                                                : appBorder),
                                        width: isActive ? 1.5 : 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Colors.white.withAlpha(50)
                                                : (isCompleted
                                                    ? accessibleAccent(const Color(0xFF16A34A)).withAlpha(35)
                                                    : appBorder),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: isCompleted
                                                ? Icon(Icons.check_rounded, size: 12, color: accessibleAccent(const Color(0xFF16A34A)))
                                                : Text(
                                                    '${idx + 1}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      color: isActive ? Colors.white : appInkMuted,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          step.shortTitle,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                            color: isActive
                                                ? Colors.white
                                                : (isCompleted ? appSuccessText : appInkSecondary),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Toggle View All / Stepper Mode
                      InkWell(
                        onTap: () => setState(() => _viewingAllSteps = !_viewingAllSteps),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _viewingAllSteps ? primary : appSurfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _viewingAllSteps ? primary : appBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _viewingAllSteps ? Icons.view_carousel_rounded : Icons.view_agenda_rounded,
                                size: 14,
                                color: _viewingAllSteps ? Colors.white : appInkSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _viewingAllSteps ? 'Stepper' : 'View All',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _viewingAllSteps ? Colors.white : appInkSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Progress Track
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _viewingAllSteps ? 1.0 : (_currentStep + 1) / _steps.length,
                      minHeight: 3,
                      backgroundColor: appSurfaceSubtle,
                      valueColor: AlwaysStoppedAnimation<Color>(accessibleAccent(primary)),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: appBorder),

            // Animated Step Body / Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _viewingAllSteps
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final s in _steps) ...[
                            _buildStepCardBlock(s),
                            const SizedBox(height: 14),
                          ],
                          _buildChecklistSection(),
                        ],
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.04, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentStep),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildStepHeader(currentStepData),
                              const SizedBox(height: 12),
                              for (final task in currentStepData.tasks)
                                _buildTaskCard(task, currentStepData.accentColor),
                              if (currentStepData.ruleCallout != null)
                                _buildRuleBox(
                                  currentStepData.ruleTitle ?? 'Operational Rule',
                                  currentStepData.ruleCallout!,
                                  isWarning: currentStepData.isWarningRule,
                                ),
                              if (_currentStep == _steps.length - 1) ...[
                                const SizedBox(height: 8),
                                _buildChecklistSection(),
                              ],
                            ],
                          ),
                        ),
                      ),
              ),
            ),

            // Stepper Bottom Navigation Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: appSurface,
                border: Border(top: BorderSide(color: appBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _currentStep > 0 && !_viewingAllSteps
                        ? () => setState(() => _currentStep--)
                        : null,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: const Text('Previous'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: appInkPrimary,
                      disabledForegroundColor: appInkMuted.withAlpha(100),
                      side: BorderSide(color: appBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _viewingAllSteps
                            ? 'Overview (${_steps.length} Steps)'
                            : 'Step ${_currentStep + 1} of ${_steps.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: appInkMuted,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_viewingAllSteps || _currentStep >= _steps.length - 1) {
                        Navigator.of(context).pop();
                      } else {
                        setState(() => _currentStep++);
                      }
                    },
                    icon: Icon(
                      _viewingAllSteps || _currentStep >= _steps.length - 1
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      _viewingAllSteps || _currentStep >= _steps.length - 1 ? 'Got It' : 'Next Step',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHeader(_SopStep step) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accessibleAccent(step.accentColor).withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(step.icon, color: accessibleAccent(step.accentColor), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: accessibleAccent(step.accentColor).withAlpha(25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'STEP ${step.number}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: accessibleAccent(step.accentColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: appInkPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  step.description,
                  style: TextStyle(fontSize: 12, color: appInkSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCardBlock(_SopStep step) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accessibleAccent(step.accentColor).withAlpha(25),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(step.icon, color: accessibleAccent(step.accentColor), size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Step ${step.number}: ${step.title}',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: appInkPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final task in step.tasks)
            _buildTaskCard(task, step.accentColor),
          if (step.ruleCallout != null)
            _buildRuleBox(
              step.ruleTitle ?? 'Operational Rule',
              step.ruleCallout!,
              isWarning: step.isWarningRule,
            ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(_SopTask task, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: appSurfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appBorder, width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accessibleAccent(accentColor).withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(task.icon, color: accessibleAccent(accentColor), size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: appInkPrimary,
                        ),
                      ),
                    ),
                    if (task.badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: accessibleAccent(accentColor).withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: accessibleAccent(accentColor).withAlpha(50)),
                        ),
                        child: Text(
                          task.badge!,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: accessibleAccent(accentColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  task.description,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: appInkSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleBox(String title, String callout, {required bool isWarning}) {
    final bgColor = isWarning ? appWarningSoft : appInfoSoft;
    final borderColor = isWarning
        ? (appIsDarkMode ? const Color(0xFF78350F) : const Color(0xFFFDE68A))
        : (appIsDarkMode ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE));
    final iconColor = isWarning
        ? accessibleAccent(const Color(0xFFD97706))
        : accessibleAccent(const Color(0xFF2563EB));
    final textColor = isWarning ? appWarningText : appInfoText;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
              size: 15, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  callout,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistSection() {
    final doneCount = _checkedChecklist.length;
    final totalCount = _checklistItems.length;
    final isAllDone = doneCount == totalCount;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: appSuccessSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: appIsDarkMode ? const Color(0xFF166534) : const Color(0xFF86EFAC),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist_rounded,
                      color: accessibleAccent(const Color(0xFF16A34A)), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Daily Frontdesk Closing Checklist',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: appSuccessText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAllDone
                      ? accessibleAccent(const Color(0xFF16A34A))
                      : (appIsDarkMode ? const Color(0xFF133E3B) : const Color(0xFFD1FAE5)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isAllDone
                        ? accessibleAccent(const Color(0xFF16A34A))
                        : (appIsDarkMode ? const Color(0xFF166534) : const Color(0xFF86EFAC)),
                  ),
                ),
                child: Text(
                  '$doneCount / $totalCount Completed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAllDone ? Colors.white : appSuccessText,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Tap items below to check off your daily operational closing tasks:',
            style: TextStyle(
              fontSize: 11.5,
              color: appSuccessText.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < _checklistItems.length; i++) ...[
            InkWell(
              onTap: () {
                setState(() {
                  if (_checkedChecklist.contains(i)) {
                    _checkedChecklist.remove(i);
                  } else {
                    _checkedChecklist.add(i);
                  }
                });
              },
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _checkedChecklist.contains(i)
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      size: 18,
                      color: _checkedChecklist.contains(i)
                          ? accessibleAccent(const Color(0xFF16A34A))
                          : appInkMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _checklistItems[i],
                        style: TextStyle(
                          fontSize: 12,
                          color: _checkedChecklist.contains(i) ? appSuccessText : appInkPrimary,
                          decoration: _checkedChecklist.contains(i) ? TextDecoration.lineThrough : null,
                          fontWeight: _checkedChecklist.contains(i) ? FontWeight.w500 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
