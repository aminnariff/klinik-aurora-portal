import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:go_router/go_router.dart";
import "package:klinik_aurora_portal/config/constants.dart";
import "package:klinik_aurora_portal/config/loading.dart";
import "package:klinik_aurora_portal/controllers/admin/admin_controller.dart";
import "package:klinik_aurora_portal/controllers/api_controller.dart";
import "package:klinik_aurora_portal/controllers/api_response_controller.dart";
import "package:klinik_aurora_portal/controllers/auth/auth_controller.dart";
import "package:klinik_aurora_portal/controllers/branch/branch_controller.dart";
import "package:klinik_aurora_portal/controllers/permission/permission_controller.dart";
import "package:klinik_aurora_portal/models/admin/admin_all_response.dart" as admin;
import "package:klinik_aurora_portal/models/admin/create_admin_request.dart";
import "package:klinik_aurora_portal/models/admin/update_admin_request.dart";
import "package:klinik_aurora_portal/models/admin/update_permission_admin_request.dart";
import "package:klinik_aurora_portal/models/branch/branch_all_response.dart" as branch_model;
import "package:klinik_aurora_portal/models/permission/permission_all_response.dart" as model_permission;
import "package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart";
import "package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart";
import "package:klinik_aurora_portal/views/widgets/size.dart";
import "package:provider/provider.dart";

class AdminDetail extends StatefulWidget {
  final admin.Data? user;
  final String type;
  const AdminDetail({super.key, this.user, required this.type});

  @override
  State<AdminDetail> createState() => _AdminDetailState();
}

class _RolePreset {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<String> permissionIds;

  const _RolePreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.permissionIds,
  });
}

class _AdminDetailState extends State<AdminDetail> {
  // Canonical Permission IDs (identical in Staging and Prod DB)
  static const String permUserManagement = "1bda631e-ef17-11ee-bd1b-cc801b09db2f";
  static const String permAdminManagement = "4ac042fa-ef2d-11ee-bd1b-cc801b09db2f";
  static const String permBranch = "68c537d4-ef31-11ee-bd1b-cc801b09db2f";
  static const String permPromotion = "e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f";
  static const String permVoucher = "d98236e8-f490-11ee-befc-aabaa50b463f";
  static const String permDoctor = "f90f9f18-057b-11ef-943b-626efeb17d5e";
  static const String permPoint = "a231db36-058d-11ef-943b-626efeb17d5e";
  static const String permRewardManagement = "dc4e7a5a-0e15-11ef-82b0-94653af51fb9";
  static const String permRewards = "6e0fe1f8-2f1f-11ef-8db9-6677d190faa2";
  static const String permService = "0699ac1c-ac52-11ef-a1b7-bc24115a1342";
  static const String permAppointment = "3b8e7d9d-ac51-11ef-a1b7-bc24115a1342";
  static const String permPayment = "f57576c4-4d15-11f0-b054-1ff6746392b2";
  static const String permSonographer = "c54a2d91-499c-11f0-9169-bc24115a1342";

  final TextEditingController _userName = TextEditingController();
  final TextEditingController _userFullname = TextEditingController();
  final TextEditingController _userEmail = TextEditingController();
  final TextEditingController _userPhone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();
  final TextEditingController _permissionSearch = TextEditingController();

  final ValueNotifier<bool> _userStatus = ValueNotifier(true);

  String? _fullnameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  DropdownAttribute? _selectedBranch;
  List<DropdownAttribute> branches = [];
  List<String> selectedPermission = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchPermissions();

    if (widget.type == "update") {
      _userName.text = widget.user?.userName ?? "";
      _userFullname.text = widget.user?.userFullname ?? "";
      _userEmail.text = widget.user?.userEmail ?? "";
      _userPhone.text = widget.user?.userPhone ?? "";
      _userStatus.value = widget.user?.userStatus == 1;

      if (widget.user?.userId != null) {
        AdminController.getPermission(context, widget.user!.userId!).then((value) {
          if (responseCode(value.code) && mounted) {
            setState(() {
              selectedPermission = (value.data?.data ?? [])
                  .map((p) => p.permissionId)
                  .whereType<String>()
                  .toList();
            });
          }
        });
      }
    } else {
      _userStatus.value = true;
    }

    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _loadBranches();
    });
  }

  void _fetchPermissions() {
    PermissionController.get(context).then((value) {
      if (responseCode(value.code) && mounted) {
        context.read<PermissionController>().permissionAllResponse = value.data;
        setState(() {});
      }
    });
  }

  void _loadBranches() {
    final branchResponse = context.read<BranchController>().branchAllResponse;
    if (branchResponse?.data?.data != null) {
      final List<DropdownAttribute> loaded = [];
      for (branch_model.Data item in branchResponse!.data!.data!) {
        if (item.branchId != null) {
          loaded.add(DropdownAttribute(item.branchId!, item.branchName ?? "Unnamed"));
        }
      }
      loaded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        branches = loaded;
        if (widget.user?.branchId != null) {
          _selectedBranch = branches.where((b) => b.key == widget.user!.branchId).firstOrNull;
        }
      });
    }
  }

  @override
  void dispose() {
    _userName.dispose();
    _userFullname.dispose();
    _userEmail.dispose();
    _userPhone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _permissionSearch.dispose();
    _userStatus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height - (isMobile ? 32 : 64);
    final maxW = math.min(880.0, MediaQuery.of(context).size.width - (isMobile ? 16 : 32));

    return Center(
      child: Container(
        width: maxW,
        constraints: BoxConstraints(
          maxWidth: maxW,
          maxHeight: maxH,
        ),
        margin: EdgeInsets.all(isMobile ? 8 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: _buildFormContent(),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isCreate = widget.type == "create";
    final title = isCreate
        ? "New Admin Account"
        : (_userFullname.text.isNotEmpty ? _userFullname.text : (widget.user?.userFullname ?? "Edit Admin"));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.admin_panel_settings_rounded, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!isCreate) ...[
                      const SizedBox(width: 10),
                      ValueListenableBuilder<bool>(
                        valueListenable: _userStatus,
                        builder: (context, active, _) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _userStatus.value = !_userStatus.value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: active ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: active ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    active ? "Active" : "Inactive",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: active ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isCreate
                      ? "Create credentials, set branch assignment, and assign permission roles"
                      : "Manage admin permissions, contact info, and system role",
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
            tooltip: "Close",
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
    final isCreate = widget.type == "create";
    final allPermissions = context.watch<PermissionController>().permissionAllResponse?.data ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader("Account Information", Icons.person_outline_rounded),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 580;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _userFullname,
                          label: "Full Name",
                          isRequired: true,
                          hintText: "e.g. Dr. Jane Doe / Staff Ali",
                          errorText: _fullnameError,
                          onChanged: () {
                            if (_fullnameError != null) setState(() => _fullnameError = null);
                          },
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _userName,
                          label: "Username",
                          isRequired: isCreate,
                          hintText: "e.g. janedoe / ali_aurora",
                          isEditable: isCreate,
                          errorText: _usernameError,
                          onChanged: () {
                            if (_usernameError != null) setState(() => _usernameError = null);
                          },
                        ),
                        if (!isCreate) ...[
                          const SizedBox(height: 4),
                          const Text(
                            "Username is fixed and cannot be changed.",
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                        if (isCreate) ...[
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _password,
                            label: "Password",
                            isRequired: true,
                            isPassword: true,
                            hintText: "At least 6 characters",
                            errorText: _passwordError,
                            onChanged: () {
                              if (_passwordError != null) setState(() => _passwordError = null);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _userEmail,
                          label: "Email Address",
                          isRequired: isCreate,
                          isEmail: true,
                          isEditable: isCreate || isSuperAdmin,
                          hintText: "admin@klinikaurora.com",
                          errorText: _emailError,
                          onChanged: () {
                            if (_emailError != null) setState(() => _emailError = null);
                          },
                        ),
                        if (!isCreate && !isSuperAdmin) ...[
                          const SizedBox(height: 4),
                          const Text(
                            "Only Super Admin can edit email address.",
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _userPhone,
                          label: "Contact Number",
                          isNumber: true,
                          hintText: "e.g. 0123456789",
                        ),
                        if (isCreate) ...[
                          const SizedBox(height: 14),
                          _buildTextField(
                            controller: _confirmPassword,
                            label: "Confirm Password",
                            isRequired: true,
                            isPassword: true,
                            hintText: "Re-enter password",
                            errorText: _confirmPasswordError,
                            onChanged: () {
                              if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _userFullname,
                    label: "Full Name",
                    isRequired: true,
                    hintText: "e.g. Dr. Jane Doe / Staff Ali",
                    errorText: _fullnameError,
                    onChanged: () {
                      if (_fullnameError != null) setState(() => _fullnameError = null);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _userName,
                    label: "Username",
                    isRequired: isCreate,
                    hintText: "e.g. janedoe / ali_aurora",
                    isEditable: isCreate,
                    errorText: _usernameError,
                    onChanged: () {
                      if (_usernameError != null) setState(() => _usernameError = null);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _userEmail,
                    label: "Email Address",
                    isRequired: isCreate,
                    isEmail: true,
                    isEditable: isCreate || isSuperAdmin,
                    hintText: "admin@klinikaurora.com",
                    errorText: _emailError,
                    onChanged: () {
                      if (_emailError != null) setState(() => _emailError = null);
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildTextField(
                    controller: _userPhone,
                    label: "Contact Number",
                    isNumber: true,
                    hintText: "e.g. 0123456789",
                  ),
                  if (isCreate) ...[
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _password,
                      label: "Password",
                      isRequired: true,
                      isPassword: true,
                      hintText: "At least 6 characters",
                      errorText: _passwordError,
                      onChanged: () {
                        if (_passwordError != null) setState(() => _passwordError = null);
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _confirmPassword,
                      label: "Confirm Password",
                      isRequired: true,
                      isPassword: true,
                      hintText: "Re-enter password",
                      errorText: _confirmPasswordError,
                      onChanged: () {
                        if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                      },
                    ),
                  ],
                ],
              );
            }
          },
        ),
        const SizedBox(height: 24),
        _sectionHeader("Branch Scope", Icons.store_outlined),
        const SizedBox(height: 12),
        _buildBranchDropdown(),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Assigning a branch restricts this admin to that branch data. Leave empty for headquarters or global management.",
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionHeader("Role & Permissions", Icons.security_rounded),
            if (isSuperAdmin)
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  "New Permission",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _showAddOrEditPermissionDialog(),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          "Choose a role preset to quickly assign recommended permissions, or select individual permissions below:",
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 12),
        _buildRolePresets(allPermissions),
        const SizedBox(height: 20),
        _buildPermissionsCard(allPermissions, isSuperAdmin),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Icon(icon, size: 15, color: const Color(0xFF475569)),
        const SizedBox(width: 6),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF475569),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? errorText,
    bool isPassword = false,
    bool isEmail = false,
    bool isNumber = false,
    bool isEditable = true,
    bool isRequired = false,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            if (isRequired)
              const Text(
                " *",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFEF4444)
                  : (isEditable ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            enabled: isEditable,
            obscureText: isPassword,
            keyboardType: isEmail
                ? TextInputType.emailAddress
                : (isNumber ? TextInputType.phone : TextInputType.text),
            style: TextStyle(
              fontSize: 13,
              color: isEditable ? const Color(0xFF0F172A) : const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
            onChanged: (_) {
              if (onChanged != null) onChanged();
            },
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 3),
          Text(
            errorText,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildBranchDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Branch Assignment",
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          alignment: Alignment.centerLeft,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              isExpanded: true,
              value: _selectedBranch?.key,
              hint: const Text(
                "All Branches (Headquarters / Global)",
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    "All Branches (Headquarters / Global)",
                    style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  ),
                ),
                ...branches.map(
                  (b) => DropdownMenuItem<String?>(
                    value: b.key,
                    child: Text(
                      b.name,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() {
                  if (val == null) {
                    _selectedBranch = null;
                  } else {
                    _selectedBranch = branches.where((b) => b.key == val).firstOrNull;
                  }
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRolePresets(List<model_permission.Data> allPermissions) {
    final allIds = allPermissions.map((p) => p.permissionId).whereType<String>().toList();

    final presets = [
      _RolePreset(
        id: "sonographer",
        title: "Sonographer (Locum)",
        subtitle: "Appointments tab only",
        icon: Icons.biotech_rounded,
        color: const Color(0xFF6366F1),
        permissionIds: const [permSonographer],
      ),
      _RolePreset(
        id: "staff",
        title: "Clinic Staff",
        subtitle: "Appointments, patients & billing",
        icon: Icons.badge_outlined,
        color: const Color(0xFF0F766E),
        permissionIds: const [
          permAppointment,
          permUserManagement,
          permService,
          permPayment,
          permPoint,
        ],
      ),
      _RolePreset(
        id: "manager",
        title: "Branch Manager",
        subtitle: "Full branch operations",
        icon: Icons.store_rounded,
        color: const Color(0xFF0284C7),
        permissionIds: const [
          permBranch,
          permAppointment,
          permUserManagement,
          permDoctor,
          permService,
          permPayment,
          permPoint,
          permRewardManagement,
          permRewards,
          permVoucher,
          permPromotion,
        ],
      ),
      _RolePreset(
        id: "superadmin",
        title: "Super Admin",
        subtitle: "Unrestricted global access",
        icon: Icons.shield_rounded,
        color: const Color(0xFFD97706),
        permissionIds: allIds,
      ),
    ];

    final currentSelectedSet = selectedPermission.toSet();
    String currentPresetId = "custom";
    for (final p in presets) {
      if (p.permissionIds.isNotEmpty &&
          p.permissionIds.toSet().length == currentSelectedSet.length &&
          p.permissionIds.toSet().difference(currentSelectedSet).isEmpty) {
        currentPresetId = p.id;
        break;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardWidth = constraints.maxWidth > 650
            ? (constraints.maxWidth - 36) / 4
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: presets.map((preset) {
            final isSelected = currentPresetId == preset.id;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  selectedPermission = List<String>.from(preset.permissionIds);
                });
              },
              child: Container(
                width: cardWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? preset.color.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? preset.color : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? preset.color : preset.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            preset.icon,
                            size: 16,
                            color: isSelected ? Colors.white : preset.color,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, size: 16, color: preset.color)
                        else
                          Icon(Icons.radio_button_unchecked_rounded, size: 16, color: Colors.grey.shade300),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      preset.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? preset.color : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected ? preset.color.withValues(alpha: 0.9) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPermissionsCard(List<model_permission.Data> allPermissions, bool isSuperAdmin) {
    final query = _permissionSearch.text.toLowerCase().trim();
    final filtered = query.isEmpty
        ? allPermissions
        : allPermissions.where((p) => (p.permissionName ?? "").toLowerCase().contains(query)).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                "All Permissions",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${selectedPermission.length}/${allPermissions.length} selected",
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                ),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    selectedPermission = allPermissions
                        .map((p) => p.permissionId)
                        .whereType<String>()
                        .toList();
                  });
                },
                child: const Text("Select All", style: TextStyle(fontSize: 11, color: Color(0xFF4F46E5))),
              ),
              const SizedBox(width: 4),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () {
                  setState(() {
                    selectedPermission.clear();
                  });
                },
                child: const Text("Clear", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 38,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: TextField(
              controller: _permissionSearch,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: "Search permissions...",
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                prefixIconConstraints: const BoxConstraints(minWidth: 26, maxHeight: 16),
                suffixIcon: _permissionSearch.text.isNotEmpty
                    ? InkWell(
                        onTap: () {
                          _permissionSearch.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                      )
                    : null,
                suffixIconConstraints: const BoxConstraints(minWidth: 26, maxHeight: 16),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: Text(
                query.isEmpty ? "No permissions configured." : "No permissions match \"$query\".",
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
              ),
            )
          else
            _buildCategorizedPermissionGrid(filtered, isSuperAdmin),
        ],
      ),
    );
  }

  Widget _buildCategorizedPermissionGrid(List<model_permission.Data> permissions, bool isSuperAdmin) {
    final Map<String, List<model_permission.Data>> groups = {
      "Clinical & Operations": [],
      "Patients & Loyalty": [],
      "Finance & Administration": [],
      "Other": [],
    };

    final clinicalIds = {permAppointment, permSonographer, permDoctor, permService, permBranch};
    final patientIds = {permUserManagement, permPoint, permRewardManagement, permRewards, permVoucher, permPromotion};
    final adminIds = {permPayment, permAdminManagement};

    for (final p in permissions) {
      if (p.permissionId == null) continue;
      if (clinicalIds.contains(p.permissionId)) {
        groups["Clinical & Operations"]!.add(p);
      } else if (patientIds.contains(p.permissionId)) {
        groups["Patients & Loyalty"]!.add(p);
      } else if (adminIds.contains(p.permissionId)) {
        groups["Finance & Administration"]!.add(p);
      } else {
        groups["Other"]!.add(p);
      }
    }

    groups.removeWhere((_, list) => list.isEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: groups.entries.map((entry) {
        final groupTitle = entry.key;
        final list = entry.value;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupTitle,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: list.map((p) {
                  final isChecked = selectedPermission.contains(p.permissionId);
                  final isInactive = p.permissionStatus == 0;

                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        if (isChecked) {
                          selectedPermission.remove(p.permissionId);
                        } else {
                          selectedPermission.add(p.permissionId!);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isChecked ? const Color(0xFFEEF2FF) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isChecked ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                            size: 16,
                            color: isChecked ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.permissionName ?? "Unnamed",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isChecked ? FontWeight.w600 : FontWeight.w400,
                              color: isChecked ? const Color(0xFF312E81) : const Color(0xFF1E293B),
                            ),
                          ),
                          if (isInactive) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                "Inactive",
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFFDC2626)),
                              ),
                            ),
                          ],
                          if (isSuperAdmin) ...[
                            const SizedBox(width: 4),
                            InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () => _showAddOrEditPermissionDialog(permission: p),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(Icons.edit_outlined, size: 13, color: Colors.grey.shade400),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showAddOrEditPermissionDialog({model_permission.Data? permission}) async {
    final isEditing = permission != null;
    final nameCtrl = TextEditingController(text: permission?.permissionName ?? "");
    int status = permission?.permissionStatus ?? 1;
    String? dialogError;
    bool dialogSaving = false;

    await showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEditing ? Icons.edit_note_rounded : Icons.add_moderator_rounded,
                    size: 20,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? "Edit Permission" : "New Permission",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Permission Name *",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 42,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: dialogError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: TextField(
                      controller: nameCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        hintText: "e.g. Lab Management or Sonographer",
                        hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      dialogError!,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                    ),
                  ],
                  if (isEditing) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          "Status:",
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text("Active", style: TextStyle(fontSize: 12)),
                          selected: status == 1,
                          selectedColor: const Color(0xFFDCFCE7),
                          onSelected: (val) => setDialogState(() => status = 1),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text("Inactive", style: TextStyle(fontSize: 12)),
                          selected: status == 0,
                          selectedColor: const Color(0xFFFEE2E2),
                          onSelected: (val) => setDialogState(() => status = 0),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: dialogSaving ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: dialogSaving
                    ? null
                    : () async {
                        final val = nameCtrl.text.trim();
                        if (val.isEmpty) {
                          setDialogState(() => dialogError = "Permission name cannot be empty");
                          return;
                        }
                        setDialogState(() => dialogSaving = true);
                        try {
                          final ApiResponse resp;
                          if (isEditing) {
                            resp = await PermissionController.update(
                              context,
                              permissionId: permission.permissionId!,
                              permissionName: val,
                              permissionStatus: status,
                            );
                          } else {
                            resp = await PermissionController.create(
                              context,
                              permissionName: val,
                            );
                          }
                          if (responseCode(resp.code)) {
                            Navigator.of(dialogCtx).pop();
                            final fresh = await PermissionController.get(context);
                            if (responseCode(fresh.code) && mounted) {
                              context.read<PermissionController>().permissionAllResponse = fresh.data;
                              setState(() {});
                              showDialogSuccess(
                                context,
                                isEditing ? "Permission updated successfully" : "Permission created successfully",
                              );
                            }
                          } else {
                            setDialogState(() {
                              dialogSaving = false;
                              dialogError = resp.message ?? "Failed to save permission";
                            });
                          }
                        } catch (e) {
                          setDialogState(() {
                            dialogSaving = false;
                            dialogError = e.toString();
                          });
                        }
                      },
                child: dialogSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(isEditing ? "Save Changes" : "Create Permission"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    final isCreate = widget.type == "create";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: _isSaving ? null : () => context.pop(),
            child: const Text("Cancel", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            ),
            onPressed: _isSaving ? null : _saveAdmin,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isCreate ? "Create Admin" : "Update Admin",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveAdmin() async {
    final isCreate = widget.type == "create";
    setState(() {
      _fullnameError = null;
      _usernameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final fullname = _userFullname.text.trim();
    final username = _userName.text.trim();
    final email = _userEmail.text.trim();
    final phone = _userPhone.text.trim();
    final password = _password.text;
    final confirm = _confirmPassword.text;

    bool hasError = false;
    if (fullname.isEmpty) {
      _fullnameError = "Full name is required";
      hasError = true;
    }
    if (isCreate) {
      if (username.isEmpty) {
        _usernameError = "Username is required";
        hasError = true;
      }
      if (email.isEmpty) {
        _emailError = "Email is required";
        hasError = true;
      } else if (!email.contains("@") || !email.contains(".")) {
        _emailError = "Enter a valid email address";
        hasError = true;
      }
      if (password.isEmpty) {
        _passwordError = "Password is required";
        hasError = true;
      } else if (password.length < 6) {
        _passwordError = "Password must be at least 6 characters";
        hasError = true;
      }
      if (confirm.isEmpty) {
        _confirmPasswordError = "Please confirm password";
        hasError = true;
      } else if (password != confirm) {
        _confirmPasswordError = "Passwords do not match";
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isSaving = true);
    showLoading();

    try {
      if (isCreate) {
        final createResp = await AdminController.create(
          context,
          CreateAdminRequest(
            userName: username,
            userFullname: fullname,
            userPhone: phone,
            userEmail: email,
            userPassword: password,
            userRetypePassword: password,
            branchId: _selectedBranch?.key,
          ),
        );

        if (!responseCode(createResp.code)) {
          dismissLoading();
          setState(() => _isSaving = false);
          showDialogError(context, createResp.message ?? "Failed to create admin");
          return;
        }

        final createdId = createResp.data?.id;
        if (createdId != null) {
          final permResp = await AdminController.updatePermission(
            context,
            UpdatePermissionAdminRequest(userId: createdId, permissionIds: selectedPermission),
          );
          if (!responseCode(permResp.code)) {
            debugPrint("Warning: permissions assign failed: ${permResp.message}");
          }
        }

        final listResp = await AdminController.getAll(context, 1, pageSize);
        dismissLoading();
        setState(() => _isSaving = false);

        if (responseCode(listResp.code)) {
          context.read<AdminController>().adminAllResponse = listResp.data;
        }
        if (mounted) {
          context.pop();
          showDialogSuccess(context, "Successfully created admin account");
        }
      } else {
        final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
        final updateResp = await AdminController.update(
          context,
          UpdateAdminRequest(
            userId: widget.user?.userId,
            userFullname: fullname,
            branchId: _selectedBranch?.key,
            userPhone: phone,
            userEmail: isSuperAdmin ? email : null,
            userStatus: _userStatus.value ? 1 : 0,
          ),
        );

        if (!responseCode(updateResp.code)) {
          dismissLoading();
          setState(() => _isSaving = false);
          showDialogError(context, updateResp.message ?? "Failed to update admin");
          return;
        }

        if (widget.user?.userId != null) {
          final permResp = await AdminController.updatePermission(
            context,
            UpdatePermissionAdminRequest(userId: widget.user!.userId!, permissionIds: selectedPermission),
          );
          if (!responseCode(permResp.code)) {
            debugPrint("Warning: permissions assign failed: ${permResp.message}");
          }
        }

        final listResp = await AdminController.getAll(context, 1, pageSize);
        dismissLoading();
        setState(() => _isSaving = false);

        if (responseCode(listResp.code)) {
          context.read<AdminController>().adminAllResponse = listResp.data;
        }
        if (mounted) {
          context.pop();
          showDialogSuccess(context, "Successfully updated admin account");
        }
      }
    } catch (e) {
      dismissLoading();
      setState(() => _isSaving = false);
      showDialogError(context, e.toString());
    }
  }
}
