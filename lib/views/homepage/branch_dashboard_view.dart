import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_operations_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/branch_operations_response.dart';
import 'package:klinik_aurora_portal/views/homepage/widgets/dashboard_metric_card.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class BranchDashboardView extends StatelessWidget {
  const BranchDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BranchOperationsController>(
      builder: (context, controller, _) {
        final data = controller.branchOperationsResponse?.data;
        final today = data?.today;
        final totalToday = today?.totalToday ?? 0;
        final totalCompleted = today?.totalCompleted ?? 0;
        final completedPercent = totalToday > 0 ? ((totalCompleted / totalToday) * 100).round() : 0;
        final onDutyCount = data?.doctorsOnDuty?.length ?? 0;
        final cancelledCount = today?.totalCancelledOrNoShow ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Today's Operations KPI Row ────────────────────────────────────
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
                              label: "Today's Appointments",
                              value: totalToday.toString(),
                              accentColor: const Color(0xFF2563EB), // Blue
                              icon: Icons.calendar_today_rounded,
                              subtitle: '$totalCompleted Completed',
                              subtitleColor: const Color(0xFF16A34A),
                              onTap: () => context.go('/appointment'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DashboardMetricCard(
                              label: 'Completed',
                              value: totalCompleted.toString(),
                              accentColor: const Color(0xFF16A34A), // Green
                              icon: Icons.check_circle_outline_rounded,
                              subtitle: '$completedPercent% Completed',
                              subtitleColor: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DashboardMetricCard(
                              label: 'Doctors on Duty',
                              value: onDutyCount.toString(),
                              accentColor: const Color(0xFFD97706), // Amber
                              icon: Icons.medical_services_outlined,
                              subtitle: '$onDutyCount Doctors Active',
                              subtitleColor: const Color(0xFFD97706),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DashboardMetricCard(
                              label: 'Cancelled / No-Show',
                              value: cancelledCount.toString(),
                              accentColor: const Color(0xFFDC2626), // Red
                              icon: Icons.cancel_outlined,
                              subtitle: cancelledCount > 0 ? 'Requires follow-up' : 'Zero missed visits',
                              subtitleColor: cancelledCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
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
                        label: "Today's Appointments",
                        value: totalToday.toString(),
                        accentColor: const Color(0xFF2563EB), // Blue
                        icon: Icons.calendar_today_rounded,
                        subtitle: '$totalCompleted Completed',
                        subtitleColor: const Color(0xFF16A34A),
                        onTap: () => context.go('/appointment'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Completed',
                        value: totalCompleted.toString(),
                        accentColor: const Color(0xFF16A34A), // Green
                        icon: Icons.check_circle_outline_rounded,
                        subtitle: '$completedPercent% Completed',
                        subtitleColor: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Doctors on Duty',
                        value: onDutyCount.toString(),
                        accentColor: const Color(0xFFD97706), // Amber
                        icon: Icons.medical_services_outlined,
                        subtitle: '$onDutyCount Doctors Active',
                        subtitleColor: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DashboardMetricCard(
                        label: 'Cancelled / No-Show',
                        value: cancelledCount.toString(),
                        accentColor: const Color(0xFFDC2626), // Red
                        icon: Icons.cancel_outlined,
                        subtitle: cancelledCount > 0 ? 'Requires follow-up' : 'Zero missed visits',
                        subtitleColor: cancelledCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // ── 2. 7-Day Activity Bar Chart ──────────────────────────────────────
            _buildWeeklyActivityCard(context, data?.weeklyActivity ?? []),

            const SizedBox(height: 18),

            // ── 3. Bottom Row: Live Queue + Service Donut & Revenue ──────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 900;
                final queueWidget = _buildLiveQueueCard(context, data?.upcomingQueue ?? []);
                final performanceWidget = _buildBranchPerformanceCard(context, data);

                if (isCompact) {
                  return Column(
                    children: [
                      queueWidget,
                      const SizedBox(height: 18),
                      performanceWidget,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: queueWidget),
                    const SizedBox(width: 18),
                    Expanded(flex: 9, child: performanceWidget),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ── Weekly Activity Chart ──────────────────────────────────────────────────
  Widget _buildWeeklyActivityCard(BuildContext context, List<WeeklyActivityItem> activity) {
    int maxVal = 5;
    for (final a in activity) {
      final total = (a.completed ?? 0) + (a.scheduled ?? 0);
      if (total > maxVal) maxVal = total;
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
                    'Weekly Appointments (Last 7 Days)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Daily breakdown of completed visits vs scheduled bookings',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Row(
                children: [
                  _legendItem('Completed', const Color(0xFF16A34A)),
                  const SizedBox(width: 14),
                  _legendItem('Scheduled', const Color(0xFF2563EB)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          AspectRatio(
            aspectRatio: isMobile ? 1.9 : 3.6,
            child: activity.isEmpty
                ? const Center(
                    child: Text('No appointment activity in the last 7 days', style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxVal * 1.25,
                      alignment: BarChartAlignment.spaceAround,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: math.max(1, (maxVal / 4).roundToDouble()),
                        getDrawingHorizontalLine: (value) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value == meta.max || value == 0) return const SizedBox();
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= activity.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  activity[idx].dayName ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: activity.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        final completed = (item.completed ?? 0).toDouble();
                        final scheduled = (item.scheduled ?? 0).toDouble();

                        return BarChartGroupData(
                          x: i,
                          barsSpace: 4,
                          barRods: [
                            BarChartRodData(
                              toY: completed,
                              color: const Color(0xFF16A34A),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: scheduled,
                              color: const Color(0xFF2563EB),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Live Patient Queue ─────────────────────────────────────────────────────
  Widget _buildLiveQueueCard(BuildContext context, List<UpcomingQueueItem> queue) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.queue_play_next_rounded, size: 18, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text(
                    'Next Patients Today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/appointment'),
                child: const Row(
                  children: [
                    Text(
                      'View Board',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (queue.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 36, color: Color(0xFF16A34A)),
                  SizedBox(height: 8),
                  Text(
                    'No more scheduled patients for today',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: queue.length,
              separatorBuilder: (_, _) => const Divider(color: Color(0xFFF1F5F9), height: 1),
              itemBuilder: (context, index) {
                final item = queue[index];
                String formattedTime = item.appointmentDatetime ?? '';
                try {
                  final dt = DateTime.parse(item.appointmentDatetime!);
                  formattedTime = DateFormat('hh:mm a').format(dt);
                } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.patientName ?? 'Patient',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              item.serviceName ?? 'General Consultation',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded, size: 12, color: Color(0xFF64748B)),
                            const SizedBox(width: 4),
                            Text(
                              item.doctorName ?? 'Unassigned',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
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

  // ── Month-To-Date Revenue & Top Services Donut ─────────────────────────────
  Widget _buildBranchPerformanceCard(BuildContext context, BranchOperationsData? data) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);
    final revenue = data?.revenueThisMonth ?? 0;
    final topServices = data?.topServices ?? [];

    final colors = [
      const Color(0xFF2563EB), // Blue
      const Color(0xFF16A34A), // Green
      const Color(0xFFF59E0B), // Yellow/Amber
      const Color(0xFF94A3B8), // Slate Gray
    ];

    final int totalBookings = topServices.fold(0, (sum, s) => sum + (s.totalBookings ?? 0));

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
          const Text(
            'Branch Monthly Performance',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Revenue Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MONTH-TO-DATE REVENUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF15803D),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(revenue),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 4),
                    ],
                  ),
                  child: const Icon(Icons.payments_rounded, color: Color(0xFF16A34A), size: 20),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Top Services This Month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          if (topServices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(child: Text('No service booking data yet', style: TextStyle(color: Color(0xFF94A3B8)))),
            )
          else ...[
            Row(
              children: [
                SizedBox(
                  height: 90,
                  width: 90,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 24,
                      sections: topServices.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final s = entry.value;
                        final val = (s.totalBookings ?? 1).toDouble();
                        return PieChartSectionData(
                          value: val,
                          color: colors[idx % colors.length],
                          radius: 16,
                          showTitle: false,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: topServices.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final s = entry.value;
                      final count = s.totalBookings ?? 0;
                      final pct = totalBookings > 0 ? ((count / totalBookings) * 100).round() : 0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: colors[idx % colors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                s.serviceName ?? 'Service',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '$count ($pct%)',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
