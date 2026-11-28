import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/constants.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/config/version.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/activity_handler_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/homepage/no_permission.dart';
import 'package:klinik_aurora_portal/views/notification/notification_homepage.dart' deferred as notification_lib;
import 'package:klinik_aurora_portal/views/settings/appearance_settings_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/command_palette/command_palette_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/aurora_collapsible_sidebar.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/deferred_page.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/toast/toast.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:url_launcher/url_launcher.dart';

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
      // --- Clinic Operations ---
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.dashboard_rounded, color: Colors.white);
        },
        label: 'Dashboard',
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.view_kanban_rounded, color: Colors.white);
        },
        label: RouteNames.queueBoardDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.event_rounded, color: Colors.white);
        },
        label: RouteNames.appointmentsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.people_rounded, color: Colors.white);
        },
        label: RouteNames.patientsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.stars_rounded, color: Colors.white);
        },
        label: RouteNames.pointsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.pregnant_woman_rounded, color: Colors.white);
        },
        label: RouteNames.babyTrackerDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.notification_important_rounded, color: Colors.white);
        },
        label: RouteNames.trimesterRecallsDisplay,
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
          return const Icon(Icons.grid_on_rounded, color: Colors.white);
        },
        label: RouteNames.utilizationHeatmapDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.receipt_long_rounded, color: Colors.white);
        },
        label: RouteNames.paymentsDisplay,
      ),
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.fact_check_rounded, color: Colors.white);
        },
        label: RouteNames.eodHandoverDisplay,
      ),

      // --- Loyalty & Marketing ---
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
      SidebarXItem(
        iconBuilder: (selected, hovered) {
          return const Icon(Icons.policy_rounded, color: Colors.white);
        },
        label: RouteNames.auditLogDisplay,
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
            sideBarAttribute.retainWhere(
              (element) =>
                  element.label == RouteNames.appointmentsDisplay ||
                  element.label == RouteNames.queueBoardDisplay,
            );
            pageController.selectIndex(0);
            context.goNamed(RouteNames.appointments);
          } else {
            if (!auth.hasPermission('1bda631e-ef17-11ee-bd1b-cc801b09db2f')) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.patientsDisplay);
            }
            if (!auth.hasPermission('4ac042fa-ef2d-11ee-bd1b-cc801b09db2f') || !isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.adminsDisplay);
            }
            if (!isSuperAdmin) {
              sideBarAttribute.removeWhere((element) => element.label == RouteNames.auditLogDisplay);
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
              sideBarAttribute.removeWhere(
                (element) =>
                    element.label == RouteNames.paymentsDisplay ||
                    element.label == RouteNames.eodHandoverDisplay,
              );
            }
            if (!auth.hasPermission('3b8e7d9d-ac51-11ef-a1b7-bc24115a1342')) {
              sideBarAttribute.removeWhere(
                (element) =>
                    element.label == RouteNames.appointmentsDisplay ||
                    element.label == RouteNames.queueBoardDisplay,
              );
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
          child: isExpandedWidth(context) ? desktopView(context) : mobileView(context),
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
        const SingleActivator(LogicalKeyboardKey.slash, shift: true): () {
          if (!PortalSearchFocusBus.isTypingInTextField()) {
            KeyboardShortcutsDialog.show(context);
          }
        },
        const SingleActivator(LogicalKeyboardKey.slash): () {
          if (!PortalSearchFocusBus.isTypingInTextField()) {
            if (!PortalSearchFocusBus.focusActive()) {
              CommandPaletteDialog.show(context);
            }
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyN): () {
          if (!PortalSearchFocusBus.isTypingInTextField()) {
            showDialog(
              context: context,
              builder: (_) => const AppointmentDetails(type: 'create'),
            );
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyQ): () {
          if (!PortalSearchFocusBus.isTypingInTextField()) {
            context.go(RouteNames.queueBoard);
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyH): () {
          if (!PortalSearchFocusBus.isTypingInTextField()) {
            context.go(RouteNames.eodHandover);
          }
        },
        const SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true): () {
          pageController.toggleExtended();
          prefs.setBool('aurora_sidebar_extended', pageController.extended);
        },
        const SingleActivator(LogicalKeyboardKey.bracketLeft, control: true): () {
          pageController.toggleExtended();
          prefs.setBool('aurora_sidebar_extended', pageController.extended);
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: colors.canvas,
          body: Row(
        children: [
          AnimatedBuilder(
            animation: pageController,
            builder: (ctxMain, child) {
              return AuroraCollapsibleSidebar(
                controller: pageController,
                allItems: sideBarAttribute,
                onAction: action,
                versionWidget: version(),
              );
            },
          ),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
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

  String get _breadcrumb {
    final path = Uri.tryParse(widget.location ?? '/')?.path ?? '/';
    const labels = {
      RouteNames.home: 'Dashboard',
      RouteNames.appointments: RouteNames.appointmentsDisplay,
      RouteNames.paymentMismatch: RouteNames.paymentMismatchDisplay,
      RouteNames.patients: RouteNames.patientsDisplay,
      RouteNames.babyTracker: RouteNames.babyTrackerDisplay,
      RouteNames.doctors: RouteNames.doctorsDisplay,
      RouteNames.services: RouteNames.servicesDisplay,
      RouteNames.branches: RouteNames.branchesDisplay,
      RouteNames.payments: RouteNames.paymentsDisplay,
      RouteNames.branchPaymentSummary: RouteNames.branchPaymentSummaryDisplay,
      RouteNames.points: RouteNames.pointsDisplay,
      RouteNames.vouchers: RouteNames.vouchersDisplay,
      RouteNames.rewards: RouteNames.rewardsDisplay,
      RouteNames.rewardHistory: RouteNames.rewardHistoryDisplay,
      RouteNames.marketing: RouteNames.marketingDisplay,
      RouteNames.promotions: RouteNames.promotionsDisplay,
      RouteNames.admins: RouteNames.adminsDisplay,
      RouteNames.queueBoard: RouteNames.queueBoardDisplay,
      RouteNames.eodHandover: RouteNames.eodHandoverDisplay,
      RouteNames.trimesterRecalls: RouteNames.trimesterRecallsDisplay,
      RouteNames.utilizationHeatmap: RouteNames.utilizationHeatmapDisplay,
      RouteNames.auditLog: RouteNames.auditLogDisplay,
    };
    return labels[path] ?? 'Klinik Aurora';
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
      child: LayoutBuilder(builder: (context, constraints) => Row(
        children: [
          // Sidebar Toggle Button
          AnimatedBuilder(
            animation: pageController,
            builder: (context, _) => IconButton(
              icon: Icon(
                pageController.extended ? Icons.menu_open_rounded : Icons.menu_rounded,
                size: 20,
                color: colors.inkSecondary,
              ),
              tooltip: pageController.extended ? 'Collapse Sidebar (⌘[)' : 'Expand Sidebar (⌘[)',
              onPressed: () {
                pageController.toggleExtended();
                prefs.setBool('aurora_sidebar_extended', pageController.extended);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _breadcrumb,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.inkPrimary),
            ),
          ),
          const SizedBox(width: 8),
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
                  if (constraints.maxWidth >= 480) const SizedBox(width: 8),
                  if (constraints.maxWidth >= 480) Text(
                    'Quick Search...',
                    style: TextStyle(fontSize: 12, color: colors.inkMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
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
          const SizedBox(width: 4),
          if (constraints.maxWidth >= 420) IconButton(
            icon: const Icon(Icons.keyboard_outlined, size: 20),
            color: colors.inkSecondary,
            tooltip: 'Keyboard Shortcuts (?)',
            onPressed: () => KeyboardShortcutsDialog.show(context),
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, size: 20),
            color: colors.inkSecondary,
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () => themeCtrl.toggleDarkMode(context),
          ),
          if (constraints.maxWidth >= 420) IconButton(
            icon: const Icon(Icons.palette_outlined, size: 20),
            color: colors.inkSecondary,
            tooltip: 'Appearance & Theme Settings',
            onPressed: () => AppearanceSettingsDialog.show(context),
          ),
          if (constraints.maxWidth >= 380 && context.read<AuthController>().isSuperAdmin) ...[
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              color: colors.inkSecondary,
              tooltip: 'Announcements',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => DeferredPage(
                  key: const ValueKey('notification-modal'),
                  libraryKey: 'notification-modal',
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
              const PopupMenuItem<String>(
                value: 'tour',
                child: Row(
                  children: [
                    Icon(Icons.play_circle_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Product Tour'),
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
                  if (constraints.maxWidth >= 560) Consumer<AuthController>(
                    builder: (context, authController, _) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          authController.authenticationResponse?.data?.user?.userFullname ?? 'N/A',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
      )),
    );
  }

  Widget mobileView(BuildContext context) {
    final colors = context.appColors;
    final themeCtrl = context.watch<DarkModeController>();
    final isDark = themeCtrl.isDarkActive(context);
    final compact = isCompactWidth(context);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.sidebarTop,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Builder(
          builder: (scaffoldCtx) => IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            tooltip: 'Open navigation menu',
            onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
          ),
        ),
        title: Text(
          _breadcrumb,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            tooltip: 'Quick Search',
            onPressed: () => CommandPaletteDialog.show(context),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
              const PopupMenuItem<String>(value: 'tour', child: Text('Product Tour')),
              const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
            ],
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!compact) ...[
                    Consumer<AuthController>(
                      builder: (context, authController, _) => ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          authController.authenticationResponse?.data?.user?.userFullname ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
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
        child: AuroraCollapsibleSidebar(
          controller: pageController,
          allItems: sideBarAttribute,
          onAction: action,
          versionWidget: version(),
          isMobileDrawer: true,
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
            key: const ValueKey('notification-modal'),
            libraryKey: 'notification-modal',
            loadLibrary: notification_lib.loadLibrary,
            builder: (_) => notification_lib.NotificationHomepage(),
          );
        },
      );
    } else if (value == 'tour') {
      await launchUrl(productTourUri, webOnlyWindowName: '_blank');
    } else if (value == 'relocate') {
      AppToast.snackbar(context, 'We\'re actively developing this feature and it\'s on its way.');
    }
  }

  void action(String? label) {
    dismissLoading();
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
      case RouteNames.queueBoardDisplay:
        context.go(RouteNames.queueBoard);
      case RouteNames.eodHandoverDisplay:
        context.go(RouteNames.eodHandover);
      case RouteNames.trimesterRecallsDisplay:
        context.go(RouteNames.trimesterRecalls);
      case RouteNames.utilizationHeatmapDisplay:
        context.go(RouteNames.utilizationHeatmap);
      case RouteNames.auditLogDisplay:
        context.go(RouteNames.auditLog);
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
