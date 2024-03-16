import 'package:flutter/cupertino.dart';

class AppCupertinoSwitch extends StatelessWidget {
  final void Function(bool)? onChanged;
  final bool value;
  const AppCupertinoSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
    );
  }
}
