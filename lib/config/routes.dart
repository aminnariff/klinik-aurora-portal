import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/models/auth/auth_response.dart';
import 'package:klinik_aurora_portal/privacy/privacy_policy.dart' deferred as privacy_policy_lib;
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart' deferred as admin_lib;
import 'package:klinik_aurora_portal/views/appointment/appointment_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/payment_mismatch_view.dart' deferred as payment_mismatch_lib;
import 'package:klinik_aurora_portal/views/appointment/queue_board_page.dart' deferred as queue_board_lib;
import 'package:klinik_aurora_portal/views/audit_log/audit_log_homepage.dart' deferred as audit_log_lib;
import 'package:klinik_aurora_portal/views/baby_tracker/baby_tracker_homepage.dart' deferred as baby_tracker_lib;
import 'package:klinik_aurora_portal/views/baby_tracker/trimester_recall_page.dart' deferred as trimester_recall_lib;
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart' deferred as branch_lib;
import 'package:klinik_aurora_portal/views/campaigns/marketing_homepage.dart' deferred as marketing_lib;
import 'package:klinik_aurora_portal/views/dashboard/utilization_heatmap_page.dart' deferred as utilization_lib;
import 'package:klinik_aurora_portal/views/delete_account/delete_account.dart' deferred as delete_account_lib;
import 'package:klinik_aurora_portal/views/doctor/doctor_homepage.dart' deferred as doctor_lib;
import 'package:klinik_aurora_portal/views/error/error.dart' deferred as error_lib;
import 'package:klinik_aurora_portal/views/homepage/dashboard.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/homepage/no_permission.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/password_recovery/admin_password_recovery.dart' deferred as password_recovery_lib;
import 'package:klinik_aurora_portal/views/payment/branch_summary_homepage.dart' deferred as branch_summary_lib;
import 'package:klinik_aurora_portal/views/payment/eod_handover_page.dart' deferred as eod_handover_lib;
import 'package:klinik_aurora_portal/views/payment/payment_homepage.dart' deferred as payment_lib;
import 'package:klinik_aurora_portal/views/points/point_homepage.dart' deferred as points_lib;
import 'package:klinik_aurora_portal/views/promotion/promotion_homepage.dart' deferred as promotion_lib;
import 'package:klinik_aurora_portal/views/reward/reward_homepage.dart' deferred as reward_lib;
import 'package:klinik_aurora_portal/views/reward_history/reward_history_homepage.dart' deferred as reward_history_lib;
import 'package:klinik_aurora_portal/views/service/service_homepage.dart' deferred as service_lib;
import 'package:klinik_aurora_portal/views/user/user_homepage.dart' deferred as user_lib;
import 'package:klinik_aurora_portal/views/voucher/voucher_homepage.dart' deferred as voucher_lib;
import 'package:klinik_aurora_portal/views/widgets/layout/deferred_page.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: RouteNames.login,
  navigatorKey: rootNavigatorKey,
  redirect: (context, state) {
    final uri = state.uri.path;

    // 1. Allow public routes
    if (uri == RouteNames.login ||
        uri == RouteNames.noPermission ||
        uri == RouteNames.passwordRecovery ||
        uri == RouteNames.privacyPolicy ||
        uri == RouteNames.termsAndConditions ||
        uri == RouteNames.refundPolicy) {
      return null;
    }

    // 2. Check for missing authentication completely
    final rawAuth = prefs.getString(authResponse);
    if (rawAuth == null || rawAuth.isEmpty) {
      return RouteNames.login;
    }

    // 2b. Check inactivity timeout (3h) — redirect to login if exceeded.
    final lastActiveRaw = prefs.getString(lastActivityTimestamp);
    if (lastActiveRaw != null && lastActiveRaw.isNotEmpty) {
      final lastActive = DateTime.tryParse(lastActiveRaw);
      if (lastActive != null) {
        final elapsed = DateTime.now().difference(lastActive);
        if (elapsed >= sessionInactivityTimeout) {
          prefs.remove(authResponse);
          prefs.remove(token);
          sessionExpiredNotice.value = true;
          return RouteNames.login;
        }
      }
    }

    // 3. Synchronously unpack the token payload to check for permissions
    try {
      final decoded = json.decode(rawAuth);
      final parsed = AuthResponse.fromJson(decoded);

      if (parsed.data?.accessToken == null) {
        return RouteNames.login;
      }

      final isSuperAdmin = parsed.data?.user?.isSuperadmin ?? false;
      final permissions = parsed.data?.user?.permissions ?? <String>[];
      final isSonographer = permissions.contains('c54a2d91-499c-11f0-9169-bc24115a1342') && !isSuperAdmin;

      // 4. SuperAdmin unconditionally has unrestricted access to all routes
      if (isSuperAdmin) {
        return null;
      }

      // 4b. Non-superadmin access to root dashboard '/'
      if (uri == RouteNames.home) {
        if (isSonographer) {
          return RouteNames.appointments;
        }
        if (permissions.isEmpty) {
          return RouteNames.noPermission;
        }
      }

      // 4c. Checking specific SuperAdmin guarded pages
      const requiresSuperAdmin = [
        RouteNames.admins,
        RouteNames.auditLog,
        RouteNames.branches,
        RouteNames.promotions,
        RouteNames.branchPaymentSummary,
        RouteNames.marketing,
      ];

      if (requiresSuperAdmin.contains(uri)) {
        return RouteNames.noPermission;
      }

      // 4d. Sonographer restricted to only appointments & today's queue
      if (isSonographer &&
          uri != RouteNames.appointments &&
          uri != RouteNames.paymentMismatch &&
          uri != RouteNames.queueBoard) {
        return RouteNames.noPermission;
      }

      // 5. Checking exact UUID permission constraints
      const permissionMap = {
        RouteNames.patients: '1bda631e-ef17-11ee-bd1b-cc801b09db2f',
        RouteNames.admins: '4ac042fa-ef2d-11ee-bd1b-cc801b09db2f',
        RouteNames.points: 'a231db36-058d-11ef-943b-626efeb17d5e',
        RouteNames.branches: '68c537d4-ef31-11ee-bd1b-cc801b09db2f',
        RouteNames.vouchers: 'd98236e8-f490-11ee-befc-aabaa50b463f',
        RouteNames.rewardHistory: 'dc4e7a5a-0e15-11ef-82b0-94653af51fb9',
        RouteNames.promotions: 'e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f',
        RouteNames.doctors: 'f90f9f18-057b-11ef-943b-626efeb17d5e',
        RouteNames.rewards: '6e0fe1f8-2f1f-11ef-8db9-6677d190faa2',
        RouteNames.services: '0699ac1c-ac52-11ef-a1b7-bc24115a1342',
        RouteNames.payments: 'f57576c4-4d15-11f0-b054-1ff6746392b2',
        RouteNames.eodHandover: 'f57576c4-4d15-11f0-b054-1ff6746392b2',
        RouteNames.appointments: '3b8e7d9d-ac51-11ef-a1b7-bc24115a1342',
        RouteNames.queueBoard: '3b8e7d9d-ac51-11ef-a1b7-bc24115a1342',
        RouteNames.paymentMismatch: '3b8e7d9d-ac51-11ef-a1b7-bc24115a1342',
      };

      final requiredPermission = permissionMap[uri];
      if (requiredPermission != null && !permissions.contains(requiredPermission)) {
        final isSonographerOnAppointment =
            (uri == RouteNames.appointments || uri == RouteNames.queueBoard) && isSonographer;
        if (!isSonographerOnAppointment) {
          return RouteNames.noPermission;
        }
      }
    } catch (e) {
      return RouteNames.login;
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      name: RouteNames.passwordRecovery,
      path: RouteNames.passwordRecovery,
      builder: (BuildContext context, GoRouterState state) {
        String? token;
        String? email;
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          token = map['token'] as String?;
          email = map['email'] as String?;
        } else if (state.extra is String) {
          token = state.extra as String;
        }
        token ??= state.uri.queryParameters['token'];
        email ??= state.uri.queryParameters['email'];
        return DeferredPage(
          loadLibrary: password_recovery_lib.loadLibrary,
          builder: (_) => password_recovery_lib.AdminPasswordRecoveryPage(token: token, email: email),
        );
      },
    ),
    GoRoute(
      name: RouteNames.deleteAccount,
      path: RouteNames.deleteAccount,
      builder: (BuildContext context, GoRouterState state) {
        return DeferredPage(
          loadLibrary: delete_account_lib.loadLibrary,
          builder: (_) => delete_account_lib.DeleteAccountPage(),
        );
      },
    ),
    GoRoute(
      name: RouteNames.privacyPolicy,
      path: RouteNames.privacyPolicy,
      builder: (BuildContext context, GoRouterState state) {
        return DeferredPage(
          loadLibrary: privacy_policy_lib.loadLibrary,
          builder: (_) => privacy_policy_lib.PrivacyPolicy(),
        );
      },
    ),
    GoRoute(
      name: RouteNames.termsAndConditions,
      path: RouteNames.termsAndConditions,
      builder: (BuildContext context, GoRouterState state) {
        return DeferredPage(
          loadLibrary: privacy_policy_lib.loadLibrary,
          builder: (_) => privacy_policy_lib.TermsAndConditions(),
        );
      },
    ),
    GoRoute(
      name: RouteNames.refundPolicy,
      path: RouteNames.refundPolicy,
      builder: (BuildContext context, GoRouterState state) {
        return DeferredPage(
          loadLibrary: privacy_policy_lib.loadLibrary,
          builder: (_) => privacy_policy_lib.RefundPolicy(),
        );
      },
    ),
    GoRoute(
      name: RouteNames.login,
      path: RouteNames.login,
      builder: (BuildContext context, GoRouterState state) {
        bool? resetUser = state.extra as bool?;
        return LoginPage(resetUser: resetUser);
      },
    ),
    GoRoute(
      name: RouteNames.noPermission,
      path: RouteNames.noPermission,
      builder: (BuildContext context, GoRouterState state) {
        return const NoPermission();
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
          name: RouteNames.home,
          path: RouteNames.home,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: MainDashboard()));
          },
        ),
        GoRoute(
          name: RouteNames.points,
          path: RouteNames.points,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: points_lib.loadLibrary,
                builder: (_) => Scaffold(body: points_lib.PointHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.patients,
          path: RouteNames.patients,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: user_lib.loadLibrary,
                builder: (_) => Scaffold(body: user_lib.UserHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.babyTracker,
          path: RouteNames.babyTracker,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: baby_tracker_lib.loadLibrary,
                builder: (_) => Scaffold(body: baby_tracker_lib.BabyTrackerHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.rewards,
          path: RouteNames.rewards,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: reward_lib.loadLibrary,
                builder: (_) => Scaffold(body: reward_lib.RewardHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.payments,
          path: RouteNames.payments,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: payment_lib.loadLibrary,
                builder: (_) => Scaffold(body: payment_lib.PaymentSummaryPage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.branchPaymentSummary,
          path: RouteNames.branchPaymentSummary,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: branch_summary_lib.loadLibrary,
                builder: (_) => Scaffold(body: branch_summary_lib.BranchPaymentSummaryPage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.rewardHistory,
          path: RouteNames.rewardHistory,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: reward_history_lib.loadLibrary,
                builder: (_) => Scaffold(body: reward_history_lib.RewardHistoryHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.marketing,
          path: RouteNames.marketing,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: marketing_lib.loadLibrary,
                builder: (_) => Scaffold(body: marketing_lib.MarketingHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.branches,
          path: RouteNames.branches,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: branch_lib.loadLibrary,
                builder: (_) => Scaffold(body: branch_lib.BranchHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.appointments,
          path: RouteNames.appointments,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return const NoTransitionPage(child: Scaffold(body: AppointmentHomepage()));
          },
        ),
        GoRoute(
          name: RouteNames.paymentMismatch,
          path: RouteNames.paymentMismatch,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: payment_mismatch_lib.loadLibrary,
                builder: (_) => Scaffold(body: payment_mismatch_lib.PaymentMismatchPage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.services,
          path: RouteNames.services,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: service_lib.loadLibrary,
                builder: (_) => Scaffold(body: service_lib.ServiceHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.admins,
          path: RouteNames.admins,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: admin_lib.loadLibrary,
                builder: (_) => Scaffold(body: admin_lib.AdminHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.promotions,
          path: RouteNames.promotions,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: promotion_lib.loadLibrary,
                builder: (_) => Scaffold(body: promotion_lib.PromotionHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.doctors,
          path: RouteNames.doctors,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            final String? branchId = state.extra as String?;
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: doctor_lib.loadLibrary,
                builder: (_) => Scaffold(body: doctor_lib.DoctorHomepage(branchId: branchId)),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.vouchers,
          path: RouteNames.vouchers,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: voucher_lib.loadLibrary,
                builder: (_) => Scaffold(body: voucher_lib.VoucherHomepage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.queueBoard,
          path: RouteNames.queueBoard,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: queue_board_lib.loadLibrary,
                builder: (_) => Scaffold(body: queue_board_lib.QueueBoardPage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.eodHandover,
          path: RouteNames.eodHandover,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: eod_handover_lib.loadLibrary,
                builder: (_) => Scaffold(body: eod_handover_lib.EodHandoverPage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.trimesterRecalls,
          path: RouteNames.trimesterRecalls,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: trimester_recall_lib.loadLibrary,
                builder: (_) => Scaffold(body: trimester_recall_lib.TrimesterRecallPage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.utilizationHeatmap,
          path: RouteNames.utilizationHeatmap,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: utilization_lib.loadLibrary,
                builder: (_) => Scaffold(body: utilization_lib.UtilizationHeatmapPage()),
              ),
            );
          },
        ),
        GoRoute(
          name: RouteNames.auditLog,
          path: RouteNames.auditLog,
          parentNavigatorKey: _shellNavigatorKey,
          pageBuilder: (context, state) {
            return NoTransitionPage(
              child: DeferredPage(
                loadLibrary: audit_log_lib.loadLibrary,
                builder: (_) => Scaffold(body: audit_log_lib.AuditLogHomepage()),
              ),
            );
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => DeferredPage(
    loadLibrary: error_lib.loadLibrary,
    builder: (_) => error_lib.ErrorPage(error: state.error),
  ),
);
