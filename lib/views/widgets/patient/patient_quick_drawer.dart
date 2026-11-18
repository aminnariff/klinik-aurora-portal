import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/patient_summary_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/launcher/web_launcher.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';

/// Slide-over 360° Patient Clinical Profile drawer.
///
/// Opens from any patient name click across Appointments, Queue, Payments,
/// Patients, Baby Tracker, Recalls, or Points without leaving the active view.
class PatientQuickDrawer extends StatefulWidget {
  final String userId;
  final String? initialName;

  const PatientQuickDrawer({
    super.key,
    required this.userId,
    this.initialName,
  });

  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? patientName,
  }) {
    if (userId.trim().isEmpty) return Future.value();
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Patient 360 Profile',
      barrierColor: const Color(0x800F172A),
      transitionDuration: reducedMotion ? Duration.zero : EmilMotion.modalDuration,
      pageBuilder: (ctx, _, _) => Align(
        alignment: Alignment.centerRight,
        child: PatientQuickDrawer(userId: userId, initialName: patientName),
      ),
      transitionBuilder: (ctx, anim, _, child) {
        if (reducedMotion) return child;
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: EmilMotion.easeOut));
        return SlideTransition(position: slide, child: child);
      },
    );
  }

  @override
  State<PatientQuickDrawer> createState() => _PatientQuickDrawerState();
}

class _PatientQuickDrawerState extends State<PatientQuickDrawer> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _loading = true;
  String? _error;
  PatientSummaryData? _data;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PatientSummaryController.fetch(context, widget.userId);
    if (!mounted) return;
    if (responseCode(res.code) && res.data != null) {
      setState(() {
        _data = res.data;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Could not load patient summary.';
        _loading = false;
      });
    }
  }

  String _waUrl(String phone, String name) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '6$digits';
    if (!digits.startsWith('60') && digits.isNotEmpty) digits = '60$digits';
    final msg = Uri.encodeComponent('Hi $name, menghubungi dari Klinik Aurora.');
    return 'https://wa.me/$digits?text=$msg';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 520 ? screenWidth : 480.0;

    return Material(
      color: colors.surface,
      elevation: 16,
      child: SizedBox(
        width: drawerWidth,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.brandPrimary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ((_data?.profile.fullname ?? widget.initialName ?? 'P').isNotEmpty
                                ? (_data?.profile.fullname ?? widget.initialName ?? 'P')[0]
                                : 'P')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _data?.profile.fullname ?? widget.initialName ?? 'Patient Profile',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _data != null
                                ? '${_data!.profile.phone.isNotEmpty ? _data!.profile.phone : _data!.profile.email}'
                                    '${_data!.profile.branchName != null ? ' · ${_data!.profile.branchName}' : ''}'
                                : '360° Clinical Summary',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: colors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Refresh profile',
                      onPressed: _load,
                      icon: Icon(Icons.refresh_rounded, size: 19, color: colors.inkMuted),
                    ),
                    IconButton(
                      tooltip: 'Close drawer',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, size: 20, color: colors.inkMuted),
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? Center(child: CircularProgressIndicator(color: colors.brandPrimary, strokeWidth: 2.5))
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.error_outline_rounded, size: 36, color: colors.danger),
                                  const SizedBox(height: 10),
                                  Text(_error!, style: TextStyle(color: colors.inkSecondary)),
                                  const SizedBox(height: 14),
                                  AppButton.primary(text: 'Retry', onPressed: _load),
                                ],
                              ),
                            ),
                          )
                        : _buildContent(context, _data!),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, PatientSummaryData data) {
    final colors = context.appColors;
    final p = data.profile;
    final stats = data.visitStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quick Contact Actions
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (p.phone.isNotEmpty)
                    AppButton.primary(
                      text: 'WhatsApp',
                      height: 36,
                      icon: const Icon(Icons.chat_rounded, size: 15),
                      onPressed: () => launchWebUrl(_waUrl(p.phone, p.fullname), webOnlyWindowName: '_blank'),
                    ),
                  if (p.phone.isNotEmpty)
                    AppButton.secondary(
                      text: 'Copy Phone',
                      height: 36,
                      icon: Icon(Icons.copy_rounded, size: 14, color: colors.inkSecondary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: p.phone));
                        AppToast.snackbar(context, 'Phone copied: ${p.phone}');
                      },
                    ),
                  if (p.nric.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'NRIC: ${p.nric}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkSecondary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // 4-metric KPI strip
              Row(
                children: [
                  Expanded(child: _kpiTile(context, 'Visits', '${stats.totalVisits}', colors.brandText)),
                  const SizedBox(width: 8),
                  Expanded(child: _kpiTile(context, 'Completed', '${stats.completedVisits}', colors.success)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kpiTile(
                      context,
                      'No-Show',
                      '${stats.noShowVisits}',
                      stats.noShowVisits > 0 ? colors.danger : colors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _kpiTile(context, 'Points', '${p.totalPoint}', colors.info)),
                ],
              ),

              // Maternal / Baby Tracker Banner
              if (data.babyTracker != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: data.babyTracker!.isOverdue ? colors.dangerSoftBg : colors.brandSoftBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: data.babyTracker!.isOverdue
                          ? colors.danger.withValues(alpha: 0.4)
                          : colors.brandBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pregnant_woman_rounded,
                        size: 22,
                        color: data.babyTracker!.isOverdue ? colors.danger : colors.brandText,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.babyTracker!.isBabyBorn
                                  ? 'Baby Born${data.babyTracker!.babyName != null ? ' · ${data.babyTracker!.babyName}' : ''}'
                                  : 'Week ${data.babyTracker!.gestationalWeek} · Trimester ${data.babyTracker!.trimester}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.inkPrimary,
                              ),
                            ),
                            Text(
                              'EDD: ${data.babyTracker!.eddDate} · Today\'s Kicks: ${data.babyTracker!.todayKicks}',
                              style: TextStyle(fontSize: 12, color: colors.inkSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (data.babyTracker!.isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colors.danger,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'OVERDUE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Visits (${data.recentAppointments.length})'),
            Tab(text: 'Points (${data.recentPoints.length})'),
            Tab(text: 'Vouchers (${data.vouchers.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _visitsList(context, data.recentAppointments),
              _pointsList(context, data.recentPoints, data.nextPointExpiry),
              _vouchersList(context, data.vouchers),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kpiTile(BuildContext context, String label, String value, Color accent) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.inkMuted)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: accent)),
        ],
      ),
    );
  }

  Widget _visitsList(BuildContext context, List<PatientRecentAppointment> list) {
    final colors = context.appColors;
    if (list.isEmpty) {
      return Center(child: Text('No appointments recorded yet.', style: TextStyle(color: colors.inkMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final item = list[idx];
        final stColor = appointmentStatusColors[item.appointmentStatus] ?? colors.inkMuted;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.serviceName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: stColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusName(item.appointmentStatus),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${item.appointmentDatetime} · ${item.branchName}'
                '${item.doctorName != null && item.doctorName!.isNotEmpty ? ' · ${item.doctorName}' : ''}',
                style: TextStyle(fontSize: 12, color: colors.inkMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pointsList(BuildContext context, List<Map<String, dynamic>> list, String? nextExpiry) {
    final colors = context.appColors;
    if (list.isEmpty) {
      return Center(child: Text('No point transactions found.', style: TextStyle(color: colors.inkMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length + (nextExpiry != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        if (nextExpiry != null && idx == 0) {
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.warningSoftBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: colors.warning),
                const SizedBox(width: 8),
                Text(
                  'Next points expiring on $nextExpiry',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                ),
              ],
            ),
          );
        }
        final item = list[nextExpiry != null ? idx - 1 : idx];
        final pts = (item['points'] as num?)?.toInt() ?? 0;
        final isCredit = pts >= 0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['description']?.toString() ?? 'Point Entry',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.inkPrimary),
                    ),
                    Text(
                      item['createdDate']?.toString() ?? '',
                      style: TextStyle(fontSize: 11, color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
              Text(
                '${isCredit ? '+' : ''}$pts pts',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isCredit ? colors.success : colors.danger,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _vouchersList(BuildContext context, List<Map<String, dynamic>> list) {
    final colors = context.appColors;
    if (list.isEmpty) {
      return Center(child: Text('No claimed vouchers.', style: TextStyle(color: colors.inkMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final v = list[idx];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.confirmation_number_outlined, size: 18, color: colors.brandText),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['voucherName']?.toString() ?? 'Voucher',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                    ),
                    Text(
                      'Code: ${v['voucherCode'] ?? '-'} · ${v['claimedDate'] ?? ''}',
                      style: TextStyle(fontSize: 11, color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _statusName(int status) {
    switch (status) {
      case 1:
        return 'Booked';
      case 2:
        return 'Cancelled';
      case 3:
        return 'Rescheduled';
      case 4:
        return 'Pending Pay';
      case 5:
        return 'Completed';
      case 6:
        return 'Refunded';
      case 7:
        return 'No-Show';
      case 8:
        return 'Transferred';
      default:
        return 'Status $status';
    }
  }
}
