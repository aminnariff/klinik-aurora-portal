import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:klinik_aurora_portal/config/color.dart';
import 'package:klinik_aurora_portal/views/widgets/input_field/input_field_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class InputField extends StatelessWidget {
  final double? width;
  final InputFieldAttribute field;

  const InputField({
    super.key,
    required this.field,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<DateTime> rebuild = ValueNotifier(DateTime.now());
    return SizedBox(
      width: width,
      child: Column(
        children: [
          // if (field.labelText != null)
          //   Row(
          //     children: [
          //       AppSelectableText(
          //         field.labelText ?? '',
          //         style: Theme.of(context).textTheme.bodyLarge!.apply(),
          //       ),
          //       if (field.helpText != null) ...[
          //         AppPadding.horizontal(denominator: 4),
          //         GestureDetector(
          //           onTap: () {
          //             // ShowDialog().material(
          //             //   context: context,
          //             //   dialogText: field.helpText!,
          //             //   showButton: false,
          //             //   allowDismiss: true,
          //             //   type: 'info',
          //             //   textAlign: field.helpTextAlign,
          //             // );
          //           },
          //           child: const Icon(
          //             Icons.help_outline,
          //             color: tertiaryColor,
          //             size: 22,
          //           ),
          //         ),
          //       ],
          //     ],
          //   ),
          // AppPadding.vertical(denominator: 4),
          ValueListenableBuilder(
            valueListenable: rebuild,
            builder: (context, data, child) {
              return Row(
                children: [
                  Expanded(
                    child: textField(context, () {
                      rebuild.value = DateTime.now();
                    }),
                  ),
                  if (field.tooltip != null)
                    Tooltip(
                      message: field.tooltip,
                      child: IconButton(
                        icon: const Icon(Icons.info),
                        onPressed: () {},
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget textField(BuildContext context, Function rebuild) {
    Widget widget = TextFormField(
      readOnly: !field.isEditable,
      style: Theme.of(context).textTheme.bodyMedium!.apply(),
      cursorColor: primary,
      obscureText: field.obscureText,
      validator: field.validator,
      focusNode: field.focusNode,
      keyboardType: field.textInputType ??
          ((field.isNumber || field.isCurrency)
              ? TextInputType.number
              : (field.isEmail)
                  ? TextInputType.emailAddress
                  : TextInputType.text),
      decoration: InputDecoration(
        fillColor: field.isEditable ? field.isEditableColor : field.uneditableColor,
        filled: true,
        suffixIcon: field.isPassword
            ? InkWell(
                onTap: () {
                  field.obscureText = !field.obscureText;
                  rebuild();
                },
                child: Icon(
                  field.obscureText ? Icons.visibility_off : Icons.visibility,
                  color: field.obscureText ? const Color(0xFFa3b7c7) : const Color(0xff163567),
                  size: 22,
                ),
              )
            : field.isDatePicker
                ? Padding(
                    padding: EdgeInsets.only(right: screenPadding / 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: primary,
                          size: 24,
                        ),
                        const SizedBox(width: 2),
                        if (field.controller.text != '')
                          const Icon(
                            Icons.close,
                            color: Colors.transparent,
                            size: 22,
                          ),
                      ],
                    ),
                  )
                : field.suffixWidget,
        prefixIcon: (field.prefixText != null)
            ? Padding(
                padding:
                    EdgeInsets.fromLTRB(screenPadding / 2, (screenPadding / 3), screenPadding / 3, screenPadding / 3),
                child: Text(
                  field.prefixText!,
                  style: Theme.of(context).textTheme.bodyLarge!.apply(),
                ),
              )
            : field.prefixIcon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: screenPadding / 2),
                        child: field.prefixIcon!,
                      ),
                    ],
                  )
                : null,
        hintText: field.hintText,
        hintStyle: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.grey),
        labelText: field.labelText,
        labelStyle: Theme.of(context).textTheme.bodyMedium?.apply(color: textPrimaryColor),
        errorText: field.errorMessage,
        errorStyle: Theme.of(context).textTheme.titleMedium!.apply(color: Colors.red),
        contentPadding: EdgeInsets.fromLTRB(screenPadding / 2, screenPadding / 3, screenPadding / 3, screenPadding / 3),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onFieldSubmitted: field.onFieldSubmitted,
      controller: field.controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: (String value) {
        if (field.errorMessage != null) {
          field.errorMessage = null;
          rebuild();
        }
        if (field.onChanged != null) {
          field.onChanged!(value);
        }
      },
      onTap: () => _copyToClipboard,
      inputFormatters: [
        if (field.isCurrency) FilteringTextInputFormatter.allow(RegExp(r"[0-9.]")),
        // if (field.isCurrency) CurrencyTextInputFormatter(symbol: ''),
        if (field.isNumber) FilteringTextInputFormatter.digitsOnly,
        if (field.isAlphaNumericOnly) FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
        LengthLimitingTextInputFormatter(field.maxCharacter),
      ],
      minLines: field.lineNumber,
      maxLines: field.lineNumber,
    );
    return widget;
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: field.controller.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Text copied to clipboard')),
    );
  }
}

InputDecoration appInputDecoration(BuildContext context, String label) {
  return InputDecoration(
    filled: true,
    fillColor: textFormFieldEditableColor,
    contentPadding: EdgeInsets.fromLTRB(screenPadding / 2, screenPadding / 3, screenPadding / 3, screenPadding / 3),
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
      borderRadius: BorderRadius.circular(12.0),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
      borderRadius: BorderRadius.circular(12.0),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
      borderRadius: BorderRadius.circular(12.0),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.red, width: 1.0),
      borderRadius: BorderRadius.circular(12.0),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.transparent, width: 0.0),
      borderRadius: BorderRadius.circular(12.0),
    ),
    labelText: label,
    hintStyle: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.grey),
    labelStyle: Theme.of(context).textTheme.bodyMedium?.apply(color: textPrimaryColor),
  );
}
