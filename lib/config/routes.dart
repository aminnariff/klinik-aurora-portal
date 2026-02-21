import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/models/auth/auth_response.dart';
import 'package:klinik_aurora_portal/privacy/privacy_policy.dart';
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_homepage.dart';
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart';
import 'package:klinik_aurora_portal/views/delete_account/delete_account.dart';
import 'package:klinik_aurora_portal/views/doctor/doctor_homepage.dart';
import 'package:klinik_aurora_portal/views/error/error.dart';
import 'package:klinik_aurora_portal/views/homepage/dashboard.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/password_recovery/admin_password_recovery.dart';
import 'package:klinik_aurora_portal/views/payment/branch_summary_homepage.dart';
import 'package:klinik_aurora_portal/views/payment/payment_homepage.dart';
import 'package:klinik_aurora_portal/views/points/point_homepage.dart';
import 'package:klinik_aurora_portal/views/promotion/promotion_homepage.dart';
import 'package:klinik_aurora_portal/views/reward/reward_homepage.dart';
import 'package:klinik_aurora_portal/views/reward_history/reward_history_homepage.dart';
import 'package:klinik_aurora_portal/views/service/service_homepage.dart';
import 'package:klinik_aurora_portal/views/user/user_homepage.dart';
import 'package:klinik_aurora_portal/views/voucher/voucher_homepage.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: LoginPage.routeName,
  navigatorKey: rootNavigatorKey,
  redirect: (context, state) {
    final uri = state.uri.path;

    // 1. Allow public routes
    if (uri == LoginPage.routeName || uri == AdminPasswordRecoveryPage.routeName || uri == PrivacyPolicy.routeName) {
      return null;
    }

    // 2. Check for missing authentication completely
    final rawAuth = prefs.getString(authResponse);
    if (rawAuth == null || rawAuth.isEmpty) {
      return LoginPage.routeName;
    }

    // 3. Synchronously unpack the token payload to check for permissions
    try {
      final decoded = json.decode(rawAuth);
      final parsed = AuthResponse.fromJson(decoded);

      if (parsed.data?.accessToken == null) {
        return LoginPage.routeName;
      }

      final isSuperAdmin = parsed.data?.user?.isSuperadmin ?? false;
      final permissions = parsed.data?.user?.permissions ?? <String>[];

      // 4. Checking specific SuperAdmin guarded pages
      final requiresSuperAdmin = [AdminHomepage.routeName, BranchHomepage.routeName, PromotionHomepage.routeName];

      if (requiresSuperAdmin.contains(uri) && !isSuperAdmin) {
        return Homepage.routeName; // Standard deflect to dashboard
      }

      // 5. Checking exact UUID permission constraints
      final permissionMap = {
        UserHomepage.routeName: '1bda631e-ef17-11ee-bd1b-cc801b09db2f',
        AdminHomepage.routeName: '4ac042fa-ef2d-11ee-bd1b-cc801b09db2f',
        PointHomepage.routeName: 'a231db36-058d-11ef-943b-626efeb17d5e',
        BranchHomepage.routeName: '68c537d4-ef31-11ee-bd1b-cc801b09db2f',
        VoucherHomepage.routeName: 'd98236e8-f490-11ee-befc-aabaa50b463f',
        RewardHistoryHomepage.routeName: 'dc4e7a5a-0e15-11ef-82b0-94653af51fb9',
        PromotionHomepage.routeName: 'e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f',
        DoctorHomepage.routeName: 'f90f9f18-057b-11ef-943b-626efeb17d5e',
        RewardHomepage.routeName: '6e0fe1f8-2f1f-11ef-8db9-6677d190faa2',
        ServiceHomepage.routeName: '0699ac1c-ac52-11ef-a1b7-bc24115a1342',
      };

      final requiredPermission = permissionMap[uri];
      if (requiredPermission != null && !permissions.contains(requiredPermission)) {
        return Homepage.routeName; // Standard deflect to dashboard
      }
    } catch (e) {
      return LoginPage.routeName; // Deflect to login heavily if JSON parsing fails (corrupted)
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      name: AdminPasswordRecoveryPage.routeName,
      path: AdminPasswordRecoveryPage.routeName,
      builder: (BuildContext context, GoRouterState state) {
        final String? token = state.extra as String?;
        return AdminPasswordRecoveryPage(token: token);
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
        return LoginPage(resetUser: resetUser);
      },
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) {
        return NoTransitionPage(
          child: Homepage(location: state.uri.toString(), child: child),
        );
      },
      routes: [
        GoRoute(
          name: Homepage.routeName,
          path: Homepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            // final orderReference = state.uri.queryParameters['orderReference'];
            return const NoTransitionPage(child: Scaffold(body: MainDashboard()));
          },
        ),
        GoRoute(
          name: PointHomepage.routeName,
          path: PointHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: PointHomepage()));
          },
        ),
        GoRoute(
          name: UserHomepage.routeName,
          path: UserHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: UserHomepage()));
          },
        ),
        GoRoute(
          name: RewardHomepage.routeName,
          path: RewardHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: RewardHomepage()));
          },
        ),
        GoRoute(
          name: PaymentSummaryPage.routeName,
          path: PaymentSummaryPage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: PaymentSummaryPage()));
          },
        ),
        GoRoute(
          name: BranchPaymentSummaryPage.routeName,
          path: BranchPaymentSummaryPage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: BranchPaymentSummaryPage()));
          },
        ),
        GoRoute(
          name: RewardHistoryHomepage.routeName,
          path: RewardHistoryHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: RewardHistoryHomepage()));
          },
        ),
        GoRoute(
          name: BranchHomepage.routeName,
          path: BranchHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: BranchHomepage()));
          },
        ),
        GoRoute(
          name: AppointmentHomepage.routeName,
          path: AppointmentHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: AppointmentHomepage()));
          },
        ),
        GoRoute(
          name: ServiceHomepage.routeName,
          path: ServiceHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: ServiceHomepage()));
          },
        ),
        GoRoute(
          name: AdminHomepage.routeName,
          path: AdminHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: AdminHomepage()));
          },
        ),
        GoRoute(
          name: PromotionHomepage.routeName,
          path: PromotionHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: PromotionHomepage()));
          },
        ),
        GoRoute(
          name: DoctorHomepage.routeName,
          path: DoctorHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            final String? branchId = state.extra as String?;
            return NoTransitionPage(
              child: Scaffold(body: DoctorHomepage(branchId: branchId)),
            );
          },
        ),
        GoRoute(
          name: VoucherHomepage.routeName,
          path: VoucherHomepage.routeName,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: VoucherHomepage()));
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => ErrorPage(error: state.error),
);
