import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/views/admin/admin_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/appointment_homepage.dart';
import 'package:klinik_aurora_portal/views/appointment/create_appointment.dart';
import 'package:klinik_aurora_portal/views/baby_tracker/baby_tracker_homepage.dart';
import 'package:klinik_aurora_portal/views/branch/branch_homepage.dart';
import 'package:klinik_aurora_portal/views/campaigns/marketing_homepage.dart';
import 'package:klinik_aurora_portal/views/doctor/doctor_homepage.dart';
import 'package:klinik_aurora_portal/views/homepage/homepage.dart';
import 'package:klinik_aurora_portal/views/payment/payment_homepage.dart';
import 'package:klinik_aurora_portal/views/points/point_homepage.dart';
import 'package:klinik_aurora_portal/views/reward/reward_homepage.dart';
import 'package:klinik_aurora_portal/views/reward_history/reward_history_homepage.dart';
import 'package:klinik_aurora_portal/views/service/service_homepage.dart';
import 'package:klinik_aurora_portal/views/user/user_homepage.dart';
import 'package:klinik_aurora_portal/views/voucher/voucher_homepage.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';

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
    // Core Navigation
    CommandItem(
      title: 'Appointments',
      category: 'Navigation',
      icon: Icons.calendar_month_rounded,
      subtitle: 'View upcoming, completed & cancelled appointments',
      onSelect: (ctx) => ctx.goNamed(AppointmentHomepage.routeName),
    ),
    CommandItem(
      title: 'Patients & Users',
      category: 'Navigation',
      icon: Icons.people_alt_outlined,
      subtitle: 'Search patient directory and profiles',
      onSelect: (ctx) => ctx.goNamed(UserHomepage.routeName),
    ),
    CommandItem(
      title: 'Dashboard Overview',
      category: 'Navigation',
      icon: Icons.dashboard_outlined,
      subtitle: 'Clinic operational KPIs and revenue stats',
      onSelect: (ctx) => ctx.goNamed(Homepage.routeName),
    ),
    CommandItem(
      title: 'Baby Tracker 3D',
      category: 'Navigation',
      icon: Icons.child_care_rounded,
      subtitle: 'Gestational timeline and hospital checklist',
      onSelect: (ctx) => ctx.goNamed(BabyTrackerHomepage.routeName),
    ),
    CommandItem(
      title: 'Doctors & Rosters',
      category: 'Navigation',
      icon: Icons.medical_services_outlined,
      subtitle: 'Practitioner schedules and duty rosters',
      onSelect: (ctx) => ctx.goNamed(DoctorHomepage.routeName),
    ),
    CommandItem(
      title: 'Clinic Branches',
      category: 'Navigation',
      icon: Icons.store_outlined,
      subtitle: 'Branch locations and operational timings',
      onSelect: (ctx) => ctx.goNamed(BranchHomepage.routeName),
    ),
    CommandItem(
      title: 'Services & Pricing',
      category: 'Navigation',
      icon: Icons.healing_outlined,
      subtitle: 'Medical packages, scans, and treatments',
      onSelect: (ctx) => ctx.goNamed(ServiceHomepage.routeName),
    ),
    CommandItem(
      title: 'Payments & Settlement',
      category: 'Navigation',
      icon: Icons.payments_outlined,
      subtitle: 'Fiuu transactions, receipts, and revenue summary',
      onSelect: (ctx) => ctx.goNamed(PaymentSummaryPage.routeName),
    ),
    CommandItem(
      title: 'Loyalty Points',
      category: 'Loyalty & Marketing',
      icon: Icons.stars_rounded,
      subtitle: 'Patient reward points and transaction ledger',
      onSelect: (ctx) => ctx.goNamed(PointHomepage.routeName),
    ),
    CommandItem(
      title: 'Vouchers & Promos',
      category: 'Loyalty & Marketing',
      icon: Icons.confirmation_number_outlined,
      subtitle: 'Discounts and redemption codes',
      onSelect: (ctx) => ctx.goNamed(VoucherHomepage.routeName),
    ),
    CommandItem(
      title: 'Reward Claims',
      category: 'Loyalty & Marketing',
      icon: Icons.card_giftcard_outlined,
      subtitle: 'Patient claimed gifts and redemptions',
      onSelect: (ctx) => ctx.goNamed(RewardHomepage.routeName),
    ),
    CommandItem(
      title: 'Reward History',
      category: 'Loyalty & Marketing',
      icon: Icons.history_rounded,
      subtitle: 'Historical point usage log',
      onSelect: (ctx) => ctx.goNamed(RewardHistoryHomepage.routeName),
    ),
    CommandItem(
      title: 'Marketing Campaigns',
      category: 'Loyalty & Marketing',
      icon: Icons.campaign_outlined,
      subtitle: 'Banners, promotions and announcements',
      onSelect: (ctx) => ctx.goNamed(MarketingHomepage.routeName),
    ),
    CommandItem(
      title: 'System & Admin Settings',
      category: 'System',
      icon: Icons.admin_panel_settings_outlined,
      subtitle: 'Staff permissions and clinic configuration',
      onSelect: (ctx) => ctx.goNamed(AdminHomepage.routeName),
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

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyDown,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 80, bottom: 40, left: 24, right: 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 600,
                constraints: const BoxConstraints(maxHeight: 520),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Search bar header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: Color(0xFF0D9488), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Type a command or search page...',
                                hintStyle: TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Text(
                              'ESC',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    // Results list
                    Flexible(
                      child: items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No matching commands or pages found.',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFFF0FDFA) : Colors.transparent, // teal-50
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFCCFBF1) : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color(0xFF0D9488).withValues(alpha: 0.15)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            item.icon,
                                            size: 18,
                                            color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                                ),
                                              ),
                                              if (item.subtitle != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.subtitle!,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSelected ? const Color(0xFF0D9488) : const Color(0xFF94A3B8),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Text(
                                          item.category,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    // Footer hint
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          _keyHint('↑↓', 'Navigate'),
                          const SizedBox(width: 14),
                          _keyHint('↵', 'Select'),
                          const SizedBox(width: 14),
                          _keyHint('ESC', 'Dismiss'),
                          const Spacer(),
                          const Text(
                            'Klinik Aurora Command',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _keyHint(String keyLabel, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keyLabel,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
        ),
        const SizedBox(width: 5),
        Text(action, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
