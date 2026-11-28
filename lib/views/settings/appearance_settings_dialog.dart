import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/config/app_theme_preset.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';
import 'package:provider/provider.dart';

/// Interactive Appearance & Theme Settings dialog for Klinik Aurora Portal.
///
/// Lets clinic staff customize:
/// - Theme mode (Light / Dark / System)
/// - Brand accent color preset (default: Aurora Plum #7E2D40)
/// with instant live preview persisted in [Storage].
class AppearanceSettingsDialog extends StatelessWidget {
  const AppearanceSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const AppearanceSettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themeCtrl = context.watch<DarkModeController>();
    final screenSize = MediaQuery.sizeOf(context);
    final isNarrow = screenSize.width < 520;

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isNarrow ? 12 : 24, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      child: EmilModalTransition(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: screenSize.height * 0.88,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.brandSoftBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.brandBorder),
                      ),
                      child: Icon(Icons.palette_outlined, size: 20, color: colors.brandText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance & Theme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.inkPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Personalize display mode and brand accent across your workspace.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close appearance settings',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, color: colors.inkMuted, size: 20),
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Display Mode
                      Text(
                        'Display Mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Switch between bright clinic reception view and low-glare dark mode.',
                        style: TextStyle(fontSize: 12, color: colors.inkMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeOptionCard(
                              label: 'Light',
                              icon: Icons.light_mode_rounded,
                              selected: themeCtrl.themeMode == ThemeMode.light,
                              onTap: () => themeCtrl.setThemeMode(ThemeMode.light),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ModeOptionCard(
                              label: 'Dark',
                              icon: Icons.dark_mode_rounded,
                              selected: themeCtrl.themeMode == ThemeMode.dark,
                              onTap: () => themeCtrl.setThemeMode(ThemeMode.dark),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ModeOptionCard(
                              label: 'System',
                              icon: Icons.brightness_auto_rounded,
                              selected: themeCtrl.themeMode == ThemeMode.system,
                              onTap: () => themeCtrl.setThemeMode(ThemeMode.system),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 2. Table & Control Density
                      Text(
                        'Workspace Density',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose compact rows for dense reception lists or comfortable spacing.',
                        style: TextStyle(fontSize: 12, color: colors.inkMuted),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _ModeOptionCard(
                              label: 'Comfortable',
                              icon: Icons.view_agenda_outlined,
                              selected: themeCtrl.tableDensity == TableDensity.comfortable,
                              onTap: () => themeCtrl.setTableDensity(TableDensity.comfortable),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ModeOptionCard(
                              label: 'Compact',
                              icon: Icons.view_headline_rounded,
                              selected: themeCtrl.tableDensity == TableDensity.compact,
                              onTap: () => themeCtrl.setTableDensity(TableDensity.compact),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. Brand Accent Color
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Primary Accent Palette',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.inkPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'All presets are contrast-verified against light & dark surfaces.',
                                  style: TextStyle(fontSize: 12, color: colors.inkMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final crossCount = constraints.maxWidth < 420 ? 1 : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: AuroraThemePreset.values.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossCount,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              mainAxisExtent: 74,
                            ),
                            itemBuilder: (context, idx) {
                              final preset = AuroraThemePreset.values[idx];
                              return _PresetCard(
                                preset: preset,
                                selected: themeCtrl.preset == preset,
                                isDefault: preset == AuroraThemePreset.auroraPlum,
                                onTap: () => themeCtrl.setPreset(preset),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // 3. Live Preview Strip
                      Text(
                        'Live Preview',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colors.inkPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: colors.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.brandSoftBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: colors.brandBorder),
                                  ),
                                  child: Text(
                                    themeCtrl.preset.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.brandText,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.successSoftBg,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    themeCtrl.preset.contrastBadge,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.success,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        gradient: LinearGradient(
                                          colors: [colors.sidebarTop, colors.sidebarBottom],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Sidebar Pair',
                                      style: TextStyle(fontSize: 11, color: colors.inkMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppButton.primary(
                                  text: 'Create Appointment',
                                  icon: const Icon(Icons.add_rounded, size: 16),
                                  onPressed: () {},
                                ),
                                AppButton.secondary(
                                  text: 'Branch Roster',
                                  icon: Icon(Icons.calendar_month_rounded, size: 15, color: colors.inkSecondary),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => themeCtrl.resetToDefaults(),
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Reset Default'),
                    ),
                    AppButton.primary(
                      text: 'Done',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label theme mode',
      child: Material(
        color: selected ? colors.brandSoftBg : colors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? colors.brandPrimary : colors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? colors.brandText : colors.inkSecondary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? colors.brandText : colors.inkPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final AuroraThemePreset preset;
  final bool selected;
  final bool isDefault;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.selected,
    required this.isDefault,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = Theme.of(context).brightness;
    final swatchPrimary = preset.primaryFor(brightness);
    final swatchSecondary = preset.gradientFor(brightness).last;

    return Semantics(
      button: true,
      selected: selected,
      label: '${preset.name} accent color — ${preset.subtitle}',
      child: Material(
        color: selected ? colors.brandSoftBg : colors.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? swatchPrimary : colors.border,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [swatchPrimary, swatchSecondary],
                    ),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              preset.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.inkPrimary,
                              ),
                            ),
                          ),
                          if (isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: colors.surfaceSubtle,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(
                                'Default',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colors.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        preset.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
