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
  ValueNotifier<DropdownAttribute?> selectedValue = ValueNotifier<DropdownAttribute?>(null);

  @override
  void initState() {
    if (widget.attributeList.value != null) {
      for (DropdownAttribute item in widget.attributeList.items) {
        if (item.key == widget.attributeList.value) {
          selectedValue.value = item;
        }
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.attributeList.labelText != null) ...[
          Text(
            widget.attributeList.labelText!,
            style: AppTypography.bodyMedium(context).apply(color: textPrimaryColor, fontWeightDelta: 1),
          ),
          const SizedBox(height: 2),
        ],
        Row(
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton2<DropdownAttribute?>(
                isExpanded: true,
                hint: Row(
                  children: [
                    if (widget.attributeList.items.isNotEmpty)
                      if (widget.attributeList.items.first.logo != null) ...[
                        const Icon(Icons.list, size: 16, color: Colors.yellow),
                        const SizedBox(width: 4),
                      ],
                    Expanded(
                      child: Text(
                        (widget.attributeList.value != '' && widget.attributeList.value != null)
                            ? widget.attributeList.titleCase == false
                                ? widget.attributeList.value.toString()
                                : widget.attributeList.value.toString().titleCase()
                            : widget.attributeList.hintText ?? 'Select',
                        style: Theme.of(context).textTheme.bodyMedium?.apply(
                          color:
                              (widget.attributeList.value != '' && widget.attributeList.value != null)
                                  ? Colors.black
                                  : Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                items:
                    widget.attributeList.items
                        .map(
                          (item) => DropdownMenuItem<DropdownAttribute>(
                            value: item,
                            child: Text(
                              widget.attributeList.titleCase == true ? item.name.titleCase() : item.name,
                              style: Theme.of(context).textTheme.bodyMedium?.apply(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (selected) {
                  selectedValue.value = selected;
                  widget.attributeList.onChanged!(selected);
                },
                buttonStyleData:
                    widget.attributeList.buttonStyleData ??
                    ButtonStyleData(
                      width: widget.attributeList.width ?? 70,
                      padding: EdgeInsets.fromLTRB(screenPadding / 2, 5, screenPadding / 3, 5),
                      // padding: const EdgeInsets.only(left: 14, right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        // border: Border.all(
                        //   color: widget.attributeList.borderColor ?? secondaryColor.withAlpha(opacityCalculation(.3)),
                        // ),
                        color: widget.attributeList.fieldColor ?? textFormFieldEditableColor,
                      ),
                      elevation: 0,
                    ),
                iconStyleData: const IconStyleData(
                  icon: Icon(Icons.arrow_drop_down),
                  iconSize: 33,
                  iconEnabledColor: secondaryColor,
                  iconDisabledColor: Colors.grey,
                ),
                dropdownStyleData: DropdownStyleData(
                  padding: null,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
                  elevation: 8,
                  offset: const Offset(0, 0),
                  scrollbarTheme: ScrollbarThemeData(
                    radius: const Radius.circular(30),
                    thickness: WidgetStateProperty.all<double>(6),
                    thumbVisibility: WidgetStateProperty.all<bool>(true),
                  ),
                ),
                menuItemStyleData: const MenuItemStyleData(height: 40, padding: EdgeInsets.only(left: 14, right: 14)),
              ),
            ),
            if (widget.attributeList.tooltip != null)
              Tooltip(message: widget.attributeList.tooltip, child: const Icon(Icons.info_outline)),
          ],
        ),
        if (widget.attributeList.errorMessage != null) ...[
          Padding(
            padding: EdgeInsets.only(left: screenPadding / 2, top: 8),
            child: Text(
              widget.attributeList.errorMessage!,
              style: AppTypography.bodyMedium(context).apply(color: errorColor),
            ),
          ),
        ],
      ],
    );
  }
}
