import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/campaign/campaign_controller.dart';
import 'package:klinik_aurora_portal/models/campaign/campaign.dart';
import 'package:klinik_aurora_portal/views/campaigns/campaign_editor.dart';
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class CampaignManagement extends StatefulWidget {
  static const routeName = '/admin/campaigns';
  static const displayName = 'Campaigns';

  /// False when embedded in a tabbed container that already renders a title,
  /// so the page does not repeat it.
  final bool showHeader;

  const CampaignManagement({super.key, this.showHeader = true});

  @override
  State<CampaignManagement> createState() => _CampaignManagementState();
}

class _CampaignManagementState extends State<CampaignManagement> {
  List<Campaign> _campaigns = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final value = await CampaignController.getAll(context);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (responseCode(value.code)) {
        _campaigns = value.data ?? [];
      } else {
        _error = value.message ?? 'Unable to load campaigns.';
      }
    });
  }

  /// Campaigns whose live windows collide.
  ///
  /// `GET /public/active-campaign` takes whichever row MySQL returns first with
  /// no tie-break, so overlapping active campaigns make the mobile theme
  /// non-deterministic. Surfaced as a warning rather than blocked — the overlap
  /// may be intentional while one is being phased out.
  Set<String> get _overlappingIds {
    final active = _campaigns.where((c) => c.isActive).toList();
    final ids = <String>{};
    for (var i = 0; i < active.length; i++) {
      for (var j = i + 1; j < active.length; j++) {
        if (active[i].overlaps(active[j])) {
          ids.add(active[i].id);
          ids.add(active[j].id);
        }
      }
    }
    return ids;
  }

  Future<void> _openEditor({Campaign? campaign}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CampaignEditor(campaign: campaign),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Campaign campaign) async {
    final confirmed = await showConfirmDialog(
      context,
      'Delete "${campaign.name}"? Any festive theme it applies will disappear from the mobile app on the next launch.',
    );
    if (!confirmed || !mounted) return;

    final value = await CampaignController.delete(context, campaign.id);
    if (!mounted) return;

    if (responseCode(value.code)) {
      showDialogSuccess(context, 'Campaign deleted.');
      _load();
    } else {
      showDialogError(context, value.message ?? 'Unable to delete this campaign.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: widget.showHeader
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Campaigns', style: AppTypography.displayMedium(context)),
                            const SizedBox(height: 4),
                            Text(
                              'Seasonal point boosts and mobile app themes.',
                              style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Button(
                  _loading ? null : () => _openEditor(),
                  actionText: 'New Campaign',
                  color: secondaryColor,
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load campaigns',
        message: _error!,
        action: Button(_load, actionText: 'Retry', color: secondaryColor),
      );
    }

    if (_campaigns.isEmpty) {
      return _EmptyState(
        icon: Icons.campaign_rounded,
        title: 'No campaigns yet',
        message: 'Create one to run a point multiplier or re-skin the mobile app for a festive season.',
        action: Button(() => _openEditor(), actionText: 'New Campaign', color: secondaryColor),
      );
    }

    final overlapping = _overlappingIds;

    return ListView.separated(
      itemCount: _campaigns.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final campaign = _campaigns[index];
        return _CampaignCard(
          campaign: campaign,
          hasOverlapWarning: overlapping.contains(campaign.id),
          onEdit: () => _openEditor(campaign: campaign),
          onDelete: () => _delete(campaign),
        );
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final bool hasOverlapWarning;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CampaignCard({
    required this.campaign,
    required this.hasOverlapWarning,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ThemeSwatch(theme: campaign.theme),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              campaign.name,
                              style: AppTypography.bodyLarge(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(campaign: campaign),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatDate(campaign.startDate)} → ${_formatDate(campaign.endDate)}',
                        style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        campaign.globalPointMultiplier == 1.0
                            ? 'No point multiplier'
                            : '${campaign.globalPointMultiplier}x points app-wide',
                        style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: secondaryColor,
                  tooltip: 'Edit',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFD32F2F),
                  tooltip: 'Delete',
                  onPressed: onDelete,
                ),
              ],
            ),
            if (hasOverlapWarning) ...[
              const SizedBox(height: 12),
              _Warning(
                message:
                    'Date range overlaps another active campaign. The mobile app picks only one, and which one is not guaranteed.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? value) {
    if (value == null) return '—';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(value.day)}/${two(value.month)}/${value.year}';
  }
}

/// Preview of the colours a campaign pushes to the mobile app.
class _ThemeSwatch extends StatelessWidget {
  final CampaignTheme theme;

  const _ThemeSwatch({required this.theme});

  @override
  Widget build(BuildContext context) {
    final colors = [
      parseHexColor(theme.primaryColor),
      parseHexColor(theme.accentColor),
      parseHexColor(theme.backgroundColor),
    ].whereType<Color>().toList();

    if (colors.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.palette_outlined, size: 20, color: Color(0xFF9CA3AF)),
      );
    }

    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [for (final color in colors) Expanded(child: Container(width: 44, color: color))],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final Campaign campaign;

  const _StatusChip({required this.campaign});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    if (!campaign.isActive) {
      label = 'Inactive';
      color = const Color(0xFF9CA3AF);
    } else if (campaign.isLive) {
      label = 'Live now';
      color = const Color(0xFF16A34A);
    } else if (campaign.startDate != null && campaign.startDate!.isAfter(DateTime.now())) {
      label = 'Scheduled';
      color = const Color(0xFF2563EB);
    } else {
      label = 'Ended';
      color = const Color(0xFF9CA3AF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withAlpha(28), borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: AppTypography.bodyMedium(context).apply(color: color, fontSizeDelta: -3, fontWeightDelta: 2),
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  final String message;

  const _Warning({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF92400E), fontSizeDelta: -2),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _EmptyState({required this.icon, required this.title, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: secondaryColor.withAlpha(100)),
          const SizedBox(height: 16),
          Text(title, style: AppTypography.bodyLarge(context)),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Parses the hex strings stored in `theme_config` for preview purposes.
///
/// Must stay in step with `ThemeService.hexToColor` in the mobile app, so that
/// what an admin previews here is what a patient actually sees.
Color? parseHexColor(String? raw) {
  if (raw == null) return null;

  var hex = raw.trim().toUpperCase().replaceAll('#', '');
  if (hex.isEmpty) return null;

  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) {
    hex = 'FF$hex';
  }
  if (hex.length != 8) return null;

  final value = int.tryParse(hex, radix: 16);
  return value == null ? null : Color(value);
}
