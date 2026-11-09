import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PatientDetailDrawer extends StatefulWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onClose;

  const PatientDetailDrawer({
    super.key,
    required this.patient,
    required this.onClose,
  });

  @override
  State<PatientDetailDrawer> createState() => _PatientDetailDrawerState();
}

class _PatientDetailDrawerState extends State<PatientDetailDrawer> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingTracker = true;
  bool _isLoadingChecklist = true;
  String? _trackerError;

  int _todayKicks = 0;
  List<dynamic> _sessions = [];
  Map<String, dynamic>? _checklistSummary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final userId = widget.patient['userId']?.toString() ?? '';
    if (userId.isEmpty) return;

    // Load Kick Tracker Data
    UserController.babyTracker(context, userId).then((resp) {
      if (!mounted) return;
      if (responseCode(resp.code) && resp.data != null) {
        final payload = resp.data['data'] as Map<String, dynamic>?;
        setState(() {
          _isLoadingTracker = false;
          _todayKicks = int.tryParse(payload?['todayKicks']?.toString() ?? '') ?? 0;
          _sessions = payload?['sessions'] as List<dynamic>? ?? [];
        });
      } else {
        setState(() {
          _isLoadingTracker = false;
          _trackerError = resp.message ?? 'Tiada data tendangan ditemui.';
        });
      }
    }).catchError((e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTracker = false;
        _trackerError = e.toString();
      });
    });

    // Load Checklist Data
    UserController.babyChecklist(context, userId).then((resp) {
      if (!mounted) return;
      if (responseCode(resp.code) && resp.data != null) {
        final payload = resp.data['data'] as Map<String, dynamic>?;
        setState(() {
          _isLoadingChecklist = false;
          _checklistSummary = payload;
        });
      } else {
        setState(() => _isLoadingChecklist = false);
      }
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _isLoadingChecklist = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.patient['patientName'] ?? 'Pesakit';
    final phone = widget.patient['patientPhone'] ?? '-';
    final branch = widget.patient['branchName'] ?? 'Klinik Aurora';
    final edd = widget.patient['eddDate'] ?? '-';
    final week = widget.patient['gestationalWeek'] as int?;
    final trimester = widget.patient['trimester'] as int?;
    final isOverdue = widget.patient['isOverdue'] == true;
    final alertStatus = widget.patient['alertStatus'] ?? 'normal';
    final alertReason = widget.patient['alertReason'] as String?;

    return Container(
      width: math.min(580.0, MediaQuery.of(context).size.width * 0.95),
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drawer Header
          _buildHeader(name, phone, branch, edd, week, trimester, isOverdue, alertStatus, alertReason),

          // Tab Navigation Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0F172A),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF0284C7),
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(
                  icon: Icon(Icons.show_chart_rounded, size: 16),
                  text: 'Pergerakan Janin',
                ),
                Tab(
                  icon: Icon(Icons.medical_services_outlined, size: 16),
                  text: 'Beg Hospital (Wad)',
                ),
                Tab(
                  icon: Icon(Icons.checklist_rounded, size: 16),
                  text: 'Senarai Semak Penuh',
                ),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildKicksTab(),
                _buildHospitalBagTab(),
                _buildAllChecklistTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    String name,
    String phone,
    String branch,
    String edd,
    int? week,
    int? trimester,
    bool isOverdue,
    String alertStatus,
    String? alertReason,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Name + Actions
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF334155),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$phone • $branch',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (phone != '-' && phone.isNotEmpty)
                IconButton(
                  tooltip: 'Buka WhatsApp',
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF059669), size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    final phoneWithCode = clean.startsWith('6') ? clean : '6$clean';
                    launchUrlString('https://wa.me/$phoneWithCode');
                  },
                ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Tutup Fail',
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Clinical Quick Badges
          Row(
            children: [
              _headerPill(
                icon: Icons.calendar_today_outlined,
                label: 'EDD: $edd',
                color: const Color(0xFF0F172A),
              ),
              const SizedBox(width: 8),
              if (week != null)
                _headerPill(
                  icon: Icons.access_time_rounded,
                  label: 'Minggu $week (${trimester != null ? 'Trimester $trimester' : ''})',
                  color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                ),
              const SizedBox(width: 8),
              _headerPill(
                icon: isOverdue
                    ? Icons.alarm_rounded
                    : alertStatus == 'low_kicks'
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                label: isOverdue
                    ? 'Overdue'
                    : alertStatus == 'low_kicks'
                        ? 'Pergerakan Rendah'
                        : 'Stabil',
                color: isOverdue
                    ? const Color(0xFFDC2626)
                    : alertStatus == 'low_kicks'
                        ? const Color(0xFFD97706)
                        : const Color(0xFF15803D),
              ),
            ],
          ),

          if (alertReason != null && alertStatus != 'normal') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      alertReason,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? const Color(0xFFB91C1C) : const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _headerPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: Kicks Log
  // ---------------------------------------------------------------------------
  Widget _buildKicksTab() {
    if (_isLoadingTracker) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trackerError != null && _sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_walk_rounded, size: 40, color: Colors.grey.shade400),
              const SizedBox(height: 10),
              Text(
                _trackerError ?? 'Tiada rekod tendangan.',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clinical Kicks Target Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'JUMLAH HARI INI',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_todayKicks',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _todayKicks >= 10 ? const Color(0xFF15803D) : const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ 10 kali',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _todayKicks >= 10 ? 'Sasaran KKM Dicapai' : 'Sedang Memantau Pergerakan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: _todayKicks >= 10 ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Protokol KKM: Minimum 10 pergerakan dalam tempoh 12 jam (9:00 AM – 9:00 PM).',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Log Sesi Pergerakan',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          if (_sessions.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('Belum ada sesi tendangan direkodkan hari ini.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _sessions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final s = _sessions[index];
                final kickCount = s['kickCount'] ?? s['kick_count'] ?? 0;
                final startTime = s['startTime']?.toString() ?? s['start_time']?.toString() ?? '-';
                final endTime = s['endTime']?.toString() ?? s['end_time']?.toString();
                final note = s['note']?.toString() ?? s['notes']?.toString();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$kickCount kali',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mula: $startTime',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                            ),
                            if (endTime != null)
                              Text('Tamat: $endTime', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            if (note != null && note.isNotEmpty)
                              Text('Nota: $note', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF475569))),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: Hospital Bag Ward Focus
  // ---------------------------------------------------------------------------
  Widget _buildHospitalBagTab() {
    if (_isLoadingChecklist) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = (_checklistSummary?['categories'] as List<dynamic>?) ?? [];
    final hospitalBagCat = categories.firstWhere(
      (c) => c['categoryKey'] == 'beg_hospital',
      orElse: () => null,
    );

    final items = (hospitalBagCat?['items'] as List<dynamic>?) ?? [];
    final hbTotal = hospitalBagCat?['itemCount'] ?? widget.patient['hospitalBagTotal'] ?? 10;
    final hbCompleted = hospitalBagCat?['completedCount'] ?? widget.patient['hospitalBagCompleted'] ?? 0;
    final hbPercentage = hbTotal > 0 ? ((hbCompleted / hbTotal) * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ward Readiness Progress Hero
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KESIAPSIAGAAN WAD',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hbPercentage%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: hbPercentage == 100
                            ? const Color(0xFF15803D)
                            : hbPercentage >= 50
                                ? const Color(0xFF0284C7)
                                : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Barangan Kemasukan Wad Bersalin',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$hbCompleted daripada $hbTotal barangan kecemasan bersalin telah siap.',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            '10 Barangan Wajib Beg Hospital',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: const Text('Tiada senarai item beg hospital.', style: TextStyle(color: Color(0xFF64748B))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final title = item['title']?.toString() ?? '-';
                final qty = item['quantity']?.toString();
                final isChecked = item['isChecked'] == true;
                final advice = item['drAuroraAdvice'] as Map<String, dynamic>?;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFFF8FAFC) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        color: isChecked ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isChecked ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                                      decoration: isChecked ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                ),
                                if (qty != null && qty.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      qty,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                    ),
                                  ),
                              ],
                            ),
                            if (advice != null && advice['specs'] != null && advice['specs'].toString().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Nasihat Dr Aurora: ${advice['specs']}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: All Checklist Categories
  // ---------------------------------------------------------------------------
  Widget _buildAllChecklistTab() {
    if (_isLoadingChecklist) {
      return const Center(child: CircularProgressIndicator());
    }

    final categories = (_checklistSummary?['categories'] as List<dynamic>?) ?? [];
    final totalItems = _checklistSummary?['totalItems'] ?? 0;
    final completedItems = _checklistSummary?['completedItems'] ?? 0;
    final progress = _checklistSummary?['progressPercentage'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Total Checklist Overview Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KEMAJUAN KESELURUHAN',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completedItems / $totalItems barangan disemak',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$progress%',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0284C7)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Categories Accordion
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, catIndex) {
              final cat = categories[catIndex];
              final catTitle = cat['title']?.toString() ?? '-';
              final catTotal = cat['itemCount'] ?? 0;
              final catCompleted = cat['completedCount'] ?? 0;
              final items = (cat['items'] as List<dynamic>?) ?? [];

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      catTitle,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    subtitle: Text(
                      '$catCompleted / $catTotal siap',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    children: items.map<Widget>((it) {
                      final itemTitle = it['title']?.toString() ?? '-';
                      final isChecked = it['isChecked'] == true;
                      final qty = it['quantity']?.toString();

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              isChecked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: isChecked ? const Color(0xFF15803D) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                itemTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isChecked ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                                  decoration: isChecked ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (qty != null && qty.isNotEmpty)
                              Text(qty, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
