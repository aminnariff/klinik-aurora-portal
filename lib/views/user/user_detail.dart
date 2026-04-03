import 'dart:async';

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
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
    maxCharacter: 20,
    isAlphaNumericOnly: true,
    isEditable: true,
    labelText: 'information'.tr(gender: 'username'),
  );
  InputFieldAttribute fullNameAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'fullName'),
  );
  InputFieldAttribute passwordAttribute = InputFieldAttribute(controller: TextEditingController());
  TextEditingController nricController = TextEditingController();
  InputFieldAttribute dobAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'dob'),
    suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month)]),
  );
  InputFieldAttribute phoneAttribute = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'information'.tr(gender: 'phoneNo'),
    isNumber: true,
    maxCharacter: 13,
    prefixIcon: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: EdgeInsets.only(right: screenPadding / 2, left: 12),
          child: const Text(
            '🇲🇾',
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
  List<DropdownAttribute> branches = [];

  @override
  void initState() {
    if (widget.type == 'update') {
      usernameAttribute.controller.text = widget.user?.userName ?? '';
      fullNameAttribute.controller.text = widget.user?.userFullname ?? '';
      branchIdAttribute.controller.text = widget.user?.branchId ?? '';
      dobAttribute.controller.text = dateConverter(widget.user?.userDob, format: 'dd-MM-yyyy') ?? '';
      nricController.text = widget.user?.userNric ?? '';
      phoneAttribute.controller.text = widget.user?.userPhone ?? '';
      emailAttribute.controller.text = widget.user?.userEmail ?? '';
      _userStatus.value = widget.user?.userStatus == 1;
    }
    try {
      if (context.read<BranchController>().branchAllResponse == null) {
        BranchController.getAll(context, 1, 100).then((value) {
          if (responseCode(value.code)) {
            context.read<BranchController>().branchAllResponse = value;
          }
        });
      }
      for (branch_model.Data item in context.read<BranchController>().branchAllResponse?.data?.data ?? []) {
        branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
      }
      branches.sort((a, b) {
        final nameA = a.name.toLowerCase();
        final nameB = b.name.toLowerCase();
        return nameA.compareTo(nameB);
      });
      rebuildDropdown.add(DateTime.now());
      try {
        Data? branch = context.read<BranchController>().branchAllResponse?.data?.data?.firstWhere(
          (element) => element.branchId == branchIdAttribute.controller.text,
        );
        if (branch != null) {
          setState(() {
            _selectedBranch = DropdownAttribute(branch.branchId ?? '', branch.branchName ?? '');
          });
        }
      } catch (e) {
        debugPrint(e.toString());
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

  Widget _sectionLabel(String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 3, height: 13, decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Icon(icon, size: 13, color: const Color(0xFF6B7280)),
        const SizedBox(width: 5),
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF6B7280), letterSpacing: 1.0)),
      ],
    );
  }

  Row editUser() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: StreamBuilder<DateTime>(
            stream: rebuild.stream,
            builder: (context, snapshot) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CardContainer(
                      IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Header ──────────────────────────────────────
                            Container(
                              padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9FAFB),
                                border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: const Color(0xFFEEF2FF), borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.person_rounded, size: 16, color: Color(0xFF6366F1)),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.type == 'create' ? 'New Customer' : 'Edit Customer',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                      Text(
                                        widget.type == 'create' ? 'Register a new customer account' : 'Update customer profile and settings',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  CloseButton(onPressed: () => context.pop()),
                                ],
                              ),
                            ),
                            // ── Body ────────────────────────────────────────
                            Padding(
                              padding: EdgeInsets.all(screenPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Left: Personal Info
                                      SizedBox(
                                        width: screenWidth1728(26),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _sectionLabel('Personal Information', Icons.badge_outlined),
                                            const SizedBox(height: 12),
                                            if (widget.type == 'update')
                                              labelValue('Username', usernameAttribute.controller.text)
                                            else
                                              InputField(field: usernameAttribute),
                                            const SizedBox(height: 12),
                                            InputField(field: fullNameAttribute),
                                            const SizedBox(height: 12),
                                            GestureDetector(
                                              onTap: () async {
                                                var results = await showCalendarDatePicker2Dialog(
                                                  context: context,
                                                  config: CalendarDatePicker2WithActionButtonsConfig(
                                                    firstDate: DateTime(DateTime.now().year - 100),
                                                    lastDate: DateTime.now(),
                                                    calendarViewMode: CalendarDatePicker2Mode.year,
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
                                              child: ReadOnly(InputField(field: dobAttribute), isEditable: false),
                                            ),
                                            const SizedBox(height: 12),
                                            InputField(
                                              field: InputFieldAttribute(
                                                labelText: 'Document ID',
                                                helpText: 'If patient is a Malaysian, please enter their NRIC. Otherwise, provide their passport number.',
                                                controller: nricController,
                                                isEditable: true,
                                                maxCharacter: 12,
                                                isUpperCase: true,
                                                isAlphaNumericOnly: true,
                                                onChanged: (value) {
                                                  if (widget.user?.userDob == null) {
                                                    try {
                                                      if (value.length == 12 && int.tryParse(value) != null) {
                                                        try {
                                                          final dob = extractDobFromNric(value);
                                                          if (dob != null) {
                                                            dobAttribute.controller.text = dob;
                                                            dobAttribute.errorMessage = null;
                                                            rebuild.add(DateTime.now());
                                                          }
                                                        } catch (e) { debugPrint(e.toString()); }
                                                      }
                                                    } catch (e) { debugPrint(e.toString()); }
                                                  }
                                                },
                                              ),
                                            ),
                                            if (widget.type == 'update') ...[
                                              const SizedBox(height: 20),
                                              const Divider(color: Color(0xFFF3F4F6), thickness: 1),
                                              const SizedBox(height: 12),
                                              _sectionLabel('Record Info', Icons.history_rounded),
                                              const SizedBox(height: 10),
                                              labelValue('Created At', dateConverter(widget.user?.createdDate) ?? '—'),
                                              if (widget.user?.modifiedDate != null) ...[
                                                const SizedBox(height: 8),
                                                labelValue('Last Updated At', dateConverter(widget.user?.modifiedDate) ?? '—'),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                      AppPadding.horizontal(),
                                      // Right: Contact & Branch
                                      SizedBox(
                                        width: screenWidth1728(30),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _sectionLabel('Contact & Branch', Icons.contacts_outlined),
                                            const SizedBox(height: 12),
                                            InputField(field: phoneAttribute),
                                            const SizedBox(height: 12),
                                            if (widget.type == 'update')
                                              labelValue('Email', emailAttribute.controller.text)
                                            else
                                              InputField(
                                                field: InputFieldAttribute(
                                                  controller: emailAttribute.controller,
                                                  labelText: emailAttribute.labelText,
                                                  isEmail: true,
                                                  errorMessage: emailAttribute.errorMessage,
                                                ),
                                              ),
                                            const SizedBox(height: 12),
                                            StreamBuilder<DateTime>(
                                              stream: rebuildDropdown.stream,
                                              builder: (context, asyncSnapshot) {
                                                return AppDropdown(
                                                  attributeList: DropdownAttributeList(
                                                    branches,
                                                    onChanged: (selected) {
                                                      setState(() {
                                                        _selectedBranch = selected;
                                                        branchIdAttribute.errorMessage = null;
                                                        branchIdAttribute.controller.text = selected!.name;
                                                      });
                                                    },
                                                    value: _selectedBranch?.name,
                                                    hintText: 'Branch',
                                                    width: screenWidth1728(30),
                                                    errorMessage: branchIdAttribute.errorMessage,
                                                  ),
                                                );
                                              },
                                            ),
                                            if (widget.type == 'update') ...[
                                              const SizedBox(height: 20),
                                              const Divider(color: Color(0xFFF3F4F6), thickness: 1),
                                              const SizedBox(height: 12),
                                              _sectionLabel('Account Metadata', Icons.info_outline_rounded),
                                              const SizedBox(height: 10),
                                              labelValue('Created by', widget.user?.createdByAdmin == 1 ? 'Admin' : 'Patient'),
                                              const SizedBox(height: 8),
                                              labelValue(
                                                'T&C Status',
                                                widget.user?.tncAccepted == 1 || widget.user?.createdByAdmin == 0 ? 'Accepted' : 'Not Accepted',
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  const Divider(color: Color(0xFFF3F4F6), thickness: 1),
                                  const SizedBox(height: 12),
                                  if (widget.type == 'update')
                                    ValueListenableBuilder<bool>(
                                      valueListenable: _userStatus,
                                      builder: (context, status, _) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: status ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7F7),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: status ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                status ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                                                size: 18,
                                                color: status ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                              ),
                                              const SizedBox(width: 10),
                                              const Text('Account Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                                              const Spacer(),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: status ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  status ? 'Active' : 'Inactive',
                                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: status ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Switch(value: status, onChanged: (val) => _userStatus.value = val, activeThumbColor: const Color(0xFF15803D)),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Button(() {
                                        if (validate()) {
                                          showLoading();
                                          if (widget.type == 'update') {
                                            UserController.update(
                                              context,
                                              UpdateUserRequest(
                                                userId: widget.user?.userId,
                                                userName: widget.user?.userName ?? usernameAttribute.controller.text.trim(),
                                                userFullname: fullNameAttribute.controller.text.trim(),
                                                userNric: notNullOrEmptyString(nricController.text) ? nricController.text : null,
                                                userDob: convertStringToDate(dobAttribute.controller.text),
                                                userPhone: phoneAttribute.controller.text.trim(),
                                                branchId: _selectedBranch?.key,
                                                userStatus: _userStatus.value ? 1 : 0,
                                              ),
                                            ).then((value) {
                                              if (responseCode(value.code)) {
                                                UserController.getAll(context, 1, pageSize, userFullName: '', userName: '', userPhone: '').then((value) {
                                                  dismissLoading();
                                                  if (responseCode(value.code)) {
                                                    context.read<UserController>().userAllResponse = value.data?.data;
                                                    context.pop();
                                                    showDialogSuccess(context, 'Successfully updated customer information');
                                                  } else {
                                                    context.pop();
                                                    showDialogSuccess(context, 'Successfully updated customer information');
                                                  }
                                                });
                                              } else {
                                                showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                                              }
                                            });
                                          } else {
                                            UserController.create(
                                              context,
                                              CreateUserRequest(
                                                userName: usernameAttribute.controller.text,
                                                userFullname: fullNameAttribute.controller.text.trim(),
                                                userPhone: phoneAttribute.controller.text.trim(),
                                                userEmail: emailAttribute.controller.text.trim(),
                                                userDob: convertStringToDate(dobAttribute.controller.text),
                                                userPassword: 'aurora123',
                                                userRetypePassword: 'aurora123',
                                                branchId: _selectedBranch?.key,
                                              ),
                                            ).then((value) {
                                              if (responseCode(value.code)) {
                                                UserController.getAll(context, 1, pageSize, userFullName: '', userPhone: '', userName: '').then((value) {
                                                  dismissLoading();
                                                  if (responseCode(value.code)) {
                                                    context.read<UserController>().userAllResponse = value.data?.data;
                                                    context.pop();
                                                    showDialogSuccess(context, 'Successfully created customer');
                                                  } else {
                                                    context.pop();
                                                    showDialogSuccess(context, 'Successfully created customer information');
                                                  }
                                                });
                                              } else {
                                                showDialogError(context, value.message ?? value.data?.message ?? 'ERROR : ${value.code}');
                                              }
                                            });
                                          }
                                        }
                                      }, actionText: 'button'.tr(gender: widget.type)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget labelValue(String label, String value, {bool alignStart = true}) {
    return Column(
      crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            // color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppSelectableText(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
      ],
    );
  }

  bool validate() {
    bool isValid = true;

    void checkRequired(InputFieldAttribute attribute) {
      if (attribute.controller.text.trim().isEmpty) {
        attribute.errorMessage = ErrorMessage.required(field: attribute.labelText);
        isValid = false;
      }
    }

    final requiredFields = [
      fullNameAttribute,
      if (widget.type != 'update') usernameAttribute,
      if (widget.type != 'update') emailAttribute,
      phoneAttribute,
      dobAttribute,
      branchIdAttribute,
    ];

    for (var field in requiredFields) {
      checkRequired(field);
    }

    if (widget.type != 'update' && usernameAttribute.controller.text.contains(' ')) {
      usernameAttribute.errorMessage = 'Username must not contain spaces.';
      isValid = false;
    }

    final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

    if (widget.type != 'update' &&
        emailAttribute.controller.text.isNotEmpty &&
        !emailRegex.hasMatch(emailAttribute.controller.text)) {
      emailAttribute.errorMessage = 'Please enter a valid email address.';
      isValid = false;
    }

    rebuild.add(DateTime.now());
    return isValid;
  }

  double bytesToMB(int bytes) {
    double megabytes = bytes / 1048576.0;
    // double sizeInGB = sizeInBytes / 1073741824.0;
    return megabytes;
  }
}
