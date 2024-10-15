import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/create_point_request.dart';
import 'package:klinik_aurora_portal/models/reward/reward_all_response.dart' as reward;
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
  final TextEditingController _userPoints = TextEditingController();
  final TextEditingController _points = TextEditingController();
  DropdownAttribute? _selectedVoucher;
  DropdownAttribute? _selectedType;
  DropdownAttribute? _selectedReward;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  voucher.Data? selectedVoucher;
  reward.Data? selectedReward;

  @override
  void initState() {
    _userFullname.text = widget.user?.userFullname ?? '';
    _userName.text = widget.user?.userName ?? '';
    _userPoints.text = widget.user?.totalPoint == null ? '0' : widget.user?.totalPoint.toString() ?? '';
    if (context.read<VoucherController>().voucherAllResponse == null) {
      VoucherController.getAll(context, 1, pageSize).then((value) {
        context.read<VoucherController>().voucherAllResponse = value;
      });
    }
    if (context.read<RewardController>().rewardAllResponse == null) {
      RewardController.getAll(context, 1, pageSize).then((value) {
        context.read<RewardController>().rewardAllResponse = value;
      });
    }
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
                              'Points Management',
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
                                      isEditable: false,
                                      labelText: 'information'.tr(gender: 'username'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _userFullname,
                                      isEditable: false,
                                      labelText: 'information'.tr(gender: 'fullName'),
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  InputField(
                                    field: InputFieldAttribute(
                                      controller: _userPoints,
                                      isEditable: false,
                                      labelText: 'User Points',
                                    ),
                                  ),
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
                                  Row(
                                    children: [
                                      StreamBuilder<DateTime>(
                                          stream: rebuildDropdown.stream,
                                          builder: (context, snapshot) {
                                            return AppDropdown(
                                              attributeList: DropdownAttributeList(
                                                [
                                                  DropdownAttribute('', 'Points'),
                                                  // DropdownAttribute('1', 'REFERRAL'),
                                                  DropdownAttribute('2', 'Voucher'),
                                                  DropdownAttribute('3', 'Reward'),
                                                ],
                                                onChanged: (selected) {
                                                  setState(() {
                                                    _selectedType = selected;
                                                    print('_selectedType?.key ${_selectedType?.key}');
                                                    selectedReward;
                                                    _selectedVoucher = null;
                                                    selectedVoucher = null;
                                                    selectedReward = null;
                                                  });
                                                },
                                                hintText: 'Select an action',
                                                value: _selectedType?.name,
                                                width: screenWidth1728(30),
                                              ),
                                            );
                                          }),
                                    ],
                                  ),
                                  if (_selectedType?.key == '2' || _selectedType?.key == '3')
                                    AppPadding.vertical(denominator: 2),
                                  if (_selectedType?.key == '2')
                                    Row(
                                      children: [
                                        StreamBuilder<DateTime>(
                                            stream: rebuildDropdown.stream,
                                            builder: (context, snapshot) {
                                              return AppDropdown(
                                                attributeList: DropdownAttributeList(
                                                  [
                                                    if (context
                                                            .read<VoucherController>()
                                                            .voucherAllResponse
                                                            ?.data
                                                            ?.data !=
                                                        null)
                                                      for (voucher.Data item in context
                                                              .read<VoucherController>()
                                                              .voucherAllResponse
                                                              ?.data
                                                              ?.data ??
                                                          [])
                                                        DropdownAttribute(item.voucherId ?? '',
                                                            '${item.voucherName} (${item.voucherCode})'),
                                                  ],
                                                  onChanged: (selected) {
                                                    setState(() {
                                                      try {
                                                        selectedVoucher = context
                                                            .read<VoucherController>()
                                                            .voucherAllResponse
                                                            ?.data
                                                            ?.data!
                                                            .firstWhere(
                                                                (element) => element.voucherId == selected?.key);
                                                        _points.text = selectedVoucher?.voucherPoint?.toString() ?? '';
                                                      } catch (e) {
                                                        debugPrint(e.toString());
                                                      }
                                                      _selectedVoucher = selected;
                                                    });
                                                  },
                                                  hintText: 'Select a voucher',
                                                  value: _selectedVoucher?.name,
                                                  width: screenWidth1728(30),
                                                ),
                                              );
                                            }),
                                      ],
                                    ),
                                  if (_selectedType?.key == '3')
                                    Row(
                                      children: [
                                        StreamBuilder<DateTime>(
                                            stream: rebuildDropdown.stream,
                                            builder: (context, snapshot) {
                                              return AppDropdown(
                                                attributeList: DropdownAttributeList(
                                                  [
                                                    if (context
                                                            .read<RewardController>()
                                                            .rewardAllResponse
                                                            ?.data
                                                            ?.data !=
                                                        null)
                                                      for (reward.Data item in context
                                                              .read<RewardController>()
                                                              .rewardAllResponse
                                                              ?.data
                                                              ?.data ??
                                                          [])
                                                        DropdownAttribute(item.rewardId ?? '',
                                                            '${item.rewardName} (${item.rewardPoint}pts)'),
                                                  ],
                                                  onChanged: (selected) {
                                                    setState(() {
                                                      try {
                                                        selectedReward = context
                                                            .read<RewardController>()
                                                            .rewardAllResponse
                                                            ?.data
                                                            ?.data!
                                                            .firstWhere((element) => element.rewardId == selected?.key);
                                                        _points.text = selectedReward?.rewardPoint?.toString() ?? '';
                                                      } catch (e) {
                                                        debugPrint(e.toString());
                                                      }
                                                      _selectedVoucher = selected;
                                                    });
                                                  },
                                                  hintText: 'Select a reward',
                                                  value: _selectedReward?.name,
                                                  width: screenWidth1728(30),
                                                ),
                                              );
                                            }),
                                      ],
                                    ),
                                  AppPadding.vertical(denominator: 2),
                                  if (_selectedType != null)
                                    InputField(
                                      field: InputFieldAttribute(
                                        controller: _points,
                                        isEditable: _selectedType?.key == '' ? true : false,
                                        isNumber: true,
                                        labelText: 'Points',
                                      ),
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
                                if (validate()) {
                                  showLoading();
                                  PointManagementController.create(
                                    context,
                                    CreatePointRequest(
                                      userId: widget.user?.userId,
                                      pointType: _selectedType?.key != null && _selectedType?.key != ''
                                          ? int.parse(_selectedType!.key)
                                          : null,
                                      totalPoint: _selectedType?.key == '' ? int.parse(_points.text) : null,
                                      voucherId: _selectedVoucher?.key,
                                      rewardId: _selectedReward?.key,
                                    ),
                                  ).then((value) {
                                    if (responseCode(value.code)) {
                                      if (_selectedType?.key == '3') {}
                                      postAction();
                                    } else {
                                      showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                    }
                                  });
                                }
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

  postAction() {
    PointManagementController.get(context, userId: widget.user?.userId).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        context.read<PointManagementController>().userPointsResponse = value.data;
        context.pop();
        showDialogSuccess(context, 'Successfully created customer\'s points');
      } else {
        context.pop();
        showDialogSuccess(context, 'Successfully created customer\'s points');
      }
    });
  }

  bool validate() {
    bool temp = true;
    if (_selectedType == null) {
      showDialogError(context, 'Please select one of the action');
      temp = false;
    } else if (_selectedType?.key == '2') {
      if ((selectedVoucher == null)) {
        showDialogError(context, 'Please select one of the voucher');
        temp = false;
      }
    } else if (_selectedType?.key == '3') {
      if ((selectedReward == null)) {
        showDialogError(context, 'Please select one of the rewards');
        temp = false;
      } else if ((selectedReward?.rewardPoint ?? 0) > (widget.user?.totalPoint ?? 0)) {
        temp = false;
        showDialogError(context, 'User points is insufficient to redeem the reward');
      }
    }
    return temp;
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }
}
