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
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch;
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/user/user_detail.dart';
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

class DoctorHomepage extends StatefulWidget {
  static const routeName = '/pic';
  static const displayName = 'Person In Charge';
  final String? branchId;
  const DoctorHomepage({super.key, this.branchId});

  @override
  State<DoctorHomepage> createState() => _DoctorHomepageState();
}

class _DoctorHomepageState extends State<DoctorHomepage> {
  int _page = 0;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);

  List<TableHeaderAttribute> headers = [
    TableHeaderAttribute(
      attribute: 'userFullname',
      label: 'Name',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'userEmail',
      label: 'Email',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'userPhone',
      label: 'Contact No.',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 130,
    ),
    TableHeaderAttribute(
      attribute: 'userStatus',
      label: 'Status',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 70,
    ),
    TableHeaderAttribute(
      attribute: 'branchId',
      label: 'Registered Branch',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'createdDate',
      label: 'Created Date',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
  ];
  final TextEditingController _orderReferenceController = TextEditingController();
  String? _selectedBranch;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(DoctorHomepage.displayName);
    });
    if (context.read<BranchController>().branchAllResponse == null) {
      BranchController.getAll(context).then(
        (value) {
          if (responseCode(value.code)) {
            context.read<BranchController>().branchAllResponse = value;
          }
        },
      );
    }
    filtering();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(
      mobile: mobileView(),
      desktop: desktopView(),
    );
  }

  Widget mobileView() {
    // return StreamBuilder<List<Results>>(
    //   stream: results.stream,
    //   builder: (context, snapshot) {
    return Column(
      children: [
        searchField(
          InputFieldAttribute(controller: _orderReferenceController, hintText: 'Search', labelText: 'Order Reference'),
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
                                  padding:
                                      EdgeInsets.symmetric(vertical: screenPadding * 1.5, horizontal: screenPadding),
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
                            Row(
                              children: [
                                Text('N/A'),
                              ],
                            ),
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
        )
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
        Text(
          '$title:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        AppPadding.horizontal(denominator: 2),
        Expanded(
          child: AppSelectableText(
            value,
          ),
        ),
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
          // Row(
          //   children: [
          //     AppPadding.horizontal(),
          //     searchField(
          //       InputFieldAttribute(
          //           controller: _orderReferenceController, hintText: 'Search', labelText: 'Order Reference'),
          //     ),
          //   ],
          // ),
          AppPadding.vertical(),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: CardContainer(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 4, 15, 0),
                      child: orderTable(),
                    ),
                    color: Colors.white,
                    margin: EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, screenPadding, screenPadding),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
    // : OrderDetailHomepage(
    //     orderReference: widget.orderReference!,
    //     previousPage: DoctorHomepage.routeName,
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
                filtering(page: 0);
              },
              child: const Icon(
                Icons.search,
                color: Colors.blue,
              ),
            ),
            isEditableColor: const Color(0xFFEEF3F7),
            onFieldSubmitted: (value) {
              filtering(enableDebounce: true, page: 0);
            },
            onChanged: (value) {
              filtering(enableDebounce: true, page: 0);
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
                child: Center(
                  child: CircularProgressIndicator(
                    color: secondaryColor,
                  ),
                ),
              ),
            ],
          );
        } else {
          return snapshot.userAllResponse == null || snapshot.userAllResponse!.isEmpty
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    tableButton(),
                    const Expanded(
                      child: Center(
                        child: NoRecordsWidget(),
                      ),
                    ),
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
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(5),
                              child: DataTable2(
                                columnSpacing: 12,
                                horizontalMargin: 12,
                                minWidth: 1300,
                                isHorizontalScrollBarVisible: true,
                                isVerticalScrollBarVisible: true,
                                columns: columns(),
                                headingRowColor: MaterialStateProperty.all(Colors.white),
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
                                  for (int index = 0; index < (snapshot.userAllResponse?.length ?? 0); index++)
                                    DataRow(
                                      color: MaterialStateProperty.all(
                                          index % 2 == 1 ? Colors.white : const Color(0xFFF3F2F7)),
                                      cells: [
                                        DataCell(
                                          TextButton(
                                            onPressed: () {
                                              showDialog(
                                                  context: context,
                                                  builder: (BuildContext context) {
                                                    return UserDetail(
                                                      user: snapshot.userAllResponse![index],
                                                      type: 'update',
                                                    );
                                                  });
                                            },
                                            child: Text(
                                              snapshot.userAllResponse?[index].userFullname ??
                                                  snapshot.userAllResponse?[index].userName ??
                                                  'N/A',
                                              style: AppTypography.bodyMedium(context).apply(color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          AppSelectableText(snapshot.userAllResponse?[index].userEmail ?? 'N/A'),
                                        ),
                                        DataCell(
                                          InkWell(
                                            onTap: () {
                                              //TODO copy item
                                            },
                                            child: Text(snapshot.userAllResponse?[index].userPhone ?? '60 12 498 2969'),
                                          ),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                            snapshot.userAllResponse?[index].userStatus == 1 ? 'Active' : 'Inactive',
                                            style: AppTypography.bodyMedium(context).apply(
                                                color: statusColor(snapshot.userAllResponse?[index].userStatus == 1
                                                    ? 'active'
                                                    : 'inactive'),
                                                fontWeightDelta: 1),
                                          ),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                              translateToBranchName(snapshot.userAllResponse?[index].branchId ?? '') ??
                                                  'N/A'),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                              dateConverter(snapshot.userAllResponse?[index].createdDate) ?? 'N/A'),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            if (isNoRecords.value)
                              const AppSelectableText(
                                'No Records Found',
                              ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: pagination(),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMobile && !isTablet)
                                    const Flexible(
                                      child: Text(
                                        'Items per page: ',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  perPage(),
                                ],
                              ),
                            ),
                            if (!isMobile && !isTablet)
                              Text(
                                '${((_page + 1) * _pageSize) - _pageSize + 1} - ${((_page + 1) * _pageSize < _totalCount) ? ((_page + 1) * _pageSize) : _totalCount} of $_totalCount',
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
      // DeviceRequest(
      //   orderReference: (_orderReferenceController.text != '') ? _orderReferenceController.text : null,
      //   serialNumber: (_ontSNController.text != '') ? _ontSNController.text : null,
      //   ont: (_ontController.text != '') ? _ontController.text : null,
      //   port: (_portController.text != '') ? _portController.text : null,
      //   card: (_slotController.text != '') ? _slotController.text : null,
      //   ontPON: (_ontPonController.text != '') ? _ontPonController.text : null,
      //   ontMAC: (_ontMacController.text != '') ? _ontMacController.text : null,
      //   ipAddress: (_ipController.text != '') ? _ipController.text : null,
      //   nltType: _nltType,
      //   page: _page,
      //   pageSize: _pageSize,
      // ),
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.length ?? 0;
        _totalPage = ((value.data?.length ?? 0) / _pageSize).ceil();
        context.read<UserController>().userAllResponse = value.data;
        // _page = 0;
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
    _orderReferenceController.text = '';
    _selectedBranch = null;
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
            ? Transform.rotate(
                angle: -math.pi,
                child: child,
              )
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
                  return const UserDetail(
                    type: 'create',
                  );
                });
          },
          child: Row(
            children: [
              const Icon(
                Icons.add,
                color: Colors.blue,
              ),
              AppPadding.horizontal(denominator: 2),
              Text(
                'Add new user',
                style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue),
              ),
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
                                    // searchField(
                                    //   InputFieldAttribute(
                                    //       controller: _orderReferenceController,
                                    //       hintText: 'Search',
                                    //       labelText: 'Order Reference'),
                                    // ),
                                    AppPadding.vertical(),
                                    StreamBuilder<DateTime>(
                                        stream: rebuildDropdown.stream,
                                        builder: (context, snapshot) {
                                          return AppDropdown(
                                            attributeList: DropdownAttributeList(
                                              [
                                                if (context.read<BranchController>().branchAllResponse?.data?.data !=
                                                    null)
                                                  for (branch.Data item in context
                                                          .read<BranchController>()
                                                          .branchAllResponse
                                                          ?.data
                                                          ?.data ??
                                                      [])
                                                    DropdownAttribute(item.branchId ?? '', item.branchName ?? ''),
                                              ],
                                              labelText: 'information'.tr(gender: 'registeredBranch'),
                                              value: _selectedBranch,
                                              onChanged: (p0) {
                                                _selectedBranch = p0?.key;
                                                rebuildDropdown.add(DateTime.now());
                                                filtering(page: 0);
                                              },
                                              width: screenWidthByBreakpoint(90, 70, 26),
                                            ),
                                          );
                                        }),
                                    AppPadding.vertical(denominator: 1 / 3),
                                    // AppOutlinedButton(
                                    //   () {
                                    //     resetAllFilter();
                                    //     filtering(enableDebounce: true, page: 0);
                                    //   },
                                    //   backgroundColor: Colors.white,
                                    //   borderRadius: 15,
                                    //   width: 131,
                                    //   height: 45,
                                    //   text: 'Clear',
                                    // ),
                                  ],
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CloseButton(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                });
          },
          child: Row(
            children: [
              const Icon(
                Icons.filter_list,
                color: Colors.blue,
              ),
              AppPadding.horizontal(denominator: 2),
              Text(
                'Filter',
                style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () {
            resetAllFilter();
            filtering(enableDebounce: true, page: 0);
          },
          child: Row(
            children: [
              const Icon(
                Icons.refresh,
                color: Colors.blue,
              ),
              AppPadding.horizontal(denominator: 2),
              Text(
                'Reset',
                style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue),
              ),
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
          filtering(
            enableDebounce: false,
          );
        },
      ),
    );
  }

  Widget pagination() {
    return Pagination(
      numOfPages: _totalPage,
      selectedPage: _page + 1,
      pagesVisible: isMobile ? 3 : 5,
      spacing: 10,
      onPageChanged: (page) {
        _movePage(page - 1);
      },
    );
  }

  void _movePage(int page) {
    filtering(page: page, enableDebounce: false);
  }
}
