import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart';
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart';
import 'package:klinik_aurora_portal/views/error/error.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/homepage/line_charts.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/user/user_homepage.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  initialLocation: LoginPage.routeName,
  navigatorKey: _rootNavigatorKey,
  routes: <RouteBase>[
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
            final orderReference = state.uri.queryParameters['orderReference'];
            return const NoTransitionPage(
              child: Scaffold(
                body: LineChartWidget(
                  isShowingMainData: true,
                ),
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
