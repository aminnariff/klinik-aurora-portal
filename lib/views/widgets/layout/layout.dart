import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:flutter/material.dart';

class LayoutWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? ultra;

  const LayoutWidget({
    Key? key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.ultra,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return breakpointWidget(
      LayoutWidget(
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      ),
    );
  }
}
