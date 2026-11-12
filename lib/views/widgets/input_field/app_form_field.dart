import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/currency_formatter.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/upper_case_alpha_formatter.dart';

/// Standardized Form Field across Klinik Aurora Portal.
///
/// Features:
/// - Top label with optional red asterisk (`*`) for required fields
/// - Universal 8px radius
/// - 42px standard single-line height
/// - Accessible contrast and focus outline (`#DF6E98`)
/// - Support for password visibility, currency, numbers, and custom validators
class AppFormField extends StatefulWidget {
  final String? label;
  final TextEditingController? controller;
  final String? hintText;
  final String? errorText;
  final String? tooltip;
  final bool isRequired;
  final bool isEditable;
  final bool isPassword;
  final bool isNumber;
  final bool isCurrency;
  final bool isUpperCase;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final double? width;

  const AppFormField({
    super.key,
    this.label,
    this.controller,
    this.hintText,
    this.errorText,
    this.tooltip,
    this.isRequired = false,
    this.isEditable = true,
    this.isPassword = false,
    this.isNumber = false,
    this.isCurrency = false,
    this.isUpperCase = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onFieldSubmitted,
    this.validator,
    this.width,
  });

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveKeyboardType = widget.keyboardType ??
        (widget.isNumber || widget.isCurrency
            ? TextInputType.number
            : TextInputType.text);

    final formatters = <TextInputFormatter>[
      if (widget.isCurrency) FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
      if (widget.isCurrency) CurrencyInputFormatter(),
      if (widget.isUpperCase) UpperCaseAlphaFormatter(),
      if (widget.isNumber && !widget.isCurrency) FilteringTextInputFormatter.digitsOnly,
      if (widget.maxLength != null) LengthLimitingTextInputFormatter(widget.maxLength),
      if (widget.inputFormatters != null) ...widget.inputFormatters!,
    ];

    Widget fieldWidget = TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      readOnly: !widget.isEditable,
      obscureText: _obscureText,
      keyboardType: effectiveKeyboardType,
      inputFormatters: formatters,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: widget.isEditable ? const Color(0xFF0F172A) : const Color(0xFF64748B),
      ),
      cursorColor: primary,
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Color(0xFF94A3B8),
        ),
        errorText: widget.errorText,
        errorStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFDC2626),
        ),
        filled: true,
        fillColor: widget.isEditable ? Colors.white : const Color(0xFFF1F5F9),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: widget.maxLines > 1 ? 12 : 10,
        ),
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: widget.prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        suffixIcon: widget.isPassword
            ? Tooltip(
                message: _obscureText ? 'Show password' : 'Hide password',
                child: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              )
            : widget.suffixIcon,
        suffixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
      ),
    );

    if (widget.label == null) {
      return SizedBox(width: widget.width, child: fieldWidget);
    }

    return SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              if (widget.isRequired)
                const Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: Text(
                    '*',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ),
              if (widget.tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: widget.tooltip!,
                  child: const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF94A3B8)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          fieldWidget,
        ],
      ),
    );
  }
}
