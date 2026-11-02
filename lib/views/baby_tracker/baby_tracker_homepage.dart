import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/aurora_3d_womb_visualizer.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/patient_clinical_card.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/patient_detail_drawer.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/template_item_editor_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/debouncer/debouncer.dart';

class BabyTrackerHomepage extends StatefulWidget {
  static const routeName = '/aurora-baby';
  static const displayName = 'Aurora Baby';

  const BabyTrackerHomepage({super.key});

  @override
  State<BabyTrackerHomepage> createState() => _BabyTrackerHomepageState();
}

class _BabyTrackerHomepageState extends State<BabyTrackerHomepage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ---------------------------------------------------------------------------
  // Tab 0: Pregnancy Reports State
  // ---------------------------------------------------------------------------
  bool _isLoadingReports = true;
  String _reportSearch = '';
  String _reportStatus = 'all'; // all, overdue, alert, low_kicks, third_trimester
  int? _filterGestationalWeek;
  int _visualizerWeek = 20;
  int _reportPage = 1;
  final int _reportPageSize = 20;
  final _debouncer = Debouncer(milliseconds: 600);

  Map<String, dynamic> _reportSummary = {
    'totalActive': 0,
    'totalOverdue': 0,
    'totalAlerts': 0,
    'totalBorn': 0,
    'avgHospitalBagPercentage': 0,
  };
  List<dynamic> _patients = [];
  bool _isCardView = true;
  Map<String, dynamic>? _selectedPatientForDrawer;

  // ---------------------------------------------------------------------------
  // Tab 1: Checklist Template State
  // ---------------------------------------------------------------------------
  bool _isLoadingTemplate = false;
  String _selectedTemplateCategory = 'all';
  List<dynamic> _templateCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        if (_tabController.index == 1 && _templateCategories.isEmpty) {
          _fetchChecklistTemplate();
        }
      }
    });

    _fetchReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // API Calls
  // ===========================================================================

  void _fetchReports() {
    setState(() => _isLoadingReports = true);
    UserController.getPregnancyReports(
      context,
      search: _reportSearch,
      status: _reportStatus,
      week: _filterGestationalWeek,
      page: _reportPage,
      pageSize: _reportPageSize,
    ).then((resp) {
      if (!mounted) return;
      setState(() => _isLoadingReports = false);
      if (responseCode(resp.code) && resp.data != null) {
        final body = resp.data as Map<String, dynamic>;
        setState(() {
          _patients = body['data'] as List<dynamic>? ?? [];
          _reportSummary = (body['summary'] as Map<String, dynamic>?) ?? _reportSummary;
        });
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _isLoadingReports = false);
    });
  }

  void _fetchChecklistTemplate() {
    setState(() => _isLoadingTemplate = true);
    UserController.getBabyChecklistTemplate(
      context,
      category: _selectedTemplateCategory,
    ).then((resp) {
      if (!mounted) return;
      setState(() => _isLoadingTemplate = false);
      if (responseCode(resp.code) && resp.data != null) {
        final payload = resp.data['data'] as Map<String, dynamic>?;
        setState(() {
          _templateCategories = payload?['categories'] as List<dynamic>? ?? [];
        });
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _isLoadingTemplate = false);
    });
  }

  // ===========================================================================
  // UI Builder
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    const primaryAccentColor = Color(0xFF0284C7);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header & Tab Bar
                _buildTopBar(primaryAccentColor),
                const SizedBox(height: 16),

                // 3D Gestational Womb Visualizer Hero Section
                Aurora3DWombVisualizer(
                  initialWeek: _visualizerWeek,
                  initiallyExpanded: false,
                  onWeekChanged: (week) {
                    _visualizerWeek = week;
                  },
                  onFilterPatients: () {
                    setState(() {
                      _filterGestationalWeek = _visualizerWeek;
                      _reportPage = 1;
                      if (_tabController.index != 0) {
                        _tabController.animateTo(0);
                      }
                    });
                    _fetchReports();
                  },
                ),
                const SizedBox(height: 16),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildReportsTab(primaryAccentColor),
                      _buildTemplateTab(primaryAccentColor),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Slide-Over Inspection Drawer
          if (_selectedPatientForDrawer != null) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPatientForDrawer = null),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: PatientDetailDrawer(
                patient: _selectedPatientForDrawer!,
                onClose: () => setState(() => _selectedPatientForDrawer = null),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header with Tabs
  // ---------------------------------------------------------------------------
  Widget _buildTopBar(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.pregnant_woman_rounded, color: Color(0xFF0F172A), size: 22),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aurora Baby Hub',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey.shade900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemantauan Pergerakan Bayi & Kawalan Senarai Semak Kelahiran',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _tabButton(0, Icons.insights_rounded, 'Laporan Kehamilan', accentColor),
                const SizedBox(width: 4),
                _tabButton(1, Icons.tune_rounded, 'Templat Senarai Semak', accentColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, IconData icon, String title, Color activeColor) {
    final isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        setState(() => _tabController.animateTo(index));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 0: Pregnancy & Movement Reports
  // ===========================================================================

  Widget _buildReportsTab(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // KPI Metric Cards
        _buildMetricCards(),
        const SizedBox(height: 16),

        // Search & Filters bar
        _buildReportsFilterBar(accentColor),
        const SizedBox(height: 14),

        // Patients Content (Card Grid or Data Table)
        Expanded(
          child: _isLoadingReports
              ? const Center(child: CircularProgressIndicator())
              : _patients.isEmpty
                  ? _buildEmptyState('Tiada rekod kehamilan dijumpai.', 'Pesakit yang mendaftar EDD di aplikasi Aurora Baby akan dipaparkan di sini.')
                  : _isCardView
                      ? _buildPatientCardGrid()
                      : _buildReportsTable(accentColor),
        ),
      ],
    );
  }

  Widget _buildPatientCardGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1400 ? 3 : (constraints.maxWidth > 880 ? 2 : 1);
        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            mainAxisExtent: 290,
          ),
          itemCount: _patients.length,
          itemBuilder: (context, index) {
            final p = _patients[index] as Map<String, dynamic>;
            return PatientClinicalCard(
              patient: p,
              onOpenDetail: () {
                setState(() => _selectedPatientForDrawer = p);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCards() {
    final overdueCount = _reportSummary['totalOverdue'] ?? 0;
    final alertCount = _reportSummary['totalAlerts'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            label: 'Ibu Hamil Aktif',
            value: '${_reportSummary['totalActive'] ?? 0}',
            subtitle: 'Dalam pemantauan antenatal',
            onTap: () {
              setState(() {
                _reportStatus = 'all';
                _reportPage = 1;
              });
              _fetchReports();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            label: 'Melebihi 40 Minggu',
            value: '$overdueCount',
            subtitle: overdueCount > 0 ? 'Perlu tindakan induksi klinikal' : 'Tiada kes tertunggak',
            valueColor: overdueCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
            onTap: () {
              setState(() {
                _reportStatus = 'overdue';
                _reportPage = 1;
              });
              _fetchReports();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            label: 'Amaran Tendangan',
            value: '$alertCount',
            subtitle: '< 10 pergerakan hari ini (Wk 28+)',
            valueColor: alertCount > 0 ? const Color(0xFFD97706) : const Color(0xFF0F172A),
            onTap: () {
              setState(() {
                _reportStatus = 'alert';
                _reportPage = 1;
              });
              _fetchReports();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            label: 'Purata Beg Hospital',
            value: '${_reportSummary['avgHospitalBagPercentage'] ?? 0}%',
            subtitle: 'Kesiapan 10 barangan wad',
            valueColor: const Color(0xFF0284C7),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required String subtitle,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: valueColor ?? const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsFilterBar(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Search box
          Expanded(
            flex: 3,
            child: TextField(
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, color: Color(0xFF1E293B)),
              onChanged: (val) {
                _reportSearch = val;
                _debouncer.run(_fetchReports);
              },
              decoration: InputDecoration(
                hintText: 'Cari nama pesakit, nombor telefon, atau emel...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Status Filter Chips (Zero childish emojis)
          _filterChip('all', 'Semua', const Color(0xFF0F172A)),
          const SizedBox(width: 6),
          _filterChip('overdue', 'Overdue (>40 M)', const Color(0xFFDC2626)),
          const SizedBox(width: 6),
          _filterChip('alert', 'Pergerakan Rendah', const Color(0xFFD97706)),
          const SizedBox(width: 6),
          _filterChip('third_trimester', 'Trimester 3 (28+ M)', const Color(0xFF0284C7)),
          if (_filterGestationalWeek != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Minggu $_filterGestationalWeek',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _filterGestationalWeek = null;
                        _reportPage = 1;
                      });
                      _fetchReports();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 10),

          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            tooltip: 'Muat Semula',
            onPressed: _fetchReports,
          ),
          const SizedBox(width: 8),

          // View mode toggle: Card Grid vs Data Table
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => setState(() => _isCardView = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isCardView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: _isCardView
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.grid_view_rounded,
                          size: 15,
                          color: _isCardView ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Kad Fail',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isCardView ? FontWeight.bold : FontWeight.w500,
                            color: _isCardView ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => setState(() => _isCardView = false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: !_isCardView ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: !_isCardView
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_rows_rounded,
                          size: 15,
                          color: !_isCardView ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Jadual',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: !_isCardView ? FontWeight.bold : FontWeight.w500,
                            color: !_isCardView ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String statusKey, String label, Color accentColor) {
    final isSelected = _reportStatus == statusKey;
    return InkWell(
      onTap: () {
        setState(() {
          _reportStatus = statusKey;
          _reportPage = 1;
        });
        _fetchReports();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? accentColor : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildReportsTable(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable2(
          columnSpacing: 16,
          horizontalMargin: 20,
          minWidth: 860,
          headingRowHeight: 48,
          dataRowHeight: 64,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn2(label: Text('PESAKIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.L),
            DataColumn2(label: Text('TARIKH EDD / USIA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.M),
            DataColumn2(label: Text('TENDANGAN HARI INI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.M),
            DataColumn2(label: Text('BEG HOSPITAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.S),
            DataColumn2(label: Text('STATUS RISIKO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.M),
            DataColumn2(label: Text('TINDAKAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), size: ColumnSize.S),
          ],
          rows: _patients.map((p) {
            final name = p['patientName'] ?? 'Pesakit';
            final phone = p['patientPhone'] ?? '-';
            final branch = p['branchName'] ?? 'Klinik Aurora';
            final edd = p['eddDate'] ?? '-';
            final week = p['gestationalWeek'];
            final trimester = p['trimester'];
            final kicks = p['todayKicks'] ?? 0;
            final lastKick = p['lastKickAt'];
            final bagPct = p['hospitalBagPercentage'] ?? 0;
            final isOverdue = p['isOverdue'] == true;
            final alertStatus = p['alertStatus'] ?? 'normal';

            return DataRow(
              cells: [
                // Patient Name & contact
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      Text('$phone • $branch', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
                    ],
                  ),
                ),

                // EDD & Week
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(edd, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      if (week != null)
                        Text(
                          'Minggu $week (${trimester != null ? 'Trimester $trimester' : ''})',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),

                // Today's Kicks
                DataCell(
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kicks >= 10
                              ? const Color(0xFFECFDF5)
                              : kicks > 0
                                  ? const Color(0xFFFFFBEB)
                                  : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$kicks kali',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: kicks >= 10
                                ? const Color(0xFF15803D)
                                : kicks > 0
                                    ? const Color(0xFFD97706)
                                    : Colors.grey.shade600,
                          ),
                        ),
                      ),
                      if (lastKick != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          lastKick.toString().split(' ').last,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ),

                // Hospital Bag
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: bagPct == 100
                          ? const Color(0xFFECFDF5)
                          : bagPct >= 50
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$bagPct%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: bagPct == 100
                            ? const Color(0xFF059669)
                            : bagPct >= 50
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFEA580C),
                      ),
                    ),
                  ),
                ),

                // Risk Status
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: alertStatus == 'overdue'
                          ? const Color(0xFFFEE2E2)
                          : alertStatus == 'low_kicks'
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alertStatus == 'overdue'
                          ? 'Overdue'
                          : alertStatus == 'low_kicks'
                              ? 'Pergerakan Rendah'
                              : 'Stabil',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: alertStatus == 'overdue'
                            ? const Color(0xFFB91C1C)
                            : alertStatus == 'low_kicks'
                                ? const Color(0xFFB45309)
                                : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),

                // Actions: Open Patient Detail Drawer
                DataCell(
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedPatientForDrawer = p as Map<String, dynamic>);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Buka Fail', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 1: Master Checklist Template Management
  // ===========================================================================

  Widget _buildTemplateTab(Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Controls & Category selector
        _buildTemplateHeaderBar(accentColor),
        const SizedBox(height: 14),

        // Items List
        Expanded(
          child: _isLoadingTemplate
              ? const Center(child: CircularProgressIndicator())
              : _templateCategories.isEmpty
                  ? _buildEmptyState('Tiada templat dijumpai.', 'Klik "+ Tambah Item Templat" untuk memulakan.')
                  : _buildTemplateCategoriesList(accentColor),
        ),
      ],
    );
  }

  Widget _buildTemplateHeaderBar(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _categoryFilterChip('all', 'Semua Kategori', accentColor),
              const SizedBox(width: 8),
              _categoryFilterChip('baju', 'Baju', accentColor),
              const SizedBox(width: 8),
              _categoryFilterChip('mandi', 'Mandi', accentColor),
              const SizedBox(width: 8),
              _categoryFilterChip('tidur', 'Tidur', accentColor),
              const SizedBox(width: 8),
              _categoryFilterChip('penyusuan', 'Penyusuan', accentColor),
              const SizedBox(width: 8),
              _categoryFilterChip('beg_hospital', 'Beg Hospital', accentColor),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _openAddTemplateItemDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Tambah Item Templat', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryFilterChip(String catKey, String label, Color accentColor) {
    final isSelected = _selectedTemplateCategory == catKey;
    return InkWell(
      onTap: () {
        setState(() => _selectedTemplateCategory = catKey);
        _fetchChecklistTemplate();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String key) {
    switch (key) {
      case 'baju':
        return Icons.checkroom_outlined;
      case 'mandi':
        return Icons.bathtub_outlined;
      case 'tidur':
        return Icons.bed_outlined;
      case 'penyusuan':
        return Icons.child_friendly_outlined;
      case 'beg_hospital':
        return Icons.medical_services_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  Widget _buildTemplateCategoriesList(Color accentColor) {
    return ListView.builder(
      itemCount: _templateCategories.length,
      itemBuilder: (context, idx) {
        final cat = _templateCategories[idx];
        final items = (cat['items'] as List<dynamic>?) ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Icon(
                _getCategoryIcon(cat['categoryKey']?.toString() ?? ''),
                size: 18,
                color: const Color(0xFF0F172A),
              ),
            ),
            title: Text(
              cat['title'] ?? 'Kategori',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              '${items.length} barangan (${items.where((i) => i['isWajib'] == true).length} Wajib)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            children: items.map((item) {
              final isWajib = item['isWajib'] == true;
              final isHospitalBag = item['isHospitalBag'] == true;
              final specs = item['drAuroraAdvice']?['specs'] ?? '';
              final safety = item['drAuroraAdvice']?['safety'] ?? '';
              final savingTip = item['drAuroraAdvice']?['savingTip'] ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item['title'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              if (item['quantity'] != null && item['quantity'].toString().isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${item['quantity']}',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 8),
                              if (isWajib)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFFECACA)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star_rounded, size: 12, color: Color(0xFFDC2626)),
                                      SizedBox(width: 3),
                                      Text('WAJIB', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                    ],
                                  ),
                                ),
                              if (isHospitalBag) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.medical_services_rounded, size: 12, color: Color(0xFF2563EB)),
                                      SizedBox(width: 3),
                                      Text('Beg Hospital', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (specs.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      specs,
                                      style: TextStyle(fontSize: 11.5, color: Colors.blueGrey.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (safety.isNotEmpty || savingTip.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (safety.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.security_outlined, size: 12, color: Color(0xFF92400E)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Keselamatan: $safety',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (savingTip.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.tips_and_updates_outlined, size: 12, color: Color(0xFF065F46)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Tip: $savingTip',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF065F46)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                      tooltip: 'Kemaskini',
                      onPressed: () => _openEditTemplateItemDialog(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'Padam',
                      onPressed: () => _confirmDeleteItem(item['templateId']),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dialogs: Add & Edit Template Item (Modernized with TemplateItemEditorDialog)
  // ---------------------------------------------------------------------------

  void _openAddTemplateItemDialog() {
    final catKey = _selectedTemplateCategory != 'all' ? _selectedTemplateCategory : 'baju';
    TemplateItemEditorDialog.show(
      context,
      categoryKey: catKey,
      onSave: (data) async {
        await UserController.createBabyChecklistTemplateItem(context, data);
        _fetchChecklistTemplate();
      },
    );
  }

  void _openEditTemplateItemDialog(Map<String, dynamic> item) {
    TemplateItemEditorDialog.show(
      context,
      item: item,
      onSave: (data) async {
        await UserController.updateBabyChecklistTemplateItem(context, item['templateId'], data);
        _fetchChecklistTemplate();
      },
    );
  }

  void _confirmDeleteItem(String templateId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Padam Item Templat?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: const Text('Item ini tidak lagi akan muncul dalam senarai semak pesakit baharu.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                UserController.deleteBabyChecklistTemplateItem(context, templateId)
                    .then((_) => _fetchChecklistTemplate());
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
              child: const Text('Padam'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
