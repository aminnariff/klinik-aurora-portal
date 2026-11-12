import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

/// Standardized search/filter field across all portal table pages.
///
/// Features:
/// - Fixed 40px height
/// - Universal 8px radius
/// - Subtle slate-50 fill with slate-200 outline
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF0F172A),
            ),
            cursorColor: primary,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: Color(0xFF94A3B8),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
              prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              suffixIcon: hasText
                  ? Tooltip(
                      message: 'Clear search',
                      child: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
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
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: primary, width: 1.5),
              ),
            ),
          );
        },
      ),
    );
  }
}
