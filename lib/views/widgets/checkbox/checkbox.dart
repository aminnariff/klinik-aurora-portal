import 'package:klinik_aurora_portal/config/color.dart';
import 'package:flutter/material.dart';

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
        fillColor: MaterialStateProperty.resolveWith(getColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.pressed,
      MaterialState.hovered,
      MaterialState.focused,
    };
    if (states.any(interactiveStates.contains)) {
      return isDisable ? Colors.grey : secondaryColor;
    }
    return isDisable ? Colors.grey : primary;
  }
}
