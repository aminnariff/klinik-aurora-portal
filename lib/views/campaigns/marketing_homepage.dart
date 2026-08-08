import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/campaigns/campaign_management.dart';
import 'package:klinik_aurora_portal/views/points/point_items_management.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// Container for the two campaign-configuration screens.
///
/// They were separate sidebar entries, which pushed a superadmin's sidebar to
/// fifteen items. Both are superadmin-only, both configure how a campaign
/// behaves, and neither is used day to day — so they share one entry and split
/// into tabs instead of competing for space in the nav.
class MarketingHomepage extends StatefulWidget {
  static const routeName = '/admin/marketing';
  static const displayName = 'Campaigns';

  const MarketingHomepage({super.key});

  @override
  State<MarketingHomepage> createState() => _MarketingHomepageState();
}

class _MarketingHomepageState extends State<MarketingHomepage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Campaigns', style: AppTypography.displayMedium(context)),
                const SizedBox(height: 4),
                Text(
                  'Seasonal themes and the point bonuses that run alongside them.',
                  style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
                ),
                const SizedBox(height: 8),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelColor: secondaryColor,
                  unselectedLabelColor: const Color(0xFF637381),
                  indicatorColor: secondaryColor,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(icon: Icon(Icons.celebration_rounded, size: 18), text: 'Campaigns'),
                    Tab(icon: Icon(Icons.auto_awesome_rounded, size: 18), text: 'Point Modifiers'),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                CampaignManagement(showHeader: false),
                PointItemsManagement(showHeader: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
