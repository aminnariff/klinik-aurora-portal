import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_performance_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/service_performance_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/branch_performance_response.dart';
import 'package:klinik_aurora_portal/models/dashboard/dashboard_response.dart';
import 'package:klinik_aurora_portal/models/dashboard/service_performance_response.dart';
import 'package:klinik_aurora_portal/views/homepage/widgets/dashboard_metric_card.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class SuperadminDashboardView extends StatelessWidget {
  const SuperadminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<DashboardController, BranchPerformanceController, ServicePerformanceController>(
      builder: (context, dashCtrl, branchCtrl, serviceCtrl, _) {
        final data = dashCtrl.dashboardResponse?.data;
        final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);

        final revenueThisMonth = data?.revenueThisMonth != null ? currencyFormatter.format(data!.revenueThisMonth) : 'RM 0.00';
        final totalAppointments = (data?.totalAppointmentsThisMonth ?? 0).toString();
        final totalBranches = '${data?.totalActiveBranch ?? 0} Clinics';
        final totalUsers = data?.totalUser?.toString() ?? '0';
        final activeUsers = data?.totalActiveUser ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Executive Network KPIs Row ────────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 768;
                if (isCompact) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DashboardMetricCard(
                              label: 'Network Revenue',
                              value: revenueThisMonth,
                              accentColor: const Color(0xFF16A34A), // Green
                              icon: Icons.payments_rounded,
                              subtitle: 'This Month',
                              subtitleColor: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DashboardMetricCard(
                              label: 'Total Appointments',
                              value: totalAppointments,
                              accentColor: const Color(0xFF2563EB), // Blue
                              icon: Icons.event_available_rounded,
                              subtitle: 'This Month',
                              subtitleColor: const Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardMetricCard(
                              label: 'Active Clinics',
                              value: totalBranches,
                              accentColor: const Color(0xFFD97706), // Amber
                              icon: Icons.store_rounded,
                              subtitle: '100% Operational',
                              subtitleColor: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DashboardMetricCard(
                              label: 'Total Patients',
                              value: totalUsers,
                              accentColor: const Color(0xFF7C3AED), // Purple/Blue
                              icon: Icons.people_alt_rounded,
                              subtitle: '$activeUsers Active Users',
                              subtitleColor: const Color(0xFF7C3AED),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Network Revenue',
                        value: revenueThisMonth,
                        accentColor: const Color(0xFF16A34A), // Green
                        icon: Icons.payments_rounded,
                        subtitle: 'This Month',
                        subtitleColor: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Total Appointments',
                        value: totalAppointments,
                        accentColor: const Color(0xFF2563EB), // Blue
                        icon: Icons.event_available_rounded,
                        subtitle: 'This Month',
                        subtitleColor: const Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Active Clinics',
                        value: totalBranches,
                        accentColor: const Color(0xFFD97706), // Amber
                        icon: Icons.store_rounded,
                        subtitle: '100% Operational',
                        subtitleColor: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Total Patients',
                        value: totalUsers,
                        accentColor: const Color(0xFF7C3AED), // Purple/Blue
                        icon: Icons.people_alt_rounded,
                        subtitle: '$activeUsers Active Users',
                        subtitleColor: const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 12),

            // ── 2. 6-Month Revenue Trajectory Area Chart ─────────────────────────
            _buildRevenueTrajectoryCard(context, data?.revenueByMonth ?? []),

            const SizedBox(height: 12),

            // ── 3. Bottom Row: Branch Leaderboard + Service Breakdown ────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 900;
                final leaderboardWidget = _buildBranchLeaderboardCard(context, branchCtrl.branchPerformanceResponse?.data);
                final serviceWidget = _buildNetworkServicesCard(context, serviceCtrl.servicePerformanceResponse?.data?.services ?? []);

                if (isCompact) {
                  return Column(
                    children: [
                      leaderboardWidget,
                      const SizedBox(height: 12),
                      serviceWidget,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: leaderboardWidget),
                    const SizedBox(width: 12),
                    Expanded(flex: 9, child: serviceWidget),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ── Revenue Trajectory Chart ───────────────────────────────────────────────
  Widget _buildRevenueTrajectoryCard(BuildContext context, List<RevenueByMonth> revenueList) {
    final currencyFormatter = NumberFormat.compactCurrency(locale: 'en_MY', symbol: 'RM ');

    double maxRevenue = 0;
    for (final r in revenueList) {
      final v = (r.revenueByMonth ?? 0).toDouble();
      if (v > maxRevenue) maxRevenue = v;
    }
    final double maxY = maxRevenue > 0 ? maxRevenue : 1000;

    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Network Revenue (6 Months)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Gross revenue progression across all operational clinics',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, color: Color(0xFF16A34A), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Network Growth',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: isMobile ? 150 : 170,
            child: revenueList.isEmpty
                ? const Center(
                    child: Text('No revenue history available', style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: math.max(1, (revenueList.length - 1).toDouble()),
                      minY: 0,
                      maxY: maxY * 1.25,
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => const Color(0xFF0F172A),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final idx = spot.x.toInt();
                              final item = (idx >= 0 && idx < revenueList.length) ? revenueList[idx] : null;
                              final mName = item?.month != null && item!.month! >= 1 && item.month! <= 12
                                  ? monthNames[item.month! - 1]
                                  : '';
                              final val = spot.y;
                              return LineTooltipItem(
                                '$mName ${item?.year ?? ''}\nRM ${val.toStringAsFixed(2)}',
                                const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: math.max(100, (maxY / 4).roundToDouble()),
                        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max || value == 0) return const SizedBox();
                              return Text(
                                currencyFormatter.format(value),
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              if (value != value.roundToDouble()) return const SizedBox();
                              final idx = value.toInt();
                              if (idx < 0 || idx >= revenueList.length) return const SizedBox();
                              final m = revenueList[idx].month;
                              final mName = (m != null && m >= 1 && m <= 12) ? monthNames[m - 1] : '';
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  mName,
                                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: revenueList.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final rev = (entry.value.revenueByMonth ?? 0).toDouble();
                            return FlSpot(idx.toDouble(), rev);
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF16A34A), // Green
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: const Color(0xFF16A34A),
                                strokeColor: Colors.white,
                                strokeWidth: 2,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF16A34A).withValues(alpha: 0.2),
                                const Color(0xFF16A34A).withValues(alpha: 0.0),
                              ],
                            ),
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

  // ── Branch Performance Ranking Leaderboard ─────────────────────────────────
  Widget _buildBranchLeaderboardCard(BuildContext context, BranchPerformanceData? data) {
    // Collect 3-month branch total appointments
    final Map<String, int> branchTotals = {};
    for (final month in data?.last3Months ?? []) {
      for (final b in month.data ?? []) {
        if (b.branchName != null) {
          branchTotals[b.branchName!] = ((branchTotals[b.branchName!] ?? 0) + (b.totalAppointments ?? 0)).toInt();
        }
      }
    }

    final sortedBranches = branchTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final int maxVal = sortedBranches.isNotEmpty ? sortedBranches.first.value : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.leaderboard_rounded, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'Branch Performance Ranking',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                'Last 3 Months',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (sortedBranches.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No branch performance data', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedBranches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = sortedBranches[index];
                final rank = index + 1;
                final count = item.value;
                final pct = maxVal > 0 ? (count / maxVal) : 0.0;

                final rankColor = rank == 1
                    ? const Color(0xFF16A34A) // Green (1st)
                    : rank == 2
                        ? const Color(0xFF2563EB) // Blue (2nd)
                        : rank == 3
                            ? const Color(0xFFD97706) // Amber (3rd)
                            : const Color(0xFF64748B);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: rankColor.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                rank.toString(),
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: rankColor),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.key,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        Text(
                          '$count appointments',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // ── Network Top Services Card ──────────────────────────────────────────────
  Widget _buildNetworkServicesCard(BuildContext context, List<ServicePerformanceItem> services) {
    final sorted = List<ServicePerformanceItem>.from(services)
      ..sort((a, b) => (b.totalBookings ?? 0).compareTo(a.totalBookings ?? 0));
    final topList = sorted.take(5).toList();
    final int maxBookings = topList.isNotEmpty ? (topList.first.totalBookings ?? 1) : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Network Services',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Last 30 Days',
                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (topList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No service performance data', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topList.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final s = topList[index];
                final count = s.totalBookings ?? 0;
                final pct = maxBookings > 0 ? (count / maxBookings) : 0.0;
                final revenue = s.completedRevenue ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            s.serviceName ?? 'Service',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$count bookings  (RM ${revenue.toStringAsFixed(0)})',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
