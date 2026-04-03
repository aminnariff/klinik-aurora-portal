import 'dart:async';
import 'dart:math' as math;

import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/appointment/appointment_response.dart' as appointment_model;
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch;
import 'package:klinik_aurora_portal/models/user/update_user_request.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/user/appointment_ids.dart';
import 'package:klinik_aurora_portal/views/user/user_detail.dart';
import 'package:klinik_aurora_portal/views/user/user_point_detail.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:klinik_aurora_portal/views/widgets/table/table_header_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/tooltip/app_tooltip.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class UserHomepage extends StatefulWidget {
  static const routeName = '/patients';
  static const displayName = 'Patients';
  const UserHomepage({super.key});

  @override
  State<UserHomepage> createState() => _UserHomepageState();
}

class _UserHomepageState extends State<UserHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);
  ValueNotifier<bool> isNoRecords = ValueNotifier<bool>(false);

  List<TableHeaderAttribute> headers = [
    TableHeaderAttribute(attribute: 'userFullname', label: 'Patient', allowSorting: false, columnSize: ColumnSize.M),
    TableHeaderAttribute(
      attribute: 'userPhone',
      label: 'Mobile No.',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 140,
    ),
    TableHeaderAttribute(
      attribute: 'totalPoints',
      label: 'Points',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 90,
    ),
    TableHeaderAttribute(
      attribute: 'branchId',
      label: 'Registered Branch',
      allowSorting: false,
      columnSize: ColumnSize.M,
    ),
    TableHeaderAttribute(
      attribute: 'userStatus',
      label: 'Status',
      allowSorting: false,
      columnSize: ColumnSize.S,
      width: 90,
    ),
    TableHeaderAttribute(attribute: 'createdDate', label: 'Joined', allowSorting: false, columnSize: ColumnSize.S),
    TableHeaderAttribute(attribute: 'actions', label: '', allowSorting: false, columnSize: ColumnSize.S, width: 56),
  ];

  final TextEditingController _userFullNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  DropdownAttribute? _selectedBranch;
  DropdownAttribute? _selectedUserStatus;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  static const List<Color> _avatarColors = [
    Color(0xFF6AD1E3),
    Color(0xFFDF6E98),
    Color(0xFF7E57C2),
    Color(0xFF26A69A),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFFFF7043),
    Color(0xFF66BB6A),
  ];

  Color _avatarColor(String name) {
    if (name.isEmpty) return _avatarColors[0];
    return _avatarColors[name.codeUnitAt(0) % _avatarColors.length];
  }

  String _initials(String? fullname, String? username) {
    final name = fullname?.trim() ?? username?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue = Homepage.getPageId(UserHomepage.displayName);
    });
    if (context.read<BranchController>().branchAllResponse == null) {
      BranchController.getAll(context, 1, 100).then((value) {
        if (responseCode(value.code)) {
          context.read<BranchController>().branchAllResponse = value;
        }
      });
    }
    filtering();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutWidget(mobile: mobileView(), desktop: desktopView());
  }


  Widget mobileView() {
    return Consumer<UserController>(
      builder: (context, snapshot, _) {
        final users = snapshot.userAllResponse ?? [];
        return Column(
          children: [
            _mobileSearchBar(),
            Expanded(
              child: users.isEmpty
                  ? const Center(child: NoRecordsWidget())
                  : ListView.builder(
                      padding: EdgeInsets.all(screenPadding),
                      itemCount: users.length,
                      itemBuilder: (context, index) => _mobileCard(users[index]),
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenPadding / 2),
              child: pagination(),
            ),
          ],
        );
      },
    );
  }

  Widget _mobileSearchBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, 0),
      child: TextField(
        controller: _userFullNameController,
        onChanged: (_) => filtering(page: 1),
        decoration: InputDecoration(
          hintText: 'Search patients…',
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF9CA3AF)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
      ),
    );
  }

  Widget _mobileCard(UserResponse user) {
    final initials = _initials(user.userFullname, user.userName);
    final color = _avatarColor(user.userFullname ?? user.userName ?? '');
    return Card(
      margin: EdgeInsets.only(bottom: screenPadding / 2),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withAlpha(40),
              child: Text(
                initials,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.userFullname?.titleCase() ?? user.userName ?? 'N/A',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.userPhone ?? 'No phone',
                    style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _statusChip(user.userStatus == 1),
                      const SizedBox(width: 8),
                      Text(
                        '${user.totalPoint ?? 0} pts',
                        style: AppTypography.bodyMedium(context).apply(color: secondaryColor, fontWeightDelta: 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _actionMenu(user),
          ],
        ),
      ),
    );
  }


  Widget desktopView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, screenPadding),
              child: _tableCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Search
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _userFullNameController,
                onChanged: (_) {
                  setState(() {});
                  filtering(page: 1);
                },
                style: AppTypography.bodyMedium(context),
                decoration: InputDecoration(
                  hintText: 'Search by name, username…',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
                  suffixIcon: _userFullNameController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF9CA3AF)),
                          onPressed: () {
                            _userFullNameController.clear();
                            filtering(enableDebounce: false, page: 1);
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: secondaryColor, width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filter button
          OutlinedButton.icon(
            onPressed: _showFilterPanel,
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Filter', style: TextStyle(fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 8),
          // Reset
          IconButton(
            onPressed: () {
              resetAllFilter();
              filtering(enableDebounce: false, page: 1);
            },
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6B7280)),
            tooltip: 'Reset filters',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          // Add patient
          ElevatedButton.icon(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const UserDetail(type: 'create'),
            ),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: const Text('Add Patient', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableCard() {
    return Consumer<UserController>(
      builder: (context, snapshot, _) {
        if (snapshot.userAllResponse == null) {
          return const Center(child: CircularProgressIndicator(color: secondaryColor));
        }
        if (snapshot.userAllResponse!.isEmpty) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(child: NoRecordsWidget()),
          );
        }
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Expanded(child: _dataTable(snapshot.userAllResponse!)),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              _tableFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _dataTable(List<UserResponse> users) {
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      isHorizontalScrollBarVisible: false,
      isVerticalScrollBarVisible: true,
      decoration: const BoxDecoration(),
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
      headingRowHeight: 44,
      dataRowHeight: 60,
      dividerThickness: 1,
      columns: columns(),
      rows: [
        for (int i = 0; i < users.length; i++)
          DataRow2(color: WidgetStateProperty.all(Colors.white), cells: _buildCells(users[i])),
      ],
    );
  }

  List<DataCell> _buildCells(UserResponse user) {
    final initials = _initials(user.userFullname, user.userName);
    final color = _avatarColor(user.userFullname ?? user.userName ?? '');
    return [
      // Patient (avatar + name + email)
      DataCell(
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color.withAlpha(40),
              child: Text(
                initials,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTooltip(
                    message:
                        '${notNullOrEmptyString(user.userNric) ? 'NRIC: ${user.userNric}\n' : ''}Email: ${user.userEmail ?? 'N/A'}',
                    child: Text(
                      user.userFullname?.titleCase() ?? user.userName ?? 'N/A',
                      style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    user.userEmail ?? '',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // Mobile
      DataCell(Text(user.userPhone ?? '—', style: AppTypography.bodyMedium(context))),
      // Points
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: secondaryColor.withAlpha(25), borderRadius: BorderRadius.circular(20)),
          child: Text(
            '${user.totalPoint ?? 0}',
            style: TextStyle(color: secondaryColor.withAlpha(230), fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ),
      // Branch
      DataCell(
        Text(
          translateToBranchName(user.branchId ?? '') ?? '—',
          style: AppTypography.bodyMedium(context),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      // Status
      DataCell(_statusChip(user.userStatus == 1)),
      // Joined
      DataCell(
        Text(dateConverter(user.createdDate) ?? '—', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
      ),
      // Actions
      DataCell(_actionMenu(user)),
    ];
  }

  Widget _statusChip(bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? Colors.green.withAlpha(25) : Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _actionMenu(UserResponse user) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 32),
      color: Colors.white,
      elevation: 4,
      tooltip: '',
      onSelected: (value) => _handleMenuSelection(value, user),
      itemBuilder: (_) => [
        _menuItem('update', Icons.edit_outlined, 'Update Info'),
        _menuItem('appointment', Icons.calendar_today_outlined, 'Appointment'),
        _menuItem('appointmentHistory', Icons.history_rounded, 'Appointment History'),
        _menuItem('managePoints', Icons.stars_rounded, 'Manage Points'),
        PopupMenuItem<String>(
          value: 'enableDisable',
          child: Row(
            children: [
              Icon(
                user.userStatus == 1 ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                size: 16,
                color: user.userStatus == 1 ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 10),
              Text(
                user.userStatus == 1 ? 'Deactivate' : 'Re-Activate',
                style: TextStyle(fontSize: 13, color: user.userStatus == 1 ? Colors.red : Colors.green),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF6B7280)),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _tableFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: pagination()),
          Row(
            children: [
              const Text('Rows: ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              perPage(),
              const SizedBox(width: 16),
              if (!isMobile && !isTablet)
                Text(
                  '${(_page * _pageSize) - _pageSize + 1}–${math.min(_page * _pageSize, _totalCount)} of $_totalCount',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
            ],
          ),
        ],
      ),
    );
  }


  void _showFilterPanel() {
    showDialog(
      context: context,
      builder: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Material(
            color: Colors.white,
            elevation: 8,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 320,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filter Patients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _filterField(_userFullNameController, 'Full Name'),
                          const SizedBox(height: 12),
                          _filterField(_userNameController, 'Username'),
                          const SizedBox(height: 12),
                          _filterField(_userPhoneController, 'Contact Number'),
                          const SizedBox(height: 12),
                          _filterField(_userEmailController, 'Email'),
                          const SizedBox(height: 12),
                          StreamBuilder<DateTime>(
                            stream: rebuildDropdown.stream,
                            builder: (context, _) => Column(
                              children: [
                                AppDropdown(
                                  attributeList: DropdownAttributeList(
                                    [
                                      if (context.read<BranchController>().branchAllResponse?.data?.data != null)
                                        for (branch.Data item
                                            in context.read<BranchController>().branchAllResponse?.data?.data ?? [])
                                          DropdownAttribute(item.branchId ?? '', item.branchName ?? ''),
                                    ],
                                    labelText: 'information'.tr(gender: 'registeredBranch'),
                                    value: _selectedBranch?.name,
                                    onChanged: (p0) {
                                      _selectedBranch = p0;
                                      rebuildDropdown.add(DateTime.now());
                                      filtering(page: 1);
                                    },
                                    width: 280,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                AppDropdown(
                                  attributeList: DropdownAttributeList(
                                    [DropdownAttribute('1', 'Active'), DropdownAttribute('0', 'Inactive')],
                                    labelText: 'Status',
                                    value: _selectedUserStatus?.name,
                                    onChanged: (p0) {
                                      _selectedUserStatus = p0;
                                      rebuildDropdown.add(DateTime.now());
                                      filtering(page: 1);
                                    },
                                    width: 280,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                resetAllFilter();
                                filtering(enableDebounce: false, page: 1);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Clear Filters'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(top: 8, right: 8, child: CloseButton()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      onChanged: (_) => filtering(page: 1),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: secondaryColor, width: 1.5),
        ),
      ),
    );
  }


  void _handleMenuSelection(String value, UserResponse user) async {
    if (value == 'appointment') {
      showDialog(
        context: context,
        builder: (_) => AppointmentDetails(
          type: 'create',
          appointment: appointment_model.Data(
            user: appointment_model.User(
              userId: user.userId,
              userName: user.userName,
              userEmail: user.userEmail,
              userFullName: user.userFullname,
              userPhone: user.userPhone,
            ),
          ),
        ),
      );
    } else if (value == 'appointmentHistory') {
      showLoading();
      UserController.appointment(context, user.userId ?? '').then((value) {
        dismissLoading();
        if (responseCode(value.code)) {
          showDialog(
            context: context,
            builder: (_) => UserAppointmentIds(response: value.data, patient: user),
          );
        }
      });
    } else if (value == 'managePoints') {
      showDialog(
        context: context,
        builder: (_) => UserPointDetail(user: user),
      );
    } else if (value == 'update') {
      showDialog(
        context: context,
        builder: (_) => UserDetail(user: user, type: 'update'),
      );
    } else if (value == 'enableDisable') {
      try {
        if (await showConfirmDialog(
          context,
          user.userStatus == 1
              ? 'Are you certain you wish to deactivate this account?'
              : 'Are you certain you wish to activate this account?',
        )) {
          Future.delayed(Duration.zero, () {
            UserController.update(
              context,
              UpdateUserRequest(
                userId: user.userId,
                userName: user.userName,
                userFullname: user.userFullname,
                userDob: dateConverter(user.userDob, format: 'yyyy-MM-dd'),
                userPhone: user.userPhone,
                branchId: user.branchId,
                userStatus: user.userStatus == 1 ? 0 : 1,
              ),
            ).then((value) {
              if (responseCode(value.code)) {
                filtering();
                showDialogSuccess(
                  context,
                  'Account ${user.userStatus == 1 ? 'deactivated' : 'activated'} successfully.',
                );
              } else {
                showDialogError(context, value.message ?? value.data?.message ?? '');
              }
            });
          });
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }
  }

  String? translateToBranchName(String branchId) {
    try {
      return context
          .read<BranchController>()
          .branchAllResponse
          ?.data
          ?.data!
          .firstWhere((e) => e.branchId == branchId)
          .branchName;
    } catch (_) {
      return null;
    }
  }

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce ? _debouncer.run(() => runFiltering(page: page)) : runFiltering(page: page);
  }

  void runFiltering({bool enableDebounce = true, int? page}) {
    showLoading();
    if (page != null) _page = page;
    UserController.getAll(
      context,
      _page,
      _pageSize,
      userFullName: _userFullNameController.text,
      userName: _userNameController.text,
      userPhone: _userPhoneController.text,
      userEmail: _userEmailController.text,
      branchId: _selectedBranch?.key,
      userStatus: _selectedUserStatus != null
          ? _selectedUserStatus?.key == '1'
                ? 1
                : _selectedUserStatus?.key == '0'
                ? 0
                : null
          : null,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage = value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        context.read<UserController>().userAllResponse = value.data?.data;
      }
    });
  }

  void resetAllFilter() {
    _userFullNameController.text = '';
    _userNameController.text = '';
    _userPhoneController.text = '';
    _userEmailController.text = '';
    _selectedBranch = null;
    _selectedUserStatus = null;
    rebuildDropdown.add(DateTime.now());
    for (TableHeaderAttribute item in headers) {
      item.isSort = false;
      item.sort = SortType.asc;
    }
  }

  List<DataColumn2> columns() {
    return headers
        .map(
          (item) => DataColumn2(
            fixedWidth: item.width,
            size: item.columnSize ?? ColumnSize.M,
            label: Text(
              item.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
          ),
        )
        .toList();
  }

  Widget perPage() {
    return PerPageWidget(
      _pageSize.toString(),
      DropdownAttributeList(
        [],
        onChanged: (selected) {
          _pageSize = int.parse((selected as DropdownAttribute).key);
          filtering(enableDebounce: false);
        },
      ),
    );
  }

  Widget pagination() {
    return Pagination(
      numOfPages: _totalPage,
      selectedPage: _page,
      pagesVisible: isMobile ? 3 : 5,
      spacing: 10,
      onPageChanged: (page) => filtering(page: page, enableDebounce: false),
    );
  }

  String? getOrderBy() {
    try {
      return headers.firstWhere((e) => e.isSort).attribute;
    } catch (_) {
      return null;
    }
  }

  String? getSortType() {
    if (getOrderBy() != null) {
      return headers.firstWhere((e) => e.isSort).sort == SortType.asc ? 'asc' : 'desc';
    }
    return null;
  }
}
