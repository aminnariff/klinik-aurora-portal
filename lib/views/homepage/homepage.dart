import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/config/version.dart';
import 'package:klinik_aurora_portal/controllers/auth/activity_handler_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_homepage.dart';
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart';
import 'package:klinik_aurora_portal/views/doctor/doctor_homepage.dart';
import 'package:klinik_aurora_portal/views/homepage/no_permission.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/notification/notification_homepage.dart';
import 'package:klinik_aurora_portal/views/payment/branch_summary_homepage.dart';
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
      // SidebarXItem(
      //   iconBuilder: (selected, hovered) {
      //     return Icon(Icons.money, color: Colors.white);
      //   },
      //   label: BranchPaymentSummaryPage.displayName,
      // ),
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
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(FontAwesomeIcons.userDoctor, color: Colors.white);
        },
        label: DoctorHomepage.displayName,
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
          if (context.read<AuthController>().hasPermission('1bda631e-ef17-11ee-bd1b-cc801b09db2f') == false) {
            sideBarAttribute.removeWhere((element) => element.label == UserHomepage.displayName);
          }
          if (!context.read<AuthController>().hasPermission('4ac042fa-ef2d-11ee-bd1b-cc801b09db2f') ||
              context.read<AuthController>().isSuperAdmin == false) {
            sideBarAttribute.removeWhere((element) => element.label == AdminHomepage.displayName);
          }
          if (context.read<AuthController>().hasPermission('a231db36-058d-11ef-943b-626efeb17d5e') == false) {
            sideBarAttribute.removeWhere((element) => element.label == PointHomepage.displayName);
          }
          if (!context.read<AuthController>().hasPermission('68c537d4-ef31-11ee-bd1b-cc801b09db2f') ||
              context.read<AuthController>().isSuperAdmin == false) {
            sideBarAttribute.removeWhere((element) => element.label == BranchHomepage.displayName);
          }
          if (!context.read<AuthController>().hasPermission('d98236e8-f490-11ee-befc-aabaa50b463f')) {
            sideBarAttribute.removeWhere((element) => element.label == VoucherHomepage.displayName);
          }
          if (!context.read<AuthController>().hasPermission('dc4e7a5a-0e15-11ef-82b0-94653af51fb9')) {
            sideBarAttribute.removeWhere((element) => element.label == RewardHistoryHomepage.displayName);
          }
          if (!context.read<AuthController>().hasPermission('e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f') ||
              context.read<AuthController>().isSuperAdmin == false) {
            sideBarAttribute.removeWhere((element) => element.label == PromotionHomepage.displayName);
          }
          if (!context.read<AuthController>().hasPermission('f90f9f18-057b-11ef-943b-626efeb17d5e')) {
            sideBarAttribute.removeWhere((element) => element.label == DoctorHomepage.displayName);
          }
          if (context.read<AuthController>().hasPermission('6e0fe1f8-2f1f-11ef-8db9-6677d190faa2') == false) {
            sideBarAttribute.removeWhere((element) => element.label == RewardHomepage.displayName);
          }
          if (context.read<AuthController>().hasPermission('0699ac1c-ac52-11ef-a1b7-bc24115a1342') == false) {
            sideBarAttribute.removeWhere((element) => element.label == ServiceHomepage.displayName);
          }
          context.read<TopBarController>().pageValue = 0;
          if (context.read<AuthController>().hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342')) {
            sideBarAttribute.removeWhere((element) => element.label == 'Dashboard');
            context.goNamed(AppointmentHomepage.routeName);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityHandlerController>(
      builder: (context, snapshot, _) {
        if (snapshot.status) {
          SchedulerBinding.instance.scheduleFrameCallback((_) {
            context.read<AuthController>().logout(context);
            context.goNamed(LoginPage.routeName);
          });
        }
        return LayoutWidget(mobile: mobileView(context), tablet: mobileView(context), desktop: desktopView(context));
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
                  width: screenWidth(8),
                  margin: EdgeInsets.zero,
                  decoration: const BoxDecoration(
                    color: sidebarColor,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                  hoverColor: Colors.white.withAlpha(20),
                  textStyle: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  itemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  selectedItemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  iconTheme: const IconThemeData(color: Color(0xB3FFFFFF), size: 22),
                  selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
                  itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.transparent),
                  selectedItemDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withAlpha(28),
                    border: Border.all(color: Colors.white.withAlpha(45)),
                  ),
                ),
                extendedTheme: SidebarXTheme(
                  width: screenWidth(15),
                  decoration: const BoxDecoration(
                    color: sidebarColor,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                  textStyle: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  itemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  selectedItemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  iconTheme: const IconThemeData(color: Color(0xB3FFFFFF), size: 22),
                  selectedIconTheme: const IconThemeData(color: Colors.white, size: 22),
                  itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Colors.transparent),
                  selectedItemDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withAlpha(28),
                    border: Border.all(color: Colors.white.withAlpha(45)),
                  ),
                ),
                footerDivider: Divider(color: Colors.white.withAlpha(40), height: 1),
                headerBuilder: (context, extended) {
                  return Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(8, 20, 8, extended ? 8 : 20),
                        child: extended
                            ? SlideInLeft(child: SizedBox(height: 15))
                            : SlideInRight(
                                child: Center(
                                  child: Image.asset('assets/icons/logo/klinik-aurora.png', width: 36, height: 36),
                                ),
                              ),
                      ),
                      if (extended)
                        Consumer<AuthController>(
                          builder: (context, auth, _) => Container(
                            margin: const EdgeInsets.fromLTRB(10, 0, 10, 14),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(30)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                                  child: Image.asset('assets/icons/logo/klinik-aurora.png', width: 27, height: 27),
                                  // child: const Icon(Icons.person_rounded, color: tertiaryColor, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        auth.authenticationResponse?.data?.user?.userFullname ?? '—',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        auth.isSuperAdmin ? 'Super Admin' : 'Admin',
                                        style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
                footerBuilder: (ctx, extended) {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          try {
                            context.read<AuthController>().logout(context);
                            context.pushReplacementNamed(LoginPage.routeName, extra: true);
                          } catch (e) {
                            debugPrint(e.toString());
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        hoverColor: Colors.white.withAlpha(20),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded, color: Color(0xB3FFFFFF), size: 22),
                              if (extended) ...[
                                const SizedBox(width: 12),
                                const Text(
                                  'Logout',
                                  style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
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
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      padding: EdgeInsets.symmetric(horizontal: screenPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (context.read<AuthController>().isSuperAdmin) ...[
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              color: const Color(0xFF637381),
              tooltip: 'Announcements',
              onPressed: () => showDialog(context: context, builder: (_) => NotificationHomepage()),
            ),
            const SizedBox(width: 4),
          ],
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            offset: const Offset(0, 44),
            color: Colors.white,
            tooltip: '',
            onSelected: _handleMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (context.read<AuthController>().isSuperAdmin)
                const PopupMenuItem<String>(value: 'announcement', child: Text('Announcement')),
              const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(10),
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
                          authController.isSuperAdmin ? 'Super Admin' : 'Admin',
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
        backgroundColor: sidebarColor,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  children: [
                    Image.asset('assets/icons/logo/klinik-aurora.png', width: 44, height: 44),
                    const SizedBox(width: 12),
                    const Text(
                      'ADMIN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
              const Divider(color: Colors.white24, height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text('Logout', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.of(context).pop();
                  try {
                    context.read<AuthController>().logout(context);
                    context.pushReplacementNamed(LoginPage.routeName, extra: true);
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
              ),
              Padding(padding: const EdgeInsets.only(bottom: 12), child: version()),
            ],
          ),
        ),
      ),
      body: sideBarAttribute.isEmpty ? const NoPermission() : widget.child,
    );
  }

  void _handleMenuSelection(String value) {
    if (value == 'logout') {
      try {
        context.read<AuthController>().logout(context);
        context.pushReplacementNamed(LoginPage.routeName, extra: true);
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
      case BranchPaymentSummaryPage.displayName:
        context.go(BranchPaymentSummaryPage.routeName);
    }
  }

  Widget version() {
    return ValueListenableBuilder<AppVersionAttribute>(
      valueListenable: appVersionAttribute,
      builder: (context, snapshot, child) {
        return Text(
          'v${snapshot.version}',
          style: Theme.of(context).textTheme.bodyMedium!.apply(color: textSecondaryColor),
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
