import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/views/widgets/button/app_button.dart';
import 'package:klinik_aurora_portal/views/widgets/motion/emil_motion.dart';

/// Global bus allowing the `/` keyboard shortcut to focus the currently visible
/// page's primary search input without coupling pages to the shell.
class PortalSearchFocusBus {
  static final List<FocusNode> _stack = [];

  static void register(FocusNode node) {
    _stack.remove(node);
    _stack.add(node);
  }

  static void unregister(FocusNode node) {
    _stack.remove(node);
  }

  static bool focusActive() {
    while (_stack.isNotEmpty) {
      final node = _stack.last;
      if (node.context != null && node.canRequestFocus) {
        node.requestFocus();
        return true;
      }
      _stack.removeLast();
    }
    return false;
  }

  /// Returns true when the user is currently typing inside an editable text field.
  static bool isTypingInTextField() {
    final focus = FocusManager.instance.primaryFocus;
    if (focus == null || focus.context == null) return false;
    final widget = focus.context!.widget;
    if (widget is EditableText) return true;
    return focus.context!.findAncestorWidgetOfExactType<EditableText>() != null;
  }
}

/// Keyboard shortcuts cheat sheet triggered by pressing `?` or from `⌘K`.
class KeyboardShortcutsDialog extends StatelessWidget {
  const KeyboardShortcutsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const KeyboardShortcutsDialog(),
    );
  }

  static const _groups = <_ShortcutGroup>[
    _ShortcutGroup(
      title: 'Global Navigation',
      items: [
        _ShortcutRow(['⌘K', 'Ctrl+K'], 'Open Quick Search & Command Palette'),
        _ShortcutRow(['⌘[', 'Ctrl+['], 'Toggle Collapsible Sidebar'),
        _ShortcutRow(['?'], 'Open Keyboard Shortcuts Cheat Sheet'),
        _ShortcutRow(['/'], 'Focus active page search bar'),
        _ShortcutRow(['Esc'], 'Close active dialog, drawer, or search'),
      ],
    ),
    _ShortcutGroup(
      title: 'Clinic Actions',
      items: [
        _ShortcutRow(['N'], 'Book New Appointment from anywhere'),
        _ShortcutRow(['Q'], 'Jump to Front-Desk Queue ("Today\'s Flow")'),
        _ShortcutRow(['H'], 'Jump to Daily EOD Branch Handover'),
      ],
    ),
    _ShortcutGroup(
      title: 'Command Palette',
      items: [
        _ShortcutRow(['↑', '↓'], 'Move through matching commands'),
        _ShortcutRow(['↵'], 'Execute highlighted command'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: screenWidth < 520 ? 12 : 24, vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.border),
      ),
      child: EmilModalTransition(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.sizeOf(context).height * 0.84,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.brandSoftBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.brandBorder),
                      ),
                      child: Icon(Icons.keyboard_rounded, size: 19, color: colors.brandText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keyboard Shortcuts',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.inkPrimary),
                          ),
                          Text(
                            'Single-key accelerators pause automatically while typing.',
                            style: TextStyle(fontSize: 12, color: colors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close shortcuts',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close_rounded, size: 20, color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int g = 0; g < _groups.length; g++) ...[
                        if (g > 0) const SizedBox(height: 18),
                        Text(
                          _groups[g].title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: colors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < _groups[g].items.length; i++) ...[
                                if (i > 0) Divider(height: 1, color: colors.border),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _groups[g].items[i].description,
                                          style: TextStyle(fontSize: 13, color: colors.inkPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Wrap(
                                        spacing: 6,
                                        children: _groups[g]
                                            .items[i]
                                            .keys
                                            .map(
                                              (k) => Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: colors.surface,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: colors.borderStrong),
                                                ),
                                                child: Text(
                                                  k,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: colors.inkSecondary,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: colors.surfaceSubtle,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton.primary(
                      text: 'Got it',
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

class _ShortcutGroup {
  final String title;
  final List<_ShortcutRow> items;
  const _ShortcutGroup({required this.title, required this.items});
}

class _ShortcutRow {
  final List<String> keys;
  final String description;
  const _ShortcutRow(this.keys, this.description);
}
