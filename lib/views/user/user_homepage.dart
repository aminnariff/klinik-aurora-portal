import 'dart:async';
import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart' as appointment_model;
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch;
import 'package:klinik_aurora_portal/models/user/update_user_request.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/user/appointment_ids.dart';
import 'package:klinik_aurora_portal/views/user/user_detail.dart';
import 'package:klinik_aurora_portal/views/user/user_point_detail.dart';
import 'package:klinik_aurora_portal/views/widgets/button/outlined_button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/global/status.dart';
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
import 'package:klinik_aurora_portal/views/widgets/tooltip/app_tooltip.dart';
import 'package:provider/provider.dart';

class UserHomepage extends StatefulWidget {
  static const routeName = '/patients';
  static const displayName = 'Patients';
  const UserHomepage({super.key});

  @override
  State<UserHomepage> createState() => _UserHomepageState();
}

class _UserHomepageState extends State<UserHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);

  List<TableHeaderAttribute> headers = [
    TableHeaderAttribute(attribute: 'userFullname', label: 'Name', allowSorting: false, columnSize: ColumnSize.S),

    TableHeaderAttribute(
      attribute: 'totalPoints',
      label: 'Points',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 90,
    ),
    TableHeaderAttribute(
      attribute: 'branchId',
      label: 'Registered Branch',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'userStatus',
      label: 'Status',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 70,
    ),
    TableHeaderAttribute(
      attribute: 'createdDate',
      label: 'Created Date',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'actions',
      label: 'Actions',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 80,
    ),
  ];
  final TextEditingController _userFullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  DropdownAttribute? _selectedBranch;
  DropdownAttribute? _selectedUserStatus;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(UserHomepage.displayName);
    });
    if (context.read<BranchController>().branchAllResponse == null) {
      BranchController.getAll(context, 1, 100).then((value) {
        if (responseCode(value.code)) {
          context.read<BranchController>().branchAllResponse = value;
        }
      });
    }
    filtering();
    super.initState();
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
          InputFieldAttribute(controller: _userFullNameController, hintText: 'Search', labelText: 'Order Reference'),
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
        Padding(
          padding: EdgeInsets.symmetric(vertical: screenPadding),
          child: pagination(),
        ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              AppPadding.horizontal(),
              searchField(
                InputFieldAttribute(controller: _userFullNameController, hintText: 'Search', labelText: 'Full Name'),
              ),
              // AppPadding.horizontal(),
              // searchField(
              //   InputFieldAttribute(controller: _emailController, hintText: 'Search', labelText: 'Email'),
              // ),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: CardContainer(
                    Padding(padding: const EdgeInsets.fromLTRB(15, 4, 15, 0), child: orderTable()),
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
            onChanged: (value) {
              // filtering(enableDebounce: true, page: 1);
            },
          ),
          width: screenWidthByBreakpoint(90, 70, 26),
        ),
      ],
    );
  }

  Widget orderTable() {
    return Consumer<UserController>(
      builder: (context, snapshot, child) {
        if (snapshot.userAllResponse == null) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Center(child: CircularProgressIndicator(color: secondaryColor)),
              ),
            ],
          );
        } else {
          return snapshot.userAllResponse == null || snapshot.userAllResponse!.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    tableButton(),
                    const Expanded(child: Center(child: NoRecordsWidget())),
                  ],
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
                                isHorizontalScrollBarVisible: true,
                                isVerticalScrollBarVisible: true,
                                columns: columns(),
                                headingRowColor: WidgetStateProperty.all(Colors.white),
                                headingRowHeight: 51,
                                decoration: const BoxDecoration(),
                                border: TableBorder(
                                  left: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
                                  top: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
                                  bottom: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
                                  right: BorderSide(width: 1, color: Colors.black.withAlpha(opacityCalculation(.1))),
                                  verticalInside: BorderSide(
                                    width: 1,
                                    color: Colors.black.withAlpha(opacityCalculation(.1)),
                                  ),
                                ),
                                rows: [
                                  for (int index = 0; index < (snapshot.userAllResponse?.length ?? 0); index++)
                                    DataRow(
                                      color: WidgetStateProperty.all(
                                        index % 2 == 1 ? Colors.white : const Color(0xFFF3F2F7),
                                      ),
                                      cells: [
                                        DataCell(
                                          AppTooltip(
                                            message:
                                                '${notNullOrEmptyString(snapshot.userAllResponse?[index].userNric) ? 'Document ID:\n${snapshot.userAllResponse?[index].userNric}\n\n' : ''}Email:\n${snapshot.userAllResponse?[index].userEmail}\n\nContact No:\n${snapshot.userAllResponse?[index].userPhone}',
                                            child: Text(
                                              snapshot.userAllResponse?[index].userFullname?.titleCase() ??
                                                  snapshot.userAllResponse?[index].userName ??
                                                  'N/A',
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              AppSelectableText(
                                                '${snapshot.userAllResponse?[index].totalPoint ?? 'N/A'}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                            translateToBranchName(snapshot.userAllResponse?[index].branchId ?? '') ??
                                                'N/A',
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [showStatus(snapshot.userAllResponse?[index].userStatus == 1)],
                                          ),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                            dateConverter(snapshot.userAllResponse?[index].createdDate) ?? 'N/A',
                                          ),
                                        ),
                                        DataCell(
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              PopupMenuButton<String>(
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                offset: const Offset(8, 35),
                                                color: Colors.white,
                                                tooltip: '',
                                                onSelected: (value) =>
                                                    _handleMenuSelection(value, snapshot.userAllResponse![index]),
                                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                                  const PopupMenuItem<String>(
                                                    value: 'update',
                                                    child: Text('Update Info'),
                                                  ),
                                                  const PopupMenuItem<String>(
                                                    value: 'appointment',
                                                    child: Text('Appointment'),
                                                  ),
                                                  const PopupMenuItem<String>(
                                                    value: 'appointmentHistory',
                                                    child: Text('Appointment History'),
                                                  ),
                                                  const PopupMenuItem<String>(
                                                    value: 'managePoints',
                                                    child: Text('Manage Points'),
                                                  ),
                                                  PopupMenuItem<String>(
                                                    value: 'enableDisable',
                                                    child: Text(
                                                      snapshot.userAllResponse?[index].userStatus == 1
                                                          ? 'Deactivate'
                                                          : 'Re-Activate',
                                                    ),
                                                  ),
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

  void _handleMenuSelection(String value, UserResponse user) async {
    if (value == 'appointment') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AppointmentDetails(
            type: 'create',
            appointment: appointment_model.Data(
              user: appointment_model.User(
                userId: user.userId,
                userName: user.userName,
                userEmail: user.userEmail,
                userFullName: user.userFullname,
                userPhone: user.userPhone,
              ),
            ),
          );
        },
      );
    } else if (value == 'appointmentHistory') {
      showLoading();
      UserController.appointment(context, user.userId ?? '').then((value) {
        dismissLoading();
        if (responseCode(value.code)) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return UserAppointmentIds(response: value.data, patient: user);
            },
          );
        }
      });
    } else if (value == 'managePoints') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return UserPointDetail(user: user);
        },
      );
    } else if (value == 'update') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return UserDetail(user: user, type: 'update');
        },
      );
    } else if (value == 'enableDisable') {
      try {
        if (await showConfirmDialog(
          context,
          user.userStatus == 1
              ? 'Are you certain you wish to deactivate this user account? Please note, this action can be reversed at a later time.'
              : 'Are you certain you wish to activate this user account? Please note, this action can be reversed at a later time.',
        )) {
          Future.delayed(Duration.zero, () {
            UserController.update(
              context,
              UpdateUserRequest(
                userId: user.userId,
                userName: user.userName,
                userFullname: user.userFullname,
                userDob: dateConverter(user.userDob, format: 'yyyy-MM-dd'),
                userPhone: user.userPhone,
                branchId: user.branchId,
                userStatus: user.userStatus == 1 ? 0 : 1,
              ),
            ).then((value) {
              if (responseCode(value.code)) {
                filtering();
                showDialogSuccess(
                  context,
                  'The user account has been successfully ${user.userStatus == 1 ? 'deactivated' : 'activated'}.',
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

  String? translateToBranchName(String branchId) {
    try {
      if (context.read<BranchController>().branchAllResponse?.data?.data != null) {
        return context
            .read<BranchController>()
            .branchAllResponse
            ?.data
            ?.data!
            .firstWhere((element) => element.branchId == branchId)
            .branchName;
      } else {
        return null;
      }
    } catch (e) {
      return null;
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
    UserController.getAll(
      context,
      _page,
      _pageSize,
      userFullName: _userFullNameController.text,
      userName: _userNameController.text,
      userPhone: _userPhoneController.text,
      userEmail: _userEmailController.text,
      branchId: _selectedBranch?.key,
      userStatus: _selectedUserStatus != null
          ? _selectedUserStatus?.key == '1'
                ? 1
                : _selectedUserStatus?.key == '0'
                ? 0
                : null
          : null,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage = value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        context.read<UserController>().userAllResponse = value.data?.data;
      } else if (value.code == 404) {}
      return null;
    });
  }

  String? getOrderBy() {
    try {
      return headers.firstWhere((element) => element.isSort).attribute;
    } catch (e) {
      return null;
    }
  }

  String? getSortType() {
    if (getOrderBy() != null) {
      if (headers.firstWhere((element) => element.isSort).sort == SortType.asc) {
        return 'asc';
      } else {
        return 'desc';
      }
    } else {
      return null;
    }
  }

  void getData({int? page}) async {
    showLoading();
  }

  List<DataColumn2> columns() {
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
              if (item.allowSorting)
                TextButton(
                  onPressed: () {
                    if (getOrderBy() != item.attribute) {
                      resetAllFilter();
                    }
                    if (item.isSort) {
                      if (item.sort == SortType.asc) {
                        item.sort = SortType.desc;
                        filtering(enableDebounce: false);
                      } else {
                        item.sort = SortType.asc;
                        item.isSort = false;
                        filtering(enableDebounce: false);
                      }
                    } else {
                      item.isSort = true;
                      filtering(enableDebounce: false);
                    }
                  },
                  child: sortingIcon(item),
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
    _userFullNameController.text = '';
    _userNameController.text = '';
    _userPhoneController.text = '';
    _userEmailController.text = '';
    _selectedBranch = null;
    _selectedUserStatus = null;
    rebuildDropdown.add(DateTime.now());

    for (TableHeaderAttribute item in headers) {
      item.isSort = false;
      item.sort = SortType.asc;
    }
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
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return const UserDetail(type: 'create');
              },
            );
          },
          child: Row(
            children: [
              const Icon(Icons.add, color: Colors.blue),
              AppPadding.horizontal(denominator: 2),
              Text('Add new user', style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue)),
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
                  children: [
                    Card(
                      surfaceTintColor: Colors.white,
                      elevation: 5.0,
                      color: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
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
                                    controller: _userFullNameController,
                                    hintText: 'Search',
                                    labelText: 'Full Name',
                                  ),
                                ),
                                AppPadding.vertical(denominator: 2),
                                searchField(
                                  InputFieldAttribute(
                                    controller: _userNameController,
                                    hintText: 'Search',
                                    labelText: 'Username',
                                  ),
                                ),
                                AppPadding.vertical(denominator: 2),
                                searchField(
                                  InputFieldAttribute(
                                    controller: _userPhoneController,
                                    hintText: 'Search',
                                    labelText: 'Contact Number',
                                  ),
                                ),
                                AppPadding.vertical(denominator: 2),
                                searchField(
                                  InputFieldAttribute(
                                    controller: _userEmailController,
                                    hintText: 'Search',
                                    labelText: 'Email',
                                  ),
                                ),
                                AppPadding.vertical(),
                                StreamBuilder<DateTime>(
                                  stream: rebuildDropdown.stream,
                                  builder: (context, snapshot) {
                                    return Column(
                                      children: [
                                        AppDropdown(
                                          attributeList: DropdownAttributeList(
                                            [
                                              if (context.read<BranchController>().branchAllResponse?.data?.data !=
                                                  null)
                                                for (branch.Data item
                                                    in context.read<BranchController>().branchAllResponse?.data?.data ??
                                                        [])
                                                  DropdownAttribute(item.branchId ?? '', item.branchName ?? ''),
                                            ],
                                            labelText: 'information'.tr(gender: 'registeredBranch'),
                                            value: _selectedBranch?.name,
                                            onChanged: (p0) {
                                              _selectedBranch = p0;
                                              rebuildDropdown.add(DateTime.now());
                                              filtering(page: 1);
                                            },
                                            width: screenWidthByBreakpoint(90, 70, 26),
                                          ),
                                        ),
                                        AppPadding.vertical(),
                                        AppDropdown(
                                          attributeList: DropdownAttributeList(
                                            [DropdownAttribute('1', 'Active'), DropdownAttribute('0', 'Inactive')],
                                            labelText: 'information'.tr(gender: 'userStatus'),
                                            value: _selectedUserStatus?.name,
                                            onChanged: (p0) {
                                              _selectedUserStatus = p0;
                                              rebuildDropdown.add(DateTime.now());
                                              filtering(page: 1);
                                            },
                                            width: screenWidthByBreakpoint(90, 70, 26),
                                          ),
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
