import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

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
            Theme.of(context).textTheme.bodyMedium?.apply(color: textPrimaryColor),
        hintText: widget.attributeList.labelText == null ? widget.attributeList.hintText : null,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.apply(color: Colors.grey),
        filled: true,
        fillColor: widget.attributeList.fieldColor ??
            (isEditable ? textFormFieldEditableColor : textFormFieldUneditableColor),
        enabled: isEditable,
        errorText: widget.attributeList.errorMessage,
        errorStyle: const TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
        contentPadding: EdgeInsets.fromLTRB(
          screenPadding / 2,
          screenPadding / 3,
          screenPadding / 3,
          screenPadding / 3,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.attributeList.borderColor ??
                (isEditable ? const Color(0xFFE5E7EB) : Colors.transparent),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: widget.attributeList.borderColor ??
                (isEditable ? const Color(0xFFE5E7EB) : Colors.transparent),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: secondaryColor, width: 1.5),
          borderRadius: BorderRadius.circular(10.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
          borderRadius: BorderRadius.circular(10.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<DropdownAttribute?>(
          isExpanded: true,
          // Without this, dropdown_button2 wraps the CLOSED button's
          // displayed value in a SizedBox sized to menuItemStyleData.height
          // (meant for the OPEN menu's list items) — forcing the button
          // taller than a same-content InputField regardless of any padding
          // here. isDense lets the closed button size to its natural
          // content height instead, matching InputField.
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
                  style: Theme.of(context).textTheme.bodyMedium?.apply(
                        color: hasValue ? const Color(0xFF111827) : Colors.grey,
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
                    style: Theme.of(context).textTheme.bodyMedium?.apply(),
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
          // The InputDecorator above now draws the field's box/border/fill/padding;
          // this button itself stays a bare, borderless, paddingless child —
          // the same relationship EditableText has to TextFormField's own
          // InputDecorator.
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
                  ? const Color(0xFF6B7280)
                  : Colors.grey.shade400,
            ),
            iconSize: 22,
            iconEnabledColor: const Color(0xFF6B7280),
            iconDisabledColor: Colors.grey,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: 260,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
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
              color: secondaryColor.withAlpha(20),
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
              child: const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.attributeList.width != null) {
      content = SizedBox(
        width: widget.attributeList.width,
        child: content,
      );
    }

    return content;
  }
}
