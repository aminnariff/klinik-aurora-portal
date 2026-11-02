import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PatientClinicalCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final VoidCallback onOpenDetail;

  const PatientClinicalCard({
    super.key,
    required this.patient,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final name = patient['patientName'] ?? 'Pesakit';
    final phone = patient['patientPhone'] ?? '-';
    final branch = patient['branchName'] ?? 'Klinik Aurora';
    final edd = patient['eddDate'] ?? '-';
    final week = patient['gestationalWeek'] as int?;
    final trimester = patient['trimester'] as int?;
    final kicks = patient['todayKicks'] ?? 0;
    final lastKick = patient['lastKickAt'];
    final bagPct = patient['hospitalBagPercentage'] ?? 0;
    final bagCompleted = patient['hospitalBagCompleted'] ?? 0;
    final bagTotal = patient['hospitalBagTotal'] ?? 10;
    final isOverdue = patient['isOverdue'] == true;
    final alertStatus = patient['alertStatus'] ?? 'normal';
    final alertReason = patient['alertReason'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFCA5A5)
              : alertStatus == 'low_kicks'
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFFE2E8F0),
          width: isOverdue || alertStatus == 'low_kicks' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Patient Info + Alert Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOverdue
                        ? [const Color(0xFFEF4444), const Color(0xFFF87171)]
                        : [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$phone • $branch',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildAlertBadge(alertStatus, isOverdue),
            ],
          ),

          if (alertReason != null && alertStatus != 'normal') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue ? Icons.alarm_on_rounded : Icons.warning_amber_rounded,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // 40-Week Gestational Timeline Bar
          _buildGestationalBar(week, trimester, edd, isOverdue),

          const SizedBox(height: 14),

          // Clinical Metrics: Kicks & Beg Hospital
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  label: 'Tendangan Hari Ini',
                  value: '$kicks 👣',
                  detail: lastKick != null ? 'Jam ${lastKick.toString().split(' ').last}' : 'Belum log hari ini',
                  badgeColor: kicks >= 10
                      ? const Color(0xFF059669)
                      : kicks > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF64748B),
                  bgColor: kicks >= 10
                      ? const Color(0xFFECFDF5)
                      : kicks > 0
                          ? const Color(0xFFFFFBEB)
                          : const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricPill(
                  label: 'Beg Hospital',
                  value: '$bagPct%',
                  detail: '$bagCompleted / $bagTotal item siap',
                  badgeColor: bagPct == 100
                      ? const Color(0xFF059669)
                      : bagPct >= 50
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFEA580C),
                  bgColor: bagPct == 100
                      ? const Color(0xFFECFDF5)
                      : bagPct >= 50
                          ? const Color(0xFFF0F9FF)
                          : const Color(0xFFFFF7ED),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Bottom Action Row
          Row(
            children: [
              if (phone != '-' && phone.isNotEmpty)
                IconButton(
                  tooltip: 'WhatsApp Pesakit',
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF059669)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFECFDF5),
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    final phoneWithCode = cleanPhone.startsWith('6') ? cleanPhone : '6$cleanPhone';
                    launchUrlString('https://wa.me/$phoneWithCode');
                  },
                ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.assignment_ind_rounded, size: 15),
                label: const Text('Buka Fail Klinikal', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBadge(String status, bool isOverdue) {
    if (isOverdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_on_rounded, size: 13, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'Overdue',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
          ],
        ),
      );
    }

    if (status == 'low_kicks') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFD97706)),
            SizedBox(width: 4),
            Text(
              'Amaran Kicks',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '🟢 Stabil',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
      ),
    );
  }

  Widget _buildGestationalBar(int? week, int? trimester, String edd, bool isOverdue) {
    final validWeek = (week != null && week > 0) ? (week > 42 ? 42 : week) : 0;
    final progress = validWeek > 0 ? (validWeek / 40.0).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    validWeek > 0 ? 'Minggu $validWeek' : 'EDD Belum Sah',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                    ),
                  ),
                  if (trimester != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'T$trimester',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ],
              ),
              Text(
                'EDD: $edd',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 40-Week Multi-Color Progress Indicator
          Stack(
            children: [
              // Background track with 3 trimester tints
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Filled progress
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOverdue
                          ? [const Color(0xFFDC2626), const Color(0xFFEF4444)]
                          : validWeek >= 28
                              ? [const Color(0xFF0284C7), const Color(0xFFF43F5E)]
                              : [const Color(0xFF0284C7), const Color(0xFF38BDF8)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('W1', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400)),
              Text('W13 (T1)', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400)),
              Text('W27 (T2)', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade400)),
              Text('W40 (EDD)', style: TextStyle(fontSize: 9.5, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required String detail,
    required Color badgeColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: badgeColor),
          ),
          const SizedBox(height: 1),
          Text(
            detail,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
