import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

class LayoutWidget extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;
  final Widget? ultra;

  const LayoutWidget({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
    this.ultra,
  });

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
