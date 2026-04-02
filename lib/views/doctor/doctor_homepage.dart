import 'dart:async';

import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/doctor/doctor_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/doctor/doctor_branch_response.dart';
import 'package:klinik_aurora_portal/models/doctor/update_doctor_request.dart';
import 'package:klinik_aurora_portal/views/doctor/doctor_detail.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/no_records/no_records.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/table/data_per_page.dart';
import 'package:klinik_aurora_portal/views/widgets/table/pagination.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class DoctorHomepage extends StatefulWidget {
  static const routeName = '/pic';
  static const displayName = 'Person In Charge';
  final String? branchId;
  const DoctorHomepage({super.key, this.branchId});

  @override
  State<DoctorHomepage> createState() => _DoctorHomepageState();
}

class _DoctorHomepageState extends State<DoctorHomepage> {
  int _page = 1;
  int _pageSize = pageSize;
  int _totalCount = 0;
  int _totalPage = 0;
  final _debouncer = Debouncer(milliseconds: 1200);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DropdownAttribute? _selectedStatus;
  StreamController<DateTime> rebuildDropdown = StreamController.broadcast();

  static const List<Color> _avatarColors = [
    Color(0xFF6AD1E3), Color(0xFFDF6E98), Color(0xFF7E57C2),
    Color(0xFF26A69A), Color(0xFFEF5350), Color(0xFF42A5F5),
    Color(0xFFFF7043), Color(0xFF66BB6A),
  ];

  Color _avatarColor(String name) =>
      name.isEmpty ? _avatarColors[0] : _avatarColors[name.codeUnitAt(0) % _avatarColors.length];

  String _initials(String? name) {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n[0].toUpperCase();
  }

  @override
  void initState() {
    dismissLoading();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      Provider.of<TopBarController>(context, listen: false).pageValue =
          Homepage.getPageId(DoctorHomepage.displayName);
      if (context.read<BranchController>().branchAllResponse == null) {
        BranchController.getAll(context, 1, 1000).then((value) {
          if (responseCode(value.code)) context.read<BranchController>().branchAllResponse = value;
        });
      }
      filtering();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutWidget(mobile: _mobileView(), desktop: _desktopView());

  // ─── Mobile ──────────────────────────────────────────────────────────────────

  Widget _mobileView() {
    return Consumer<DoctorController>(
      builder: (context, snapshot, _) {
        final docs = snapshot.doctorBranchResponse?.data ?? [];
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, 0),
              child: _searchInput(_nameController, 'Search by name…'),
            ),
            Expanded(
              child: docs.isEmpty
                  ? const Center(child: NoRecordsWidget())
                  : ListView.builder(
                      padding: EdgeInsets.all(screenPadding),
                      itemCount: docs.length,
                      itemBuilder: (_, i) => _mobileCard(docs[i]),
                    ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenPadding / 2),
              child: _pagination(),
            ),
          ],
        );
      },
    );
  }

  Widget _mobileCard(Data doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB))),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _avatar(doc),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.doctorName ?? 'N/A',
                      style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 2)),
                  const SizedBox(height: 2),
                  Text(doc.doctorPhone ?? '—',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                  const SizedBox(height: 4),
                  _statusChip(doc.doctorStatus == 1),
                ],
              ),
            ),
            _actionMenu(doc),
          ],
        ),
      ),
    );
  }

  // ─── Desktop ─────────────────────────────────────────────────────────────────

  Widget _desktopView() {
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
          Expanded(
            child: SizedBox(
              height: 40,
              child: _searchInput(_nameController, 'Search by PIC name…'),
            ),
          ),
          const SizedBox(width: 12),
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
          IconButton(
            onPressed: () { _resetFilters(); filtering(enableDebounce: false, page: 1); },
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6B7280)),
            tooltip: 'Reset filters',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () =>
                showDialog(context: context, builder: (_) => const DoctorDetails(type: 'create')),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
            label: const Text('Add PIC', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
    return Consumer<DoctorController>(
      builder: (context, snapshot, _) {
        if (snapshot.doctorBranchResponse == null) {
          return const Center(child: CircularProgressIndicator(color: secondaryColor));
        }
        final docs = snapshot.doctorBranchResponse?.data ?? [];
        if (docs.isEmpty) {
          return Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB))),
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
              Expanded(child: _dataTable(docs)),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              _tableFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _dataTable(List<Data> docs) {
    const headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280));
    return DataTable2(
      columnSpacing: 12,
      horizontalMargin: 16,
      isHorizontalScrollBarVisible: false,
      isVerticalScrollBarVisible: true,
      decoration: const BoxDecoration(),
      headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
      headingRowHeight: 44,
      dataRowHeight: 64,
      dividerThickness: 1,
      columns: const [
        DataColumn2(label: Text('Person In Charge', style: headerStyle), size: ColumnSize.M),
        DataColumn2(label: Text('Contact', style: headerStyle), size: ColumnSize.S),
        DataColumn2(label: Text('Branch', style: headerStyle), size: ColumnSize.M),
        DataColumn2(label: Text('Status', style: headerStyle), fixedWidth: 90),
        DataColumn2(label: Text('Joined', style: headerStyle), size: ColumnSize.S),
        DataColumn2(label: Text('', style: headerStyle), fixedWidth: 56),
      ],
      rows: docs.map((doc) => DataRow2(
        color: WidgetStateProperty.all(Colors.white),
        cells: [
          // Name + avatar
          DataCell(Row(
            children: [
              _avatar(doc),
              const SizedBox(width: 10),
              Expanded(
                child: Text(doc.doctorName ?? 'N/A',
                    style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          )),
          // Phone
          DataCell(Text(doc.doctorPhone ?? '—',
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)))),
          // Branch
          DataCell(Text(_branchName(doc.branchId ?? '') ?? '—',
              style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
          // Status
          DataCell(_statusChip(doc.doctorStatus == 1)),
          // Created
          DataCell(Text(dateConverter(doc.createdDate) ?? '—',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          // Actions
          DataCell(_actionMenu(doc)),
        ],
      )).toList(),
    );
  }

  Widget _avatar(Data doc) {
    final color = _avatarColor(doc.doctorName ?? '');
    if (doc.doctorImage != null) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage('${Environment.imageUrl}${doc.doctorImage}'),
        onBackgroundImageError: (_, __) {},
        backgroundColor: color.withAlpha(40),
        child: null,
      );
    }
    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withAlpha(40),
      child: Text(_initials(doc.doctorName),
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
    );
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

  Widget _actionMenu(Data doc) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      offset: const Offset(0, 32),
      color: Colors.white,
      elevation: 4,
      tooltip: '',
      onSelected: (value) => _handleMenu(value, doc),
      itemBuilder: (_) => [
        PopupMenuItem<String>(
          value: 'update',
          child: Row(children: const [
            Icon(Icons.edit_outlined, size: 16, color: Color(0xFF6B7280)),
            SizedBox(width: 10),
            Text('Update', style: TextStyle(fontSize: 13)),
          ]),
        ),
        PopupMenuItem<String>(
          value: 'enableDisable',
          child: Row(children: [
            Icon(doc.doctorStatus == 1 ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                size: 16, color: doc.doctorStatus == 1 ? Colors.red : Colors.green),
            const SizedBox(width: 10),
            Text(doc.doctorStatus == 1 ? 'Deactivate' : 'Re-Activate',
                style: TextStyle(
                    fontSize: 13,
                    color: doc.doctorStatus == 1 ? Colors.red : Colors.green)),
          ]),
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

  Widget _tableFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _pagination()),
          Row(children: [
            const Text('Rows: ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            _perPage(),
            const SizedBox(width: 16),
            if (!isMobile && !isTablet)
              Text(
                '${(_page * _pageSize) - _pageSize + 1}–${(_page * _pageSize < _totalCount) ? _page * _pageSize : _totalCount} of $_totalCount',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
          ]),
        ],
      ),
    );
  }

  // ─── Filter Panel ─────────────────────────────────────────────────────────────

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
              width: 300,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Filter PICs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        _filterTextField(_nameController, 'PIC Name'),
                        const SizedBox(height: 12),
                        _filterTextField(_phoneController, 'Contact Number'),
                        const SizedBox(height: 12),
                        StreamBuilder<DateTime>(
                          stream: rebuildDropdown.stream,
                          builder: (context, _) => AppDropdown(
                            attributeList: DropdownAttributeList(
                              [DropdownAttribute('1', 'Active'), DropdownAttribute('0', 'Inactive')],
                              labelText: 'Status',
                              value: _selectedStatus?.name,
                              onChanged: (p0) {
                                _selectedStatus = p0;
                                rebuildDropdown.add(DateTime.now());
                                filtering(page: 1);
                              },
                              width: 260,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () { _resetFilters(); filtering(enableDebounce: false, page: 1); },
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
                  Positioned(
                    top: 8, right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  Widget _searchInput(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      onChanged: (_) { setState(() {}); filtering(page: 1); },
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 18),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF9CA3AF)),
                onPressed: () { ctrl.clear(); filtering(enableDebounce: false, page: 1); setState(() {}); })
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: secondaryColor, width: 1.5)),
      ),
    );
  }

  Widget _filterTextField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => filtering(page: 1),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: secondaryColor, width: 1.5)),
      ),
    );
  }

  void _handleMenu(String value, Data doc) async {
    if (value == 'update') {
      showDialog(context: context, builder: (_) => DoctorDetails(doctor: doc, type: 'update'));
    } else if (value == 'enableDisable') {
      try {
        if (await showConfirmDialog(
          context,
          doc.doctorStatus == 1
              ? 'Are you certain you wish to deactivate this PIC?'
              : 'Are you certain you wish to activate this PIC?',
        )) {
          Future.delayed(Duration.zero, () {
            DoctorController.update(
              context,
              UpdateDoctorRequest(
                doctorId: doc.doctorId, doctorName: doc.doctorName,
                branchId: doc.branchId, doctorPhone: doc.doctorPhone,
                doctorStatus: doc.doctorStatus == 1 ? 0 : 1,
              ),
            ).then((value) {
              if (responseCode(value.code)) {
                filtering();
                showDialogSuccess(context,
                    'PIC ${doc.doctorStatus == 1 ? 'deactivated' : 'activated'} successfully.');
              } else {
                showDialogError(context, value.message ?? value.data?.message ?? '');
              }
            });
          });
        }
      } catch (e) { debugPrint(e.toString()); }
    }
  }

  String? _branchName(String branchId) {
    try {
      return context.read<BranchController>().branchAllResponse?.data?.data!
          .firstWhere((e) => e.branchId == branchId).branchName;
    } catch (_) { return null; }
  }

  void filtering({bool enableDebounce = true, int? page}) {
    enableDebounce ? _debouncer.run(() => _runFiltering(page: page)) : _runFiltering(page: page);
  }

  void _runFiltering({int? page}) {
    showLoading();
    if (page != null) _page = page;
    DoctorController.get(
      context, _page, _pageSize,
      branchId: context.read<AuthController>().isSuperAdmin
          ? null
          : context.read<AuthController>().authenticationResponse?.data?.user?.branchId,
      doctorName: _nameController.text,
      doctorPhone: _phoneController.text,
      doctorStatus: _selectedStatus != null
          ? _selectedStatus?.key == '1' ? 1 : 0
          : null,
    ).then((value) {
      dismissLoading();
      if (responseCode(value.code)) {
        _totalCount = value.data?.totalCount ?? 0;
        _totalPage = value.data?.totalPage ?? ((value.data?.data?.length ?? 0) / _pageSize).ceil();
        context.read<DoctorController>().doctorBranchResponse = value.data;
      }
    });
  }

  void _resetFilters() {
    _nameController.text = '';
    _phoneController.text = '';
    _selectedStatus = null;
    rebuildDropdown.add(DateTime.now());
  }

  Widget _perPage() {
    return PerPageWidget(_pageSize.toString(), DropdownAttributeList([], onChanged: (selected) {
      _pageSize = int.parse((selected as DropdownAttribute).key);
      filtering(enableDebounce: false);
    }));
  }

  Widget _pagination() {
    return Pagination(
      numOfPages: _totalPage, selectedPage: _page,
      pagesVisible: isMobile ? 3 : 5, spacing: 10,
      onPageChanged: (page) => filtering(page: page, enableDebounce: false),
    );
  }
}
