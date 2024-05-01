import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_request.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/models/voucher/voucher_all_response.dart' as voucher;
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class PointDetail extends StatefulWidget {
  final UserResponse? user;
  const PointDetail({super.key, required this.user});

  @override
  State<PointDetail> createState() => _PointDetailState();
}

class _PointDetailState extends State<PointDetail> {
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _userFullname = TextEditingController();
  DropdownAttribute? _selectedVoucher;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();

  @override
  void initState() {
    _userFullname.text = widget.user?.userFullname ?? '';
    VoucherController.getAll(context).then((value) => context.read<VoucherController>().voucherAllResponse = value);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return editUser();
  }

  editUser() {
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
                              'Create User Points',
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
                                      controller: _userName,
                                      labelText: 'information'.tr(gender: 'username'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _userFullname,
                                      labelText: 'information'.tr(gender: 'fullName'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  AppPadding.vertical(denominator: 2),
                                  AppPadding.vertical(denominator: 2),
                                ],
                              ),
                            ),
                            AppPadding.horizontal(),
                            SizedBox(
                              width: screenWidth1728(30),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  AppPadding.vertical(denominator: 2),
                                  AppPadding.vertical(denominator: 2),
                                  Row(
                                    children: [
                                      AppDropdown(
                                        attributeList: DropdownAttributeList(
                                          [
                                            if (context.read<VoucherController>().voucherAllResponse?.data?.data !=
                                                null)
                                              for (voucher.Data item
                                                  in context.read<VoucherController>().voucherAllResponse?.data?.data ??
                                                      [])
                                                DropdownAttribute(item.voucherId ?? '', item.voucherName ?? ''),
                                          ],
                                          onChanged: (selected) {
                                            setState(() {
                                              _selectedVoucher = selected;
                                            });
                                          },
                                          value: _selectedVoucher?.name,
                                          width: screenWidth1728(30),
                                        ),
                                      ),
                                    ],
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                ],
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
                                showLoading();
                                PointManagementController.create(
                                  context,
                                  CreatePointRequest(
                                    userId: widget.user?.userId,
                                    pointType: 2,
                                    voucherId: _selectedVoucher?.key,
                                  ),
                                ).then((value) {
                                  if (responseCode(value.code)) {
                                    UserController.getAll(
                                      context,
                                    ).then((value) {
                                      dismissLoading();
                                      if (responseCode(value.code)) {
                                        context.read<UserController>().userAllResponse = value.data;
                                        context.pop();
                                        showDialogSuccess(context, 'Successfully created customer');
                                      } else {
                                        context.pop();
                                        showDialogSuccess(context, 'Successfully created customer information');
                                      }
                                    });
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
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }
}
