import 'dart:math' as math;

import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/controllers/api_response_controller.dart';
import 'package:klinik_aurora_portal/controllers/point_management/point_modifier_controller.dart';
import 'package:klinik_aurora_portal/models/point_management/point_modifier.dart';
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

class PointItemsManagement extends StatefulWidget {
  static const routeName = '/admin/point-items';
  static const displayName = 'Point Modifiers';

  /// False when embedded in a tabbed container that already renders a title,
  /// so the page does not repeat it.
  final bool showHeader;

  const PointItemsManagement({super.key, this.showHeader = true});

  @override
  State<PointItemsManagement> createState() => _PointItemsManagementState();
}

class _PointItemsManagementState extends State<PointItemsManagement> {
  List<PointModifier> _modifiers = [];
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

    final value = await PointModifierController.getAll(context);
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (responseCode(value.code)) {
        _modifiers = value.data ?? [];
      } else {
        _error = value.message ?? 'Unable to load point modifiers.';
      }
    });
  }

  Future<void> _openEditor({PointModifier? modifier}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ModifierEditor(modifier: modifier),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(PointModifier modifier) async {
    final confirmed = await showConfirmDialog(
      context,
      'Delete "${modifier.itemName}"? Branch staff will no longer be able to apply it. '
      'Points already awarded are unaffected.',
    );
    if (!confirmed || !mounted) return;

    final value = await PointModifierController.delete(context, modifier.id);
    if (!mounted) return;

    if (responseCode(value.code)) {
      showDialogSuccess(context, 'Point modifier deleted.');
      _load();
    } else {
      showDialogError(context, value.message ?? 'Unable to delete this modifier.');
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
                            Text('Point Modifiers', style: AppTypography.displayMedium(context)),
                            const SizedBox(height: 4),
                            Text(
                              'Bonuses branch staff can apply when awarding points.',
                              style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                Button(
                  _loading ? null : () => _openEditor(),
                  actionText: 'New Modifier',
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
      return _Empty(
        icon: Icons.error_outline_rounded,
        title: 'Could not load modifiers',
        message: _error!,
        action: Button(_load, actionText: 'Retry', color: secondaryColor),
      );
    }

    if (_modifiers.isEmpty) {
      return _Empty(
        icon: Icons.stars_rounded,
        title: 'No modifiers yet',
        message: 'Create one to let branch staff add a bonus on top of the points a transaction earns.',
        action: Button(() => _openEditor(), actionText: 'New Modifier', color: secondaryColor),
      );
    }

    return ListView.separated(
      itemCount: _modifiers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final modifier = _modifiers[index];
        return CardContainer(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: modifier.isActive ? secondaryColor.withAlpha(30) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: modifier.isActive ? secondaryColor : const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              modifier.itemName,
                              style: AppTypography.bodyLarge(context),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusChip(modifier: modifier),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Three labelled facts rather than a run-on sentence: what
                      // it awards, when staff can use it, and what that means on
                      // a real transaction.
                      Wrap(
                        spacing: 20,
                        runSpacing: 6,
                        children: [
                          _Fact(icon: Icons.add_circle_outline_rounded, label: 'Awards', value: modifier.summary),
                          _Fact(
                            icon: Icons.event_available_outlined,
                            label: 'Available',
                            value: modifier.windowLabel,
                          ),
                          _Fact(
                            icon: Icons.calculate_outlined,
                            label: 'Example',
                            value: '100 pts → ${100 + modifier.bonusFor(100)} pts',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: secondaryColor,
                  tooltip: 'Edit',
                  onPressed: () => _openEditor(modifier: modifier),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: const Color(0xFFD32F2F),
                  tooltip: 'Delete',
                  onPressed: () => _delete(modifier),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModifierEditor extends StatefulWidget {
  final PointModifier? modifier;

  const _ModifierEditor({this.modifier});

  @override
  State<_ModifierEditor> createState() => _ModifierEditorState();
}

class _ModifierEditorState extends State<_ModifierEditor> {
  final InputFieldAttribute _name = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Name',
    hintText: 'e.g. Buku Pink Bonus',
    helpText: 'Branch staff pick this by name when awarding points.',
    maxCharacter: 60,
  );
  final InputFieldAttribute _multiplier = InputFieldAttribute(
    controller: TextEditingController(text: '1.0'),
    labelText: 'Multiplier',
    hintText: '1.0',
    helpText: '1.0 leaves base points unchanged; 1.5 adds 50%.',
    isNumber: true,
    maxCharacter: 6,
  );
  final InputFieldAttribute _bonus = InputFieldAttribute(
    controller: TextEditingController(text: '0'),
    labelText: 'Fixed bonus',
    hintText: '0',
    helpText: 'Flat points added on top, regardless of transaction size.',
    isNumber: true,
    maxCharacter: 6,
  );
  final InputFieldAttribute _startDate = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Available from',
    isEditable: false,
    suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month)]),
  );
  final InputFieldAttribute _endDate = InputFieldAttribute(
    controller: TextEditingController(),
    labelText: 'Available until',
    isEditable: false,
    suffixWidget: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.calendar_month)]),
  );

  DateTime? _start;
  DateTime? _end;
  bool _isActive = true;
  bool _saving = false;
  String? _validationError;

  bool get _isEditing => widget.modifier != null;

  @override
  void initState() {
    super.initState();
    final modifier = widget.modifier;
    if (modifier == null) return;

    _name.controller.text = modifier.itemName;
    _multiplier.controller.text = modifier.multiplier.toString();
    _bonus.controller.text = modifier.fixedBonus.toString();
    _isActive = modifier.isActive;
    _start = modifier.startDate;
    _end = modifier.endDate;
    _syncDateText();
  }

  @override
  void dispose() {
    _name.controller.dispose();
    _multiplier.controller.dispose();
    _bonus.controller.dispose();
    _startDate.controller.dispose();
    _endDate.controller.dispose();
    super.dispose();
  }

  void _syncDateText() {
    _startDate.controller.text = _start == null ? '' : dateConverter('$_start', format: 'dd-MM-yyyy') ?? '';
    _endDate.controller.text = _end == null ? '' : dateConverter('$_end', format: 'dd-MM-yyyy') ?? '';
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _start : _end;
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
        // Starts at midnight, ends at the last minute of the day, so a window
        // written as "1 Aug to 31 Aug" genuinely covers all of 31 August.
        _start = DateTime(picked.year, picked.month, picked.day);
      } else {
        _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
      _syncDateText();
    });
  }

  String? _validate() {
    if (_name.controller.text.trim().isEmpty) return 'Give the modifier a name.';

    final multiplier = double.tryParse(_multiplier.controller.text.trim());
    if (multiplier == null || multiplier <= 0) return 'The multiplier must be a number greater than 0.';
    if (multiplier > 999.99) return 'The multiplier cannot exceed 999.99.';

    final bonus = int.tryParse(_bonus.controller.text.trim());
    if (bonus == null) return 'The fixed bonus must be a whole number.';

    if (multiplier == 1.0 && bonus == 0) {
      return 'This modifier would award nothing. Set a multiplier above 1, a fixed bonus, or both.';
    }

    if (_start != null && _end != null) {
      final startDay = DateTime(_start!.year, _start!.month, _start!.day);
      final endDay = DateTime(_end!.year, _end!.month, _end!.day);
      if (endDay.isBefore(startDay)) {
        return 'The "available until" date must come after the "available from" date.';
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

    final multiplier = double.parse(_multiplier.controller.text.trim());
    final bonus = int.parse(_bonus.controller.text.trim());
    final modifier = widget.modifier;

    final value = modifier == null
        ? await PointModifierController.create(
            context,
            itemName: _name.controller.text.trim(),
            multiplier: multiplier,
            fixedBonus: bonus,
            isActive: _isActive,
            startDate: _start,
            endDate: _end,
          )
        : await PointModifierController.update(
            context,
            id: modifier.id,
            itemName: _name.controller.text.trim(),
            multiplier: multiplier,
            fixedBonus: bonus,
            isActive: _isActive,
            startDate: _start,
            endDate: _end,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (responseCode(value.code)) {
      Navigator.of(context).pop(true);
    } else {
      showDialogError(context, value.message ?? 'Unable to save this modifier.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.min(560.0, MediaQuery.of(context).size.width * 0.94);
    final multiplier = double.tryParse(_multiplier.controller.text.trim()) ?? 1.0;
    final bonus = int.tryParse(_bonus.controller.text.trim()) ?? 0;
    final preview = ((100 * multiplier) - 100).floor() + bonus;

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
                    Text(_isEditing ? 'Edit Modifier' : 'New Modifier', style: AppTypography.displayMedium(context)),
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
                        InputField(field: _name..onChanged = (_) => setState(() {})),
                        AppPadding.vertical(denominator: 2),
                        InputField(field: _multiplier..onChanged = (_) => setState(() {})),
                        AppPadding.vertical(denominator: 2),
                        InputField(field: _bonus..onChanged = (_) => setState(() {})),
                        AppPadding.vertical(denominator: 1),
                        Text('Availability', style: AppTypography.bodyLarge(context)),
                        const SizedBox(height: 4),
                        Text(
                          'Leave both blank to keep this modifier available indefinitely.',
                          style: AppTypography.bodyMedium(
                            context,
                          ).apply(color: textMutedColor, fontSizeDelta: -2),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: true),
                                child: ReadOnly(InputField(field: _startDate), isEditable: false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickDate(isStart: false),
                                child: ReadOnly(InputField(field: _endDate), isEditable: false),
                              ),
                            ),
                          ],
                        ),
                        if (_start != null || _end != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              _start = null;
                              _end = null;
                              _syncDateText();
                            }),
                            icon: const Icon(Icons.clear_rounded, size: 16),
                            label: const Text('Clear dates'),
                          ),
                        ],
                        AppPadding.vertical(denominator: 2),
                        Row(
                          children: [
                            Switch(
                              value: _isActive,
                              activeThumbColor: secondaryColor,
                              onChanged: (value) => setState(() => _isActive = value),
                            ),
                            const SizedBox(width: 4),
                            Text('Available to branch staff', style: AppTypography.bodyMedium(context)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'A transaction worth 100 base points would earn '
                            '${preview >= 0 ? '+' : ''}$preview extra (${100 + preview} total).',
                            style: AppTypography.bodyMedium(context).apply(color: textMutedColor),
                          ),
                        ),
                        if (_validationError != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _validationError!,
                              style: AppTypography.bodyMedium(context).apply(color: const Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                      actionText: _saving ? 'Saving…' : (_isEditing ? 'Save Changes' : 'Create Modifier'),
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
}

/// One labelled fact in a modifier row — "Awards: +15 pts".
///
/// Labelled because the values alone are ambiguous: "+15 pts" and
/// "Until 31 Aug" read as unrelated fragments without saying what they describe.
class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Fact({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: textMutedColor),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: AppTypography.bodyMedium(context).apply(color: textMutedColor, fontSizeDelta: -2),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium(
            context,
          ).apply(color: textPrimaryColor, fontSizeDelta: -2, fontWeightDelta: 2),
        ),
      ],
    );
  }
}

/// Why a modifier is or is not currently offered to branch staff.
///
/// "Inactive" (switched off) and "Expired" (outside its window) are shown
/// separately — they look identical to staff but need different fixes.
class _StatusChip extends StatelessWidget {
  final PointModifier modifier;

  const _StatusChip({required this.modifier});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;

    if (!modifier.isActive) {
      label = 'Inactive';
      color = const Color(0xFF6B7280);
    } else if (modifier.hasExpired) {
      label = 'Expired';
      color = const Color(0xFFB45309);
    } else if (modifier.isScheduled) {
      label = 'Scheduled';
      color = const Color(0xFF2563EB);
    } else {
      label = 'Live';
      color = const Color(0xFF16A34A);
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

class _Empty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  const _Empty({required this.icon, required this.title, required this.message, this.action});

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
