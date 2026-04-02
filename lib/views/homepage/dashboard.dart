import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_performance_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/models/dashboard/dashboard_response.dart';
import 'package:klinik_aurora_portal/views/homepage/branch_performance_chart.dart';
import 'package:klinik_aurora_portal/views/homepage/dashboard_stats.dart';
import 'package:klinik_aurora_portal/views/homepage/registration_chart.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  List<UserData> userData = [];

  @override
  void initState() {
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      if (context.read<AuthController>().hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342') == false) {
        BranchPerformanceController.get(context).then((value) {
          if (responseCode(value.code) && mounted) {
            context.read<BranchPerformanceController>().branchPerformanceResponse = value.data;
          }
        });

        DashboardController.get(context).then((value) {
          if (responseCode(value.code)) {
            final currentDate = DateTime.now();
            final List<TotalRegistrationByMonth> totalRegistrationList =
                value.data?.data?.totalRegistrationByMonth ?? [];
            final List<TotalRegistrationByMonth> lastThreeMonths = [];
            final List<TotalRegistrationByDay> last7days = value.data?.data?.totalRegistrationByDay ?? [];
            for (int i = (value.data?.data?.totalRegistrationByMonth?.length ?? 0) - 1; i >= 0; i--) {
              final targetMonth = DateTime(currentDate.year, currentDate.month - i, 1);
              final registrationData = totalRegistrationList.firstWhere(
                (item) => item.year == targetMonth.year && item.month == targetMonth.month,
                orElse: () => TotalRegistrationByMonth(
                  year: targetMonth.year,
                  month: targetMonth.month,
                  totalRegistrationByMonth: 0,
                ),
              );
              lastThreeMonths.add(registrationData);
            }

            final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
            last7days.sort((a, b) {
              if (a.date == null || b.date == null) return 0;
              final DateTime dateA = dateFormat.parse(a.date!);
              final DateTime dateB = dateFormat.parse(b.date!);
              return dateA.compareTo(dateB);
            });

            if (!mounted) return;
            context.read<DashboardController>().dashboardResponse = DashboardResponse(
              message: value.data?.message,
              data: Data(
                totalActiveUser: value.data?.data?.totalActiveUser,
                totalActiveBranch: value.data?.data?.totalActiveBranch,
                totalActivePromotion: value.data?.data?.totalActivePromotion,
                totalUser: value.data?.data?.totalUser,
                totalRegistrationByMonth: lastThreeMonths,
                totalRegistrationByDay: last7days,
              ),
            );
          }
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (isMobile) return _buildMobileLayout();
    return _buildDesktopLayout();
  }

  Widget _buildDesktopLayout() {
    final contentWidth = screenWidth(85);
    return SingleChildScrollView(
      child: Column(
        children: [
          AppPadding.vertical(denominator: 2),
          SizedBox(width: contentWidth, child: const DashboardStats()),
          AppPadding.vertical(denominator: 2),
          Container(
            width: contentWidth,
            margin: EdgeInsets.symmetric(horizontal: screenPadding),
            child: const RegistrationChart(),
          ),
          AppPadding.vertical(denominator: 2),
          Container(
            width: contentWidth,
            margin: EdgeInsets.symmetric(horizontal: screenPadding),
            child: const BranchPerformanceChart(),
          ),
          AppPadding.vertical(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    // Charts are wrapped in a horizontally scrollable container so they never
    // overflow — user can scroll right to see the full chart, or switch to table.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppPadding.vertical(denominator: 2),
          const DashboardStats(),
          AppPadding.vertical(denominator: 2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            child: const RegistrationChart(),
          ),
          AppPadding.vertical(denominator: 2),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            child: const BranchPerformanceChart(),
          ),
          AppPadding.vertical(),
        ],
      ),
    );
  }
}

class UserData {
  String email;

  UserData({required this.email});
}
