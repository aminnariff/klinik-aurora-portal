import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
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
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';
import 'package:klinik_aurora_portal/models/permission/permission_all_response.dart' as model_permission;
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
  List<DropdownAttribute> branches = [];
  final Map<String, List<String>> permissionBundles = {
    'Branch': [
      '1bda631e-ef17-11ee-bd1b-cc801b09db2f', //User Management
      '3b8e7d9d-ac51-11ef-a1b7-bc24115a1342', //Appointment
      'dc4e7a5a-0e15-11ef-82b0-94653af51fb9', //Reward Management
      '0699ac1c-ac52-11ef-a1b7-bc24115a1342', //Service
      'f57576c4-4d15-11f0-b054-1ff6746392b2', //Payment
      'a231db36-058d-11ef-943b-626efeb17d5e', //Point Management
      'f90f9f18-057b-11ef-943b-626efeb17d5e', //Doctor
    ],
    'Sonographer': ['c54a2d91-499c-11f0-9169-bc24115a1342'], //Sonographer
  };

  @override
  void initState() {
    if (widget.type == 'update') {
      AdminController.getPermission(context, widget.user!.userId!).then((value) {
        if (responseCode(value.code)) {
          setState(() {
            currentPermissionList = value.data?.data ?? [];
            for (admin_permission.Data item in value.data?.data ?? []) {
              selectedPermission.add(item.permissionId!);
            }
          });
        }
      });
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
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (context.read<BranchController>().branchAllResponse != null) {
        for (branch_model.Data item in context.read<BranchController>().branchAllResponse?.data?.data ?? []) {
          branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
        }
        branches.sort((a, b) {
          final nameA = a.name.toLowerCase();
          final nameB = b.name.toLowerCase();
          return nameA.compareTo(nameB);
        });
        rebuildDropdown.add(DateTime.now());
      }
    });
    try {
      if (widget.user?.branchId != null) {
        Data? branch = context.read<BranchController>().branchAllResponse?.data?.data?.firstWhere(
          (element) => element.branchId == widget.user!.branchId,
        );
        if (branch != null) {
          _selectedBranch = DropdownAttribute(branch.branchId ?? '', branch.branchName ?? '');
          rebuildDropdown.add(DateTime.now());
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

  Widget buildPermissionBundles({
    required Map<String, List<String>> permissionBundles,
    required List<String> selectedPermission,
    required Function(List<String>) onPermissionChanged,
    required List<model_permission.Data> allPermissions,
  }) {
    final Map<String, String> permissionIdToName = {for (var p in allPermissions) p.permissionId!: p.permissionName!};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: permissionBundles.entries.map((entry) {
        final bundleName = entry.key;
        final bundleIds = entry.value;

        final permissionNames = bundleIds.map((id) => permissionIdToName[id] ?? 'Unknown').join(', ');

        final isChecked = bundleIds.every((id) => selectedPermission.contains(id));

        return Tooltip(
          message: permissionNames,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isChecked,
                onChanged: (bool? value) {
                  final newSelected = [...selectedPermission];
                  if (value == true) {
                    for (final id in bundleIds) {
                      if (!newSelected.contains(id)) {
                        newSelected.add(id);
                      }
                    }
                  } else {
                    newSelected.removeWhere((id) => bundleIds.contains(id));
                  }
                  onPermissionChanged(newSelected);
                },
              ),
              Text(bundleName),
            ],
          ),
        );
      }).toList(),
    );
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
                            AppSelectableText('Admin Details', style: AppTypography.bodyLarge(context)),
                            CloseButton(
                              onPressed: () {
                                context.pop();
                              },
                            ),
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
                                  if (widget.type == 'create') ...[
                                    InputField(
                                      field: InputFieldAttribute(
                                        controller: _password,
                                        labelText: 'information'.tr(gender: 'password'),
                                      ),
                                    ),
                                    AppPadding.vertical(denominator: 2),
                                  ],
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
                                  StreamBuilder<DateTime>(
                                    stream: rebuildDropdown.stream,
                                    builder: (context, snapshot) {
                                      return Row(
                                        children: [
                                          AppDropdown(
                                            attributeList: DropdownAttributeList(
                                              branches,
                                              isEditable: true,
                                              onChanged: (selected) {
                                                _selectedBranch = selected;
                                                _branchId.text = selected!.name;
                                                rebuildDropdown.add(DateTime.now());
                                              },
                                              value: _selectedBranch?.name,
                                              width: screenWidth1728(30),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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
                            buildPermissionBundles(
                              permissionBundles: permissionBundles,
                              selectedPermission: selectedPermission,
                              allPermissions: context.read<PermissionController>().permissionAllResponse?.data ?? [],
                              onPermissionChanged: (newList) {
                                setState(() {
                                  selectedPermission = newList;
                                });
                              },
                            ),
                            SizedBox(height: 16),
                            Container(
                              width: screenWidth(80),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey, // Border color
                                  width: 1.5, // Border width
                                ),
                                borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Wrap(
                                  spacing: 24,
                                  runSpacing: 12,
                                  children: List.generate(
                                    context.read<PermissionController>().permissionAllResponse?.data?.length ?? 0,
                                    (index) {
                                      final permission = context
                                          .read<PermissionController>()
                                          .permissionAllResponse!
                                          .data![index];
                                      final isChecked = selectedPermission.contains(permission.permissionId);

                                      return SizedBox(
                                        width: 180,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Checkbox(
                                              value: isChecked,
                                              onChanged: (value) {
                                                try {
                                                  setState(() {
                                                    if (value == true) {
                                                      selectedPermission.add(permission.permissionId!);
                                                    } else {
                                                      selectedPermission.remove(permission.permissionId!);
                                                    }
                                                  });
                                                } catch (e) {
                                                  showDialogError(context, e.toString());
                                                }
                                              },
                                            ),
                                            Expanded(
                                              child: Text(
                                                permission.permissionName ?? '',
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context).textTheme.bodyMedium,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: screenWidth(80),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Note:\nThe checkboxes labeled Branch and Sonographer are permission bundles — selecting them will automatically select a group of related permissions.\nYou can still manually customize individual permissions as needed.',
                                      style: AppTypography.bodyMedium(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        ),
                        button(),
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
        Button(() {
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
                  UpdatePermissionAdminRequest(userId: widget.user!.userId, permissionIds: selectedPermission),
                ).then((value) {
                  if (responseCode(value.code)) {
                    AdminController.getAll(context, 1, pageSize).then((value) {
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
                    showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
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
                    UpdatePermissionAdminRequest(userId: widget.user!.userId, permissionIds: selectedPermission),
                  ).then((updateResponse) {
                    dismissLoading();
                    if (responseCode(updateResponse.code)) {
                      showLoading();
                      AdminController.getAll(context, 1, pageSize).then((adminResponse) {
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
        }, actionText: 'button'.tr(gender: widget.type)),
      ],
    );
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }
}
