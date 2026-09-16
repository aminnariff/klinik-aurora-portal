import 'dart:async';
import 'dart:math' as math;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart';
import 'package:klinik_aurora_portal/models/user/create_user_request.dart';
import 'package:klinik_aurora_portal/models/user/update_user_request.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
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
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nricController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final ValueNotifier<bool> _userStatus = ValueNotifier(true);
  DropdownAttribute? _selectedBranch;
  List<DropdownAttribute> branches = [];
  final StreamController<DateTime> _rebuildDropdown = StreamController.broadcast();

  int? _appointmentCount;
  bool _isSaving = false;

  // Validation errors
  String? _fullNameError;
  String? _usernameError;
  String? _nricError;
  String? _phoneError;
  String? _dobError;
  String? _emailError;
  String? _branchError;

  // Demographic reactive state
  bool _isMalaysianIc = false;
  String? _derivedGender;
  int? _derivedAge;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'update') {
      _usernameController.text = widget.user?.userName ?? '';
      _fullNameController.text = widget.user?.userFullname ?? '';
      _dobController.text = dateConverter(widget.user?.userDob, format: 'dd-MM-yyyy') ?? '';
      _nricController.text = widget.user?.userNric ?? '';
      _phoneController.text = widget.user?.userPhone ?? '';
      _emailController.text = widget.user?.userEmail ?? '';
      _userStatus.value = widget.user?.userStatus == 1;

      // Initial demographic parse
      _inspectDocumentId(_nricController.text);

      // Fetch appointment count in background
      if (widget.user?.userId != null) {
        _fetchAppointmentCount(widget.user!.userId!);
      }
    }

    _loadBranches();
  }

  void _fetchAppointmentCount(String userId) {
    UserController.appointment(context, userId).then((val) {
      if (mounted && responseCode(val.code)) {
        setState(() {
          _appointmentCount = val.data?.data?.length ?? 0;
        });
      }
    }).catchError((e) {
      debugPrint('Error fetching appointments count: $e');
    });
  }

  void _loadBranches() {
    try {
      if (context.read<BranchController>().branchAllResponse == null) {
        BranchController.getAll(context, 1, 100).then((value) {
          if (responseCode(value.code)) {
            context.read<BranchController>().branchAllResponse = value;
            _populateBranches();
          }
        });
      } else {
        _populateBranches();
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _populateBranches() {
    branches.clear();
    for (branch_model.Data item in context.read<BranchController>().branchAllResponse?.data?.data ?? []) {
      branches.add(DropdownAttribute(item.branchId ?? '', item.branchName ?? ''));
    }
    branches.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _rebuildDropdown.add(DateTime.now());

    final branchId = widget.user?.branchId;
    if (branchId != null) {
      try {
        Data? branch = context.read<BranchController>().branchAllResponse?.data?.data?.firstWhere(
              (element) => element.branchId == branchId,
            );
        if (branch != null) {
          setState(() {
            _selectedBranch = DropdownAttribute(branch.branchId ?? '', branch.branchName ?? '');
          });
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  void _inspectDocumentId(String raw) {
    final clean = raw.trim();
    if (clean.length == 12 && RegExp(r'^\d{12}$').hasMatch(clean)) {
      _isMalaysianIc = true;
      final lastDigit = int.tryParse(clean[11]);
      if (lastDigit != null) {
        _derivedGender = lastDigit % 2 != 0 ? 'Male' : 'Female';
      } else {
        _derivedGender = null;
      }

      // Auto-extract DOB if not set or create mode
      if (widget.type == 'create' || (widget.user?.userDob == null && _dobController.text.isEmpty)) {
        final dob = extractDobFromNric(clean);
        if (dob != null) {
          _dobController.text = dob;
          _dobError = null;
        }
      }
    } else {
      _isMalaysianIc = false;
      _derivedGender = null;
    }

    _derivedAge = _calculateAge(_dobController.text.trim());
  }

  int? _calculateAge(String dobStr) {
    if (dobStr.isEmpty) return null;
    try {
      DateTime? birthDate;
      if (dobStr.contains('-')) {
        final parts = dobStr.split('-');
        if (parts.length == 3) {
          if (parts[0].length == 4) {
            birthDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          } else {
            birthDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        }
      }
      if (birthDate != null) {
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        return age >= 0 ? age : null;
      }
    } catch (_) {}
    return null;
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return 'PT';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, math.min(2, parts[0].length)).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _fullNameError = null;
      _usernameError = null;
      _nricError = null;
      _phoneError = null;
      _dobError = null;
      _emailError = null;
      _branchError = null;

      if (_fullNameController.text.trim().isEmpty) {
        _fullNameError = 'Full name is required';
        isValid = false;
      }

      if (_nricController.text.trim().isEmpty) {
        _nricError = 'Document ID (NRIC / Passport) is required';
        isValid = false;
      }

      if (_phoneController.text.trim().isEmpty) {
        _phoneError = 'Contact number is required';
        isValid = false;
      }

      if (_dobController.text.trim().isEmpty) {
        _dobError = 'Date of birth is required';
        isValid = false;
      }

      if (_selectedBranch == null) {
        _branchError = 'Please select a branch';
        isValid = false;
      }

      final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
      if (widget.type != 'update') {
        if (_usernameController.text.trim().isEmpty) {
          _usernameError = 'Username is required';
          isValid = false;
        } else if (_usernameController.text.contains(' ')) {
          _usernameError = 'Username cannot contain spaces';
          isValid = false;
        }

        if (_emailController.text.trim().isEmpty) {
          _emailError = 'Email address is required';
          isValid = false;
        } else {
          final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
          if (!emailRegex.hasMatch(_emailController.text.trim())) {
            _emailError = 'Enter a valid email address';
            isValid = false;
          }
        }
      } else if (isSuperAdmin && _emailController.text.trim().isNotEmpty) {
        final emailRegex = RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
        if (!emailRegex.hasMatch(_emailController.text.trim())) {
          _emailError = 'Enter a valid email address';
          isValid = false;
        }
      }
    });

    return isValid;
  }

  void _submit() {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);
    showLoading();

    final rawPhone = _phoneController.text.trim();
    final docId = _nricController.text.trim().isNotEmpty ? _nricController.text.trim() : null;
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
    final emailToUpdate = isSuperAdmin && _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim().toLowerCase()
        : null;

    if (widget.type == 'update') {
      UserController.update(
        context,
        UpdateUserRequest(
          userId: widget.user?.userId,
          userName: widget.user?.userName ?? _usernameController.text.trim(),
          userFullname: _fullNameController.text.trim(),
          userNric: docId,
          userDob: convertStringToDate(_dobController.text.trim()),
          userPhone: rawPhone,
          branchId: _selectedBranch?.key,
          userStatus: _userStatus.value ? 1 : 0,
          userEmail: emailToUpdate,
        ),
      ).then((value) {
        if (responseCode(value.code)) {
          UserController.getAll(context, 1, pageSize, userFullName: '', userName: '', userPhone: '').then((value) {
            dismissLoading();
            if (mounted) {
              setState(() => _isSaving = false);
              context.read<UserController>().userAllResponse = value.data?.data;
              context.pop(true);
              showDialogSuccess(context, 'Successfully updated customer information');
            }
          }).catchError((e) {
            dismissLoading();
            if (mounted) setState(() => _isSaving = false);
          });
        } else {
          dismissLoading();
          if (mounted) {
            setState(() => _isSaving = false);
            showDialogError(context, value.message ?? value.data?.message ?? 'ERROR: ${value.code}');
          }
        }
      }).catchError((e) {
        dismissLoading();
        if (mounted) {
          setState(() => _isSaving = false);
          showDialogError(context, e.toString());
        }
      });
    } else {
      UserController.create(
        context,
        CreateUserRequest(
          userName: _usernameController.text.trim(),
          userFullname: _fullNameController.text.trim(),
          userNric: docId,
          userPhone: rawPhone,
          userEmail: _emailController.text.trim().toLowerCase(),
          userDob: convertStringToDate(_dobController.text.trim()),
          userPassword: 'aurora123',
          userRetypePassword: 'aurora123',
          branchId: _selectedBranch?.key,
        ),
      ).then((value) {
        if (responseCode(value.code)) {
          UserController.getAll(context, 1, pageSize, userFullName: '', userPhone: '', userName: '').then((value) {
            dismissLoading();
            if (mounted) {
              setState(() => _isSaving = false);
              context.read<UserController>().userAllResponse = value.data?.data;
              context.pop(true);
              showDialogSuccess(context, 'Successfully created customer');
            }
          }).catchError((e) {
            dismissLoading();
            if (mounted) setState(() => _isSaving = false);
          });
        } else {
          dismissLoading();
          if (mounted) {
            setState(() => _isSaving = false);
            showDialogError(context, value.message ?? value.data?.message ?? 'ERROR: ${value.code}');
          }
        }
      }).catchError((e) {
        dismissLoading();
        if (mounted) {
          setState(() => _isSaving = false);
          showDialogError(context, e.toString());
        }
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _nricController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rebuildDropdown.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height - (isMobile ? 32 : 64);
    final maxW = math.min(640.0, MediaQuery.of(context).size.width - 24);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
        margin: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 30,
              offset: const Offset(0, 10),
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
                if (widget.type == 'update') _buildQuickStats(),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormGrid(),
                        if (widget.type == 'update') ...[
                          const SizedBox(height: 18),
                          _buildAccountStatusCard(),
                          const SizedBox(height: 14),
                          _buildMetadataCard(),
                        ],
                      ],
                    ),
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
    final isCreate = widget.type == 'create';
    final displayName = isCreate ? 'Register New Patient' : (_fullNameController.text.isNotEmpty ? _fullNameController.text : widget.user?.userFullname ?? 'Patient Details');
    final initials = isCreate ? 'PT' : _getInitials(displayName);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF0EA5E9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
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
                        displayName,
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
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _userStatus,
                        builder: (context, active, _) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                              ),
                            ),
                            child: Text(
                              active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active ? const Color(0xFF059669) : const Color(0xFFDC2626),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                _buildDemographicBadges(),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
            splashRadius: 18,
            onPressed: () => context.pop(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicBadges() {
    final List<Widget> badges = [];

    final docText = _nricController.text.trim();
    if (docText.isNotEmpty) {
      badges.add(_badge(
        _isMalaysianIc ? 'MyKad' : 'Passport / ID',
        icon: _isMalaysianIc ? Icons.badge_outlined : Icons.flight_takeoff_outlined,
        color: const Color(0xFF0369A1),
        bgColor: const Color(0xFFF0F9FF),
      ));
    }

    if (_derivedGender != null) {
      final isMale = _derivedGender == 'Male';
      badges.add(_badge(
        _derivedGender!,
        icon: isMale ? Icons.male_rounded : Icons.female_rounded,
        color: isMale ? const Color(0xFF2563EB) : const Color(0xFFDB2777),
        bgColor: isMale ? const Color(0xFFEFF6FF) : const Color(0xFFFDF2F8),
      ));
    }

    if (_derivedAge != null && _derivedAge! >= 0) {
      badges.add(_badge(
        '$_derivedAge yrs',
        icon: Icons.cake_outlined,
        color: const Color(0xFF059669),
        bgColor: const Color(0xFFECFDF5),
      ));
    }

    final dob = _dobController.text.trim();
    if (dob.isNotEmpty) {
      badges.add(_badge(
        dob,
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFF475569),
        bgColor: const Color(0xFFF1F5F9),
      ));
    }

    if (badges.isEmpty) {
      return Text(
        widget.type == 'create' ? 'Fill details below to register patient' : 'No IC / demographic details',
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges,
    );
  }

  Widget _badge(String text, {required IconData icon, required Color color, required Color bgColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final branchName = _selectedBranch?.name ?? '—';
    final points = widget.user?.totalPoint ?? 0;
    final visits = _appointmentCount != null ? '$_appointmentCount Visits' : '...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCard('Home Branch', branchName, Icons.storefront_outlined, const Color(0xFF475569)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard('Appointments', visits, Icons.event_note_outlined, const Color(0xFF0284C7)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _statCard('Points Balance', '$points pts', Icons.stars_rounded, const Color(0xFFD97706)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accentColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFormGrid() {
    final isSuperAdmin = context.read<AuthController>().isSuperAdmin;
    final isUpdate = widget.type == 'update';
    final canEditEmail = !isUpdate || isSuperAdmin;

    final leftCol = [
      _buildTextField(
        label: 'Full Name *',
        controller: _fullNameController,
        errorText: _fullNameError,
        hintText: 'e.g. Siti Aminah Binti Yusof',
        onChanged: (val) {
          if (_fullNameError != null) setState(() => _fullNameError = null);
        },
      ),
      const SizedBox(height: 12),
      _buildTextField(
        label: 'Document ID (NRIC / Passport) *',
        controller: _nricController,
        errorText: _nricError,
        hintText: '12-digit NRIC or Passport No',
        onChanged: (val) {
          if (_nricError != null) setState(() => _nricError = null);
          _inspectDocumentId(val);
          setState(() {});
        },
      ),
      const SizedBox(height: 12),
      _buildDatePickerField(),
      if (widget.type != 'update') ...[
        const SizedBox(height: 12),
        _buildTextField(
          label: 'Username *',
          controller: _usernameController,
          errorText: _usernameError,
          hintText: 'e.g. sitiaminah',
          onChanged: (val) {
            if (_usernameError != null) setState(() => _usernameError = null);
          },
        ),
      ],
    ];

    final rightCol = [
      _buildTextField(
        label: 'Contact Number *',
        controller: _phoneController,
        errorText: _phoneError,
        hintText: 'e.g. 0123456789 or +60123456789',
        onChanged: (val) {
          if (_phoneError != null) setState(() => _phoneError = null);
        },
      ),
      const SizedBox(height: 12),
      _buildTextField(
        label: isUpdate
            ? (isSuperAdmin ? 'Email Address (Superadmin Edit)' : 'Email Address')
            : 'Email Address *',
        controller: _emailController,
        errorText: _emailError,
        readOnly: !canEditEmail,
        hintText: 'e.g. patient@gmail.com',
        onChanged: (val) {
          if (_emailError != null) setState(() => _emailError = null);
        },
      ),
      const SizedBox(height: 12),
      _buildBranchDropdown(),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [...leftCol, const SizedBox(height: 12), ...rightCol],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: leftCol)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rightCol)),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    String? hintText,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 5),
        Container(
          height: 42,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: errorText != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: readOnly ? const Color(0xFF475569) : const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Color(0xFF94A3B8)),
            ),
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

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Date of Birth *',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        InkWell(
          onTap: () async {
            var results = await showCalendarDatePicker2Dialog(
              context: context,
              config: CalendarDatePicker2WithActionButtonsConfig(
                firstDate: DateTime(DateTime.now().year - 100),
                lastDate: DateTime.now(),
                calendarViewMode: CalendarDatePicker2Mode.year,
              ),
              dialogSize: Size(
                isMobile ? (MediaQuery.of(context).size.width * 0.88) : screenWidth1728(60),
                screenHeight829(60),
              ),
              borderRadius: BorderRadius.circular(15),
            );
            if (results != null && results.isNotEmpty && results.first != null) {
              final formatted = dateConverter('${results.first}', format: 'dd-MM-yyyy') ?? '';
              setState(() {
                _dobController.text = formatted;
                _dobError = null;
                _derivedAge = _calculateAge(formatted);
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _dobError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                width: _dobError != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _dobController.text.isNotEmpty ? _dobController.text : 'Select Date of Birth',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: _dobController.text.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                      color: _dobController.text.isNotEmpty ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
        if (_dobError != null) ...[
          const SizedBox(height: 3),
          Text(
            _dobError!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildBranchDropdown() {
    final selectedItem = _selectedBranch != null && branches.any((b) => b.key == _selectedBranch!.key)
        ? branches.firstWhere((b) => b.key == _selectedBranch!.key)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Registered Branch *',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _branchError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
              width: _branchError != null ? 1.5 : 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DropdownAttribute>(
              isExpanded: true,
              value: selectedItem,
              hint: const Text(
                'Select Branch',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              onChanged: (DropdownAttribute? selected) {
                if (selected != null) {
                  setState(() {
                    _selectedBranch = selected;
                    _branchError = null;
                  });
                }
              },
              items: branches.map((DropdownAttribute b) {
                return DropdownMenuItem<DropdownAttribute>(
                  value: b,
                  child: Text(
                    b.name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        if (_branchError != null) ...[
          const SizedBox(height: 3),
          Text(
            _branchError!,
            style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountStatusCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: _userStatus,
      builder: (context, active, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFF0FDF4) : const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? const Color(0xFFBBF7D0) : const Color(0xFFFECDD3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.check_circle_outline_rounded : Icons.block_rounded,
                size: 18,
                color: active ? const Color(0xFF15803D) : const Color(0xFFBE123C),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Status: ${active ? "Active" : "Deactivated"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: active ? const Color(0xFF166534) : const Color(0xFF9F1239),
                      ),
                    ),
                    Text(
                      active ? 'Patient is eligible to book appointments & earn points' : 'Account deactivated — booking & portal login disabled',
                      style: TextStyle(
                        fontSize: 11,
                        color: active ? const Color(0xFF15803D) : const Color(0xFFBE123C),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: (val) => _userStatus.value = val,
                activeThumbColor: const Color(0xFF16A34A),
                activeTrackColor: const Color(0xFFBBF7D0),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataCard() {
    final createdDate = dateConverter(widget.user?.createdDate) ?? '—';
    final modifiedDate = widget.user?.modifiedDate != null ? dateConverter(widget.user?.modifiedDate) ?? '—' : null;
    final createdBy = widget.user?.createdByAdmin == 1 ? 'Admin' : 'Self Registered';
    final tnc = widget.user?.tncAccepted == 1 || widget.user?.createdByAdmin == 0 ? 'Accepted' : 'Pending';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _miniMeta('Joined', createdDate),
          if (modifiedDate != null) _miniMeta('Last Active', modifiedDate),
          _miniMeta('Origin', createdBy),
          _miniMeta('Terms', tnc),
        ],
      ),
    );
  }

  Widget _miniMeta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final isCreate = widget.type == 'create';

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
            onPressed: _isSaving ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    isCreate ? 'Register Patient' : 'Save Changes',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
    );
  }
}
