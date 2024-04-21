import 'dart:async';
import 'dart:typed_data';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/promotion/promotion_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/document/file_attribute.dart';
import 'package:klinik_aurora_portal/models/promotion/create_promotion_request.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/mobile_view/mobile_view.dart';
import 'package:klinik_aurora_portal/views/promotion/promotion_detail.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/button/outlined_button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/checkbox/checkbox.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:klinik_aurora_portal/views/widgets/upload_document/upload_document.dart';
import 'package:provider/provider.dart';

class PromotionHomepage extends StatefulWidget {
  static const routeName = '/promotion';
  static const displayName = 'Promotions';
  final String? orderReference;
  const PromotionHomepage({super.key, this.orderReference});

  @override
  State<PromotionHomepage> createState() => _PromotionHomepageState();
}

class _PromotionHomepageState extends State<PromotionHomepage> {
  int _page = 0;
  final int _pageSize = pageSize;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);
  final TextEditingController _orderReferenceController = TextEditingController();
  final TextEditingController _promotionName = TextEditingController();
  final TextEditingController _promotionDescription = TextEditingController();
  final TextEditingController _promotionTnc = TextEditingController();
  final TextEditingController _startDate = TextEditingController();
  final TextEditingController _endDate = TextEditingController();
  final ValueNotifier<bool> _showOnStart = ValueNotifier(false);
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<String?> documentErrorMessage = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  StreamController<DateTime> fileRebuild = StreamController.broadcast();
  List<FileAttribute> selectedFiles = [];

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue =
          Homepage.getPageId(PromotionHomepage.displayName);
    });
    filtering();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(
      mobile: const MobileView(),
      desktop: desktopView(),
    );
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
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              AppPadding.horizontal(),
              // searchField(
              //   InputFieldAttribute(
              //       controller: _orderReferenceController, hintText: 'Search', labelText: 'Order Reference'),
              // ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(15, screenPadding / 2, 15, 0),
                    child: orderTable(),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          createNewPromotion();
        },
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

  createNewPromotion() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CardContainer(
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: screenPadding, vertical: screenPadding / 2),
                        child: IntrinsicWidth(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  AppSelectableText(
                                    'Promotion',
                                    style: AppTypography.bodyLarge(context),
                                  ),
                                  CloseButton(
                                    onPressed: () {
                                      context.pop();
                                    },
                                  )
                                ],
                              ),
                              AppPadding.vertical(denominator: 2),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: screenWidth1728(26),
                                    child: Column(
                                      children: [
                                        InputField(
                                          field: InputFieldAttribute(
                                            controller: _promotionName,
                                            labelText: 'Name',
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        TextField(
                                          maxLines: null,
                                          style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                          controller: _promotionDescription,
                                          decoration: appInputDecoration(context, 'Description'),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        TextField(
                                          maxLines: null,
                                          style: Theme.of(context).textTheme.bodyMedium!.apply(),
                                          controller: _promotionTnc,
                                          decoration: appInputDecoration(context, "Terms and Conditions"),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppPadding.horizontal(),
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: StreamBuilder<DateTime>(
                                      stream: fileRebuild.stream,
                                      builder: (context, snapshot) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.start,
                                          children: [
                                            if (selectedFiles.length < 3) ...[
                                              UploadDocumentsField(
                                                title: 'promotionPage'.tr(gender: 'browseFile'),
                                                fieldTitle: 'promotionPage'.tr(gender: 'promotionImage'),
                                                // tooltipText: 'promotionPage'.tr(gender: 'browse'),
                                                action: () async {
                                                  documentErrorMessage.add(null);
                                                  FilePickerResult? result = await FilePicker.platform.pickFiles();

                                                  if (result != null) {
                                                    PlatformFile file = result.files.first;
                                                    if (supportedExtensions.contains(file.extension)) {
                                                      debugPrint(bytesToMB(file.size).toString());
                                                      debugPrint(file.name);
                                                      if (bytesToMB(file.size) < 5.0) {
                                                        Uint8List? fileBytes = result.files.first.bytes;
                                                        String fileName = result.files.first.name;

                                                        selectedFiles
                                                            .add(FileAttribute(name: fileName, value: fileBytes));
                                                        fileRebuild.add(DateTime.now());
                                                      } else {
                                                        documentErrorMessage.add('error'.tr(
                                                            gender: 'err-21',
                                                            args: [fileSizeLimit.toStringAsFixed(0)]));
                                                      }
                                                    } else {
                                                      documentErrorMessage.add('error'.tr(gender: 'err-22'));
                                                    }
                                                  } else {
                                                    // User canceled the picker
                                                  }
                                                },
                                                cancelAction: () {},
                                              ),
                                            ],
                                            for (int index = 0; index < selectedFiles.length; index++)
                                              ListTile(
                                                title: Text(
                                                  '${index + 1}.  ${selectedFiles[index].name ?? ''}',
                                                  style: AppTypography.bodyMedium(context),
                                                ),
                                                enableFeedback: true,
                                                enabled: true,
                                                trailing: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                  ),
                                                  tooltip: 'button'.tr(gender: 'remove'),
                                                  onPressed: () {
                                                    selectedFiles.removeAt(index);
                                                    fileRebuild.add(DateTime.now());
                                                  },
                                                ),
                                              ),
                                            AppPadding.vertical(),
                                            GestureDetector(
                                              onTap: () async {
                                                var results = await showCalendarDatePicker2Dialog(
                                                  context: context,
                                                  config: CalendarDatePicker2WithActionButtonsConfig(
                                                    firstDate: DateTime.now(),
                                                  ),
                                                  dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                                  borderRadius: BorderRadius.circular(15),
                                                );
                                                _startDate.text =
                                                    dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                              },
                                              child: ReadOnly(
                                                InputField(
                                                  field: InputFieldAttribute(
                                                    controller: _startDate,
                                                    isEditable: false,
                                                    labelText: 'promotionPage'.tr(gender: 'startDate'),
                                                  ),
                                                ),
                                                isEditable: false,
                                              ),
                                            ),
                                            AppPadding.vertical(denominator: 2),
                                            GestureDetector(
                                              onTap: () async {
                                                var results = await showCalendarDatePicker2Dialog(
                                                  context: context,
                                                  config: CalendarDatePicker2WithActionButtonsConfig(
                                                    firstDate: DateTime.now(),
                                                  ),
                                                  dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                                  borderRadius: BorderRadius.circular(15),
                                                );
                                                _endDate.text =
                                                    dateConverter('${results?.first}', format: 'dd-MM-yyyy') ?? '';
                                              },
                                              child: ReadOnly(
                                                InputField(
                                                  field: InputFieldAttribute(
                                                    controller: _endDate,
                                                    isEditable: false,
                                                    labelText: 'promotionPage'.tr(gender: 'endDate'),
                                                  ),
                                                ),
                                                isEditable: false,
                                              ),
                                            ),
                                            AppPadding.vertical(denominator: 2),
                                            ValueListenableBuilder<bool>(
                                                valueListenable: _showOnStart,
                                                builder: (context, snapshot, _) {
                                                  return Row(
                                                    children: [
                                                      CheckBoxWidget(
                                                        (p0) {
                                                          _showOnStart.value = !snapshot;
                                                        },
                                                        value: snapshot,
                                                      ),
                                                      AppPadding.horizontal(denominator: 2),
                                                      Flexible(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            _showOnStart.value = !snapshot;
                                                          },
                                                          child: Text(
                                                            'promotionPage'.tr(gender: 'showOnStart'),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              AppPadding.vertical(denominator: 1 / 1.5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Button(
                                    () {
                                      PromotionController.create(
                                        orderReference,
                                        CreatePromotionRequest(
                                          promotionName: _promotionName.text,
                                          promotionDescription: _promotionName.text,
                                          promotionStartDate: _startDate.text,
                                          promotionEndDate: _endDate.text,
                                          showOnStart: _showOnStart.value ? 1 : 0,
                                          documents: [selectedFiles.first],
                                        ),
                                      ).then((value) {
                                        if (responseCode(value.code)) {
                                          filtering();
                                          context.pop();
                                          showDialogSuccess(context,
                                              'We\'ve just whipped up an amazing new promotion that\'s sure to bring endless joy to our customers! 🎉');
                                        } else {
                                          showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                        }
                                      });
                                    },
                                    actionText: 'button'.tr(gender: 'create'),
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
              ),
            ],
          );
        });
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
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
    return Consumer<PromotionController>(
      builder: (context, snapshot, child) {
        if (snapshot.promotionAllResponse == null) {
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
          return snapshot.promotionAllResponse == null || snapshot.promotionAllResponse!.data!.data!.isEmpty
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
              : GridView.count(
                  padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, screenPadding / 2),
                  childAspectRatio: 0.8,
                  shrinkWrap: true,
                  crossAxisCount: 5,
                  crossAxisSpacing: screenPadding,
                  mainAxisSpacing: 2.0,
                  primary: false,
                  children: [
                    for (int index = 0; index < (snapshot.promotionAllResponse?.data?.data?.length ?? 0); index++)
                      Consumer<DarkModeController>(builder: (context, darkMode, _) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return PromotionDetail(
                                    promotion: snapshot.promotionAllResponse!.data!.data![index],
                                  );
                                });
                          },
                          child: CardContainer(
                            elevation: 2.0,
                            // color: snapshot.cardColorGlobal,
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: screenPadding / 2),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AppPadding.vertical(denominator: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        statusTranslate(
                                            snapshot.promotionAllResponse?.data?.data?[index].promotionStatus),
                                        style: AppTypography.bodyMedium(context).apply(
                                            fontWeightDelta: 1,
                                            color: statusColor(
                                                '${snapshot.promotionAllResponse?.data?.data?[index].promotionStatus}')),
                                      )
                                    ],
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  Image.network(
                                    '${Environment.imageUrl}${snapshot.promotionAllResponse?.data?.data?[index].promotionImage}',
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          snapshot.promotionAllResponse?.data?.data?[index].promotionName ?? '',
                                          maxLines: 2,
                                          style: Theme.of(context).textTheme.bodyMedium!.apply(fontWeightDelta: 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                            'End Date: ${dateConverter(snapshot.promotionAllResponse?.data?.data?[index].promotionEndDate, format: 'dd-MM-yyyy')}',
                                            maxLines: 2,
                                            style: Theme.of(context).textTheme.bodyMedium),
                                      ),
                                    ],
                                  ),
                                  AppPadding.horizontal(),
                                ],
                              ),
                            ),
                            margin: EdgeInsets.zero,
                          ),
                        );
                      }),
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
    PromotionController.getAll(
      context,
      // DeviceRequest(
      //   orderReference: (_orderReferenceController.text != '') ? _orderReferenceController.text : null,
      //   page: _page,
      //   pageSize: _pageSize,
      // ),
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalPage = ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        context.read<PromotionController>().promotionAllResponse = value;
        // _page = 0;
      } else if (value.code == 404) {}
      return null;
    });
  }

  void getData({int? page}) async {
    showLoading();
  }

  resetAllFilter() {
    _orderReferenceController.text = '';
    rebuildDropdown.add(DateTime.now());
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
}
