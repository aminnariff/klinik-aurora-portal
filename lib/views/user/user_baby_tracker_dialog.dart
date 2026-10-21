import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/aurora_3d_womb_visualizer.dart';

class UserBabyTrackerDialog extends StatefulWidget {
  final UserResponse? patient;
  const UserBabyTrackerDialog({super.key, required this.patient});

  @override
  State<UserBabyTrackerDialog> createState() => _UserBabyTrackerDialogState();
}

class _UserBabyTrackerDialogState extends State<UserBabyTrackerDialog> {
  int _dialogTab = 0; // 0: Kicks, 1: Checklist

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profile;
  int _todayKicks = 0;
  List<dynamic> _sessions = [];

  // Checklist state
  bool _isLoadingChecklist = false;
  Map<String, dynamic>? _checklistSummary;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    final userId = widget.patient?.userId;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Patient user ID not found';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isLoadingChecklist = true;
    });

    // 1. Fetch kick tracker data
    UserController.babyTracker(context, userId).then((resp) {
      if (!mounted) return;
      if (responseCode(resp.code) && resp.data != null) {
        final payload = resp.data['data'] as Map<String, dynamic>?;
        setState(() {
          _isLoading = false;
          _profile = payload?['profile'] as Map<String, dynamic>?;
          _todayKicks = int.tryParse(payload?['todayKicks']?.toString() ?? '') ?? 0;
          _sessions = payload?['sessions'] as List<dynamic>? ?? [];
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = resp.message ?? 'Unable to fetch baby tracker data';
        });
      }
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    });

    // 2. Fetch checklist data
    UserController.babyChecklist(context, userId).then((resp) {
      if (!mounted) return;
      if (responseCode(resp.code) && resp.data != null) {
        final payload = resp.data['data'] as Map<String, dynamic>?;
        setState(() {
          _isLoadingChecklist = false;
          _checklistSummary = payload;
        });
      } else {
        setState(() {
          _isLoadingChecklist = false;
        });
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() {
        _isLoadingChecklist = false;
      });
    });
  }

  int? get _gestationalWeek {
    final eddStr = _profile?['eddDate']?.toString();
    if (eddStr == null) return null;
    final edd = DateTime.tryParse(eddStr);
    if (edd == null) return null;
    final lmp = edd.subtract(const Duration(days: 280));
    final days = DateTime.now().difference(lmp).inDays;
    if (days < 0 || days > 42 * 7) return null;
    return (days / 7).floor() + 1;
  }

  String? get _trimester {
    final week = _gestationalWeek;
    if (week == null) return null;
    if (week <= 13) return '1st Trimester';
    if (week <= 27) return '2nd Trimester';
    return '3rd Trimester';
  }

  @override
  Widget build(BuildContext context) {
    const pinkColor = Color(0xFFE91E8C);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(760, MediaQuery.of(context).size.width * 0.94),
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: pinkColor.withValues(alpha: 0.15))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: pinkColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(_dialogTab == 0 ? '👣' : '📋', style: const TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dialogTab == 0
                                  ? 'Baby Kick Tracker & Fetal Movement'
                                  : 'Baby Preparation Checklist & Hospital Bag',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.patient?.userFullname ?? widget.patient?.userName ?? 'Patient',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        splashRadius: 18,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Sub-tab switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: pinkColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _dialogTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _dialogTab == 0 ? pinkColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '🦶 Tendangan & Pergerakan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _dialogTab == 0 ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _dialogTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _dialogTab == 1 ? pinkColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '📋 Checklist & Beg Hospital',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _dialogTab == 1 ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: _dialogTab == 0 ? _buildKicksBody(pinkColor) : _buildChecklistBody(pinkColor),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 0: Fetal Kicks Body
  // ---------------------------------------------------------------------------

  Widget _buildKicksBody(Color pinkColor) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_profile == null && _sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.child_care_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No baby tracker or kick data recorded for this patient.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_gestationalWeek != null) ...[
            _buildGestational3DHeroCard(_gestationalWeek!, pinkColor),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: 'Estimated Due Date (EDD)',
                  value: _profile?['eddDate'] != null
                      ? DateFormat('d MMM yyyy').format(DateTime.parse(_profile!['eddDate']))
                      : 'Not Set',
                  subtitle: _gestationalWeek != null
                      ? 'Week $_gestationalWeek · $_trimester'
                      : 'Pregnancy tracking',
                  icon: Icons.calendar_today_rounded,
                  color: pinkColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCard(
                  title: "Today's Kicks",
                  value: '$_todayKicks kicks',
                  subtitle: 'Total recorded today',
                  icon: Icons.touch_app_rounded,
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCard(
                  title: 'Total Sessions',
                  value: '${_sessions.length} sessions',
                  subtitle: 'Logged history',
                  icon: Icons.history_rounded,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Kick Session History',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),
          if (_sessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              alignment: Alignment.center,
              child: Text(
                'No kick sessions recorded yet.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(1.4),
                  1: FlexColumnWidth(1.2),
                  2: FlexColumnWidth(1.0),
                  3: FlexColumnWidth(1.0),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey.shade100),
                    children: const [
                      _TableHeader('Date & Time'),
                      _TableHeader('End Time'),
                      _TableHeader('Kicks Count'),
                      _TableHeader('Status'),
                    ],
                  ),
                  ..._sessions.map((sess) {
                    final startStr = sess['startTime']?.toString() ?? '';
                    final endStr = sess['endTime']?.toString();
                    final kickCount = sess['kickCount']?.toString() ?? '0';
                    final isActive = endStr == null || endStr.isEmpty;

                    return TableRow(
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      children: [
                        _TableCell(startStr),
                        _TableCell(endStr ?? '—'),
                        _TableCell(
                          '$kickCount kicks',
                          isBold: true,
                          textColor: pinkColor,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? pinkColor.withValues(alpha: 0.1)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Completed',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? pinkColor : Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tab 1: Checklist Body
  // ---------------------------------------------------------------------------

  Widget _buildChecklistBody(Color pinkColor) {
    if (_isLoadingChecklist) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFFE91E8C)),
        ),
      );
    }

    if (_checklistSummary == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Tiada rekod checklist ditemui untuk pesakit ini.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final totalItems = _checklistSummary?['totalItems'] ?? 0;
    final completedItems = _checklistSummary?['completedItems'] ?? 0;
    final progress = _checklistSummary?['progressPercentage'] ?? 0;
    final hbTotal = _checklistSummary?['hospitalBagTotal'] ?? 0;
    final hbCompleted = _checklistSummary?['hospitalBagCompleted'] ?? 0;
    final hbProgress = _checklistSummary?['hospitalBagPercentage'] ?? 0;
    final categories = (_checklistSummary?['categories'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Readiness metrics cards
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  title: 'Status Persediaan Keseluruhan',
                  value: '$progress% Sedia',
                  subtitle: '$completedItems daripada $totalItems barangan siap',
                  icon: Icons.checklist_rounded,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _metricCard(
                  title: 'Beg Hospital (Kritikal Wad)',
                  value: '$hbProgress% Sedia',
                  subtitle: '$hbCompleted daripada $hbTotal barangan siap',
                  icon: Icons.medical_services_outlined,
                  color: pinkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Categories list
          Text(
            'Pecahan Kategori Checklist Pesakit',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 12),

          ...categories.map((cat) {
            final catTitle = cat['title']?.toString() ?? '';
            final catIcon = cat['icon']?.toString() ?? '📦';
            final catKey = cat['categoryKey']?.toString() ?? '';
            final itemCount = cat['itemCount'] ?? 0;
            final completedCount = cat['completedCount'] ?? 0;
            final items = (cat['items'] as List<dynamic>?) ?? [];
            final isHospitalBag = catKey == 'beg_hospital';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isHospitalBag ? const Color(0xFFFFF1F2) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isHospitalBag ? const Color(0xFFFDA4AF) : Colors.grey.shade200,
                  width: isHospitalBag ? 1.5 : 1,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: isHospitalBag,
                shape: const Border(),
                leading: Text(catIcon, style: const TextStyle(fontSize: 20)),
                title: Row(
                  children: [
                    Text(
                      catTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isHospitalBag ? const Color(0xFFBE123C) : Colors.grey.shade900,
                      ),
                    ),
                    if (isHospitalBag) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Kritikal Wad',
                          style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: completedCount == itemCount && itemCount > 0
                        ? const Color(0xFFDCFCE7)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$completedCount / $itemCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: completedCount == itemCount && itemCount > 0
                          ? const Color(0xFF15803D)
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      children: items.map((item) {
                        final isChecked = item['isChecked'] == true || item['isChecked'] == 1;
                        final title = item['title']?.toString() ?? '';
                        final qty = item['quantity']?.toString() ?? '';
                        final notes = item['notes']?.toString() ?? '';
                        final isWajib = item['isWajib'] == true || item['isWajib'] == 1;

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: isChecked ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isChecked ? const Color(0xFFBBF7D0) : Colors.grey.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                size: 18,
                                color: isChecked ? const Color(0xFF16A34A) : Colors.grey.shade400,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        decoration: isChecked ? TextDecoration.lineThrough : null,
                                        color: isChecked ? Colors.grey.shade600 : Colors.grey.shade900,
                                      ),
                                    ),
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Nota: $notes',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (qty.isNotEmpty)
                                Text(
                                  qty,
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                              if (isWajib) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Wajib',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFDC2626),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGestational3DHeroCard(int week, Color pinkColor) {
    final bio = Aurora3DWombVisualizer.getBiometricsForWeek(week);
    final trimesterText = bio.trimester == 1
        ? 'Trimester 1'
        : bio.trimester == 2
            ? 'Trimester 2'
            : 'Trimester 3';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF5F8), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD1DC), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE84C7A).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 3D Mini Womb Orb with cardiac Doppler pulse
          Container(
            width: 95,
            height: 95,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE4E6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Mini3DWombOrb(week: week, size: 88),
          ),
          const SizedBox(width: 16),

          // Biometrics Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: pinkColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Minggu $week • $trimesterText',
                        style: TextStyle(
                          color: pinkColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${bio.fruitEmoji} ${bio.fruit}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Metrics Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _bioChip('Panjang (CRL)', bio.formattedCrl),
                    _bioChip('Anggaran Berat', bio.formattedWeight),
                    _bioChip('Diameter Kepala (BPD)', bio.formattedBpd),
                    _bioChip('Denyutan Jantung', bio.formattedFhr),
                  ],
                ),
                const SizedBox(height: 8),

                // Clinical note
                Text(
                  '💖 Dr. Aurora: ${bio.milestone}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bioChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  const _TableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey.shade700),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final bool isBold;
  final Color? textColor;

  const _TableCell(this.text, {this.isBold = false, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: textColor ?? Colors.grey.shade800,
        ),
      ),
    );
  }
}
