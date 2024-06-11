import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/privacy/privacy_policy.dart';
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart';
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart';
import 'package:klinik_aurora_portal/views/delete_account/delete_account.dart';
import 'package:klinik_aurora_portal/views/doctor/doctor_homepage.dart';
import 'package:klinik_aurora_portal/views/error/error.dart';
import 'package:klinik_aurora_portal/views/homepage/dashboard.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/password_recovery/password_recovery.dart';
import 'package:klinik_aurora_portal/views/promotion/promotion_homepage.dart';
import 'package:klinik_aurora_portal/views/reward/reward_homepage.dart';
import 'package:klinik_aurora_portal/views/reward_history/reward_history_homepage.dart';
import 'package:klinik_aurora_portal/views/user/user_homepage.dart';
import 'package:klinik_aurora_portal/views/voucher/voucher_homepage.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: LoginPage.routeName,
  navigatorKey: rootNavigatorKey,
  routes: <RouteBase>[
    GoRoute(
      name: PasswordRecoveryPage.routeName,
      path: PasswordRecoveryPage.routeName,
      builder: (BuildContext context, GoRouterState state) {
        final token = state.uri.queryParameters['p1'];
        return PasswordRecoveryPage(
          token: token,
        );
      },
    ),
    GoRoute(
      name: DeleteAccountPage.routeName,
      path: DeleteAccountPage.routeName,
      builder: (BuildContext context, GoRouterState state) {
        return const DeleteAccountPage();
      },
    ),
    GoRoute(
      name: PrivacyPolicy.routeName,
      path: PrivacyPolicy.routeName,
      builder: (BuildContext context, GoRouterState state) {
        return const PrivacyPolicy();
      },
    ),
    GoRoute(
      name: LoginPage.routeName,
      path: LoginPage.routeName,
      builder: (BuildContext context, GoRouterState state) {
        bool? resetUser = state.extra as bool?;
        return LoginPage(
          resetUser: resetUser,
        );
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) {
        return NoTransitionPage(
            child: Homepage(
          location: state.uri.toString(),
          child: child,
        ));
      },
      routes: [
        GoRoute(
          name: Homepage.routeName,
          path: Homepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            // final orderReference = state.uri.queryParameters['orderReference'];
            return const NoTransitionPage(
              child: Scaffold(
                body: MainDashboard(),
              ),
            );
          },
        ),
        GoRoute(
          name: UserHomepage.routeName,
          path: UserHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: Scaffold(
                body: UserHomepage(),
              ),
            );
          },
        ),
        GoRoute(
          name: RewardHomepage.routeName,
          path: RewardHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: Scaffold(
                body: RewardHomepage(),
              ),
            );
          },
        ),
        GoRoute(
          name: RewardHistoryHomepage.routeName,
          path: RewardHistoryHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: Scaffold(
                body: RewardHistoryHomepage(),
              ),
            );
          },
        ),
        GoRoute(
          name: BranchHomepage.routeName,
          path: BranchHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: Scaffold(
                body: BranchHomepage(),
              ),
            );
          },
        ),
        GoRoute(
          name: AdminHomepage.routeName,
          path: AdminHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: Scaffold(
                body: AdminHomepage(),
              ),
            );
          },
        ),
        GoRoute(
          name: PromotionHomepage.routeName,
          path: PromotionHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: Scaffold(
                body: PromotionHomepage(),
              ),
            );
          },
        ),
        GoRoute(
          name: DoctorHomepage.routeName,
          path: DoctorHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            final String? branchId = state.extra as String?;
            return NoTransitionPage(
              child: Scaffold(
                body: DoctorHomepage(
                  branchId: branchId,
                ),
              ),
            );
          },
        ),
        GoRoute(
          name: VoucherHomepage.routeName,
          path: VoucherHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(
              child: Scaffold(
                body: VoucherHomepage(),
              ),
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => ErrorPage(error: state.error),
);

// returning value
// onTap: () {
//   final bool? result = await context.push<bool>('/page2');
//   if(result ?? false)...
// }

// onTap: () => context.pop(true)
