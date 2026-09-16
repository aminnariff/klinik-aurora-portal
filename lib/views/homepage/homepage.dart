import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/version.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/activity_handler_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_homepage.dart';
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart';
import 'package:klinik_aurora_portal/views/campaigns/marketing_homepage.dart';
import 'package:klinik_aurora_portal/views/doctor/doctor_homepage.dart';
import 'package:klinik_aurora_portal/views/homepage/no_permission.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/notification/notification_homepage.dart';
import 'package:klinik_aurora_portal/views/payment/payment_homepage.dart';
import 'package:klinik_aurora_portal/views/points/point_homepage.dart';
import 'package:klinik_aurora_portal/views/promotion/promotion_homepage.dart';
import 'package:klinik_aurora_portal/views/reward/reward_homepage.dart';
import 'package:klinik_aurora_portal/views/reward_history/reward_history_homepage.dart';
import 'package:klinik_aurora_portal/views/service/service_homepage.dart';
import 'package:klinik_aurora_portal/views/user/user_homepage.dart';
import 'package:klinik_aurora_portal/views/voucher/voucher_homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
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

  void _initSidebar() {
    sideBarAttribute = [
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.dashboard_rounded, color: Colors.white);
        },
        label: 'Dashboard',
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.people_rounded, color: Colors.white);
        },
        label: UserHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.stars_rounded, color: Colors.white);
        },
        label: PointHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.event_rounded, color: Colors.white);
        },
        label: AppointmentHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.receipt_long_rounded, color: Colors.white);
        },
        label: PaymentSummaryPage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return FaIcon(FontAwesomeIcons.userDoctor, color: Colors.white);
        },
        label: DoctorHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.medical_services_rounded, color: Colors.white);
        },
        label: ServiceHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.admin_panel_settings_rounded, color: Colors.white);
        },
        label: AdminHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.store_rounded, color: Colors.white);
        },
        label: BranchHomepage.displayName,
      ),
      // Campaigns and Point Modifiers share one entry — see MarketingHomepage.
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.celebration_rounded, color: Colors.white);
        },
        label: MarketingHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.campaign_rounded, color: Colors.white);
        },
        label: PromotionHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.confirmation_number_rounded, color: Colors.white);
        },
        label: VoucherHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.redeem_rounded, color: Colors.white);
        },
        label: RewardHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.history_rounded, color: Colors.white);
        },
        label: RewardHistoryHomepage.displayName,
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
            sideBarAttribute.retainWhere((element) => element.label == AppointmentHomepage.displayName);
            pageController.selectIndex(0);
            context.goNamed(AppointmentHomepage.routeName);
          } else {
            if (!auth.hasPermission('1bda631e-ef17-11ee-bd1b-cc801b09db2f')) {
              sideBarAttribute.removeWhere((element) => element.label == UserHomepage.displayName);
            }
            if (!auth.hasPermission('4ac042fa-ef2d-11ee-bd1b-cc801b09db2f') || !isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == AdminHomepage.displayName);
            }
            if (!auth.hasPermission('a231db36-058d-11ef-943b-626efeb17d5e')) {
              sideBarAttribute.removeWhere((element) => element.label == PointHomepage.displayName);
            }
            if (!auth.hasPermission('68c537d4-ef31-11ee-bd1b-cc801b09db2f') || !isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == BranchHomepage.displayName);
            }
            if (!auth.hasPermission('d98236e8-f490-11ee-befc-aabaa50b463f')) {
              sideBarAttribute.removeWhere((element) => element.label == VoucherHomepage.displayName);
            }
            if (!auth.hasPermission('dc4e7a5a-0e15-11ef-82b0-94653af51fb9')) {
              sideBarAttribute.removeWhere((element) => element.label == RewardHistoryHomepage.displayName);
            }
            if (!auth.hasPermission('e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f') || !isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == PromotionHomepage.displayName);
            }
            if (!auth.hasPermission('f90f9f18-057b-11ef-943b-626efeb17d5e')) {
              sideBarAttribute.removeWhere((element) => element.label == DoctorHomepage.displayName);
            }
            if (!auth.hasPermission('6e0fe1f8-2f1f-11ef-8db9-6677d190faa2')) {
              sideBarAttribute.removeWhere((element) => element.label == RewardHomepage.displayName);
            }
            if (!auth.hasPermission('0699ac1c-ac52-11ef-a1b7-bc24115a1342')) {
              sideBarAttribute.removeWhere((element) => element.label == ServiceHomepage.displayName);
            }
            if (!auth.hasPermission('f57576c4-4d15-11f0-b054-1ff6746392b2')) {
              sideBarAttribute.removeWhere((element) => element.label == PaymentSummaryPage.displayName);
            }
            if (!auth.hasPermission('3b8e7d9d-ac51-11ef-a1b7-bc24115a1342')) {
              sideBarAttribute.removeWhere((element) => element.label == AppointmentHomepage.displayName);
            }
            if (!isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == MarketingHomepage.displayName);
            }
            context.read<TopBarController>().pageValue = 0;
          }

          if (sideBarAttribute.isEmpty) {
            context.goNamed(NoPermission.routeName);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          Consumer<TopBarController>(
            builder: (ctxMain, snapshot, child) {
              return SidebarX(
                controller: pageController,
                theme: SidebarXTheme(
                  width: 76,
                  margin: EdgeInsets.zero,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF246E7A),
                        Color(0xFF1B545E),
                      ],
                    ),
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                    boxShadow: [
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
                  itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.transparent),
                  selectedItemDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF246E7A),
                        Color(0xFF1B545E),
                      ],
                    ),
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                    boxShadow: [
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
                  itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.transparent),
                  selectedItemDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
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
                                            fontSize: 10,
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
                                              fontSize: 9.5,
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
                    ],
                  );
                },
                footerDivider: Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                footerBuilder: (ctx, extended) {
                  return Column(
                    children: [
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          try {
                            await context.read<AuthController>().logout(context);
                            if (context.mounted) context.pushReplacementNamed(LoginPage.routeName, extra: true);
                          } catch (e) {
                            debugPrint(e.toString());
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
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
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      padding: EdgeInsets.symmetric(horizontal: screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (context.read<AuthController>().isSuperAdmin) ...[
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              color: const Color(0xFF637381),
              tooltip: 'Announcements',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: () => showDialog(context: context, builder: (_) => NotificationHomepage()),
            ),
            const SizedBox(width: 4),
          ],
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 38),
            color: Colors.white,
            tooltip: '',
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (context.read<AuthController>().isSuperAdmin)
                const PopupMenuItem<String>(value: 'announcement', child: Text('Announcement')),
              const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
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
                          style: AppTypography.bodyMedium(context).apply(fontWeightDelta: 1),
                        ),
                        Text(
                          authController.hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342')
                              ? 'Sonographer'
                              : authController.isSuperAdmin
                              ? 'Super Admin'
                              : 'Admin',
                          style: AppTypography.bodyMedium(
                            context,
                          ).apply(color: const Color(0xFF9CA3AF), fontSizeDelta: -2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.person_rounded, color: tertiaryColor, size: 18),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF9CA3AF), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget mobileView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: sidebarColor,
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
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            offset: const Offset(0, 40),
            color: Colors.white,
            tooltip: '',
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                    decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                    child: const Icon(Icons.person, color: tertiaryColor, size: 18),
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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF246E7A),
                Color(0xFF1B545E),
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
                      for (int i = 0; i < sideBarAttribute.length; i++)
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
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
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
    if (value == 'logout') {
      try {
        await context.read<AuthController>().logout(context);
        if (mounted) context.pushReplacementNamed(LoginPage.routeName, extra: true);
      } catch (e) {
        debugPrint(e.toString());
      }
    } else if (value == 'announcement') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return NotificationHomepage();
        },
      );
    } else if (value == 'relocate') {
      AppToast.snackbar(context, 'We\'re actively developing this feature and it\'s on its way.');
    }
  }

  void action(String? label) {
    switch (label) {
      case 'Dashboard':
        context.go(Homepage.routeName);
      case PointHomepage.displayName:
        context.go(PointHomepage.routeName);
      case AppointmentHomepage.displayName:
        context.go(AppointmentHomepage.routeName);
      case ServiceHomepage.displayName:
        context.go(ServiceHomepage.routeName);
      case UserHomepage.displayName:
        context.go(UserHomepage.routeName);
      case AdminHomepage.displayName:
        context.go(AdminHomepage.routeName);
      case BranchHomepage.displayName:
        context.go(BranchHomepage.routeName);
      case DoctorHomepage.displayName:
        context.go(DoctorHomepage.routeName);
      case PromotionHomepage.displayName:
        context.go(PromotionHomepage.routeName);
      case VoucherHomepage.displayName:
        context.go(VoucherHomepage.routeName);
      case RewardHomepage.displayName:
        context.go(RewardHomepage.routeName);
      case RewardHistoryHomepage.displayName:
        context.go(RewardHistoryHomepage.routeName);
      case PaymentSummaryPage.displayName:
        context.go(PaymentSummaryPage.routeName);
      case MarketingHomepage.displayName:
        context.go(MarketingHomepage.routeName);
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
              fontSize: 10,
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
