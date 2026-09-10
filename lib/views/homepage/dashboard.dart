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

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  String? _selectedBranchId; // null = Network View for superadmin
  String? _selectedBranchName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final isSuper = context.read<AuthController>().isSuperAdmin;

    if (isSuper) {
      // Load branches for switcher dropdown
      BranchController.getAll(context, 1, 100).then((res) {
        if (responseCode(res.code) && mounted) {
          context.read<BranchController>().branchAllResponse = res;
        }
      });

      if (_selectedBranchId == null) {
        // Load Superadmin Network data
        Future.wait([
          DashboardController.get(context).then((val) {
            if (responseCode(val.code) && mounted) {
              context.read<DashboardController>().dashboardResponse = val.data;
            }
          }),
          BranchPerformanceController.get(context).then((val) {
            if (responseCode(val.code) && mounted) {
              context.read<BranchPerformanceController>().branchPerformanceResponse = val.data;
            }
          }),
          ServicePerformanceController.get(context).then((val) {
            if (responseCode(val.code) && mounted) {
              context.read<ServicePerformanceController>().servicePerformanceResponse = val.data;
            }
          }),
        ]).whenComplete(() {
          if (mounted) setState(() => _isLoading = false);
        });
      } else {
        // Superadmin viewing a specific branch's operations
        BranchOperationsController.get(context, branchId: _selectedBranchId).then((val) {
          if (responseCode(val.code) && mounted) {
            context.read<BranchOperationsController>().branchOperationsResponse = val.data;
          }
          if (mounted) setState(() => _isLoading = false);
        });
      }
    } else {
      // Branch Admin: load their clinic's real-time operations
      BranchOperationsController.get(context).then((val) {
        if (responseCode(val.code) && mounted) {
          context.read<BranchOperationsController>().branchOperationsResponse = val.data;
        }
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuper = context.watch<AuthController>().isSuperAdmin;
    final userBranchId = context.watch<AuthController>().authenticationResponse?.data?.user?.branchId;
    final branches = context.watch<BranchController>().branchAllResponse?.data?.data ?? [];
    final userBranch = branches.where((b) => b.branchId == userBranchId).firstOrNull;
    final branchOpsName = context.watch<BranchOperationsController>().branchOperationsResponse?.data?.branchName;
    final activeBranchName = _selectedBranchName ?? userBranch?.branchName ?? branchOpsName;

    return SingleChildScrollView(
      padding: EdgeInsets.all(screenPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Bar ───────────────────────────────────────────────
              _buildHeader(isSuper, activeBranchName),
              const SizedBox(height: 20),

              // ── Main Content ─────────────────────────────────────────────
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (isSuper && _selectedBranchId == null)
                const SuperadminDashboardView()
              else
                const BranchDashboardView(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSuper, String? userBranchName) {
    final branches = context.watch<BranchController>().branchAllResponse?.data?.data ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    isSuper && _selectedBranchId == null
                        ? 'Network Intelligence Dashboard'
                        : '${_selectedBranchName ?? userBranchName ?? "Clinic"} Operations Dashboard',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSuper && _selectedBranchId == null
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isSuper && _selectedBranchId == null ? 'EXECUTIVE' : 'BRANCH LEVEL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isSuper && _selectedBranchId == null
                            ? const Color(0xFF1D4ED8)
                            : const Color(0xFF15803D),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isSuper && _selectedBranchId == null
                    ? 'Consolidated revenue, branch rankings, and patient volume across all clinics'
                    : 'Real-time daily appointments, doctor rosters, and patient queue',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          Row(
            children: [
              // Branch Switcher for Superadmin
              if (isSuper) ...[
                Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedBranchId,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('🌐 All Branches (Network View)'),
                        ),
                        ...branches.map(
                          (b) => DropdownMenuItem<String?>(
                            value: b.branchId,
                            child: Text('🏥 ${b.branchName ?? "Branch"}'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedBranchId = val;
                          if (val == null) {
                            _selectedBranchName = null;
                          } else {
                            final match = branches.firstWhere((b) => b.branchId == val, orElse: () => branches.first);
                            _selectedBranchName = match.branchName;
                          }
                        });
                        _loadData();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],

              // Refresh Button
              Tooltip(
                message: 'Refresh data',
                child: InkWell(
                  onTap: _loadData,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF475569)),
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
