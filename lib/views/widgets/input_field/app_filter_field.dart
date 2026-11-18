import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/app_colors.dart';

/// Standardized search/filter field across all portal table pages.
///
/// Features:
/// - Fixed 40px height
/// - Universal 8px radius
/// - Theme-aware light & dark surface fill + border
/// - Search icon prefix & clear icon suffix
class AppFilterField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String)? onChanged;
  final VoidCallback? onClear;
  final double? width;
  final double height;

  const AppFilterField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.width,
    this.height = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: width,
      height: height,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final hasText = value.text.isNotEmpty;
          return TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.inkPrimary,
            ),
            cursorColor: colors.brandText,
            decoration: InputDecoration(
              hintText: hintText,
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
                          controller.clear();
                          if (onChanged != null) onChanged!('');
                          if (onClear != null) onClear!();
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
