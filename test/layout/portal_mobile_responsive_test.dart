import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/admin/admin_controller.dart';
import 'package:klinik_aurora_portal/controllers/appointment/appointment_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/activity_handler_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/branch/branch_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/appointment_dashboard_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_operations_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/branch_performance_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/dashboard_controller.dart';
import 'package:klinik_aurora_portal/controllers/dashboard/service_performance_controller.dart';
import 'package:klinik_aurora_portal/controllers/doctor/doctor_controller.dart';
import 'package:klinik_aurora_portal/controllers/payment/payment_controller.dart';
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
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/queue_board_page.dart';
import 'package:klinik_aurora_portal/views/audit_log/audit_log_homepage.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/baby_tracker_homepage.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/widgets/template_item_editor_dialog.dart';
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart';
import 'package:klinik_aurora_portal/views/doctor/doctor_homepage.dart';
import 'package:klinik_aurora_portal/views/homepage/dashboard.dart';
import 'package:klinik_aurora_portal/views/homepage/dashboard_stats.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/notification/notification_homepage.dart';
import 'package:klinik_aurora_portal/views/payment/payment_homepage.dart';
import 'package:klinik_aurora_portal/views/promotion/promotion_homepage.dart';
import 'package:klinik_aurora_portal/views/reward/reward_homepage.dart';
import 'package:klinik_aurora_portal/views/service/service_homepage.dart';
import 'package:klinik_aurora_portal/views/settings/appearance_settings_dialog.dart';
import 'package:klinik_aurora_portal/views/user/user_homepage.dart';
import 'package:klinik_aurora_portal/views/voucher/voucher_homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/command_palette/command_palette_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/patient/patient_quick_drawer.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:provider/provider.dart';

const List<({String name, Size size})> _viewports = [
  (name: 'mobile_compact', size: Size(360, 800)),
  (name: 'mobile_standard', size: Size(390, 844)),
  (name: 'narrow_tablet', size: Size(600, 900)),
  (name: 'desktop_guard', size: Size(1440, 900)),
];

Widget _buildHarness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(1728, 829),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => MultiProvider(
      providers: [
        ChangeNotifierProvider<ActivityHandlerController>(create: (_) => ActivityHandlerController()),
        ChangeNotifierProvider<AdminController>(create: (_) => AdminController()),
        ChangeNotifierProvider<AppointmentController>(create: (_) => AppointmentController()),
        ChangeNotifierProvider<AppointmentDashboardController>(create: (_) => AppointmentDashboardController()),
        ChangeNotifierProvider<BranchOperationsController>(create: (_) => BranchOperationsController()),
        ChangeNotifierProvider<BranchPerformanceController>(create: (_) => BranchPerformanceController()),
        ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
        ChangeNotifierProvider<BranchController>(create: (_) => BranchController()),
        ChangeNotifierProvider<DashboardController>(create: (_) => DashboardController()),
        ChangeNotifierProvider<ServicePerformanceController>(create: (_) => ServicePerformanceController()),
        ChangeNotifierProvider<DoctorController>(create: (_) => DoctorController()),
        ChangeNotifierProvider<DarkModeController>(
          create: (_) => DarkModeController(initialThemeMode: ThemeMode.light),
        ),
        ChangeNotifierProvider<PaymentController>(create: (_) => PaymentController()),
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
      child: MaterialApp(
        builder: EasyLoading.init(),
        theme: ThemeData.light().copyWith(
          extensions: [AppColors.light(AuroraThemePreset.auroraPlum)],
        ),
        home: child,
      ),
    ),
  );
}

Future<void> _pumpAndAssertNoOverflow(
  WidgetTester tester, {
  required Size size,
  required Widget widget,
  Duration settleDuration = const Duration(milliseconds: 250),
}) async {
  final errors = <FlutterErrorDetails>[];
  final prevHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    errors.add(details);
  };
  try {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(_buildHarness(widget));
    await tester.pump(settleDuration);
    await tester.pump(const Duration(milliseconds: 100));
  } finally {
    FlutterError.onError = prevHandler;
    // Drain any Debouncer / Dio / EasyLoading timers created during initState.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 120));
  }

  final layoutErrors = errors.where((e) {
    final msg = e.exceptionAsString();
    return msg.contains('overflowed') ||
        msg.contains('RenderFlex') ||
        msg.contains('BoxConstraints') ||
        msg.contains('hasSize');
  }).toList();

  expect(
    layoutErrors,
    isEmpty,
    reason: 'Layout/overflow error(s) at ${size.width}x${size.height}: '
        '${layoutErrors.map((e) => e.toString()).join('\n---\n')}',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    await Storage.init();
  });

  group('Responsive Foundation (size.dart)', () {
    testWidgets('context-aware width helpers classify 360, 390, 600, 1440 accurately', (tester) async {
      late bool compact360, medium600, expanded1440;

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      await tester.pumpWidget(
        _buildHarness(
          Builder(
            builder: (ctx) {
              compact360 = isCompactWidth(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(compact360, isTrue);

      tester.view.physicalSize = const Size(600, 900);
      await tester.pumpWidget(
        _buildHarness(
          Builder(
            builder: (ctx) {
              medium600 = isMediumWidth(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(medium600, isTrue);

      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpWidget(
        _buildHarness(
          Builder(
            builder: (ctx) {
              expanded1440 = isExpandedWidth(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(expanded1440, isTrue);
    });
  });

  group('Mobile + Desktop Layout Regression Suite', () {
    for (final vp in _viewports) {
      testWidgets('LoginPage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(tester, size: vp.size, widget: const LoginPage());
      });

      testWidgets('Homepage Shell has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Homepage(child: SizedBox.expand()),
        );
      });

      testWidgets('DashboardStats has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: SingleChildScrollView(child: DashboardStats())),
        );
      });

      testWidgets('MainDashboard has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: MainDashboard()),
        );
      });

      testWidgets('CommandPaletteDialog has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: CommandPaletteDialog()),
        );
      });

      testWidgets('AppearanceSettingsDialog has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: Center(child: AppearanceSettingsDialog())),
        );
      });

      testWidgets('TemplateItemEditorDialog has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: Scaffold(
            body: Center(
              child: TemplateItemEditorDialog(
                categoryKey: 'baju',
                onSave: (_) async {},
              ),
            ),
          ),
        );
      });

      testWidgets('AppointmentHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: AppointmentHomepage()),
        );
      });

      testWidgets('QueueBoardPage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const QueueBoardPage(),
        );
      });

      testWidgets('UserHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: UserHomepage()),
        );
      });

      testWidgets('ServiceHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: ServiceHomepage()),
        );
      });

      testWidgets('BranchHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: BranchHomepage()),
        );
      });

      testWidgets('PaymentSummaryPage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const PaymentSummaryPage(),
        );
      });

      testWidgets('DoctorHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: DoctorHomepage()),
        );
      });

      testWidgets('AdminHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: AdminHomepage()),
        );
      });

      testWidgets('VoucherHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: VoucherHomepage()),
        );
      });

      testWidgets('RewardHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: RewardHomepage()),
        );
      });

      testWidgets('PromotionHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: PromotionHomepage()),
        );
      });

      testWidgets('BabyTrackerHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: BabyTrackerHomepage()),
        );
      });

      testWidgets('NotificationHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: NotificationHomepage()),
        );
      });

      testWidgets('AuditLogHomepage has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const AuditLogHomepage(),
        );
      });

      testWidgets('PatientQuickDrawer has no overflow at ${vp.name} (${vp.size.width}x${vp.size.height})', (tester) async {
        await _pumpAndAssertNoOverflow(
          tester,
          size: vp.size,
          widget: const Scaffold(body: PatientQuickDrawer(userId: 'test-user', initialName: 'Test Patient With Long Name')),
        );
      });
    }
  });
}
