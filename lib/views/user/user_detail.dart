import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';
import 'package:klinik_aurora_portal/models/user/create_user_request.dart';
import 'package:klinik_aurora_portal/models/user/update_user_request.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/error_message.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class UserDetail extends StatefulWidget {
  final UserResponse? user;
  final String type;
  const UserDetail({super.key, this.user, required this.type});

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  InputFieldAttribute usernameAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'username'),
  );
  InputFieldAttribute fullNameAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'fullName'),
  );
  InputFieldAttribute passwordAttribute = InputFieldAttribute(controller: TextEditingController());
  InputFieldAttribute dobAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    isEditable: false,
    labelText: 'information'.tr(gender: 'dob'),
    suffixWidget: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.calendar_month,
        ),
      ],
    ),
  );
  InputFieldAttribute phoneAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'phoneNo'),
    isNumber: true,
    maxCharacter: 10,
    prefixIcon: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: screenPadding / 2, left: 12),
          child: const Text(
            '+60',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.0, color: textPrimaryColor),
          ),
        ),
      ],
    ),
  );
  InputFieldAttribute emailAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'email'),
    isEmail: true,
  );
  InputFieldAttribute branchIdAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'registeredBranch'),
  );
  final ValueNotifier<bool> _userStatus = ValueNotifier(false);
  DropdownAttribute? _selectedBranch;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> rebuild = StreamController.broadcast();

  @override
  void initState() {
    if (widget.type == 'update') {
      usernameAttribute.controller.text = widget.user?.userName ?? '';
      fullNameAttribute.controller.text = widget.user?.userFullname ?? '';
      branchIdAttribute.controller.text = widget.user?.branchId ?? '';
      dobAttribute.controller.text = dateConverter(widget.user?.userDob, format: 'dd-MM-yyyy') ?? '';
      phoneAttribute.controller.text = widget.user?.userPhone?.substring(1, widget.user?.userPhone?.length) ?? '';
      emailAttribute.controller.text = widget.user?.userEmail ?? '';
      _userStatus.value = widget.user?.userStatus == 1;
    }
    try {
      Data? branch = context
          .read<BranchController>()
          .branchAllResponse
          ?.data
          ?.data
          ?.firstWhere((element) => element.branchId == branchIdAttribute.controller.text);
      if (branch != null) {
        setState(() {
          _selectedBranch = DropdownAttribute(branch.branchId ?? '', branch.branchName ?? '');
        });
      }
    } catch (e) {
      debugPrint(e.toString());
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
        StreamBuilder<DateTime>(
            stream: rebuild.stream,
            builder: (context, snapshot) {
              return SingleChildScrollView(
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
                                    'User Details',
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
                                          field: usernameAttribute,
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(
                                          field: fullNameAttribute,
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        GestureDetector(
                                          onTap: () async {
                                            var results = await showCalendarDatePicker2Dialog(
                                              context: context,
                                              config: CalendarDatePicker2WithActionButtonsConfig(
                                                lastDate: DateTime.now(),
                                              ),
                                              dialogSize: Size(screenWidth1728(60), screenHeight829(60)),
                                              borderRadius: BorderRadius.circular(15),
                                            );
                                            if (results != null) {
                                              if (dobAttribute.errorMessage != null) {
                                                dobAttribute.errorMessage = null;
                                                rebuild.add(DateTime.now());
                                              }
                                              dobAttribute.controller.text =
                                                  dateConverter('${results.first}', format: 'dd-MM-yyyy') ?? '';
                                            }
                                          },
                                          child: ReadOnly(
                                            InputField(
                                              field: dobAttribute,
                                            ),
                                            isEditable: false,
                                          ),
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        // if (widget.type == 'create') ...[
                                        //   InputField(
                                        //     field: InputFieldAttribute(
                                        //       controller: _password,
                                        //       labelText: 'information'.tr(gender: 'password'),
                                        //     ),
                                        //   ),
                                        //   AppPadding.vertical(denominator: 2),
                                        // ],
                                      ],
                                    ),
                                  ),
                                  AppPadding.horizontal(),
                                  SizedBox(
                                    width: screenWidth1728(30),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        InputField(
                                          field: phoneAttribute,
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        InputField(
                                          field: emailAttribute,
                                        ),
                                        AppPadding.vertical(denominator: 2),
                                        Row(
                                          children: [
                                            AppDropdown(
                                              attributeList: DropdownAttributeList(
                                                [
                                                  if (context.read<BranchController>().branchAllResponse?.data?.data !=
                                                      null)
                                                    for (Data item in context
                                                            .read<BranchController>()
                                                            .branchAllResponse
                                                            ?.data
                                                            ?.data ??
                                                        [])
                                                      DropdownAttribute(item.branchId ?? '', item.branchName ?? ''),
                                                ],
                                                onChanged: (selected) {
                                                  setState(() {
                                                    _selectedBranch = selected;
                                                    branchIdAttribute.errorMessage = null;
                                                    branchIdAttribute.controller.text = selected!.name;
                                                  });
                                                },
                                                value: _selectedBranch?.name,
                                                width: screenWidth1728(30),
                                                errorMessage: branchIdAttribute.errorMessage,
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
                                      if (validate()) {
                                        showLoading();
                                        if (widget.type == 'update') {
                                          UserController.update(
                                            context,
                                            UpdateUserRequest(
                                              userId: widget.user?.userId,
                                              userName: usernameAttribute.controller.text,
                                              userFullname: fullNameAttribute.controller.text,
                                              userDob: convertStringToDate(dobAttribute.controller.text),
                                              userPhone: '0${phoneAttribute.controller.text}',
                                              branchId: _selectedBranch?.key,
                                              userStatus: _userStatus.value ? 1 : 0,
                                            ),
                                          ).then((value) {
                                            if (responseCode(value.code)) {
                                              UserController.getAll(context, '', '', '').then((value) {
                                                dismissLoading();
                                                if (responseCode(value.code)) {
                                                  context.read<UserController>().userAllResponse = value.data?.data;
                                                  context.pop();
                                                  showDialogSuccess(
                                                      context, 'Successfully updated customer information');
                                                } else {
                                                  context.pop();
                                                  showDialogSuccess(
                                                      context, 'Successfully updated customer information');
                                                }
                                              });
                                            } else {
                                              showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                            }
                                          });
                                        } else {
                                          UserController.create(
                                            context,
                                            CreateUserRequest(
                                              userName: usernameAttribute.controller.text,
                                              userFullname: fullNameAttribute.controller.text,
                                              userPhone: '0${phoneAttribute.controller.text}',
                                              userEmail: emailAttribute.controller.text,
                                              userDob: convertStringToDate(dobAttribute.controller.text),
                                              userPassword: 'aurora123',
                                              userRetypePassword: 'aurora123',
                                              branchId: _selectedBranch?.key,
                                            ),
                                          ).then((value) {
                                            if (responseCode(value.code)) {
                                              UserController.getAll(context, '', '', '').then((value) {
                                                dismissLoading();
                                                if (responseCode(value.code)) {
                                                  context.read<UserController>().userAllResponse = value.data?.data;
                                                  context.pop();
                                                  showDialogSuccess(context, 'Successfully created customer');
                                                } else {
                                                  context.pop();
                                                  showDialogSuccess(
                                                      context, 'Successfully created customer information');
                                                }
                                              });
                                            } else {
                                              showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                                            }
                                          });
                                        }
                                      }
                                    },
                                    actionText: 'button'.tr(gender: widget.type),
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
              );
            }),
      ],
    );
  }

  bool validate() {
    bool temp = true;
    if (fullNameAttribute.controller.text == '') {
      temp = false;
      fullNameAttribute.errorMessage = ErrorMessage.required(field: fullNameAttribute.labelText);
    }
    if (usernameAttribute.controller.text == '') {
      temp = false;
      usernameAttribute.errorMessage = ErrorMessage.required(field: usernameAttribute.labelText);
    }
    if (emailAttribute.controller.text == '') {
      temp = false;
      emailAttribute.errorMessage = ErrorMessage.required(field: emailAttribute.labelText);
    }
    if (phoneAttribute.controller.text == '') {
      temp = false;
      phoneAttribute.errorMessage = ErrorMessage.required(field: phoneAttribute.labelText);
    }
    if (dobAttribute.controller.text == '') {
      temp = false;
      dobAttribute.errorMessage = ErrorMessage.required(field: dobAttribute.labelText);
    }
    if (branchIdAttribute.controller.text == '') {
      temp = false;
      branchIdAttribute.errorMessage = ErrorMessage.required(field: branchIdAttribute.labelText);
    }
    if (branchIdAttribute.controller.text == '') {
      temp = false;
      branchIdAttribute.errorMessage = ErrorMessage.required(field: branchIdAttribute.labelText);
    }
    rebuild.add(DateTime.now());
    return temp;
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }
}
