import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:klinik_aurora_portal/views/mobile_view/mobile_view.dart';
import 'package:klinik_aurora_portal/views/points/point_homepage.dart';
import 'package:klinik_aurora_portal/views/promotion/promotion_homepage.dart';
import 'package:klinik_aurora_portal/views/reward/reward_homepage.dart';
import 'package:klinik_aurora_portal/views/reward_history/reward_history_homepage.dart';
import 'package:klinik_aurora_portal/views/service/service_homepage.dart';
import 'package:klinik_aurora_portal/views/user/user_homepage.dart';
import 'package:klinik_aurora_portal/views/voucher/voucher_homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
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
          return Icon(Icons.add_circle_outline_rounded, color: Colors.white);
        },
        label: 'Dashboard',
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.add_circle_outline_rounded, color: Colors.white);
        },
        label: PointHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.date_range, color: Colors.white);
        },
        label: AppointmentHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.medical_services, color: Colors.white);
        },
        label: ServiceHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.person, color: Colors.white);
        },
        label: UserHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.admin_panel_settings, color: Colors.white);
        },
        label: AdminHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(FontAwesomeIcons.codeBranch, color: Colors.white);
        },
        label: BranchHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(FontAwesomeIcons.personArrowUpFromLine, color: Colors.white);
        },
        label: DoctorHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(FontAwesomeIcons.solidImage, color: Colors.white);
        },
        label: PromotionHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(FontAwesomeIcons.ticketSimple, color: Colors.white);
        },
        label: VoucherHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(FontAwesomeIcons.gifts, color: Colors.white);
        },
        label: RewardHomepage.displayName,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return Icon(Icons.local_shipping, color: Colors.white);
        },
        label: RewardHistoryHomepage.displayName,
      ),
    ];
    super.initState();
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      context.read<TopBarController>().pageValue = 0;
      if (context.read<AuthController>().authenticationResponse != null) {
        if (!context.read<AuthController>().hasPermission('1bda631e-ef17-11ee-bd1b-cc801b09db2f')) {
          sideBarAttribute.removeWhere((element) => element.label == UserHomepage.displayName);
        }
        if (!context.read<AuthController>().hasPermission('4ac042fa-ef2d-11ee-bd1b-cc801b09db2f')) {
          sideBarAttribute.removeWhere((element) => element.label == AdminHomepage.displayName);
        }
        if (!context.read<AuthController>().hasPermission('68c537d4-ef31-11ee-bd1b-cc801b09db2f')) {
          sideBarAttribute.removeWhere((element) => element.label == BranchHomepage.displayName);
        }
        if (!context.read<AuthController>().hasPermission('d98236e8-f490-11ee-befc-aabaa50b463f')) {
          sideBarAttribute.removeWhere((element) => element.label == VoucherHomepage.displayName);
        }
        if (!context.read<AuthController>().hasPermission('dc4e7a5a-0e15-11ef-82b0-94653af51fb9')) {
          sideBarAttribute.removeWhere((element) => element.label == RewardHistoryHomepage.displayName);
        }
        if (!context.read<AuthController>().hasPermission('e7f8bc9e-ef43-11ee-bd1b-cc801b09db2f')) {
          sideBarAttribute.removeWhere((element) => element.label == PromotionHomepage.displayName);
        }
        if (!context.read<AuthController>().hasPermission('f90f9f18-057b-11ef-943b-626efeb17d5e')) {
          sideBarAttribute.removeWhere((element) => element.label == DoctorHomepage.displayName);
        }
        if (!context.read<AuthController>().hasPermission('6e0fe1f8-2f1f-11ef-8db9-6677d190faa2')) {
          sideBarAttribute.removeWhere((element) => element.label == RewardHomepage.displayName);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActivityHandlerController>(
      builder: (context, snapshot, _) {
        if (snapshot.status) {
          SchedulerBinding.instance.scheduleFrameCallback((_) {
            context.read<AuthController>().logout(context);
            context.pushReplacement(LoginPage.routeName);
          });
        }
        return LayoutWidget(mobile: const MobileView(), desktop: desktopView(context));
      },
    );
  }

  Widget desktopView(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Consumer<TopBarController>(
            builder: (ctxMain, snapshot, child) {
              return SidebarX(
                controller: pageController,
                theme: SidebarXTheme(
                  width: screenWidth(8),
                  margin: const EdgeInsets.all(0),
                  decoration: const BoxDecoration(
                    color: sidebarColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                  ),
                  hoverColor: Colors.black.withOpacity(0.31),
                  textStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  itemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  iconTheme: IconThemeData(color: Colors.white.withOpacity(0.7), size: 20),
                  itemDecoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  selectedItemDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primary.withOpacity(0.7)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.28))],
                  ),
                  // selectedItemMargin: const EdgeInsets.symmetric(horizontal: 10),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  selectedItemTextPadding: const EdgeInsets.symmetric(horizontal: 10),
                  selectedIconTheme: const IconThemeData(color: Colors.white, size: 20),
                ),
                extendedTheme: SidebarXTheme(
                  width: screenWidth(15),
                  decoration: const BoxDecoration(
                    color: sidebarColor,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0),
                    ),
                  ),
                  // textStyle: titlesBold!.apply(color: DSH_SHADOW_COLOR),
                  // selectedTextStyle: titlesBold!.apply(color: Colors.white),
                  // selectedItemMargin: EdgeInsets.only(left: screenPadding / 3, right: screenPadding / 3),
                  // itemPadding: EdgeInsets.fromLTRB(screenPadding, screenPadding, screenPadding, screenWidth(1)),
                  // selectedItemPadding: EdgeInsets.fromLTRB(screenPadding, screenPadding / 2, 0, screenPadding / 2),
                ),
                footerDivider: Divider(color: Colors.white.withOpacity(0.3), height: 1),
                headerBuilder: (context, extended) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 8),
                    child: Column(
                      children: [
                        if (extended)
                          SlideInLeft(
                            child: Image(
                              image: const AssetImage('assets/icons/logo/klinik-aurora.png'),
                              width: extended ? 100 : 50,
                              height: extended ? 100 : 50,
                            ),
                          ),
                        if (!extended)
                          SlideInRight(
                            child: Image(
                              image: const AssetImage('assets/icons/logo/klinik-aurora.png'),
                              width: extended ? 100 : 50,
                              height: extended ? 100 : 50,
                            ),
                          ),
                        if (extended)
                          Padding(
                            padding: EdgeInsets.only(top: screenPadding / 2),
                            child: AppSelectableText(
                              'ADMIN',
                              style: GoogleFonts.hindMadurai(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
                footerBuilder: (ctx, extended) {
                  return Column(
                    children: [
                      AppPadding.vertical(),
                      ListTile(
                        onTap: () {
                          try {
                            context.read<AuthController>().logout(context);
                            context.pushReplacementNamed(LoginPage.routeName, extra: true);
                          } catch (e) {
                            debugPrint(e.toString());
                          }
                        },
                        title: ElasticIn(
                          child: Row(
                            mainAxisAlignment: (extended) ? MainAxisAlignment.start : MainAxisAlignment.center,
                            children: [
                              AppPadding.horizontal(denominator: 4),
                              const Icon(Icons.logout, color: Colors.white),
                              if (extended) ...[
                                AppPadding.horizontal(denominator: 2),
                                ElasticIn(
                                  child: Text(
                                    'Logout',
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodyMedium!.apply(color: textSecondaryColor),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      version(),
                    ],
                  );
                },
                items: [
                  for (int index = 0; index < sideBarAttribute.length; index++)
                    SidebarXItem(
                      icon: sideBarAttribute[index].icon,
                      label: sideBarAttribute[index].label,
                      iconBuilder: sideBarAttribute[index].iconBuilder,
                      onTap: () {
                        action(sideBarAttribute[index].label);
                      },
                    ),
                ],
              );
            },
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                if (sideBarAttribute.isEmpty) const NoPermission(),
                widget.child,
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, screenPadding, 0),
                      child: TextButton(
                        onPressed: () {},
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Consumer<AuthController>(
                              builder: (context, authController, _) {
                                return Text(authController.authenticationResponse?.data?.user?.userFullname ?? 'N/A');
                              },
                            ),
                            AppPadding.horizontal(denominator: 2),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: secondaryColor, shape: BoxShape.circle),
                              child: const Icon(Icons.person, color: tertiaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
