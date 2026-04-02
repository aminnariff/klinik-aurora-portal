import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_performance_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/dashboard_response.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DashboardController, BranchPerformanceController>(
      builder: (context, dashCtrl, perfCtrl, _) {
        final data = dashCtrl.dashboardResponse?.data;

        // This month's total appointments from last3Months[last entry]
        final months = perfCtrl.branchPerformanceResponse?.data?.last3Months ?? [];
        final thisMonthTotal = months.isNotEmpty ? months.last.total : null;

        if (isMobile) {
          return _MobileStats(data: data, thisMonthAppointments: thisMonthTotal);
        }
        return _DesktopStats(data: data, thisMonthAppointments: thisMonthTotal);
      },
    );
  }
}

// ─── Desktop: single-row 4-card layout ────────────────────────────────────────

class _DesktopStats extends StatelessWidget {
  final Data? data;
  final int? thisMonthAppointments;
  const _DesktopStats({required this.data, required this.thisMonthAppointments});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: EdgeInsets.symmetric(horizontal: screenPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _UserDonutCard(data: data),
          SizedBox(width: screenPadding / 2),
          _StatCard(
            label: 'Active Branches',
            value: data?.totalActiveBranch,
            icon: Icons.store_outlined,
            accent: const Color(0xFFDF6E98),
            bg: const Color(0xFF2A0D18),
          ),
          SizedBox(width: screenPadding / 2),
          _StatCard(
            label: 'Active Promotions',
            value: data?.totalActivePromotion,
            icon: Icons.local_offer_outlined,
            accent: const Color(0xFFFFB74D),
            bg: const Color(0xFF2A1D0D),
          ),
          SizedBox(width: screenPadding / 2),
          _StatCard(
            label: 'Appointments This Month',
            value: thisMonthAppointments,
            icon: Icons.calendar_month_outlined,
            accent: const Color(0xFF7C3AED),
            bg: const Color(0xFF1A0D2E),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile: donut full-width + 2×2 grid ──────────────────────────────────────

class _MobileStats extends StatelessWidget {
  final Data? data;
  final int? thisMonthAppointments;
  const _MobileStats({required this.data, required this.thisMonthAppointments});

  @override
  Widget build(BuildContext context) {
    final gap = screenPadding / 2;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenPadding),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [_UserDonutCard(data: data)]),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatCard(
                  label: 'Active Branches',
                  value: data?.totalActiveBranch,
                  icon: Icons.store_outlined,
                  accent: const Color(0xFFDF6E98),
                  bg: const Color(0xFF2A0D18),
                ),
                SizedBox(width: gap),
                _StatCard(
                  label: 'Active Promotions',
                  value: data?.totalActivePromotion,
                  icon: Icons.local_offer_outlined,
                  accent: const Color(0xFFFFB74D),
                  bg: const Color(0xFF2A1D0D),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatCard(
                  label: 'Appts This Month',
                  value: thisMonthAppointments,
                  icon: Icons.calendar_month_outlined,
                  accent: const Color(0xFF7C3AED),
                  bg: const Color(0xFF1A0D2E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Donut card ────────────────────────────────────────────────────────────────

class _UserDonutCard extends StatelessWidget {
  final Data? data;
  const _UserDonutCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final total = data?.totalUser ?? 0;
    final active = data?.totalActiveUser ?? 0;
    final inactive = (total - active).clamp(0, total);
    final percent = total > 0 ? (active / total * 100).round() : 0;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF141d26), borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 32,
                      startDegreeOffset: -90,
                      sections: total == 0
                          ? [PieChartSectionData(value: 1, color: const Color(0xFF2a3a4a), radius: 14, showTitle: false)]
                          : [
                              PieChartSectionData(value: active.toDouble(), color: const Color(0xFF6ad1e3), radius: 14, showTitle: false),
                              PieChartSectionData(value: inactive.toDouble(), color: const Color(0xFF2a3a4a), radius: 14, showTitle: false),
                            ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const Text('active', style: TextStyle(color: Color(0xff68737d), fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Users', style: TextStyle(color: Color(0xff68737d), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    total > 0 ? '$total' : '—',
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1),
                  ),
                  const SizedBox(height: 10),
                  _legend(const Color(0xFF6ad1e3), 'Active', '$active'),
                  const SizedBox(height: 4),
                  _legend(const Color(0xFF2a3a4a), 'Inactive', '$inactive'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legend(Color color, String label, String value) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: color == const Color(0xFF2a3a4a) ? Border.all(color: const Color(0xff68737d), width: 1) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Color(0xff68737d), fontSize: 13)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Generic stat card ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int? value;
  final IconData icon;
  final Color accent;
  final Color bg;

  const _StatCard({required this.label, required this.value, required this.icon, required this.accent, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withAlpha(40)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Color(0xff68737d), fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: accent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: accent, size: 18),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value != null ? '$value' : '—',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, height: 1),
                ),
                const SizedBox(height: 4),
                Container(height: 3, width: 28, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
