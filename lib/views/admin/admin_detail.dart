import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/admin/admin_controller.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/permission/permission_controller.dart';
import 'package:klinik_aurora_portal/models/admin/admin_all_response.dart' as admin;
import 'package:klinik_aurora_portal/models/admin/create_admin_request.dart';
import 'package:klinik_aurora_portal/models/admin/permission_admin_response.dart' as admin_permission;
import 'package:klinik_aurora_portal/models/admin/update_admin_request.dart';
import 'package:klinik_aurora_portal/models/admin/update_permission_admin_request.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';
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

class AdminDetail extends StatefulWidget {
  final admin.Data? user;
  final String type;
  const AdminDetail({super.key, this.user, required this.type});

  @override
  State<AdminDetail> createState() => _AdminDetailState();
}

class _AdminDetailState extends State<AdminDetail> {
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _userFullname = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _branchId = TextEditingController();
  final TextEditingController _userPhone = TextEditingController();
  final TextEditingController _userEmail = TextEditingController();
  final ValueNotifier<bool> _userStatus = ValueNotifier(false);
  bool allowEditableField = true;
  DropdownAttribute? _selectedBranch;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();
  StreamController<DateTime> validateRebuild = StreamController.broadcast();
  List<admin_permission.Data> currentPermissionList = [];
  List<String> selectedPermission = [];

  @override
  void initState() {
    if (widget.type == 'update') {
      AdminController.getPermission(context, widget.user!.userId!).then(
        (value) {
          if (responseCode(value.code)) {
            setState(() {
              currentPermissionList = value.data?.data ?? [];
              for (admin_permission.Data item in value.data?.data ?? []) {
                selectedPermission.add(item.permissionId!);
              }
            });
          }
        },
      );
      setState(() {
        allowEditableField = false;
      });
      _userName.text = widget.user?.userName ?? '';
      _userFullname.text = widget.user?.userFullname ?? '';
      _branchId.text = widget.user?.branchId ?? '';
      _userPhone.text = widget.user?.userPhone?.substring(1, widget.user?.userPhone?.length) ?? '';
      _userEmail.text = widget.user?.userEmail ?? '';
      _userStatus.value = widget.user?.userStatus == 1;
    }
    try {
      if (widget.user?.branchId != null) {
        Data? branch = context
            .read<BranchController>()
            .branchAllResponse
            ?.data
            ?.data
            ?.firstWhere((element) => element.branchId == widget.user!.branchId);
        if (branch != null) {
          setState(() {
            _selectedBranch = DropdownAttribute(branch.branchId ?? '', branch.branchName ?? '');
          });
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return editAdmin();
  }

  editAdmin() {
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
                              'Admin Details',
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
                                      isEditable: allowEditableField,
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
                                  // InputField(
                                  //   field: InputFieldAttribute(
                                  //     controller: _userPhone,
                                  //     labelText: 'information'.tr(gender: 'phoneNo'),
                                  //     isNumber: true,
                                  //     maxCharacter: 10,
                                  //     prefixIcon: Row(
                                  //       mainAxisSize: MainAxisSize.min,
                                  //       crossAxisAlignment: CrossAxisAlignment.center,
                                  //       children: [
                                  //         Padding(
                                  //           padding: EdgeInsets.only(right: screenPadding / 2, left: 12),
                                  //           child: const Text(
                                  //             '+60',
                                  //             style: TextStyle(
                                  //                 fontWeight: FontWeight.w700, fontSize: 15.0, color: textPrimaryColor),
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // ),
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
                                    field: InputFieldAttribute(
                                      controller: _userEmail,
                                      labelText: 'information'.tr(gender: 'email'),
                                      isEmail: true,
                                      isEditable: allowEditableField,
                                    ),
                                  ),
                                  AppPadding.vertical(denominator: 2),
                                  Row(
                                    children: [
                                      AppDropdown(
                                        attributeList: DropdownAttributeList(
                                          [
                                            if (context.read<BranchController>().branchAllResponse?.data?.data != null)
                                              for (Data item
                                                  in context.read<BranchController>().branchAllResponse?.data?.data ??
                                                      [])
                                                DropdownAttribute(item.branchId ?? '', item.branchName ?? ''),
                                          ],
                                          onChanged: (selected) {
                                            setState(() {
                                              _selectedBranch = selected;
                                              _branchId.text = selected!.name;
                                            });
                                          },
                                          value: _selectedBranch?.name,
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSelectableText(
                              'Permission',
                              style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                            ),
                            AppPadding.vertical(denominator: 3),
                            SizedBox(
                              width: screenWidth(80),
                              child: Wrap(
                                direction: Axis.horizontal,
                                children: [
                                  for (int index = 0;
                                      index <
                                          (context.read<PermissionController>().permissionAllResponse?.data?.length ??
                                              0);
                                      index++)
                                    Container(
                                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Checkbox(
                                            value: selectedPermission.contains(context
                                                .read<PermissionController>()
                                                .permissionAllResponse
                                                ?.data?[index]
                                                .permissionId),
                                            onChanged: (value) {
                                              try {
                                                setState(() {
                                                  if (value == true) {
                                                    selectedPermission.add(context
                                                        .read<PermissionController>()
                                                        .permissionAllResponse!
                                                        .data![index]
                                                        .permissionId
                                                        .toString());
                                                  } else {
                                                    selectedPermission.removeWhere((element) =>
                                                        element ==
                                                        context
                                                            .read<PermissionController>()
                                                            .permissionAllResponse!
                                                            .data![index]
                                                            .permissionId
                                                            .toString());
                                                  }
                                                });
                                              } catch (e) {
                                                showDialogError(context, e.toString());
                                              }
                                            },
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Text(
                                              '${context.read<PermissionController>().permissionAllResponse!.data![index].permissionName}'),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            AppPadding.vertical(denominator: 3 / 2),
                          ],
                        ),
                        button()
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

  Widget button() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Button(
          () {
            showLoading();
            if (widget.type == 'update') {
              AdminController.update(
                context,
                UpdateAdminRequest(
                  userId: widget.user?.userId,
                  userFullname: _userFullname.text,
                  branchId: _selectedBranch?.key,
                  userPhone: '0${_userPhone.text}',
                  userStatus: _userStatus.value ? 1 : 0,
                ),
              ).then((value) {
                if (responseCode(value.code)) {
                  AdminController.updatePermission(
                    context,
                    UpdatePermissionAdminRequest(
                      userId: widget.user!.userId,
                      permissionIds: selectedPermission,
                    ),
                  ).then((value) {
                    if (responseCode(value.code)) {
                      AdminController.getAll(
                        context,
                      ).then((value) {
                        dismissLoading();
                        if (responseCode(value.code)) {
                          context.read<AdminController>().adminAllResponse = value.data;
                          context.pop();
                          showDialogSuccess(context, 'Successfully updated admin information');
                        } else {
                          context.pop();
                          showDialogSuccess(context, 'Successfully updated admin information');
                        }
                      });
                    } else {
                      showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                    }
                  });
                } else {
                  showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            } else {
              AdminController.create(
                context,
                CreateAdminRequest(
                  userName: _userName.text,
                  userFullname: _userFullname.text,
                  userPhone: '0${_userPhone.text}',
                  userEmail: _userEmail.text,
                  userPassword: _password.text,
                  userRetypePassword: _password.text,
                  branchId: _selectedBranch?.key,
                ),
              ).then((value) {
                if (responseCode(value.code)) {
                  if (responseCode(value.code)) {
                    AdminController.updatePermission(
                      context,
                      UpdatePermissionAdminRequest(
                        userId: widget.user!.userId,
                        permissionIds: selectedPermission,
                      ),
                    ).then((updateResponse) {
                      dismissLoading();
                      if (responseCode(updateResponse.code)) {
                        showLoading();
                        AdminController.getAll(
                          context,
                        ).then((adminResponse) {
                          dismissLoading();
                          if (responseCode(adminResponse.code)) {
                            context.read<AdminController>().adminAllResponse = adminResponse.data;
                            context.pop();
                            showDialogSuccess(context, 'Successfully created admin');
                          } else {
                            context.pop();
                            showDialogSuccess(context, 'Successfully created admin');
                          }
                        });
                      } else {
                        showDialogError(context, updateResponse.data?.message ?? 'ERROR : ${updateResponse.code}');
                      }
                    });
                  }
                } else {
                  showDialogError(context, value.data?.message ?? 'ERROR : ${value.code}');
                }
              });
            }
          },
          actionText: 'button'.tr(gender: widget.type),
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
