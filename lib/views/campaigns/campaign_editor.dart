import 'dart:math' as math;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/campaign/campaign_controller.dart';
import 'package:klinik_aurora_portal/models/campaign/campaign.dart';
import 'package:klinik_aurora_portal/views/campaigns/campaign_image_field.dart';
import 'package:klinik_aurora_portal/views/campaigns/campaign_management.dart' show parseHexColor;
import 'package:klinik_aurora_portal/views/widgets/button/button.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:klinik_aurora_portal/views/widgets/dialog/reusable_dialog.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

/// Create/edit dialog for a campaign, including the mobile app theme it pushes.
///
/// Pops `true` when something was saved, so the caller knows to refresh.
class CampaignEditor extends StatefulWidget {
  final Campaign? campaign;

  const CampaignEditor({super.key, this.campaign});

  @override
  State<CampaignEditor> createState() => _CampaignEditorState();
}

class _CampaignEditorState extends State<CampaignEditor> {
  final InputFieldAttribute _name = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Campaign name',
    hintText: 'e.g. Merdeka 2026',
    maxCharacter: 80,
  );
  final InputFieldAttribute _startField = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Starts',
    isEditable: false,
    suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month)]),
  );
  final InputFieldAttribute _endField = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Ends',
    isEditable: false,
    suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month)]),
  );
  final InputFieldAttribute _multiplierField = InputFieldAttribute(
    controller: TextEditingController(text: '1.0x — points unchanged'),
    labelText: 'Point multiplier',
    isEditable: false,
    helpText: 'Fixed at 1x. Award bonus points under Point Modifiers instead.',
    suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline_rounded, size: 18)]),
  );

  final InputFieldAttribute _primary = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Primary colour',
    hintText: '#C8102E',
    maxCharacter: 9,
  );
  final InputFieldAttribute _accent = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Accent colour',
    hintText: '#FFD700',
    maxCharacter: 9,
  );
  final InputFieldAttribute _backgroundColour = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Background colour',
    hintText: '#FFF5F5',
    maxCharacter: 9,
  );
  final InputFieldAttribute _splash = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Splash image URL (Optional)',
    hintText: 'https://…/splash.png',
  );
  final InputFieldAttribute _banner = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Banner image URL (Optional)',
    hintText: 'https://…/banner.png',
  );
  final InputFieldAttribute _backgroundImage = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Background image URL (Optional)',
    hintText: 'https://…/bg.png',
  );

  DateTime? _startDate;
  DateTime? _endDate;

  /// null = let the app choose from the image's shape.
  String? _backgroundFit;

  bool _isActive = true;
  bool _saving = false;
  String? _validationError;

  bool get _isEditing => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final campaign = widget.campaign;
    if (campaign == null) return;

    _name.controller.text = campaign.name;
    _startDate = campaign.startDate;
    _endDate = campaign.endDate;
    _isActive = campaign.isActive;
    _primary.controller.text = campaign.theme.primaryColor ?? '';
    _accent.controller.text = campaign.theme.accentColor ?? '';
    _backgroundColour.controller.text = campaign.theme.backgroundColor ?? '';
    _splash.controller.text = campaign.theme.splashUrl ?? '';
    _banner.controller.text = campaign.theme.bannerUrl ?? '';
    _backgroundImage.controller.text = campaign.theme.backgroundUrl ?? '';
    _backgroundFit = campaign.theme.backgroundFit;
    _syncDateText();
  }

  @override
  void dispose() {
    for (final field in [
      _name,
      _startField,
      _endField,
      _multiplierField,
      _primary,
      _accent,
      _backgroundColour,
      _splash,
      _banner,
      _backgroundImage,
    ]) {
      field.controller.dispose();
    }
    super.dispose();
  }

  void _syncDateText() {
    _startField.controller.text = _startDate == null ? '' : dateConverter('$_startDate', format: 'dd-MM-yyyy') ?? '';
    _endField.controller.text = _endDate == null ? '' : dateConverter('$_endDate', format: 'dd-MM-yyyy') ?? '';
  }

  CampaignTheme get _theme => CampaignTheme(
    primaryColor: _primary.controller.text,
    accentColor: _accent.controller.text,
    backgroundColor: _backgroundColour.controller.text,
    splashUrl: _splash.controller.text,
    bannerUrl: _banner.controller.text,
    backgroundUrl: _backgroundImage.controller.text,
    backgroundFit: _backgroundFit,
    // Preserved rather than edited: the mobile app parses it but does not yet
    // render it, so exposing a field would promise something that does nothing.
    lottieUrl: widget.campaign?.theme.lottieUrl,
  );

  String? _validate() {
    if (_name.controller.text.trim().isEmpty) return 'Give the campaign a name.';
    if (_startDate == null || _endDate == null) return 'Pick both a start and an end date.';
    final startDay = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
    final endDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);
    if (endDay.isBefore(startDay)) return 'The end date must come after the start date.';

    for (final entry in {
      'Primary colour': _primary.controller.text,
      'Accent colour': _accent.controller.text,
      'Background colour': _backgroundColour.controller.text,
    }.entries) {
      if (entry.value.trim().isNotEmpty && parseHexColor(entry.value) == null) {
        return '${entry.key} is not a valid hex colour (try #RRGGBB).';
      }
    }

    for (final entry in {
      'Splash image': _splash.controller.text,
      'Banner image': _banner.controller.text,
      'Background image': _backgroundImage.controller.text,
    }.entries) {
      final raw = entry.value.trim();
      if (raw.isEmpty) continue;
      final uri = Uri.tryParse(raw);
      if (uri == null || !uri.hasScheme || !uri.isScheme('https')) {
        return '${entry.key} must be a full https:// URL.';
      }
    }

    return null;
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    setState(() {
      _validationError = null;
      _saving = true;
    });

    // Pinned rather than read from a field: campaigns are theme-only, and
    // sending anything else here would silently change point economics.
    const multiplier = 1.0;
    final campaign = widget.campaign;

    final value = campaign == null
        ? await CampaignController.create(
            context,
            name: _name.controller.text.trim(),
            startDate: _startDate!,
            endDate: _endDate!,
            globalPointMultiplier: multiplier,
            theme: _theme,
            isActive: _isActive,
          )
        : await CampaignController.update(
            context,
            id: campaign.id,
            name: _name.controller.text.trim(),
            startDate: _startDate!,
            endDate: _endDate!,
            globalPointMultiplier: multiplier,
            theme: _theme,
            isActive: _isActive,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (responseCode(value.code)) {
      Navigator.of(context).pop(true);
    } else {
      showDialogError(context, value.message ?? 'Unable to save this campaign.');
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final results = await showCalendarDatePicker2Dialog(
      context: context,
      barrierDismissible: true,
      dialogBackgroundColor: Colors.white,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
        currentDate: DateTime.now(),
        selectedDayHighlightColor: secondaryColor,
        openedFromDialog: true,
      ),
      value: current == null ? [] : [current],
      dialogSize: Size(screenWidthByBreakpoint(90, 70, 50), screenHeightByBreakpoint(90, 80, 50)),
      borderRadius: BorderRadius.circular(15),
    );

    final picked = results?.firstOrNull;
    if (picked == null || !mounted) return;

    setState(() {
      if (isStart) {
        _startDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        // End of day, so a campaign written as "1st to 5th" covers all of the 5th.
        _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
      _syncDateText();
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.min(880.0, MediaQuery.of(context).size.width * 0.94);

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: MediaQuery.of(context).size.height * 0.92),
        child: CardContainer(
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isEditing ? 'Edit Campaign' : 'New Campaign',
                      style: AppTypography.displayMedium(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: const Color(0xFF637381),
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel(context, 'Basics'),
                        AppPadding.vertical(denominator: 2),
                        InputField(field: _name..onChanged = (_) => setState(() {})),
                        AppPadding.vertical(denominator: 2),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: true),
                                child: ReadOnly(InputField(field: _startField), isEditable: false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: false),
                                child: ReadOnly(InputField(field: _endField), isEditable: false),
                              ),
                            ),
                          ],
                        ),
                        AppPadding.vertical(denominator: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: ReadOnly(InputField(field: _multiplierField), isEditable: false)),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Active',
                                  style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
                                ),
                                Switch(
                                  value: _isActive,
                                  activeThumbColor: secondaryColor,
                                  onChanged: (value) => setState(() => _isActive = value),
                                ),
                              ],
                            ),
                          ],
                        ),
                        AppPadding.vertical(),
                        _sectionLabel(context, 'Mobile app theme'),
                        const SizedBox(height: 4),
                        Text(
                          'Applied to the Home, Rewards and Profile tabs while the campaign is live. '
                          'Leave a field blank to keep the app default.',
                          style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -2),
                        ),
                        AppPadding.vertical(denominator: 2),
                        _colourField(_primary),
                        AppPadding.vertical(denominator: 2),
                        _colourField(_accent),
                        AppPadding.vertical(denominator: 2),
                        _colourField(_backgroundColour),
                        AppPadding.vertical(denominator: 2),
                        CampaignImageField(field: _splash, onChanged: () => setState(() {})),
                        AppPadding.vertical(denominator: 2),
                        CampaignImageField(field: _banner, onChanged: () => setState(() {})),
                        AppPadding.vertical(denominator: 2),
                        CampaignImageField(field: _backgroundImage, onChanged: () => setState(() {})),
                        if (_backgroundImage.controller.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _backgroundFitSelector(),
                        ],
                        AppPadding.vertical(),
                        _ThemePreview(theme: _theme),
                      ],
                    ),
                  ),
                ),
                if (_validationError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      _validationError!,
                      style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF991B1B)),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    Button(
                      _saving ? null : _save,
                      actionText: _saving ? 'Saving…' : (_isEditing ? 'Save Changes' : 'Create Campaign'),
                      color: secondaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(text, style: AppTypography.bodyLarge(context));
  }

  /// How the app scales the background image.
  ///
  /// Automatic is right nearly always — the app measures the image and centres
  /// it rather than cropping when filling the screen would cut away too much,
  /// which is what happens to square artwork on a tall phone. The explicit
  /// options exist for artwork where that guess is wrong.
  Widget _backgroundFitSelector() {
    const options = <String?, String>{
      null: 'Automatic',
      'cover': 'Fill screen',
      'contain': 'Show whole image',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image fit',
          style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final entry in options.entries)
                ChoiceChip(
                  label: Text(entry.value, style: const TextStyle(fontSize: 12)),
                  selected: _backgroundFit == entry.key,
                  selectedColor: secondaryColor.withAlpha(45),
                  onSelected: (_) => setState(() => _backgroundFit = entry.key),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Hex input paired with a live swatch, so a typo is obvious before saving.
  Widget _colourField(InputFieldAttribute field) {
    final parsed = parseHexColor(field.controller.text);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: InputField(field: field..onChanged = (_) => setState(() {}))),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: parsed ?? const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: parsed == null ? const Icon(Icons.block_rounded, size: 18, color: Color(0xFF9CA3AF)) : null,
          ),
        ),
      ],
    );
  }
}

/// Approximation of the themed mobile tab, so an admin can sanity-check
/// contrast before a campaign goes live.
class _ThemePreview extends StatelessWidget {
  final CampaignTheme theme;

  const _ThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    if (theme.isEmpty) return const SizedBox.shrink();

    final background = parseHexColor(theme.backgroundColor) ?? Colors.white;
    final primary = parseHexColor(theme.primaryColor) ?? secondaryColor;
    final accent = parseHexColor(theme.accentColor) ?? primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preview', style: AppTypography.bodyLarge(context)),
        const SizedBox(height: 10),
        Container(
          width: 240,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (theme.bannerUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    theme.bannerUrl!,
                    height: 56,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 56,
                      color: const Color(0xFFF1F5F9),
                      alignment: Alignment.center,
                      child: const Text('Banner unreachable', style: TextStyle(fontSize: 11)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text('Your Points', style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8)),
                child: const Text('Redeem Rewards', style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
