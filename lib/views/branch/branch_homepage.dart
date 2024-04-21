import 'dart:async';
import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/views/branch/branch_detail.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/outlined_button.dart';
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

class BranchHomepage extends StatefulWidget {
  static const routeName = '/branch';
  static const displayName = 'Branches';
  final String? orderReference;
  const BranchHomepage({super.key, this.orderReference});

  @override
  State<BranchHomepage> createState() => _BranchHomepageState();
}

class _BranchHomepageState extends State<BranchHomepage> {
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
      attribute: 'city',
      label: 'City',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'state',
      label: 'State',
      allowSorting: false,
      columnSize: ColumnSize.S,
    ),
    TableHeaderAttribute(
      attribute: 'branchStatus',
      label: 'Branch Status',
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
  ];
  final TextEditingController _orderReferenceController = TextEditingController();
  final TextEditingController _ontController = TextEditingController();
  final TextEditingController _slotController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _ontSNController = TextEditingController();
  final TextEditingController _ontPonController = TextEditingController();
  final TextEditingController _ontMacController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  String? _nltType;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(BranchHomepage.displayName);
    });
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
          Row(
            children: [
              AppPadding.horizontal(),
              searchField(
                InputFieldAttribute(
                    controller: _orderReferenceController, hintText: 'Search', labelText: 'Order Reference'),
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
    //     previousPage: BranchHomepage.routeName,
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
    return Consumer<BranchController>(
      builder: (context, snapshot, child) {
        if (snapshot.branchAllResponse == null) {
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
          return snapshot.branchAllResponse == null || snapshot.branchAllResponse!.data!.data!.isEmpty
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
                                  for (int index = 0;
                                      index < (snapshot.branchAllResponse?.data?.data?.length ?? 0);
                                      index++)
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
                                                    return BranchDetail(
                                                      branch: snapshot.branchAllResponse?.data?.data?[index],
                                                      type: 'update',
                                                    );
                                                  });
                                            },
                                            child: Text(
                                              snapshot.branchAllResponse?.data?.data?[index].branchName ?? 'N/A',
                                              style: AppTypography.bodyMedium(context).apply(color: Colors.blue),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                              snapshot.branchAllResponse?.data?.data?[index].city ?? 'N/A'),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                              snapshot.branchAllResponse?.data?.data?[index].state ?? 'N/A'),
                                        ),
                                        DataCell(
                                          AppSelectableText(
                                            snapshot.branchAllResponse?.data?.data?[index].branchStatus == 1
                                                ? 'Active'
                                                : 'Inactive',
                                            style: AppTypography.bodyMedium(context).apply(
                                                color: statusColor(
                                                    snapshot.branchAllResponse?.data?.data?[index].branchStatus == 1
                                                        ? 'active'
                                                        : 'inactive'),
                                                fontWeightDelta: 1),
                                          ),
                                        ),
                                        DataCell(
                                          AppSelectableText(dateConverter(
                                                  snapshot.branchAllResponse?.data?.data?[index].createdDate) ??
                                              'N/A'),
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
    BranchController.getAll(context).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.data?.length ?? 0;
        _totalPage = ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        context.read<BranchController>().branchAllResponse = value;
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
    _ontController.text = '';
    _slotController.text = '';
    _portController.text = '';
    _ontSNController.text = '';
    _ontPonController.text = '';
    _ontMacController.text = '';
    _ipController.text = '';
    _nltType = null;
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
                  return const BranchDetail(
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
                'Add new branch',
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
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _orderReferenceController,
                                          hintText: 'Search',
                                          labelText: 'Order Reference'),
                                    ),
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _ontController, hintText: 'Search', labelText: 'ONT'),
                                    ),
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _slotController, hintText: 'Search', labelText: 'Slot'),
                                    ),
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _portController, hintText: 'Search', labelText: 'Port'),
                                    ),
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _ontSNController,
                                          hintText: 'Search',
                                          labelText: 'ONT Serial Number'),
                                    ),
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _ontPonController, hintText: 'Search', labelText: 'ONT PON'),
                                    ),
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _ontMacController, hintText: 'Search', labelText: 'ONT MAC'),
                                    ),
                                    searchField(
                                      InputFieldAttribute(
                                          controller: _ipController, hintText: 'Search', labelText: 'IP Address'),
                                    ),
                                    AppPadding.vertical(),
                                    StreamBuilder<DateTime>(
                                        stream: rebuildDropdown.stream,
                                        builder: (context, snapshot) {
                                          return AppDropdown(
                                            attributeList: DropdownAttributeList(
                                              [
                                                DropdownAttribute('CONFIRM', 'CONFIRM'),
                                                DropdownAttribute('COMPLETE', 'COMPLETE'),
                                              ],
                                              labelText: 'nltType',
                                              value: _nltType,
                                              onChanged: (p0) {
                                                _nltType = p0?.key;
                                                rebuildDropdown.add(DateTime.now());
                                                filtering(page: 0);
                                              },
                                              width: screenWidthByBreakpoint(90, 70, 26),
                                            ),
                                          );
                                        }),
                                    AppPadding.vertical(denominator: 1 / 3),
                                    AppOutlinedButton(
                                      () {
                                        resetAllFilter();
                                        filtering(enableDebounce: true, page: 0);
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
