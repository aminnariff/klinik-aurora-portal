import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:intl/intl.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/utilization_heatmap_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/models/branch/branch_all_response.dart' as branch_model;
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:provider/provider.dart';

/// Branch Utilization Heatmap & Practitioner Capacity Alerts (#6).
class UtilizationHeatmapPage extends StatefulWidget {
  static const routeName = RouteNames.utilizationHeatmap;
  static const displayName = RouteNames.utilizationHeatmapDisplay;

  const UtilizationHeatmapPage({super.key});

  @override
  State<UtilizationHeatmapPage> createState() => _UtilizationHeatmapPageState();
}

class _UtilizationHeatmapPageState extends State<UtilizationHeatmapPage> {
  int _windowDays = 14;
  String? _selectedBranchId;
  List<branch_model.Data> _branches = [];
  bool _loading = true;
  String? _error;
  UtilizationHeatmapData? _data;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (!mounted) return;
      context.read<TopBarController>().pageValue = Homepage.getPageId(UtilizationHeatmapPage.displayName);
      final auth = context.read<AuthController>();
      if (!auth.isSuperAdmin) {
        _selectedBranchId = auth.authenticationResponse?.data?.user?.branchId;
      } else {
        _loadBranches();
      }
      _fetch();
    });
  }

  Future<void> _loadBranches() async {
    final res = await BranchController.getAll(context, 1, 100);
    if (!mounted) return;
    if (responseCode(res.code)) {
      setState(() => _branches = res.data?.data ?? []);
    }
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: _windowDays - 1));
      final fmt = DateFormat('yyyy-MM-dd');
      final res = await UtilizationHeatmapController.fetch(
        context,
        branchId: _selectedBranchId,
        startDate: fmt.format(start),
        endDate: fmt.format(now),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => ApiResponse(code: 408, message: 'Request timed out. Please retry.'),
      );
      if (!mounted) return;
      if (responseCode(res.code) && res.data != null) {
        setState(() {
          _data = res.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.message ?? 'Failed to load utilization heatmap.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error loading utilization: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = context.read<AuthController>();
    final isNarrow = MediaQuery.sizeOf(context).width < 900;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.brandPrimary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!, style: TextStyle(color: colors.danger)),
                      const SizedBox(height: 12),
                      AppButton.primary(text: 'Retry', onPressed: _fetch),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isNarrow ? 12 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header ─────────────────────────────────────────
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Branch Utilization Heatmap & Capacity Alerts',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.inkPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Window: ${_data?.startDate ?? ''} to ${_data?.endDate ?? ''} · Roster supply vs actual appointments.',
                                style: TextStyle(fontSize: 13, color: colors.inkMuted),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              for (final days in [7, 14, 30])
                                ChoiceChip(
                                  label: Text('${days}D'),
                                  selected: _windowDays == days,
                                  onSelected: (_) {
                                    setState(() => _windowDays = days);
                                    _fetch();
                                  },
                                ),
                              if (auth.isSuperAdmin && _branches.isNotEmpty)
                                Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String?>(
                                      value: _selectedBranchId,
                                      hint: Text('All Branches', style: TextStyle(fontSize: 12, color: colors.inkMuted)),
                                      dropdownColor: colors.surfaceElevated,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                                      items: [
                                        const DropdownMenuItem<String?>(value: null, child: Text('All Branches')),
                                        for (final b in _branches)
                                          DropdownMenuItem<String?>(value: b.branchId, child: Text(b.branchName ?? 'Branch')),
                                      ],
                                      onChanged: (v) {
                                        setState(() => _selectedBranchId = v);
                                        _fetch();
                                      },
                                    ),
                                  ),
                                ),
                              AppButton.primary(
                                text: 'Refresh',
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                onPressed: _fetch,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── KPI Summary Row ────────────────────────────────
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _kpiBox(context, 'Avg Utilization', '${_data!.avgUtilizationPct}%',
                              '${_data!.totalBooked} booked / ${_data!.totalCapacity} slots', colors.brandText),
                          _kpiBox(context, 'Overloaded Staff', '${_data!.overloadedPractitioners}',
                              'At >=85% roster capacity',
                              _data!.overloadedPractitioners > 0 ? colors.danger : colors.success),
                          _kpiBox(context, 'Underutilized Staff', '${_data!.underutilizedPractitioners}',
                              'Below <=30% roster capacity', colors.warning),
                          _kpiBox(context, 'Unassigned Bookings', '${_data!.unassignedAppointments}',
                              'Appointments without doctor',
                              _data!.unassignedAppointments > 0 ? colors.warning : colors.inkMuted),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Heatmap Matrix ─────────────────────────────────
                      RepaintBoundary(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Day × Hour Capacity Matrix',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                                  ),
                                  Wrap(
                                    spacing: 10,
                                    children: [
                                      _legendChip(context, 'Idle (<25%)', colors.info.withValues(alpha: 0.22)),
                                      _legendChip(context, 'Balanced (25–75%)', colors.success.withValues(alpha: 0.45)),
                                      _legendChip(context, 'Peak (75–95%)', colors.warning.withValues(alpha: 0.65)),
                                      _legendChip(context, 'Overload (>=95%)', colors.danger.withValues(alpha: 0.80)),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: _buildGrid(context, _data!.heatmap),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Peak vs Off-Peak Recommendations ───────────────
                      LayoutBuilder(
                        builder: (context, c) {
                          final stacked = c.maxWidth < 860;
                          final peak = _slotInsightCard(
                            context,
                            'Peak Bottleneck Hours (Add Locum Capacity)',
                            _data!.peakSlots,
                            colors.danger,
                            'No bottlenecks >=75% in this window.',
                          );
                          final idle = _slotInsightCard(
                            context,
                            'Off-Peak Idle Windows (Promo Voucher Targets)',
                            _data!.idleSlots,
                            colors.info,
                            'No underutilized rostered slots <=25%.',
                          );
                          if (stacked) {
                            return Column(children: [peak, const SizedBox(height: 12), idle]);
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: peak),
                              const SizedBox(width: 12),
                              Expanded(child: idle),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // ── Practitioner Load Table ────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Practitioner Capacity Load (${_data!.practitionerLoad.length})',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                            ),
                            const SizedBox(height: 12),
                            if (_data!.practitionerLoad.isEmpty)
                              Text('No rostered practitioners found in this window.',
                                  style: TextStyle(color: colors.inkMuted))
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _data!.practitionerLoad.length,
                                separatorBuilder: (_, _) => Divider(height: 16, color: colors.border),
                                itemBuilder: (context, idx) {
                                  final doc = _data!.practitionerLoad[idx];
                                  final statusColor = doc.status == 'overloaded'
                                      ? colors.danger
                                      : doc.status == 'underutilized'
                                          ? colors.warning
                                          : colors.success;
                                  return Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(doc.doctorName,
                                                style: TextStyle(
                                                    fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
                                            Text(
                                              '${doc.branchName.isNotEmpty ? '${doc.branchName} · ' : ''}${doc.shiftHours}h rostered · ${doc.bookedCount}/${doc.capacitySlots} slots',
                                              style: TextStyle(fontSize: 11, color: colors.inkMuted),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(999),
                                          child: LinearProgressIndicator(
                                            value: (doc.utilizationPct / 100).clamp(0.0, 1.0),
                                            minHeight: 8,
                                            backgroundColor: colors.surfaceSubtle,
                                            color: statusColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 48,
                                        child: Text(
                                          '${doc.utilizationPct}%',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: statusColor),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          doc.status.toUpperCase(),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildGrid(BuildContext context, List<HeatmapCell> cells) {
    final colors = context.appColors;
    final map = <String, HeatmapCell>{for (final c in cells) '${c.dayOfWeek}:${c.hour}': c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour headers
        Row(
          children: [
            const SizedBox(width: 48),
            for (final h in _hours)
              SizedBox(
                width: 52,
                child: Text(
                  '${h.toString().padLeft(2, '0')}:00',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.inkMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (int dow = 0; dow < 7; dow++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Text(
                    _dayLabels[dow],
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.inkSecondary),
                  ),
                ),
                for (final h in _hours) _heatCell(context, map['$dow:$h']),
              ],
            ),
          ),
      ],
    );
  }

  Widget _heatCell(BuildContext context, HeatmapCell? cell) {
    final colors = context.appColors;
    final booked = cell?.bookedCount ?? 0;
    final cap = cell?.capacityCount ?? 0;
    final pct = cell?.utilizationPct ?? 0;

    Color bg;
    if (cap == 0 && booked == 0) {
      bg = colors.surfaceSubtle;
    } else if (pct >= 95) {
      bg = colors.danger.withValues(alpha: 0.82);
    } else if (pct >= 75) {
      bg = colors.warning.withValues(alpha: 0.68);
    } else if (pct >= 25) {
      bg = colors.success.withValues(alpha: 0.48);
    } else {
      bg = colors.info.withValues(alpha: 0.24);
    }

    final fg = (pct >= 75) ? Colors.white : colors.inkPrimary;

    return Tooltip(
      message: '${_dayLabels[cell?.dayOfWeek ?? 0]} ${(cell?.hour ?? 8).toString().padLeft(2, '0')}:00\n'
          'Booked: $booked / Capacity: $cap ($pct%)',
      child: Container(
        width: 48,
        height: 34,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          (cap == 0 && booked == 0) ? '–' : '$pct%',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }

  Widget _kpiBox(BuildContext context, String label, String value, String sub, Color accent) {
    final colors = context.appColors;
    return Container(
      width: 215,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 11, color: colors.inkMuted)),
        ],
      ),
    );
  }

  Widget _legendChip(BuildContext context, String label, Color color) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: colors.inkMuted)),
      ],
    );
  }

  Widget _slotInsightCard(
    BuildContext context,
    String title,
    List<HeatmapCell> slots,
    Color accent,
    String emptyText,
  ) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.inkPrimary)),
          const SizedBox(height: 10),
          if (slots.isEmpty)
            Text(emptyText, style: TextStyle(fontSize: 12, color: colors.inkMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map(
                    (s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accent.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        '${_dayLabels[s.dayOfWeek]} ${s.hour.toString().padLeft(2, '0')}:00 · ${s.bookedCount}/${s.capacityCount} (${s.utilizationPct}%)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: accent),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
