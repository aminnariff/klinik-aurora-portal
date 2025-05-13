import 'dart:async';
import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/outlined_button.dart';
import 'package:klinik_aurora_portal/views/widgets/calendar/selection_calendar_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
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

  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  final int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  final TextEditingController _serviceNameController = TextEditingController();
  DropdownAttribute? _selectedServiceStatus;
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);

  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  int _selectedTabIndex = 0;

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(
        AppointmentHomepage.displayName,
      );
    });
    _tabController = TabController(length: _tabs.length, vsync: this);
    filtering();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _selectedTabIndex = _tabController.index;
      debugPrint('Active Tab Index: $_selectedTabIndex (${_tabs[_selectedTabIndex]})');
      filtering(enableDebounce: false);
    });
    super.initState();
  }

  List<String>? getAppointmentStatus() {
    if (_tabs[_selectedTabIndex] == 'Upcoming') {
      return ['1', '3', '4'];
    } else if (_tabs[_selectedTabIndex] == 'Completed') {
      return ['5'];
    } else if (_tabs[_selectedTabIndex] == 'No-Show') {
      return ['7'];
    } else if (_tabs[_selectedTabIndex] == 'Cancelled') {
      return ['2', '6'];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: mobileView(), desktop: desktopView());
  }

  Widget mobileView() {
    // return StreamBuilder<List<Results>>(
    //   stream: results.stream,
    //   builder: (context, snapshot) {
    return Column(
      children: [
        searchField(
          InputFieldAttribute(controller: _serviceNameController, hintText: 'Search', labelText: 'Patient Name'),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (int index = 0; index < (2); index++)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CardContainer(
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: screenPadding * 1.5,
                                    horizontal: screenPadding,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      mobileText('Central Office', 'N/A'),
                                      mobileText('Serving Cabinet', 'N/A'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: CardContainer(
                      Padding(
                        padding: EdgeInsets.all(screenPadding),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('N/A'),
                            Text('N/A'),
                            Row(children: [Text('N/A')]),
                            Text('aaaaa'),
                          ],
                        ),
                      ),
                      margin: EdgeInsets.symmetric(vertical: screenPadding / 2, horizontal: screenPadding),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: screenPadding), child: pagination()),
      ],
    );
    // },
    // );
  }

  Widget mobileText(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$title:', style: Theme.of(context).textTheme.bodyMedium),
        AppPadding.horizontal(denominator: 2),
        Expanded(child: AppSelectableText(value)),
      ],
    );
  }

  Widget desktopView() {
    return
    // (widget.orderReference == null)
    //     ?
    Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            dividerColor: Colors.transparent,
          ),
          // Row(
          //   children: [
          //     AppPadding.horizontal(),
          //     searchField(
          //       InputFieldAttribute(controller: _serviceNameController, hintText: 'Search', labelText: 'Patient Name'),
          //     ),
          //     // AppPadding.horizontal(),
          //     // searchField(
          //     //   InputFieldAttribute(controller: _emailController, hintText: 'Search', labelText: 'Email'),
          //     // ),
          //   ],
          // ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: CardContainer(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 4, 15, 0),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          orderTable(),
                          orderTable(),
                          orderTable(),
                          orderTable(),
                          // Center(child: Text('Completed Appointments')),
                          // Center(child: Text('No-Show Appointments')),
                          // Center(child: Text('Cancelled Appointments')),
                        ],
                      ),
                    ),
                    color: Colors.white,
                    margin: EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, screenPadding),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    // : OrderDetailHomepage(
    //     orderReference: widget.orderReference!,
    //     previousPage: AppointmentHomepage.routeName,
    //   );
  }

  Widget searchField(InputFieldAttribute attribute) {
    return Column(
      children: [
        AppPadding.vertical(),
        InputField(
          field: InputFieldAttribute(
            controller: attribute.controller,
            hintText: attribute.hintText,
            labelText: attribute.labelText,
            suffixWidget: TextButton(
              onPressed: () {
                filtering(page: 1);
              },
              child: const Icon(Icons.search, color: Colors.blue),
            ),
            isEditableColor: const Color(0xFFEEF3F7),
            onFieldSubmitted: (value) {
              filtering(enableDebounce: true, page: 1);
            },
          ),
          width: screenWidthByBreakpoint(90, 70, 26),
        ),
      ],
    );
  }

  Widget orderTable() {
    return Consumer<AppointmentController>(
      builder: (context, snapshot, child) {
        if (snapshot.appointmentResponse == null) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [Expanded(child: Center(child: CircularProgressIndicator(color: secondaryColor)))],
          );
        } else {
          return snapshot.appointmentResponse?.data == null || snapshot.appointmentResponse!.data!.data!.isEmpty
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [tableButton(), const Expanded(child: Center(child: NoRecordsWidget()))],
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  tableButton(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white),
                            padding: const EdgeInsets.all(5),
                            child: DataTable2(
                              columnSpacing: 12,
                              horizontalMargin: 12,
                              minWidth: 1300,
                              isHorizontalScrollBarVisible: true,
                              isVerticalScrollBarVisible: true,
                              columns: columns(),
                              headingRowColor: WidgetStateProperty.all(Colors.white),
                              headingRowHeight: 51,
                              decoration: const BoxDecoration(),
                              border: TableBorder(
                                left: BorderSide(width: 1, color: Colors.black.withOpacity(0.1)),
                                top: BorderSide(width: 1, color: Colors.black.withOpacity(0.1)),
                                bottom: BorderSide(width: 1, color: Colors.black.withOpacity(0.1)),
                                right: BorderSide(width: 1, color: Colors.black.withOpacity(0.1)),
                                verticalInside: BorderSide(width: 1, color: Colors.black.withOpacity(0.1)),
                              ),
                              rows: [
                                for (
                                  int index = 0;
                                  index < (snapshot.appointmentResponse?.data?.data?.length ?? 0);
                                  index++
                                )
                                  DataRow(
                                    color: WidgetStateProperty.all(
                                      index % 2 == 1 ? Colors.white : const Color(0xFFF3F2F7),
                                    ),
                                    cells: [
                                      DataCell(
                                        Tooltip(
                                          message:
                                              'Contact No : ${snapshot.appointmentResponse?.data?.data?[index].user?.userPhone ?? 'N/A'}\nEmail : ${snapshot.appointmentResponse?.data?.data?[index].user?.userEmail ?? 'N/A'}',
                                          child: Text(
                                            snapshot.appointmentResponse?.data?.data?[index].user?.userFullName ??
                                                'N/A',
                                            style: AppTypography.bodyMedium(context).apply(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Tooltip(
                                          message:
                                              '${snapshot.appointmentResponse?.data?.data?[index].service?.serviceDescription ?? 'N/A'}\n\nBooking Fee : RM ${snapshot.appointmentResponse?.data?.data?[index].service?.serviceBookingFee ?? 'N/A'}',
                                          child: Text(
                                            snapshot.appointmentResponse?.data?.data?[index].service?.serviceName ??
                                                'N/A',
                                          ),
                                        ),
                                      ),
                                      if (context.read<AuthController>().isSuperAdmin)
                                        DataCell(
                                          AppSelectableText(
                                            snapshot.appointmentResponse?.data?.data?[index].branch?.branchName ??
                                                'N/A',
                                          ),
                                        ),
                                      DataCell(
                                        Text(
                                          getAppointmentStatusLabel(
                                            snapshot.appointmentResponse?.data?.data?[index].appointmentStatus,
                                          ),
                                          style: AppTypography.bodyMedium(context).apply(
                                            fontWeightDelta: 1,
                                            color:
                                                appointmentStatusColors[snapshot
                                                    .appointmentResponse
                                                    ?.data
                                                    ?.data?[index]
                                                    .appointmentStatus],
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          convertUtcToMalaysiaTime(
                                                snapshot.appointmentResponse?.data?.data?[index].appointmentDatetime,
                                              ) ??
                                              'N/A',
                                          style: AppTypography.bodyMedium(context).apply(),
                                        ),
                                      ),
                                      DataCell(
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            IconButton(
                                              onPressed: () {},
                                              icon: Icon(FontAwesomeIcons.whatsapp),
                                              color: Colors.green,
                                            ),
                                            PopupMenuButton<String>(
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              offset: const Offset(8, 35),
                                              color: Colors.white,
                                              tooltip: '',
                                              onSelected:
                                                  (value) => _handleMenuSelection(
                                                    value,
                                                    snapshot.appointmentResponse?.data?.data?[index] ?? Data(),
                                                  ),
                                              itemBuilder:
                                                  (BuildContext context) => <PopupMenuEntry<String>>[
                                                    const PopupMenuItem<String>(value: 'update', child: Text('Update')),
                                                  ],
                                              child: Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(4),
                                                    // decoration: const BoxDecoration(
                                                    //   color: Colors.white,
                                                    //   shape: BoxShape.circle,
                                                    // ),
                                                    child: Icon(Icons.more_vert, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          if (isNoRecords.value) const AppSelectableText('No Records Found'),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: pagination()),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isMobile && !isTablet)
                                  const Flexible(
                                    child: Text('Items per page: ', overflow: TextOverflow.ellipsis, maxLines: 1),
                                  ),
                                perPage(),
                              ],
                            ),
                          ),
                          if (!isMobile && !isTablet)
                            Text(
                              '${((_page) * _pageSize) - _pageSize + 1} - ${((_page) * _pageSize < _totalCount) ? ((_page) * _pageSize) : _totalCount} of $_totalCount',
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
        }
      },
    );
  }

  void _handleMenuSelection(String value, Data appointment) async {
    if (value == 'update') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AppointmentDetails(type: 'update', appointment: appointment, tabs: getAppointmentStatus());
        },
      );
    }
  }

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce
        ? _debouncer.run(() {
          runFiltering(page: page);
        })
        : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) {
      _page = page;
    }
    context.read<AppointmentController>().appointmentResponse = null;
    AppointmentController()
        .get(
          context,
          _page,
          _pageSize,
          status: getAppointmentStatus(),
          branchId:
              context.read<AuthController>().authenticationResponse?.data?.user?.isSuperadmin == true
                  ? null
                  : context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
        )
        .then((value) {
          dismissLoading();
          context.read<AppointmentController>().appointmentResponse = value;
          _totalCount = value.data?.totalCount ?? 0;
        });
  }

  void getData({int? page}) async {
    showLoading();
  }

  List<DataColumn2> columns() {
    List<TableHeaderAttribute> headers = [
      TableHeaderAttribute(attribute: 'userFullName', label: 'Name', allowSorting: false, columnSize: ColumnSize.S),
      TableHeaderAttribute(
        attribute: 'serviceName',
        label: 'Service Name',
        allowSorting: false,
        columnSize: ColumnSize.S,
      ),
      if (context.read<AuthController>().isSuperAdmin)
        TableHeaderAttribute(
          attribute: 'branchName',
          label: 'Branch Name',
          allowSorting: false,
          columnSize: ColumnSize.S,
        ),
      TableHeaderAttribute(
        attribute: 'appointmentStatus',
        label: 'Status',
        allowSorting: false,
        columnSize: ColumnSize.S,
      ),
      TableHeaderAttribute(
        attribute: 'appointmentDatetime',
        label: 'Appointment Date',
        allowSorting: false,
        columnSize: ColumnSize.S,
      ),
      TableHeaderAttribute(
        attribute: 'actions',
        label: 'Actions',
        allowSorting: false,
        columnSize: ColumnSize.S,
        width: 100,
      ),
    ];
    return [
      for (TableHeaderAttribute item in headers)
        DataColumn2(
          fixedWidth: item.width,
          label: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: AppSelectableText(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.apply(fontWeightDelta: 2),
                      ),
                    ),
                    // if (item.tooltip != null) ...[
                    //   const SizedBox(
                    //     width: 10,
                    //   ),
                    //   const Icon(
                    //     Icons.help_outline_rounded,
                    //     size: 18,
                    //     color: Colors.grey,
                    //   ),
                    // ],
                  ],
                ),
              ),
            ],
          ),
          numeric: item.numeric,
          tooltip: item.tooltip,
          size: item.columnSize ?? ColumnSize.M,
        ),
    ];
  }

  resetAllFilter() {
    _serviceNameController.text = '';
    _selectedServiceStatus = null;
    rebuildDropdown.add(DateTime.now());
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

  Widget tableButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (false)
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.topRight,
                        children: [
                          CardContainer(
                            Padding(
                              padding: EdgeInsets.all(screenPadding),
                              child: const SelectionCalendarView(
                                startMonth: 5,
                                year: 2025,
                                totalMonths: 2,
                                initialDateTimes: [
                                  "2025-05-06T02:43:00.000Z",
                                  "2025-05-21T02:43:00.000Z",
                                  "2025-05-25T02:43:00.000Z",
                                  "2025-05-23T02:43:00.000Z",
                                  "2025-05-16T02:43:00.000Z",
                                  "2025-05-10T10:00:00.000Z",
                                  "2025-05-16T10:00:00.000Z",
                                  "2025-05-31T10:00:00.000Z",
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              );
              // showDialog(
              //   context: context,
              //   builder: (BuildContext context) {
              //     return const AppointmentDetails(type: 'create');
              //   },
              // );
            },
            child: Row(
              children: [
                const Icon(Icons.add, color: Colors.blue),
                AppPadding.horizontal(denominator: 2),
                Text('Add new appointment', style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue)),
              ],
            ),
          ),
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Card(
                        surfaceTintColor: Colors.white,
                        elevation: 5.0,
                        color: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            bottomLeft: Radius.circular(15),
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding),
                              child: Column(
                                children: [
                                  searchField(
                                    InputFieldAttribute(
                                      controller: _serviceNameController,
                                      hintText: 'Search',
                                      labelText: 'Service Name',
                                    ),
                                  ),
                                  AppPadding.vertical(),
                                  StreamBuilder<DateTime>(
                                    stream: rebuildDropdown.stream,
                                    builder: (context, snapshot) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            children: [
                                              AppDropdown(
                                                attributeList: DropdownAttributeList(
                                                  [
                                                    DropdownAttribute('1', 'Active'),
                                                    DropdownAttribute('0', 'Inactive'),
                                                  ],
                                                  labelText: 'information'.tr(gender: 'userStatus'),
                                                  value: _selectedServiceStatus?.name,
                                                  onChanged: (p0) {
                                                    _selectedServiceStatus = p0;
                                                    rebuildDropdown.add(DateTime.now());
                                                    filtering(page: 1);
                                                  },
                                                  width: screenWidthByBreakpoint(90, 70, 26),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  AppPadding.vertical(denominator: 1 / 3),
                                  AppOutlinedButton(
                                    () {
                                      resetAllFilter();
                                      filtering(enableDebounce: true, page: 1);
                                    },
                                    backgroundColor: Colors.white,
                                    borderRadius: 15,
                                    width: 131,
                                    height: 45,
                                    text: 'Clear',
                                  ),
                                ],
                              ),
                            ),
                            const Padding(padding: EdgeInsets.all(8.0), child: CloseButton()),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.blue),
              AppPadding.horizontal(denominator: 2),
              Text('Filter', style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue)),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            resetAllFilter();
            filtering(enableDebounce: true, page: 1);
          },
          child: Row(
            children: [
              const Icon(Icons.refresh, color: Colors.blue),
              AppPadding.horizontal(denominator: 2),
              Text('Reset', style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue)),
            ],
          ),
        ),
      ],
    );
  }

  Widget perPage() {
    return PerPageWidget(
      _pageSize.toString(),
      DropdownAttributeList(
        [],
        onChanged: (selected) {
          DropdownAttribute item = selected as DropdownAttribute;
          _pageSize = int.parse(item.key);
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
      onPageChanged: (page) {
        _movePage(page);
      },
    );
  }

  void _movePage(int page) {
    filtering(page: page, enableDebounce: false);
  }
}
