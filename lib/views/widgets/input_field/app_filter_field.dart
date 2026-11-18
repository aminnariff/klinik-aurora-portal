import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';
import 'package:klinik_aurora_portal/views/widgets/shortcuts/portal_shortcuts.dart';

/// Standardized search/filter field across all portal table pages.
///
/// Features:
/// - Fixed 40px height
/// - Universal 8px radius
/// - Theme-aware light & dark surface fill + border
/// - Search icon prefix & clear icon suffix
/// - Auto-registers with [PortalSearchFocusBus] so pressing `/` focuses it
class AppFilterField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final double? width;
  final double height;
  final FocusNode? focusNode;
  final bool registerGlobalSearchShortcut;

  const AppFilterField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.width,
    this.height = 40.0,
    this.focusNode,
    this.registerGlobalSearchShortcut = true,
  });

  @override
  State<AppFilterField> createState() => _AppFilterFieldState();
}

class _AppFilterFieldState extends State<AppFilterField> {
  FocusNode? _ownedFocusNode;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.registerGlobalSearchShortcut) {
      PortalSearchFocusBus.register(_effectiveFocusNode);
    }
  }

  @override
  void didUpdateWidget(covariant AppFilterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode ||
        oldWidget.registerGlobalSearchShortcut != widget.registerGlobalSearchShortcut) {
      final oldNode = oldWidget.focusNode ?? _ownedFocusNode;
      if (oldNode != null) {
        PortalSearchFocusBus.unregister(oldNode);
      }
      if (widget.registerGlobalSearchShortcut) {
        PortalSearchFocusBus.register(_effectiveFocusNode);
      }
    }
  }

  @override
  void dispose() {
    final node = widget.focusNode ?? _ownedFocusNode;
    if (node != null && widget.registerGlobalSearchShortcut) {
      PortalSearchFocusBus.unregister(node);
    }
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            onChanged: widget.onChanged,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.inkPrimary,
            ),
            cursorColor: colors.brandText,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: colors.inkMuted,
              ),
              filled: true,
              fillColor: colors.inputFill,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              prefixIcon: Icon(Icons.search_rounded, size: 16, color: colors.inkMuted),
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              suffixIcon: hasText
                  ? Tooltip(
                      message: 'Clear search',
                      child: IconButton(
                        icon: Icon(Icons.clear_rounded, size: 16, color: colors.inkMuted),
                        onPressed: () {
                          widget.controller.clear();
                          if (widget.onChanged != null) widget.onChanged!('');
                          if (widget.onClear != null) widget.onClear!();
                        },
                      ),
                    )
                  : null,
              suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colors.brandText, width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}
