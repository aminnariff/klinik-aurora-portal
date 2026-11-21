import 'dart:async';

import '../widgets/motion/emil_motion.dart';
import '../widgets/aurora/aurora_empty_state.dart';
import '../widgets/shimmer/table_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_operations_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_performance_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/service_performance_controller.dart';
import 'package:klinik_aurora_portal/views/homepage/branch_dashboard_view.dart';
import 'package:klinik_aurora_portal/views/homepage/superadmin_dashboard_view.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';
import 'package:klinik_aurora_portal/config/color.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  String? _selectedBranchId; // null = Network View for superadmin
  String? _selectedBranchName;
  bool _isLoading = true;
  String? _loadedBranchId;
  int _loadGeneration = 0;
  DateTime? _lastUpdatedAt;
  bool _refreshFailed = false;
  Timer? _cooldown;
  static const Duration _cooldownDuration = Duration(seconds: 5);

  bool get _isCooldownActive => _cooldown?.isActive ?? false;

  void _handleManualRefresh() {
    if (_isLoading || _isCooldownActive) return;
    _cooldown = Timer(_cooldownDuration, () {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final generation = ++_loadGeneration;
    bool current() => mounted && generation == _loadGeneration;
    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    final isSuper = auth.isSuperAdmin;
    final branchId = isSuper ? _selectedBranchId : auth.authenticationResponse?.data?.user?.branchId;

    if (isSuper) {
      final branches = context.read<BranchController>();
      unawaited(
        BranchController.getAll(context, 1, 100).then((result) {
          if (mounted && responseCode(result.code)) branches.branchAllResponse = result;
        }),
      );
    }

    var success = false;
    try {
      if (isSuper && branchId == null) {
        final overview = context.read<DashboardController>();
        final branches = context.read<BranchPerformanceController>();
        final services = context.read<ServicePerformanceController>();
        final results = await Future.wait([
          DashboardController.get(context).then((result) {
            if (!current() || !responseCode(result.code)) return false;
            overview.dashboardResponse = result.data;
            return true;
          }),
          BranchPerformanceController.get(context).then((result) {
            if (!current() || !responseCode(result.code)) return false;
            branches.branchPerformanceResponse = result.data;
            return true;
          }),
          ServicePerformanceController.get(context).then((result) {
            if (!current() || !responseCode(result.code)) return false;
            services.servicePerformanceResponse = result.data;
            return true;
          }),
        ]);
        success = results.every((loaded) => loaded);
      } else {
        final operations = context.read<BranchOperationsController>();
        final result = await BranchOperationsController.get(context, branchId: isSuper ? branchId : null);
        if (!current()) return;
        success = responseCode(result.code) && result.data != null;
        if (success) {
          _loadedBranchId = branchId;
          operations.branchOperationsResponse = result.data;
        }
      }
    } on Exception {
      success = false;
    } finally {
      if (current()) {
        setState(() {
          _isLoading = false;
          _refreshFailed = !success;
          if (success) _lastUpdatedAt = DateTime.now();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isSuper = context.watch<AuthController>().isSuperAdmin;
    final userBranchId = context.watch<AuthController>().authenticationResponse?.data?.user?.branchId;
    final branches = context.watch<BranchController>().branchAllResponse?.data?.data ?? [];
    final userBranch = branches.where((b) => b.branchId == userBranchId).firstOrNull;
    final branchOpsName = context.watch<BranchOperationsController>().branchOperationsResponse?.data?.branchName;
    final activeBranchName = _selectedBranchName ?? userBranch?.branchName ?? branchOpsName;
    final network = isSuper && _selectedBranchId == null;
    final hasData = network
        ? context.watch<DashboardController>().dashboardResponse != null
        : _loadedBranchId == (isSuper ? _selectedBranchId : userBranchId) &&
              context.watch<BranchOperationsController>().branchOperationsResponse != null;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(screenPadding, 8, screenPadding, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Bar ───────────────────────────────────────────────
              _buildHeader(isSuper, activeBranchName),
              const SizedBox(height: 12),

              // ── Main Content ─────────────────────────────────────────────
              SizedBox(
                height: 2,
                child: _isLoading
                    ? LinearProgressIndicator(minHeight: 2, value: MediaQuery.disableAnimationsOf(context) ? 0 : null)
                    : null,
              ),
              if (_isLoading && !hasData)
                const SizedBox(height: 300, child: AppTableSkeleton(rows: 5))
              else if (!hasData)
                Center(
                  child: AuroraEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: 'Dashboard could not be loaded',
                    actionLabel: 'Retry',
                    onAction: _loadData,
                  ),
                )
              else if (network)
                const SuperadminDashboardView()
              else
                BranchDashboardView(key: ValueKey(isSuper ? _selectedBranchId : userBranchId)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSuper, String? userBranchName) {
    final branches = context.watch<BranchController>().branchAllResponse?.data?.data ?? [];

    final reduce = MediaQuery.disableAnimationsOf(context);
    final updated = _lastUpdatedAt;
    final updatedLabel = updated == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(updated));
    final status = _isLoading
        ? 'Refreshing dashboard…'
        : _refreshFailed
        ? 'Some dashboard data could not refresh'
        : updatedLabel == null
        ? ''
        : 'Updated $updatedLabel';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    isSuper && _selectedBranchId == null
                        ? 'Network Intelligence Dashboard'
                        : '${_selectedBranchName ?? userBranchName ?? "Clinic"} Operations Dashboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: appInkPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSuper && _selectedBranchId == null ? appInfoSoft : appSuccessSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSuper && _selectedBranchId == null ? 'EXECUTIVE' : 'BRANCH LEVEL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isSuper && _selectedBranchId == null ? appInfoText : appSuccessText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Semantics(
                liveRegion: true,
                child: AnimatedSwitcher(
                  duration: reduce ? Duration.zero : EmilMotion.shellFadeDuration,
                  child: Text(
                    status,
                    key: ValueKey(status),
                    style: TextStyle(fontSize: 12, color: appInkMuted),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Branch Switcher for Superadmin
              if (isSuper) ...[
                Builder(
                  builder: (context) {
                    final sortedBranches = List.from(
                      branches,
                    )..sort((a, b) => (a.branchName ?? '').toLowerCase().compareTo((b.branchName ?? '').toLowerCase()));

                    return Container(
                      width: MediaQuery.sizeOf(context).width >= 480 ? 240 : 180,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: appSurfaceSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: appBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedBranchId,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: appInkMuted),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: appInkPrimary),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Branches (Network View)', overflow: TextOverflow.ellipsis),
                            ),
                            ...sortedBranches.map(
                              (b) => DropdownMenuItem<String?>(
                                value: b.branchId,
                                child: Text(b.branchName ?? 'Branch', overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val == _selectedBranchId) return;
                            setState(() {
                              _lastUpdatedAt = null;
                              _selectedBranchId = val;
                              if (val == null) {
                                _selectedBranchName = null;
                              } else {
                                final match = branches.firstWhere(
                                  (b) => b.branchId == val,
                                  orElse: () => branches.first,
                                );
                                _selectedBranchName = match.branchName;
                              }
                            });
                            _loadData();
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
              ],

              // Refresh Button
              Tooltip(
                message: _isLoading
                    ? 'Refreshing...'
                    : _isCooldownActive
                    ? 'Please wait a moment'
                    : 'Refresh data',
                child: InkWell(
                  onTap: (_isLoading || _isCooldownActive) ? null : _handleManualRefresh,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: appSurfaceSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: appBorder),
                    ),
                    child: _isLoading && !reduce
                        ? Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: appInkMuted),
                            ),
                          )
                        : Icon(
                            Icons.refresh_rounded,
                            size: 18,
                            color: (_isLoading || _isCooldownActive) ? appInkMuted : appInkSecondary,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
