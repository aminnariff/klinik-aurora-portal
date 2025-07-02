// Coded by Amin (May 2023)
import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/routes.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/config/theme.dart';
import 'package:klinik_aurora_portal/config/version.dart';
import 'package:klinik_aurora_portal/controllers/admin/admin_controller.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/activity_handler_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/appointment_dashboard_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/controllers/doctor/doctor_controller.dart';
import 'package:klinik_aurora_portal/controllers/permission/permission_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_management_controller.dart';
import 'package:klinik_aurora_portal/controllers/promotion/promotion_controller.dart';
import 'package:klinik_aurora_portal/controllers/refresh_token/refresh_token_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_controller.dart';
import 'package:klinik_aurora_portal/controllers/reward/reward_history_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_available_dt_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_branch_exception_controller.dart';
import 'package:klinik_aurora_portal/controllers/service/service_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/controllers/user/user_controller.dart';
import 'package:klinik_aurora_portal/controllers/voucher/voucher_controller.dart';
import 'package:provider/provider.dart';

// Admin Portal
// firebase deploy --project klinik-aurora

// Password Recovery
// firebase deploy --project klinik-aurora-recovery

// Get Klinik Aurora
// firebase deploy --project get-klinik-aurora
// Your reliable assistant for retrieving lost passwords securely.

// Production
// flutter build web -t lib/main_production.dart

// Staging
// flutter build web -t lib/main_staging.dart

// Devlopment
// flutter build web -t lib/main.dart

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await EasyLocalization.ensureInitialized();
      environment = Flavor.production;
      AppVersion.init();
      AppLoading.init();
      Storage.init();
      runApp(
        EasyLocalization(
          supportedLocales: const [Locale('en', 'US')],
          path: 'assets/translations',
          fallbackLocale: const Locale('en', 'US'),
          child: const MyApp(),
        ),
      );
    },
    (exception, stackTrace) async {
      debugPrint(exception.toString());
      // await Sentry.captureException(exception, stackTrace: stackTrace);
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // late UserActivityHandler _activityHandler;

  @override
  void initState() {
    super.initState();

    // _activityHandler = UserActivityHandler(
    //   timeout: const Duration(milliseconds: 5000),
    //   onTimeout: () {
    //     if (mounted) {
    //       context.read<AuthController>().logout(context);
    //       Future.delayed(const Duration(milliseconds: 500), () {
    //         rootNavigatorKey.currentContext?.pushReplacement(LoginPage.routeName);
    //       });
    //     }
    //   },
    // );
    // _activityHandler.initialize();
  }

  // @override
  // void dispose() {
  //   _activityHandler.dispose();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1728, 829),
      minTextAdapt: true,
      splitScreenMode: false,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider<ActivityHandlerController>(create: (_) => ActivityHandlerController()),
            ChangeNotifierProvider<AdminController>(create: (_) => AdminController()),
            ChangeNotifierProvider<AppointmentController>(create: (_) => AppointmentController()),
            ChangeNotifierProvider<AppointmentDashboardController>(create: (_) => AppointmentDashboardController()),
            ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
            ChangeNotifierProvider<BranchController>(create: (_) => BranchController()),
            ChangeNotifierProvider<DashboardController>(create: (_) => DashboardController()),
            ChangeNotifierProvider<DoctorController>(create: (_) => DoctorController()),
            ChangeNotifierProvider<DarkModeController>(create: (_) => DarkModeController()),
            ChangeNotifierProvider<PermissionController>(create: (_) => PermissionController()),
            ChangeNotifierProvider<PointManagementController>(create: (_) => PointManagementController()),
            ChangeNotifierProvider<PromotionController>(create: (_) => PromotionController()),
            ChangeNotifierProvider<RefreshTokenController>(create: (_) => RefreshTokenController()),
            ChangeNotifierProvider<RewardController>(create: (_) => RewardController()),
            ChangeNotifierProvider<RewardHistoryController>(create: (_) => RewardHistoryController()),
            ChangeNotifierProvider<ServiceController>(create: (_) => ServiceController()),
            ChangeNotifierProvider<ServiceBranchController>(create: (_) => ServiceBranchController()),
            ChangeNotifierProvider<ServiceBranchExceptionController>(create: (_) => ServiceBranchExceptionController()),
            ChangeNotifierProvider<ServiceBranchAvailableDtController>(
              create: (_) => ServiceBranchAvailableDtController(),
            ),
            ChangeNotifierProvider<UserController>(create: (_) => UserController()),
            ChangeNotifierProvider<VoucherController>(create: (_) => VoucherController()),
            ChangeNotifierProvider<TopBarController>(create: (_) => TopBarController()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            title: 'Klinik Aurora Admin',
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            builder: EasyLoading.init(builder: FToastBuilder()),
            debugShowCheckedModeBanner: false,
            theme: theme(context),
          ),
        );
      },
    );
  }
}
