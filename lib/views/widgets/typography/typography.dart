import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:flutter/material.dart';

class AppTypography extends StatelessWidget {
  const AppTypography({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }

  static TextStyle error(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.apply(
          color: Colors.red,
          fontSizeDelta: textSize,
        );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.apply(fontSizeDelta: textSize);
  }

  static TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.apply(fontSizeDelta: textSize);
  }

  static TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge!.apply(fontSizeDelta: textSize);
  }

  static TextStyle displayMedium(BuildContext context) {
    return Theme.of(context).textTheme.displayMedium!.apply(fontSizeDelta: textSize);
  }
}
