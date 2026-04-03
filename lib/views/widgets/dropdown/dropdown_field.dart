import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

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

    // Match InputField border logic:
    // editable + open  → teal 1.5px
    // editable + closed → gray 1px
    // non-editable      → transparent (fill only)
    final Color borderColor = _isOpen
        ? secondaryColor
        : isEditable
        ? const Color(0xFFE5E7EB)
        : Colors.transparent;
    final double borderWidth = _isOpen ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.attributeList.labelText != null) ...[
          Text(
            widget.attributeList.labelText!,
            style: AppTypography.bodyMedium(
              context,
            ).apply(color: textPrimaryColor, fontWeightDelta: 1),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton2<DropdownAttribute?>(
                isExpanded: true,
                onMenuStateChange: (isOpen) =>
                    setState(() => _isOpen = isOpen),
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
                            ? widget.attributeList.titleCase == false
                                  ? widget.attributeList.value.toString()
                                  : widget.attributeList.value
                                        .toString()
                                        .titleCase()
                            : widget.attributeList.hintText ?? 'Select',
                        style: Theme.of(context).textTheme.bodyMedium?.apply(
                          color: hasValue
                              ? const Color(0xFF111827)
                              : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                items: widget.attributeList.items
                    .map(
                      (item) => DropdownMenuItem<DropdownAttribute>(
                        value: item,
                        child: Text(
                          widget.attributeList.titleCase == true
                              ? item.name.titleCase()
                              : item.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.apply(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isEditable
                    ? (selected) {
                        widget.attributeList.onChanged!(selected);
                      }
                    : null,
                buttonStyleData:
                    widget.attributeList.buttonStyleData ??
                    ButtonStyleData(
                      width: widget.attributeList.width ?? 70,
                      height: 48,
                      // Same padding as InputField contentPadding
                      padding: EdgeInsets.fromLTRB(
                        screenPadding / 2,
                        0,
                        screenPadding / 3,
                        0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: borderColor,
                          width: borderWidth,
                        ),
                        color:
                            widget.attributeList.fieldColor ??
                            (isEditable
                                ? textFormFieldEditableColor
                                : textFormFieldUneditableColor),
                      ),
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
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  selectedMenuItemBuilder: (context, child) => Container(
                    color: secondaryColor.withAlpha(20),
                    child: child,
                  ),
                ),
              ),
            ),
            if (widget.attributeList.tooltip != null)
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
        ),
        if (widget.attributeList.errorMessage != null) ...[
          Padding(
            padding: EdgeInsets.only(left: screenPadding / 2, top: 6),
            child: Text(
              widget.attributeList.errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
