import 'package:flutter/cupertino.dart';

class AppCupertinoSwitch extends StatelessWidget {
  final void Function(bool)? onChanged;
  final bool value;
  const AppCupertinoSwitch({
    Key? key,
    required this.value,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
    );
  }
}
