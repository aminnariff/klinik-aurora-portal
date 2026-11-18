import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/config/version.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/activity_handler_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/views/homepage/no_permission.dart';
import 'package:klinik_aurora_portal/views/notification/notification_homepage.dart' deferred as notification_lib;
import 'package:klinik_aurora_portal/views/settings/appearance_settings_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/command_palette/command_palette_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/deferred_page.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';

final pageController = SidebarXController(selectedIndex: 0, extended: true);
List<SidebarXItem> sideBarAttribute = [];

class Homepage extends StatefulWidget {
  static const routeName = '/';
  static const displayName = '/';
  final String? location;
  final Widget child;

  static int getPageId(String label) {
    return sideBarAttribute.indexWhere((element) => element.label == label);
  }

  const Homepage({super.key, this.location, required this.child});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  void initState() {
    super.initState();
    _initSidebar();
  }

  static String _getItemCategory(String? label) {
    if (label == null) return '';
    if (label == 'Dashboard' ||
        label == RouteNames.patientsDisplay ||
        label == RouteNames.babyTrackerDisplay ||
        label == RouteNames.appointmentsDisplay ||
        label == RouteNames.doctorsDisplay ||
        label == RouteNames.servicesDisplay ||
        label == RouteNames.branchesDisplay ||
        label == RouteNames.paymentsDisplay) {
      return 'Clinic Operations';
    }
    if (label == RouteNames.pointsDisplay ||
        label == RouteNames.vouchersDisplay ||
        label == RouteNames.rewardsDisplay ||
        label == RouteNames.rewardHistoryDisplay ||
        label == RouteNames.marketingDisplay ||
        label == RouteNames.promotionsDisplay) {
      return 'Loyalty & Marketing';
    }
    if (label == RouteNames.adminsDisplay) {
      return 'System & Settings';
    }
    return 'Other';
  }

  void _initSidebar() {
    sideBarAttribute = [
      // --- Clinic Operations ---
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.dashboard_rounded, color: Colors.white);
        },
        label: 'Dashboard',
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.people_rounded, color: Colors.white);
        },
        label: RouteNames.patientsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.pregnant_woman_rounded, color: Colors.white);
        },
        label: RouteNames.babyTrackerDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.event_rounded, color: Colors.white);
        },
        label: RouteNames.appointmentsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const FaIcon(FontAwesomeIcons.userDoctor, color: Colors.white);
        },
        label: RouteNames.doctorsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.medical_services_rounded, color: Colors.white);
        },
        label: RouteNames.servicesDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.store_rounded, color: Colors.white);
        },
        label: RouteNames.branchesDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.receipt_long_rounded, color: Colors.white);
        },
        label: RouteNames.paymentsDisplay,
      ),

      // --- Loyalty & Marketing ---
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.stars_rounded, color: Colors.white);
        },
        label: RouteNames.pointsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.confirmation_number_rounded, color: Colors.white);
        },
        label: RouteNames.vouchersDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.redeem_rounded, color: Colors.white);
        },
        label: RouteNames.rewardsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.history_rounded, color: Colors.white);
        },
        label: RouteNames.rewardHistoryDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.celebration_rounded, color: Colors.white);
        },
        label: RouteNames.marketingDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.campaign_rounded, color: Colors.white);
        },
        label: RouteNames.promotionsDisplay,
      ),

      // --- System & Settings ---
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.admin_panel_settings_rounded, color: Colors.white);
        },
        label: RouteNames.adminsDisplay,
      ),
    ];
    getAuthController();
    super.initState();
  }

  void getAuthController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthController>().init(context).then((value) {
        if (value != null) {
          final auth = context.read<AuthController>();
          final isSuperAdmin = auth.isSuperAdmin;
          final isSonographer = auth.hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342') && !isSuperAdmin;

          if (isSonographer) {
            sideBarAttribute.retainWhere((element) => element.label == RouteNames.appointmentsDisplay);
            pageController.selectIndex(0);
            context.goNamed(RouteNames.appointments);
          } else {
            if (!auth.hasPermission('1bda631e-ef17-11ee-bd1b-cc801b09db2f')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.patientsDisplay);
            }
            if (!auth.hasPermission('4ac042fa-ef2d-11ee-bd1b-cc801b09db2f') || !isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.adminsDisplay);
            }
            if (!auth.hasPermission('a231db36-058d-11ef-943b-626efeb17d5e')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.pointsDisplay);
            }
            if (!auth.hasPermission('68c537d4-ef31-11ee-bd1b-cc801b09db2f') || !isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.branchesDisplay);
            }
            if (!auth.hasPermission('d98236e8-f490-11ee-befc-aabaa50b463f')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.vouchersDisplay);
            }
            if (!auth.hasPermission('dc4e7a5a-0e15-11ef-82b0-94653af51fb9')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.rewardHistoryDisplay);
            }
            if (!auth.hasPermission('e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f') || !isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.promotionsDisplay);
            }
            if (!auth.hasPermission('f90f9f18-057b-11ef-943b-626efeb17d5e')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.doctorsDisplay);
            }
            if (!auth.hasPermission('6e0fe1f8-2f1f-11ef-8db9-6677d190faa2')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.rewardsDisplay);
            }
            if (!auth.hasPermission('0699ac1c-ac52-11ef-a1b7-bc24115a1342')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.servicesDisplay);
            }
            if (!auth.hasPermission('f57576c4-4d15-11f0-b054-1ff6746392b2')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.paymentsDisplay);
            }
            if (!auth.hasPermission('3b8e7d9d-ac51-11ef-a1b7-bc24115a1342')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.appointmentsDisplay);
            }
            if (!isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.marketingDisplay);
            }
            context.read<TopBarController>().pageValue = 0;
          }

          if (sideBarAttribute.isEmpty) {
            context.goNamed(RouteNames.noPermission);
          }
          if (mounted) setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityHandlerController>(
      builder: (context, activityHandler, _) {
        // Check BOTH the legacy ActivityHandlerController.status AND the
        // new AuthController.sessionExpiredByInactivity flag.
        final authCtrl = context.read<AuthController>();
        final sessionExpired = activityHandler.status || authCtrl.sessionExpiredByInactivity;

        if (sessionExpired) {
          if (authCtrl.sessionExpiredByInactivity) {
            activityHandler.markInactive();
          }
          SchedulerBinding.instance.scheduleFrameCallback((_) async {
            activityHandler.reset();
            ApiController.handleSessionExpired(context);
          });
          return const SizedBox.shrink();
        }

        // Start/renew the inactivity monitor whenever the homepage renders
        // while the user is authenticated.
        authCtrl.startInactivityMonitor();

        return InactivityWatcher(
          child: LayoutWidget(mobile: mobileView(context), tablet: mobileView(context), desktop: desktopView(context)),
        );
      },
    );
  }

  Widget desktopView(BuildContext context) {
    final colors = context.appColors;
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () {
          CommandPaletteDialog.show(context);
        },
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () {
          CommandPaletteDialog.show(context);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: colors.canvas,
          body: Row(
        children: [
          Consumer<TopBarController>(
            builder: (ctxMain, snapshot, child) {
              return SidebarX(
                controller: pageController,
                theme: SidebarXTheme(
                  width: 76,
                  margin: EdgeInsets.zero,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.sidebarTop,
                        colors.sidebarBottom,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(4, 0),
                      ),
                    ],
                  ),
                  hoverColor: Colors.white.withValues(alpha: 0.12),
                  textStyle: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  itemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  selectedItemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  iconTheme: const IconThemeData(color: Color(0xCCFFFFFF), size: 20),
                  selectedIconTheme: const IconThemeData(color: Colors.white, size: 20),
                  itemMargin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  selectedItemMargin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.transparent),
                  selectedItemDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                extendedTheme: SidebarXTheme(
                  width: 255,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        colors.sidebarTop,
                        colors.sidebarBottom,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(4, 0),
                      ),
                    ],
                  ),
                  hoverColor: Colors.white.withValues(alpha: 0.12),
                  textStyle: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                  itemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  selectedItemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  iconTheme: const IconThemeData(color: Color(0xCCFFFFFF), size: 20),
                  selectedIconTheme: const IconThemeData(color: Colors.white, size: 20),
                  itemMargin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  selectedItemMargin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.transparent),
                  selectedItemDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                headerBuilder: (context, extended) {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(12, 20, 12, extended ? 12 : 20),
                        child: extended
                            ? Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.12),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset('assets/icons/logo/klinik-aurora.png', fit: BoxFit.contain),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'KLINIK AURORA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 1),
                                        Text(
                                          'Management Portal',
                                          style: TextStyle(
                                            color: Color(0xB3FFFFFF),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                width: 40,
                                height: 40,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Image.asset('assets/icons/logo/klinik-aurora.png', fit: BoxFit.contain),
                              ),
                      ),
                      if (extended)
                        Consumer<AuthController>(
                          builder: (context, auth, _) {
                            final isSonographer = auth.hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342') && !auth.isSuperAdmin;
                            final isSuper = auth.isSuperAdmin;
                            final roleTitle = isSonographer
                                ? 'Sonographer (Locum)'
                                : isSuper
                                    ? 'Super Admin'
                                    : 'Clinic Admin';

                            final roleBg = isSonographer
                                ? const Color(0xFF818CF8)
                                : isSuper
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF34D399);

                            final fullName = auth.authenticationResponse?.data?.user?.userFullname ??
                                auth.authenticationResponse?.data?.user?.userName ??
                                'Staff';

                            final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

                            return Container(
                              margin: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.22),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: const Color(0xFF246E7A), width: 1.5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          fullName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: roleBg.withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: roleBg.withValues(alpha: 0.5)),
                                          ),
                                          child: Text(
                                            roleTitle,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      if (extended && sideBarAttribute.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _getItemCategory(sideBarAttribute.first.label).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
                separatorBuilder: (context, index) {
                  if (index >= sideBarAttribute.length - 1) {
                    return const SizedBox(height: 2);
                  }
                  final currentCat = _getItemCategory(sideBarAttribute[index].label);
                  final nextCat = _getItemCategory(sideBarAttribute[index + 1].label);

                  if (currentCat != nextCat) {
                    return AnimatedBuilder(
                      animation: pageController,
                      builder: (context, _) {
                        final extended = pageController.extended;
                        if (!extended) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Divider(
                              color: Colors.white.withValues(alpha: 0.2),
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Divider(
                              color: Colors.white.withValues(alpha: 0.15),
                              height: 1,
                              indent: 14,
                              endIndent: 14,
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                nextCat.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                        );
                      },
                    );
                  }
                  return const SizedBox(height: 2);
                },
                footerDivider: Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                footerBuilder: (ctx, extended) {
                  return Column(
                    children: [
                      const SizedBox(height: 6),
                      Tooltip(
                        message: 'Appearance & Theme',
                        child: InkWell(
                          onTap: () => AppearanceSettingsDialog.show(context),
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: Colors.white.withValues(alpha: 0.15),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.palette_outlined, color: Color(0xE6FFFFFF), size: 20),
                                if (extended) ...[
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Appearance',
                                    style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Tooltip(
                        message: 'Logout',
                        child: InkWell(
                          onTap: () async {
                            try {
                              await context.read<AuthController>().logout(context);
                              if (context.mounted) context.pushReplacementNamed(RouteNames.login, extra: true);
                            } catch (e) {
                              debugPrint(e.toString());
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          hoverColor: Colors.white.withValues(alpha: 0.15),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Row(
                              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout_rounded, color: Color(0xD9FFFFFF), size: 20),
                                if (extended) ...[
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Logout',
                                    style: TextStyle(color: Color(0xD9FFFFFF), fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(padding: const EdgeInsets.only(bottom: 12), child: version()),
                    ],
                  );
                },
                items: [
                  for (int index = 0; index < sideBarAttribute.length; index++)
                    SidebarXItem(
                      icon: sideBarAttribute[index].icon,
                      label: sideBarAttribute[index].label,
                      iconBuilder: sideBarAttribute[index].iconBuilder,
                      onTap: () => action(sideBarAttribute[index].label),
                    ),
                ],
              );
            },
          ),
          Expanded(
            child: Column(
              children: [
                if (widget.location == '/') _buildTopBar(context),
                Expanded(child: sideBarAttribute.isEmpty ? const NoPermission() : widget.child),
              ],
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildTopBar(BuildContext context) {
    final colors = context.appColors;
    final themeCtrl = context.watch<DarkModeController>();
    final isDark = themeCtrl.isDarkActive(context);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: screenPadding),
      child: Row(
        children: [
          // Quick Search / Command Palette trigger pill
          InkWell(
            onTap: () => CommandPaletteDialog.show(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.surfaceSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, size: 16, color: colors.inkMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Search...',
                    style: TextStyle(fontSize: 12, color: colors.inkMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.borderStrong),
                    ),
                    child: Text(
                      '⌘K',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.inkSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
            color: colors.inkSecondary,
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeCtrl.toggleDarkMode(context),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined, size: 20),
            color: colors.inkSecondary,
            tooltip: 'Appearance & Theme Settings',
            onPressed: () => AppearanceSettingsDialog.show(context),
          ),
          if (context.read<AuthController>().isSuperAdmin) ...[
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              color: colors.inkSecondary,
              tooltip: 'Announcements',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => DeferredPage(
                  loadLibrary: notification_lib.loadLibrary,
                  builder: (_) => notification_lib.NotificationHomepage(),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.border),
            ),
            offset: const Offset(0, 42),
            color: colors.surfaceElevated,
            tooltip: 'Account menu',
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'appearance',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Appearance & Theme'),
                  ],
                ),
              ),
              if (context.read<AuthController>().isSuperAdmin)
                const PopupMenuItem<String>(
                  value: 'announcement',
                  child: Row(
                    children: [
                      Icon(Icons.campaign_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('Announcement'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<AuthController>(
                    builder: (context, authController, _) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          authController.authenticationResponse?.data?.user?.userFullname ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colors.inkPrimary,
                          ),
                        ),
                        Text(
                          authController.hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342')
                              ? 'Sonographer'
                              : authController.isSuperAdmin
                              ? 'Super Admin'
                              : 'Admin',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: colors.brandPrimary, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: colors.inkMuted, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileView(BuildContext context) {
    final colors = context.appColors;
    final themeCtrl = context.watch<DarkModeController>();
    final isDark = themeCtrl.isDarkActive(context);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.sidebarTop,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Image.asset('assets/icons/logo/klinik-aurora.png', width: 32, height: 32),
            const SizedBox(width: 8),
            const Text(
              'Aurora Admin',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20, color: Colors.white),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeCtrl.toggleDarkMode(context),
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: colors.border),
            ),
            offset: const Offset(0, 44),
            color: colors.surfaceElevated,
            tooltip: 'Account menu',
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'appearance', child: Text('Appearance & Theme')),
              if (context.read<AuthController>().isSuperAdmin)
                const PopupMenuItem<String>(value: 'announcement', child: Text('Announcement')),
              const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Consumer<AuthController>(
                    builder: (context, authController, _) => Text(
                      authController.authenticationResponse?.data?.user?.userFullname ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: colors.brandPrimary, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colors.sidebarTop,
                colors.sidebarBottom,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset('assets/icons/logo/klinik-aurora.png', fit: BoxFit.contain),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KLINIK AURORA',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'Management Portal',
                            style: TextStyle(
                              color: Color(0xB3FFFFFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    children: [
                      for (int i = 0; i < sideBarAttribute.length; i++) ...[
                        if (i == 0 ||
                            _getItemCategory(sideBarAttribute[i].label) !=
                                _getItemCategory(sideBarAttribute[i - 1].label)) ...[
                          if (i > 0) ...[
                            const SizedBox(height: 10),
                            Divider(color: Colors.white.withValues(alpha: 0.15), height: 1, indent: 8, endIndent: 8),
                            const SizedBox(height: 10),
                          ],
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
                            child: Text(
                              _getItemCategory(sideBarAttribute[i].label).toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                        _DrawerItem(
                          icon: sideBarAttribute[i].iconBuilder != null
                              ? sideBarAttribute[i].iconBuilder!(false, false)
                              : Icon(sideBarAttribute[i].icon, color: Colors.white),
                          label: sideBarAttribute[i].label ?? '',
                          onTap: () {
                            Navigator.of(context).pop();
                            action(sideBarAttribute[i].label);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Colors.white),
                  title: const Text('Appearance & Theme', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.of(context).pop();
                    AppearanceSettingsDialog.show(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Logout', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _handleMenuSelection('logout');
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: version(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: sideBarAttribute.isEmpty ? const NoPermission() : widget.child,
    );
  }

  Future<void> _handleMenuSelection(String value) async {
    if (value == 'appearance') {
      await AppearanceSettingsDialog.show(context);
    } else if (value == 'logout') {
      try {
        await context.read<AuthController>().logout(context);
        if (mounted) context.pushReplacementNamed(RouteNames.login, extra: true);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else if (value == 'announcement') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return DeferredPage(
            loadLibrary: notification_lib.loadLibrary,
            builder: (_) => notification_lib.NotificationHomepage(),
          );
        },
      );
    } else if (value == 'relocate') {
      AppToast.snackbar(context, 'We\'re actively developing this feature and it\'s on its way.');
    }
  }

  void action(String? label) {
    switch (label) {
      case 'Dashboard':
        context.go(RouteNames.home);
      case RouteNames.pointsDisplay:
        context.go(RouteNames.points);
      case RouteNames.appointmentsDisplay:
        context.go(RouteNames.appointments);
      case RouteNames.servicesDisplay:
        context.go(RouteNames.services);
      case RouteNames.patientsDisplay:
        context.go(RouteNames.patients);
      case RouteNames.babyTrackerDisplay:
        context.go(RouteNames.babyTracker);
      case RouteNames.adminsDisplay:
        context.go(RouteNames.admins);
      case RouteNames.branchesDisplay:
        context.go(RouteNames.branches);
      case RouteNames.doctorsDisplay:
        context.go(RouteNames.doctors);
      case RouteNames.promotionsDisplay:
        context.go(RouteNames.promotions);
      case RouteNames.vouchersDisplay:
        context.go(RouteNames.vouchers);
      case RouteNames.rewardsDisplay:
        context.go(RouteNames.rewards);
      case RouteNames.rewardHistoryDisplay:
        context.go(RouteNames.rewardHistory);
      case RouteNames.paymentsDisplay:
        context.go(RouteNames.payments);
      case RouteNames.marketingDisplay:
        context.go(RouteNames.marketing);
    }
  }

  Widget version() {
    return ValueListenableBuilder<AppVersionAttribute>(
      valueListenable: appVersionAttribute,
      builder: (context, snapshot, child) {
        final ver = snapshot.version ?? '1.3.0';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            'v$ver',
            style: const TextStyle(
              color: Color(0xD9FFFFFF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        );
      },
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon,
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      onTap: onTap,
      horizontalTitleGap: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: Colors.black26,
    );
  }
}

/// Wraps protected UI and records user activity (pointer + keyboard events)
/// via [AuthController.trackActivity] so the inactivity timer is reset on
/// every interaction.  Place this as the outermost child of the homepage ShellRoute.
class InactivityWatcher extends StatefulWidget {
  final Widget child;
  const InactivityWatcher({super.key, required this.child});

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  void _onActivity() {
    // Safe guard: controller may not be available during hot-reload
    if (!mounted) return;
    try {
      context.read<AuthController>().trackActivity();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          _onActivity();
        }
        return KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: (_) => _onActivity(),
        onPointerMove: (_) => _onActivity(),
        onPointerUp: (_) => _onActivity(),
        onPointerSignal: (_) => _onActivity(),
        child: widget.child,
      ),
    );
  }
}
