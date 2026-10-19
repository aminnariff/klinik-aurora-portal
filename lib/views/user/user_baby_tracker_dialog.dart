import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/models/user/user_all_response.dart';

class UserBabyTrackerDialog extends StatefulWidget {
  final UserResponse? patient;
  const UserBabyTrackerDialog({super.key, required this.patient});

  @override
  State<UserBabyTrackerDialog> createState() => _UserBabyTrackerDialogState();
}

class _UserBabyTrackerDialogState extends State<UserBabyTrackerDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profile;
  int _todayKicks = 0;
  List<dynamic> _sessions = [];

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
          maxWidth: math.min(680, MediaQuery.of(context).size.width * 0.92),
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF2F8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: pinkColor.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: pinkColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text('👣', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baby Kick Tracker & Fetal Movement',
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
            ),

            // Body
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: pinkColor),
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        )
                      : (_profile == null && _sessions.isEmpty)
                          ? Center(
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
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Stats summary cards
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

                                  // Session Table Header
                                  Text(
                                    'Kick Session History',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Session List
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
                            ),
            ),
          ],
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
