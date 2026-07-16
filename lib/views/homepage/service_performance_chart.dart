import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/service_performance_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/service_performance_response.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

/// Ranks services by appointment volume (last 30 days) so admins can see
/// which services attract the most customers and which are underperforming.
class ServicePerformanceChart extends StatefulWidget {
  const ServicePerformanceChart({super.key});

  static const _bgColor = Color(0xff232d37);
  static const _dividerColor = Color(0xff37434d);
  static const _mutedColor = Color(0xff68737d);
  static const _barBgColor = Color(0xff2a3a4a);

  @override
  State<ServicePerformanceChart> createState() => _ServicePerformanceChartState();
}

class _ServicePerformanceChartState extends State<ServicePerformanceChart> {
  static const _collapsedCount = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ServicePerformanceController>(
      builder: (context, controller, _) {
        final services = controller.servicePerformanceResponse?.data?.services ?? [];
        final isLoading = controller.servicePerformanceResponse == null;

        return Container(
          decoration: const BoxDecoration(
            color: ServicePerformanceChart._bgColor,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  screenPadding,
                  screenPadding * 0.5,
                  screenPadding * 0.75,
                  screenPadding * 0.5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Service Performance', style: AppTypography.displayMedium(context).apply(color: Colors.white)),
                    const Text(
                      'Last 30 days',
                      style: TextStyle(color: ServicePerformanceChart._mutedColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Divider(color: ServicePerformanceChart._dividerColor, height: 1),
              Padding(
                padding: EdgeInsets.all(screenPadding),
                child: isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Loading...',
                            style: TextStyle(color: ServicePerformanceChart._mutedColor, fontSize: 13),
                          ),
                        ),
                      )
                    : services.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No service data available',
                            style: TextStyle(color: ServicePerformanceChart._mutedColor, fontSize: 13),
                          ),
                        ),
                      )
                    : _buildRanking(services),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRanking(List<ServicePerformanceItem> services) {
    final maxBookings = services
        .map((s) => s.totalBookings ?? 0)
        .fold<int>(0, (prev, e) => e > prev ? e : prev);
    final hasMore = services.length > _collapsedCount;
    final visibleCount = _expanded || !hasMore ? services.length : _collapsedCount;
    final hiddenCount = services.length - visibleCount;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              for (int i = 0; i < visibleCount; i++) ...[
                _ServiceRow(rank: i + 1, item: services[i], maxBookings: maxBookings),
                if (i != visibleCount - 1) const SizedBox(height: 12),
              ],
            ],
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff6ad1e3),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              icon: Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, size: 18),
              label: Text(_expanded ? 'Show less' : 'Show more ($hiddenCount)'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final int rank;
  final ServicePerformanceItem item;
  final int maxBookings;

  const _ServiceRow({required this.rank, required this.item, required this.maxBookings});

  @override
  Widget build(BuildContext context) {
    final bookings = item.totalBookings ?? 0;
    final ratio = maxBookings > 0 ? bookings / maxBookings : 0.0;
    final currencyFormatter = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ', decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '#$rank',
                style: const TextStyle(color: ServicePerformanceChart._mutedColor, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              child: Text(
                item.serviceName ?? '-',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (item.averageRating != null) ...[
              const Icon(Icons.star_rounded, color: Color(0xFFFFB74D), size: 14),
              const SizedBox(width: 2),
              Text('${item.averageRating}', style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 12)),
              const SizedBox(width: 10),
            ],
            Text(
              '$bookings booking${bookings == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 8, color: ServicePerformanceChart._barBgColor),
                FractionallySizedBox(
                  widthFactor: ratio.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xff23b6e6), Color(0xFF6ad1e3)]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _chip('Upcoming', item.totalUpcoming, const Color(0xFF2196F3)),
              _chip('Completed', item.totalCompleted, const Color(0xFF059669)),
              _chip('No-Show', item.totalNoShow, const Color(0xFFF59E0B)),
              _chip('Cancelled', item.totalCancelled, const Color(0xFFEF4444)),
              if ((item.completedRevenue ?? 0) > 0)
                Text(
                  currencyFormatter.format(item.completedRevenue),
                  style: const TextStyle(color: Color(0xff02d39a), fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, int? value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text('$label ${value ?? 0}', style: const TextStyle(color: ServicePerformanceChart._mutedColor, fontSize: 11)),
      ],
    );
  }
}
