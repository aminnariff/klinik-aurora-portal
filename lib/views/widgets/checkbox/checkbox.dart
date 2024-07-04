import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/config/color.dart';

class CheckBoxWidget extends StatelessWidget {
  final bool? value;
  final bool isDisable;
  final void Function(bool?)? onChanged;
  const CheckBoxWidget(
    this.onChanged, {
    super.key,
    this.value,
    this.isDisable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1.5,
      child: Checkbox(
        value: value,
        fillColor: WidgetStateProperty.resolveWith(getColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Color getColor(Set<WidgetState> states) {
    const Set<WidgetState> interactiveStates = <WidgetState>{
      WidgetState.pressed,
      WidgetState.hovered,
      WidgetState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return isDisable ? Colors.grey : secondaryColor;
    }
    return isDisable
        ? Colors.grey
        : value == true
            ? primary
            : Colors.white;
  }
}
