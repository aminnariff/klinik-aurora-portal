import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/views/settings/appearance_settings_dialog.dart';
import 'package:provider/provider.dart';
import 'package:sidebarx/sidebarx.dart';

class NavGroup {
  final String key;
  final String title;
  final IconData icon;
  final List<String> itemLabels;

  const NavGroup({
    required this.key,
    required this.title,
    required this.icon,
    required this.itemLabels,
  });
}

class AuroraCollapsibleSidebar extends StatefulWidget {
  final SidebarXController controller;
  final List<SidebarXItem> allItems;
  final void Function(String? label) onAction;
  final Widget versionWidget;
  final bool isMobileDrawer;

  const AuroraCollapsibleSidebar({
    super.key,
    required this.controller,
    required this.allItems,
    required this.onAction,
    required this.versionWidget,
    this.isMobileDrawer = false,
  });

  /// The 4 always-visible, pinned core workspace items
  static const List<String> pinnedLabels = [
    'Dashboard',
    RouteNames.queueBoardDisplay,
    RouteNames.appointmentsDisplay,
    RouteNames.patientsDisplay,
  ];

  /// The 4 collapsible accordion groups
  static const List<NavGroup> groups = [
    NavGroup(
      key: 'clinical',
      title: 'Clinical & Practice',
      icon: Icons.medical_services_outlined,
      itemLabels: [
        RouteNames.babyTrackerDisplay,
        RouteNames.trimesterRecallsDisplay,
        RouteNames.doctorsDisplay,
        RouteNames.servicesDisplay,
        RouteNames.branchesDisplay,
        RouteNames.utilizationHeatmapDisplay,
      ],
    ),
    NavGroup(
      key: 'finance',
      title: 'Finance & Cashier',
      icon: Icons.account_balance_wallet_outlined,
      itemLabels: [
        RouteNames.paymentsDisplay,
        RouteNames.eodHandoverDisplay,
      ],
    ),
    NavGroup(
      key: 'loyalty',
      title: 'Loyalty & Marketing',
      icon: Icons.card_giftcard_rounded,
      itemLabels: [
        RouteNames.pointsDisplay,
        RouteNames.vouchersDisplay,
        RouteNames.rewardsDisplay,
        RouteNames.rewardHistoryDisplay,
        RouteNames.marketingDisplay,
        RouteNames.promotionsDisplay,
      ],
    ),
    NavGroup(
      key: 'system',
      title: 'System & Governance',
      icon: Icons.admin_panel_settings_outlined,
      itemLabels: [
        RouteNames.adminsDisplay,
        RouteNames.auditLogDisplay,
      ],
    ),
  ];

  @override
  State<AuroraCollapsibleSidebar> createState() => _AuroraCollapsibleSidebarState();
}

class _AuroraCollapsibleSidebarState extends State<AuroraCollapsibleSidebar> {
  late Set<String> _expandedGroups;
  static const String _prefKey = 'aurora_sidebar_expanded_groups';

  @override
  void initState() {
    super.initState();
    // Clinical & Finance expanded by default for smooth workflow
    final saved = prefs.getStringList(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _expandedGroups = saved.toSet();
    } else {
      _expandedGroups = {'clinical', 'finance'};
    }

    widget.controller.addListener(_autoExpandActiveGroup);
    _autoExpandActiveGroup();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_autoExpandActiveGroup);
    super.dispose();
  }

  void _autoExpandActiveGroup() {
    final activeIndex = widget.controller.selectedIndex;
    if (activeIndex >= 0 && activeIndex < widget.allItems.length) {
      final activeLabel = widget.allItems[activeIndex].label;
      if (activeLabel != null) {
        for (final group in AuroraCollapsibleSidebar.groups) {
          if (group.itemLabels.contains(activeLabel)) {
            if (!_expandedGroups.contains(group.key)) {
              setState(() => _expandedGroups.add(group.key));
              _saveExpandedState();
            }
            break;
          }
        }
      }
    }
  }

  void _saveExpandedState() {
    prefs.setStringList(_prefKey, _expandedGroups.toList());
  }

  void _toggleGroup(String key) {
    setState(() {
      if (_expandedGroups.contains(key)) {
        _expandedGroups.remove(key);
      } else {
        _expandedGroups.add(key);
      }
    });
    _saveExpandedState();
  }

  SidebarXItem? _findItemByLabel(String label) {
    try {
      return widget.allItems.firstWhere((it) => it.label == label);
    } catch (_) {
      return null;
    }
  }

  int _getItemIndex(String? label) {
    if (label == null) return -1;
    return widget.allItems.indexWhere((it) => it.label == label);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final extended = widget.isMobileDrawer ? true : widget.controller.extended;

    final containerDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.sidebarTop,
          colors.sidebarBottom,
        ],
      ),
      borderRadius: widget.isMobileDrawer
          ? BorderRadius.zero
          : const BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 16,
          offset: Offset(4, 0),
        ),
      ],
    );

    final width = widget.isMobileDrawer ? double.infinity : (extended ? 255.0 : 76.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: width,
      decoration: containerDecoration,
      child: SafeArea(
        top: !widget.isMobileDrawer,
        bottom: true,
        child: Column(
          children: [
            _buildHeader(context, extended),
            const SizedBox(height: 6),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: extended ? 10 : 8,
                  vertical: 4,
                ),
                children: [
                  // --- Pinned Core Workspace ---
                  if (extended)
                    _buildSectionHeader('Core Workspace', Icons.workspace_premium_rounded),
                  for (final label in AuroraCollapsibleSidebar.pinnedLabels) ...[
                    if (_findItemByLabel(label) != null)
                      _buildMenuItem(
                        item: _findItemByLabel(label)!,
                        extended: extended,
                        isPinned: true,
                      ),
                  ],

                  // --- Collapsible Groups ---
                  for (final group in AuroraCollapsibleSidebar.groups) ...[
                    _buildGroupSection(context, group, extended),
                  ],
                ],
              ),
            ),
            _buildFooter(context, extended),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool extended) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(12, 16, 12, extended ? 10 : 16),
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
              final isSonographer =
                  auth.hasPermission('c54a2d91-499c-11f0-9169-bc24115a1342') && !auth.isSuperAdmin;
              final isSuper = auth.isSuperAdmin;
              final roleTitle = isSonographer
                  ? 'Sonographer'
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
                margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
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
                          width: 32,
                          height: 32,
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
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 8,
                            height: 8,
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
                                fontSize: 10.5,
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
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.45)),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSection(BuildContext context, NavGroup group, bool extended) {
    // Check available items in this group
    final availableItems = group.itemLabels
        .map((label) => _findItemByLabel(label))
        .whereType<SidebarXItem>()
        .toList();

    if (availableItems.isEmpty) return const SizedBox();

    final isExpanded = _expandedGroups.contains(group.key);
    final activeIndex = widget.controller.selectedIndex;
    final activeLabel = (activeIndex >= 0 && activeIndex < widget.allItems.length)
        ? widget.allItems[activeIndex].label
        : null;
    final hasActiveChild = group.itemLabels.contains(activeLabel);

    if (!extended) {
      // In compact icon mode: show small section divider and the icons
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(
              color: hasActiveChild ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.15),
              thickness: hasActiveChild ? 1.5 : 0.8,
              indent: 14,
              endIndent: 14,
            ),
          ),
          for (final item in availableItems)
            _buildMenuItem(item: item, extended: false, isChild: true),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Accordion Group Header
          InkWell(
            onTap: () => _toggleGroup(group.key),
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.white.withValues(alpha: 0.10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  Icon(
                    group.icon,
                    size: 16,
                    color: hasActiveChild ? const Color(0xFF34D399) : const Color(0xCCFFFFFF),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      group.title,
                      style: TextStyle(
                        color: hasActiveChild ? Colors.white : const Color(0xE6FFFFFF),
                        fontSize: 12.5,
                        fontWeight: hasActiveChild ? FontWeight.w700 : FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasActiveChild && !isExpanded)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF34D399),
                        shape: BoxShape.circle,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${availableItems.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Accordion Group Children with Smooth Expand/Collapse
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.fastOutSlowIn,
            alignment: Alignment.topCenter,
            child: isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(left: 10, top: 2, bottom: 4),
                    child: Column(
                      children: [
                        for (final item in availableItems)
                          _buildMenuItem(
                            item: item,
                            extended: true,
                            isChild: true,
                          ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required SidebarXItem item,
    required bool extended,
    bool isPinned = false,
    bool isChild = false,
  }) {
    final activeIndex = widget.controller.selectedIndex;
    final itemIndex = _getItemIndex(item.label);
    final isSelected = activeIndex >= 0 && activeIndex == itemIndex;

    final cell = Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.22) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isSelected
            ? Border.all(color: Colors.white.withValues(alpha: 0.35))
            : Border.all(color: Colors.transparent),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.isMobileDrawer) Navigator.of(context).pop();
            if (itemIndex >= 0) widget.controller.selectIndex(itemIndex);
            widget.onAction(item.label);
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withValues(alpha: 0.12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extended ? (isChild ? 10 : 10) : 0,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                if (isChild && extended) ...[
                  Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                _buildItemIcon(item, isSelected),
                if (extended) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.label ?? '',
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xCCFFFFFF),
                        fontSize: isChild ? 12.5 : 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!extended && item.label != null) {
      return Tooltip(
        message: item.label!,
        preferBelow: false,
        verticalOffset: 20,
        child: cell,
      );
    }

    return cell;
  }

  Widget _buildItemIcon(SidebarXItem item, bool isSelected) {
    if (item.iconBuilder != null) {
      return item.iconBuilder!(isSelected, false);
    }
    if (item.icon != null) {
      return Icon(
        item.icon,
        size: 19,
        color: isSelected ? Colors.white : const Color(0xCCFFFFFF),
      );
    }
    return const Icon(Icons.circle, size: 8, color: Colors.white);
  }

  Widget _buildFooter(BuildContext context, bool extended) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
        const SizedBox(height: 4),

        // Appearance & Theme
        Tooltip(
          message: 'Appearance & Theme',
          child: InkWell(
            onTap: () {
              if (widget.isMobileDrawer) Navigator.of(context).pop();
              AppearanceSettingsDialog.show(context);
            },
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.white.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: extended ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  const Icon(Icons.palette_outlined, color: Color(0xE6FFFFFF), size: 19),
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

        // Logout
        Tooltip(
          message: 'Logout',
          child: InkWell(
            onTap: () async {
              try {
                if (widget.isMobileDrawer) Navigator.of(context).pop();
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
                  const Icon(Icons.logout_rounded, color: Color(0xD9FFFFFF), size: 19),
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

        // Desktop Toggle Expand/Collapse Button
        if (!widget.isMobileDrawer) ...[
          const SizedBox(height: 2),
          InkWell(
            onTap: () => widget.controller.toggleExtended(),
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.white.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                mainAxisAlignment: extended ? MainAxisAlignment.end : MainAxisAlignment.center,
                children: [
                  if (extended) ...[
                    Text(
                      'Collapse Sidebar',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    extended ? Icons.arrow_back_ios_new_rounded : Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (extended) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: widget.versionWidget,
          ),
        ],
      ],
    );
  }
}
