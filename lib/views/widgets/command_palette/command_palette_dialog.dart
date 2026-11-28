import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/route_names.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/settings/appearance_settings_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';
import 'package:provider/provider.dart';

class CommandItem {
  final String title;
  final String category;
  final IconData icon;
  final String? subtitle;
  final void Function(BuildContext context) onSelect;

  const CommandItem({
    required this.title,
    required this.category,
    required this.icon,
    this.subtitle,
    required this.onSelect,
  });
}

class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Command Palette',
      barrierColor: const Color(0x7F0F172A), // slate-900 @ 50%
      transitionDuration: EmilMotion.modalDuration,
      pageBuilder: (context, anim, _) => const CommandPaletteDialog(),
      transitionBuilder: (context, anim, _, child) {
        final curve = CurvedAnimation(parent: anim, curve: EmilMotion.easeOut);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curve),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  late final List<CommandItem> _allItems = [
    // Quick Actions
    CommandItem(
      title: 'Book New Appointment',
      category: 'Quick Actions',
      icon: Icons.add_circle_outline_rounded,
      subtitle: 'Schedule a patient for clinical service',
      onSelect: (ctx) => showDialog(
        context: ctx,
        builder: (_) => const AppointmentDetails(type: 'create'),
      ),
    ),
    CommandItem(
      title: 'Appearance & Theme Settings',
      category: 'Quick Actions',
      icon: Icons.palette_outlined,
      subtitle: 'Customize brand accent palette and Light/Dark mode',
      onSelect: (ctx) => AppearanceSettingsDialog.show(ctx),
    ),
    CommandItem(
      title: 'Toggle Dark / Light Mode',
      category: 'Quick Actions',
      icon: Icons.dark_mode_outlined,
      subtitle: 'Switch between bright reception view and low-glare dark mode',
      onSelect: (ctx) => ctx.read<DarkModeController>().toggleDarkMode(ctx),
    ),
    CommandItem(
      title: 'Keyboard Shortcuts (?)',
      category: 'Quick Actions',
      icon: Icons.keyboard_rounded,
      subtitle: 'View all power-user keyboard accelerators',
      onSelect: (ctx) => KeyboardShortcutsDialog.show(ctx),
    ),
    // Core Navigation
    CommandItem(
      title: "Today's Flow (Front-Desk Queue)",
      category: 'Clinic Operations',
      icon: Icons.view_kanban_outlined,
      subtitle: 'Live check-in board, room assignments, and wait timers',
      onSelect: (ctx) => ctx.goNamed(RouteNames.queueBoard),
    ),
    CommandItem(
      title: 'Daily EOD Branch Handover',
      category: 'Clinic Operations',
      icon: Icons.fact_check_outlined,
      subtitle: 'End-of-day cash/Fiuu reconciliation and shift export',
      onSelect: (ctx) => ctx.goNamed(RouteNames.eodHandover),
    ),
    CommandItem(
      title: 'Next-Trimester Scan Recalls',
      category: 'Clinic Operations',
      icon: Icons.notification_important_outlined,
      subtitle: 'Follow up expectant mothers due for NT, Detail, or 4D/5D scans',
      onSelect: (ctx) => ctx.goNamed(RouteNames.trimesterRecalls),
    ),
    CommandItem(
      title: 'Branch Utilization Heatmap',
      category: 'Clinic Operations',
      icon: Icons.grid_on_rounded,
      subtitle: 'Peak/idle hours and practitioner capacity alerts',
      onSelect: (ctx) => ctx.goNamed(RouteNames.utilizationHeatmap),
    ),
    CommandItem(
      title: 'Audit Trail & Activity Log',
      category: 'System',
      icon: Icons.policy_outlined,
      subtitle: 'Super Admin searchable change history and JSON diff viewer',
      onSelect: (ctx) => ctx.goNamed(RouteNames.auditLog),
    ),
    CommandItem(
      title: 'Appointments',
      category: 'Navigation',
      icon: Icons.calendar_month_rounded,
      subtitle: 'View upcoming, completed & cancelled appointments',
      onSelect: (ctx) => ctx.goNamed(RouteNames.appointments),
    ),
    CommandItem(
      title: 'Patients & Users',
      category: 'Navigation',
      icon: Icons.people_alt_outlined,
      subtitle: 'Search patient directory and profiles',
      onSelect: (ctx) => ctx.goNamed(RouteNames.patients),
    ),
    CommandItem(
      title: 'Dashboard Overview',
      category: 'Navigation',
      icon: Icons.dashboard_outlined,
      subtitle: 'Clinic operational KPIs and revenue stats',
      onSelect: (ctx) => ctx.goNamed(RouteNames.home),
    ),
    CommandItem(
      title: 'Baby Tracker 3D',
      category: 'Navigation',
      icon: Icons.child_care_rounded,
      subtitle: 'Gestational timeline and hospital checklist',
      onSelect: (ctx) => ctx.goNamed(RouteNames.babyTracker),
    ),
    CommandItem(
      title: 'Doctors & Rosters',
      category: 'Navigation',
      icon: Icons.medical_services_outlined,
      subtitle: 'Practitioner schedules and duty rosters',
      onSelect: (ctx) => ctx.goNamed(RouteNames.doctors),
    ),
    CommandItem(
      title: 'Clinic Branches',
      category: 'Navigation',
      icon: Icons.store_outlined,
      subtitle: 'Branch locations and operational timings',
      onSelect: (ctx) => ctx.goNamed(RouteNames.branches),
    ),
    CommandItem(
      title: 'Services & Pricing',
      category: 'Navigation',
      icon: Icons.healing_outlined,
      subtitle: 'Medical packages, scans, and treatments',
      onSelect: (ctx) => ctx.goNamed(RouteNames.services),
    ),
    CommandItem(
      title: 'Payments & Settlement',
      category: 'Navigation',
      icon: Icons.payments_outlined,
      subtitle: 'Fiuu transactions, receipts, and revenue summary',
      onSelect: (ctx) => ctx.goNamed(RouteNames.payments),
    ),
    CommandItem(
      title: 'Loyalty Points',
      category: 'Loyalty & Marketing',
      icon: Icons.stars_rounded,
      subtitle: 'Patient reward points and transaction ledger',
      onSelect: (ctx) => ctx.goNamed(RouteNames.points),
    ),
    CommandItem(
      title: 'Vouchers & Promos',
      category: 'Loyalty & Marketing',
      icon: Icons.confirmation_number_outlined,
      subtitle: 'Discounts and redemption codes',
      onSelect: (ctx) => ctx.goNamed(RouteNames.vouchers),
    ),
    CommandItem(
      title: 'Reward Claims',
      category: 'Loyalty & Marketing',
      icon: Icons.card_giftcard_outlined,
      subtitle: 'Patient claimed gifts and redemptions',
      onSelect: (ctx) => ctx.goNamed(RouteNames.rewards),
    ),
    CommandItem(
      title: 'Reward History',
      category: 'Loyalty & Marketing',
      icon: Icons.history_rounded,
      subtitle: 'Historical point usage log',
      onSelect: (ctx) => ctx.goNamed(RouteNames.rewardHistory),
    ),
    CommandItem(
      title: 'Marketing Campaigns',
      category: 'Loyalty & Marketing',
      icon: Icons.campaign_outlined,
      subtitle: 'Banners, promotions and announcements',
      onSelect: (ctx) => ctx.goNamed(RouteNames.marketing),
    ),
    CommandItem(
      title: 'System & Admin Settings',
      category: 'System',
      icon: Icons.admin_panel_settings_outlined,
      subtitle: 'Staff permissions and clinic configuration',
      onSelect: (ctx) => ctx.goNamed(RouteNames.admins),
    ),
  ];

  List<CommandItem> get _filteredItems {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _allItems;
    return _allItems.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          (item.subtitle?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() => _selectedIndex = 0);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _execute(CommandItem item) {
    Navigator.of(context).pop();
    item.onSelect(context);
  }

  void _handleKeyDown(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final items = _filteredItems;
    if (items.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % items.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + items.length) % items.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex < items.length) {
        _execute(items[_selectedIndex]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;
    final colors = context.appColors;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 600;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyDown,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(
              top: isCompact ? 16 : 80,
              bottom: isCompact ? 16 : 32,
              left: isCompact ? 12 : 24,
              right: isCompact ? 12 : 24,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isCompact ? screenWidth - 24 : 600,
                    maxHeight: 520,
                  ),
                  child: Container(
                    width: isCompact ? screenWidth - 24 : double.infinity,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowColor,
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Search bar header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: colors.brandText, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: colors.inkPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Type a command or search page...',
                                  hintStyle: TextStyle(
                                    fontSize: 15,
                                    color: colors.inkMuted,
                                    fontWeight: FontWeight.normal,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.borderStrong),
                              ),
                              child: Text(
                                'ESC',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: colors.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: colors.border),
                      // Results list
                      Flexible(
                        child: items.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  'No matching commands or pages found.',
                                  style: TextStyle(color: colors.inkMuted, fontSize: 14),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final isSelected = index == _selectedIndex;

                                  return InkWell(
                                    onTap: () => _execute(item),
                                    onHover: (hovered) {
                                      if (hovered) setState(() => _selectedIndex = index);
                                    },
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(minHeight: 48),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? colors.brandSoftBg : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? colors.brandBorder : Colors.transparent,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(7),
                                              decoration: BoxDecoration(
                                                color: isSelected ? colors.brandSoftBg : colors.surfaceSubtle,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                item.icon,
                                                size: 18,
                                                color: isSelected ? colors.brandText : colors.inkMuted,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                      color: colors.inkPrimary,
                                                    ),
                                                  ),
                                                  if (item.subtitle != null) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item.subtitle!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isSelected ? colors.brandText : colors.inkMuted,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            if (!isCompact) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                item.category,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colors.inkMuted,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      if (!isCompact) ...[
                        Divider(height: 1, thickness: 1, color: colors.border),
                        // Footer hint
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              _keyHint(context, '↑↓', 'Navigate'),
                              const SizedBox(width: 14),
                              _keyHint(context, '↵', 'Select'),
                              const SizedBox(width: 14),
                              _keyHint(context, 'ESC', 'Dismiss'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Klinik Aurora Command',
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 11, color: colors.inkMuted, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  Widget _keyHint(BuildContext context, String keyLabel, String action) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: colors.surfaceSubtle,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keyLabel,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colors.inkSecondary),
          ),
        ),
        const SizedBox(width: 5),
        Text(action, style: TextStyle(fontSize: 11, color: colors.inkMuted)),
      ],
    );
  }
}
