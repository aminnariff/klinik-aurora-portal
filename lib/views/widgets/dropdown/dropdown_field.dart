import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';

class AppDropdown extends StatefulWidget {
  final DropdownAttributeList attributeList;

  const AppDropdown({super.key, required this.attributeList});

  @override
  State<AppDropdown> createState() => _AppDropdownState();
}

class _AppDropdownState extends State<AppDropdown> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final isEditable = widget.attributeList.isEditable;
    final hasValue =
        widget.attributeList.value != null && widget.attributeList.value != '';

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final hasLongItem = widget.attributeList.items.any((it) => it.name.length > 20);
    final autoMenuWidth = hasLongItem ? (isMobile ? 320.0 : 420.0) : null;
    final effectiveMenuWidth = widget.attributeList.menuWidth ?? autoMenuWidth;

    // Wrapped in InputDecorator (the same chrome TextFormField uses under the
    // hood) rather than a plain Text-above-a-box, so the label floats inside
    // the field the same way InputField's does — same size, same position,
    // same border & border radius — instead of sitting as a separate caption above it.
    Widget content = InputDecorator(
      isFocused: _isOpen,
      isEmpty: !hasValue,
      decoration: InputDecoration(
        labelText: widget.attributeList.labelText,
        floatingLabelBehavior:
            widget.attributeList.floatingLabelBehavior ?? FloatingLabelBehavior.always,
        labelStyle: widget.attributeList.labelStyle ??
            TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: appInkMuted),
        floatingLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: primary),
        hintText: widget.attributeList.labelText == null ? widget.attributeList.hintText : null,
        hintStyle: TextStyle(fontSize: 13, color: appInkMuted),
        filled: true,
        fillColor: widget.attributeList.fieldColor ??
            (isEditable ? appSurface : appSurfaceSubtle),
        enabled: isEditable,
        errorText: widget.attributeList.errorMessage,
        errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
        contentPadding: widget.attributeList.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        prefixIcon: widget.attributeList.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: widget.attributeList.prefixIcon,
              )
            : null,
        prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.attributeList.borderColor ?? appBorderStrong,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.attributeList.borderColor ?? appBorderStrong,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 1.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.0),
          borderRadius: BorderRadius.circular(8.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          borderRadius: BorderRadius.circular(8.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.attributeList.borderColor ?? appBorderStrong,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<DropdownAttribute?>(
          isExpanded: true,
          isDense: true,
          enableFeedback: true,
          onMenuStateChange: (isOpen) => setState(() => _isOpen = isOpen),
          hint: Row(
            children: [
              if (widget.attributeList.items.isNotEmpty &&
                  widget.attributeList.items.first.logo != null) ...[
                const Icon(Icons.list, size: 16, color: Colors.yellow),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  hasValue
                      ? (widget.attributeList.titleCase == false
                          ? widget.attributeList.value.toString()
                          : widget.attributeList.value.toString().titleCase())
                      : (widget.attributeList.hintText ?? 'Select'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: hasValue ? FontWeight.w500 : FontWeight.normal,
                    color: hasValue ? appInkPrimary : appInkMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          items: widget.attributeList.items
              .map(
                (item) => DropdownItem<DropdownAttribute>(
                  value: item,
                  child: Text(
                    widget.attributeList.titleCase == true
                        ? item.name.titleCase()
                        : item.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: appInkPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: isEditable
              ? (selected) {
                  widget.attributeList.onChanged?.call(selected);
                }
              : null,
          buttonStyleData: widget.attributeList.buttonStyleData ??
              const ButtonStyleData(
                padding: EdgeInsets.zero,
                decoration: BoxDecoration(color: Colors.transparent),
                elevation: 0,
              ),
          iconStyleData: IconStyleData(
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: isEditable
                  ? appInkMuted
                  : appInkMuted.withAlpha(100),
            ),
            iconSize: 20,
            iconEnabledColor: appInkMuted,
            iconDisabledColor: Colors.grey,
          ),
          dropdownStyleData: DropdownStyleData(
            width: effectiveMenuWidth,
            maxHeight: 280,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: appSurfaceElevated,
              border: Border.all(color: appBorderStrong),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            elevation: 0,
            offset: const Offset(0, 4),
            scrollbarTheme: ScrollbarThemeData(
              radius: const Radius.circular(8),
              thickness: WidgetStateProperty.all<double>(4),
              thumbVisibility: WidgetStateProperty.all<bool>(true),
            ),
          ),
          menuItemStyleData: MenuItemStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            selectedMenuItemBuilder: (context, child) => Container(
              color: primary.withAlpha(20),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (widget.attributeList.tooltip != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(child: content),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Tooltip(
              message: widget.attributeList.tooltip!,
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: appInkMuted,
              ),
            ),
          ),
        ],
      );
    }

    if (widget.attributeList.width != null) {
      return SizedBox(
        width: widget.attributeList.width,
        child: content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedWidth) {
          return SizedBox(
            width: constraints.maxWidth,
            child: content,
          );
        }
        return content;
      },
    );
  }
}
