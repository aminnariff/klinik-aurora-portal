import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_request.dart';
import 'package:klinik_aurora_portal/models/point_management/user_points_response.dart' as user_model;
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/mobile_view/mobile_view.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class PointHomepage extends StatefulWidget {
  static const routeName = '/points';
  static const displayName = 'Points';
  const PointHomepage({super.key});

  @override
  State<PointHomepage> createState() => _PointHomepageState();
}

class _PointHomepageState extends State<PointHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  final InputFieldAttribute _amount = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Amount',
    prefixText: 'RM',
    // prefixIcon: Row(children: [Text('RM')],),
  );
  final InputFieldAttribute _msisdn = InputFieldAttribute(
    controller: TextEditingController(text: kDebugMode ? '012' : ''),
    labelText: 'Contact No',
  );
  bool isExpanded = false;
  @override
  void initState() {
    super.initState();
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(PointHomepage.displayName);
      runFiltering();
      context.read<UserController>().userAllResponse = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(
      mobile: const MobileView(),
      desktop: desktopView(),
    );
  }

  Widget desktopView() {
    return
        // (widget.orderReference == null)
        //     ?
        Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        height: screenHeight(100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            AppPadding.vertical(),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      child: customerPoints(),
                    ),
                  ),
                  // const CardContainer(
                  //   Column(
                  //     children: [Text('data')],
                  //   ),
                  // ),
                  Expanded(
                    flex: 2,
                    child: history(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: secondaryColor,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
    // : OrderDetailHomepage(
    //     orderReference: widget.orderReference!,
    //     previousPage: PromotionHomepage.routeName,
    //   );
  }

  Widget customerPoints() {
    return CardContainer(
      Padding(
        padding: EdgeInsets.all(screenPadding),
        child: Column(
          children: [
            Text(
              'Customer Payment',
              style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
            ),
            AppPadding.vertical(),
            pointDetails(),
            AppPadding.vertical(),
            InputField(
              field: InputFieldAttribute(
                  controller: _amount.controller,
                  labelText: _amount.labelText,
                  prefixText: _amount.prefixText,
                  errorMessage: _amount.errorMessage,
                  isCurrency: true,
                  maxCharacter: 9,
                  isEditable: true,
                  onChanged: (value) {
                    if (_amount.errorMessage != null) {
                      setState(() {
                        _amount.errorMessage = null;
                      });
                    }
                  }),
            ),
            AppPadding.vertical(),
            InputField(
              field: InputFieldAttribute(
                controller: _msisdn.controller,
                labelText: _msisdn.labelText,
                maxCharacter: 12,
                suffixWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.search,
                        color: Colors.blue,
                      ),
                      color: secondaryColor,
                      onPressed: () {
                        if (_amount.controller.text == '') {
                          setState(() {
                            _amount.errorMessage = ErrorMessage.required(field: _amount.labelText);
                          });
                        } else if (calculateCustomerPoints(_amount.controller.text) <= 0) {
                          setState(() {
                            _amount.errorMessage = 'Amount is invalid';
                          });
                        } else {
                          showLoading();
                          UserController.getAll(context, 1, 20, userPhone: _msisdn.controller.text).then((value) async {
                            dismissLoading();
                            if (responseCode(value.code)) {
                              context.read<UserController>().userAllResponse = value.data?.data;
                            } else {
                              showDialogError(context, 'No user found.');
                            }
                          });
                        }
                      },
                    )
                  ],
                ),
              ),
            ),
            Consumer<UserController>(
              builder: (context, snapshot, _) {
                return (snapshot.userAllResponse?.length ?? 0) == 0
                    ? const SizedBox()
                    : Expanded(
                        child: CardContainer(
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    AppPadding.vertical(),
                                    Text(
                                      'Patient List (${snapshot.userAllResponse?.length})',
                                      style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                                    ),
                                    AppPadding.vertical(denominator: 2),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            for (UserResponse item in snapshot.userAllResponse ?? [])
                                              ListTile(
                                                title: Text(
                                                  '${item.userFullname}',
                                                  style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                                                ),
                                                subtitle: Text(
                                                  '${item.userPhone} (${item.totalPoint} pts)',
                                                  style: AppTypography.bodyMedium(context)
                                                      .apply(color: Colors.grey.shade600),
                                                ),
                                                onTap: () async {
                                                  int totalPoint = calculateCustomerPoints(_amount.controller.text);
                                                  if (await showConfirmDialog(context,
                                                      'Patient -> ${item.userFullname}\nAre you sure you want to store $totalPoint point(s) for this patient for spending RM ${_amount.controller.text}?')) {
                                                    PointManagementController.create(
                                                      context,
                                                      CreatePointRequest(
                                                          userId: item.userId,
                                                          totalPoint: totalPoint,
                                                          pointDescription:
                                                              'You have earned $totalPoint point(s) for spending RM ${_amount.controller.text}'),
                                                    ).then((value) {
                                                      dismissLoading();
                                                      if (responseCode(value.code)) {
                                                        showDialogSuccess(context,
                                                            'Successfully added ${calculateCustomerPoints(_amount.controller.text)} point(s) for ${item.userFullname}.');
                                                        _amount.controller.text = '';
                                                        _msisdn.controller.text = '';
                                                        runFiltering();
                                                      } else {
                                                        showDialogError(context,
                                                            value.data?.message ?? 'error'.tr(gender: 'err-7'));
                                                      }
                                                    });
                                                  }
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    AppPadding.vertical(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          margin: EdgeInsets.symmetric(vertical: screenPadding, horizontal: 0),
                        ),
                      );
              },
            ),
          ],
        ),
      ),
      margin: EdgeInsets.fromLTRB(screenPadding, screenPadding, 0, screenPadding),
    );
  }

  Widget pointDetails() {
    return Column(
      children: [
        Column(
          children: [
            AppPadding.vertical(),
            GestureDetector(
              onTap: () {
                setState(() {
                  isExpanded = !isExpanded;
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "How do patients collect points?",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
            if (isExpanded == false) AppPadding.vertical(),
            if (isExpanded) ...[
              const SizedBox(height: 16),
              const Text(
                "With every service payment at Klinik Aurora. Terms & conditions apply.",
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPointsOption(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'RM 100  = ',
                          style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1, fontSizeDelta: -1),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber,
                            border: Border.all(
                              color: Colors.yellow,
                              width: 3.4,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '10',
                              style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1, fontSizeDelta: -2),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppPadding.horizontal(),
                  _buildPointsOption(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.amber,
                            border: Border.all(
                              color: Colors.yellow,
                              width: 3.4,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '10',
                              style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1, fontSizeDelta: -2),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Text(
                          ' =  RM 1',
                          style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1, fontSizeDelta: -1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: screenHeightByBreakpoint(90, 70, 50),
                                  child: CardContainer(
                                    Padding(
                                      padding: EdgeInsets.all(screenPadding),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Terms and Conditions',
                                            style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                                          ),
                                          AppPadding.vertical(),
                                          Row(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  // •	Refer a friend and earn an extra points when they make their first payment!\n
                                                  '•	Earn extra points on special occasions and during promotional events!\n•	Points expire after 12 months.\n•	For every RM 10, you earn 1 point.\n•	Each transaction gives you a minimum of 1 point and a maximum of 1,000 points.\n• Points can be redeemed for discounts or exclusive rewards at Klinik Aurora',
                                                  style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 0),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    "Learn more",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPointsOption(Widget child) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: 1),
          decoration: BoxDecoration(
            color: context.read<DarkModeController>().darkMode ? Colors.white54 : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget history() {
    return CardContainer(
      Consumer<PointManagementController>(builder: (context, snapshot, _) {
        return Column(
          children: [
            AppPadding.vertical(),
            Text(
              'Point History',
              style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (user_model.Data item in snapshot.userPointsResponse?.data ?? [])
                      SizedBox(
                        child: ListTile(
                          onTap: () {},
                          title: Text(
                            item.username ?? ' N/A',
                            style: AppTypography.bodyMedium(context),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.pointDescription != null ? '${item.pointDescription}\n' : ''}by ${item.createdByFullname ?? 'N/A'}\n${dateConverter(item.createdDate)}',
                                style: AppTypography.bodyMedium(context).apply(fontSizeDelta: -2),
                              ),
                              Text(
                                ((item.totalPoint ?? 0) > 0) ? '+ ${item.totalPoint}' : '${item.totalPoint}',
                                style: AppTypography.bodyMedium(context).apply(
                                    fontWeightDelta: 2,
                                    fontSizeDelta: 5,
                                    color: ((item.totalPoint ?? 0) < 0) ? errorColor : Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            paginationWidget(),
          ],
        );
      }),
    );
  }

  Widget paginationWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: pagination(),
            ),
          ],
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
                '${((_page) * _pageSize) - _pageSize + 1} - ${((_page) * _pageSize < _totalCount) ? ((_page) * _pageSize) : _totalCount} of $_totalCount',
              ),
          ],
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
      selectedPage: _page,
      pagesVisible: 3,
      spacing: 10,
      onPageChanged: (page) {
        _movePage(page);
      },
    );
  }

  void _movePage(int page) {
    filtering(page: page, enableDebounce: false);
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

    PointManagementController.get(context, _page).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<PointManagementController>().userPointsResponse = value.data;
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage = value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
      } else {
        showDialogError(context, value.data?.message ?? 'error'.tr(gender: 'generic'));
      }
    });
  }
}
