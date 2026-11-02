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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOverdue
              ? const Color(0xFFFCA5A5)
              : alertStatus == 'low_kicks'
                  ? const Color(0xFFFCD34D)
                  : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Row: Patient Info + Alert Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF334155),
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$phone • $branch',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
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
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isOverdue ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOverdue ? Icons.alarm_rounded : Icons.warning_amber_rounded,
                    size: 13,
                    color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      alertReason,
                      style: TextStyle(
                        fontSize: 11,
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

          const SizedBox(height: 12),

          // 40-Week Gestational Timeline Track
          _buildGestationalTrack(week, trimester, edd, isOverdue),

          const SizedBox(height: 12),

          // Clinical Metrics: Kicks & Beg Hospital
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  label: 'PERGERAKAN HARI INI',
                  value: '$kicks',
                  unit: 'kali',
                  detail: lastKick != null ? 'Jam ${lastKick.toString().split(' ').last}' : 'Belum log',
                  badgeColor: kicks >= 10
                      ? const Color(0xFF15803D)
                      : kicks > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  label: 'BEG HOSPITAL',
                  value: '$bagPct%',
                  unit: '',
                  detail: '$bagCompleted / $bagTotal item',
                  badgeColor: bagPct == 100
                      ? const Color(0xFF15803D)
                      : bagPct >= 50
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFD97706),
                ),
              ),
            ],
          ),

          const Spacer(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Bottom Action Row
          Row(
            children: [
              if (phone != '-' && phone.isNotEmpty)
                IconButton(
                  tooltip: 'WhatsApp Pesakit',
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF059669)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FDF4),
                    padding: const EdgeInsets.all(7),
                    minimumSize: const Size(32, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                    final phoneWithCode = cleanPhone.startsWith('6') ? cleanPhone : '6$cleanPhone';
                    launchUrlString('https://wa.me/$phoneWithCode');
                  },
                ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.description_outlined, size: 14),
                label: const Text('Buka Rekod', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.alarm_rounded, size: 12, color: Color(0xFFDC2626)),
            SizedBox(width: 4),
            Text(
              'Overdue',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
          ],
        ),
      );
    }

    if (status == 'low_kicks') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFD97706)),
            SizedBox(width: 4),
            Text(
              'Pergerakan Rendah',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 12, color: Color(0xFF15803D)),
          SizedBox(width: 4),
          Text(
            'Stabil',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
          ),
        ],
      ),
    );
  }

  Widget _buildGestationalTrack(int? week, int? trimester, String edd, bool isOverdue) {
    final validWeek = (week != null && week > 0) ? (week > 42 ? 42 : week) : 0;
    final progress = validWeek > 0 ? (validWeek / 40.0).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                    ),
                  ),
                  if (trimester != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '• Trimester $trimester',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ],
              ),
              Text(
                'EDD: $edd',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Precision Hairline Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('W1', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('W13 (T1)', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('W27 (T2)', style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8))),
              Text('W40 (EDD)', style: TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required String unit,
    required String detail,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: badgeColor),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unit,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 1),
          Text(
            detail,
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
