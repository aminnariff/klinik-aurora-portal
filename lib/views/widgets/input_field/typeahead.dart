import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/extension/string.dart';
import 'package:klinik_aurora_portal/views/widgets/global/global.dart';
import 'package:klinik_aurora_portal/views/widgets/read_only/read_only.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

ValueNotifier<bool> hasValue = ValueNotifier(false);

class DropdownSearch extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final bool isEditable;
  final String? initialValue;
  final int maxCharacters;
  final double? width;
  final bool emptyDecoration;
  final String? emptyItemText;
  final bool isNumber;
  final List<TypeaheadAtribute>? items;
  final void Function(TypeaheadAtribute?) onSelected;
  final bool? isTitleCase;
  final TextEditingController? controller;
  final int? minCharForSuggestion;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final Color? fillColor;
  final bool? autofocus;
  final FocusNode? focusNode;
  final Function(String) onChanged;
  final void Function()? onClear;
  final FutureOr<List<TypeaheadAtribute>?> Function(String)? suggestionsCallback;
  final bool enabledClear;
  final TextAlign textAlign;
  final String? prefixText;
  final TextInputType? keyboardType;
  final Widget? suffixWidget;

  const DropdownSearch({
    super.key,
    this.width,
    this.hintText,
    this.maxCharacters = 30,
    this.items,
    required this.onSelected,
    required this.controller,
    required this.onChanged,
    this.suggestionsCallback,
    this.isEditable = true,
    this.isNumber = false,
    this.emptyDecoration = false,
    this.labelText = '',
    this.isTitleCase = true,
    this.minCharForSuggestion,
    this.prefixText,
    this.hintStyle,
    this.labelStyle,
    this.autofocus = true,
    this.fillColor,
    this.initialValue,
    this.focusNode,
    this.onClear,
    this.textAlign = TextAlign.start,
    this.enabledClear = false,
    this.emptyItemText,
    this.keyboardType,
    this.suffixWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (initialValue != null) {
      controller!.text = initialValue!;
    }
    return SizedBox(width: width, child: ReadOnly(field(context), isEditable: isEditable));
  }

  Widget field(context) {
    return Column(
      children: [
        TypeAheadField<TypeaheadAtribute?>(
          controller: controller,
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              autofocus: autofocus ?? true,
              focusNode: focusNode,
              enabled: isEditable,
              cursorColor: primary,
              maxLines: 2,
              minLines: 1,
              textAlign: textAlign,
              style: AppTypography.bodyMedium(context),
              keyboardType: keyboardType ?? TextInputType.text,
              decoration: InputDecoration(
                enabled: isEditable,
                labelText: labelText,
                labelStyle: labelStyle ?? Theme.of(context).textTheme.bodyMedium?.apply(color: primary),
                fillColor: fillColor ?? (isEditable ? textFormFieldEditableColor : textFormFieldUneditableColor),
                filled: true,
                prefixText: prefixText,
                suffix:
                    enabledClear
                        ? ValueListenableBuilder(
                          valueListenable: hasValue,
                          builder: (context, value, child) {
                            return value == true
                                ? Padding(
                                  padding: EdgeInsets.only(right: screenPadding / 2),
                                  child: InkWell(onTap: onClear, child: const Icon(Icons.close)),
                                )
                                : const SizedBox();
                          },
                        )
                        : suffixWidget,
                hintText: hintText,
                hintStyle:
                    hintStyle ?? Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.grey, fontWeightDelta: -2),
                contentPadding: EdgeInsets.fromLTRB(
                  screenPadding / 2,
                  screenPadding / 3,
                  screenPadding / 3,
                  screenPadding / 3,
                ),
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primary.withAlpha(opacityCalculation(.1)), width: 0.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: primary.withAlpha(opacityCalculation(.1)), width: 0.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: errorColor, width: 1.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                disabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              inputFormatters: [
                LengthLimitingTextInputFormatter(maxCharacters),
                // if (isNumber) FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: onChanged,
            );
          },
          suggestionsCallback:
              suggestionsCallback ??
              (pattern) async {
                List<TypeaheadAtribute> item = [];
                item = items!.where((element) => element.name.toLowerCase().contains(pattern.toLowerCase())).toList();
                List<TypeaheadAtribute> tempItems = [];
                for (var element in item) {
                  tempItems.add(TypeaheadAtribute(key: element.key, name: element.name));
                }
                return tempItems;
              },
          itemBuilder: (context, suggestion) {
            String address = suggestion!.name;
            return ListTile(
              title: Text(
                isTitleCase == true ? address.titleCase() : address,
                style: AppTypography.bodyMedium(context),
              ),
            );
          },
          decorationBuilder: (context, child) {
            return Material(
              type: MaterialType.card,
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: child,
            );
          },
          // suggestionsBoxDecoration: SuggestionsBoxDecoration(
          //   // color: AUTH_COLOR,
          //   constraints: BoxConstraints(maxHeight: screenHeight(30)),
          //   borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          // ),
          loadingBuilder: (context) => const Text('Loading...'),
          emptyBuilder:
              (context) => ListTile(
                title: Text(
                  emptyItemText ?? 'noItemsFound'.tr(),
                  style: AppTypography.bodyMedium(context).apply(color: Colors.grey),
                ),
              ),
          onSelected: onSelected,
          hideOnError: true,
          // minCharsForSuggestions: minCharForSuggestion ?? 0,
        ),
      ],
    );
  }
}

class TypeaheadAtribute {
  final String key;
  final String name;

  TypeaheadAtribute({required this.key, required this.name});
}
