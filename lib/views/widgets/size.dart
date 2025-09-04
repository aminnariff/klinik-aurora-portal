import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:klinik_aurora_portal/views/widgets/layout/layout.dart';

double screenPadding = screenPaddingCalculate();
double textSize = textSizeCalculate();
bool isMobile = breakpoint() == Breakpoint.mobile;
bool isTablet = breakpoint() == Breakpoint.tablet;
bool isDekstop = breakpoint() == Breakpoint.desktop;

class SizeWidget extends StatelessWidget {
  const SizeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

double textSizeCalculate() {
  switch (breakpoint()) {
    case Breakpoint.mobile:
      return 0;
    case Breakpoint.tablet:
      return 0;
    case Breakpoint.desktop:
      return 0;
    case Breakpoint.ultra:
      return 0;
  }
}

double screenPaddingCalculate({double? value}) {
  double width = ScreenUtil().screenWidth;
  switch (breakpoint()) {
    case Breakpoint.mobile:
      return width * 0.05;
    case Breakpoint.tablet:
      return width * 0.03;
    case Breakpoint.desktop:
      return width * 0.02;
    case Breakpoint.ultra:
      return width * 0.01;
  }
}

double screenPaddingVertical({double? value}) {
  double width = ScreenUtil().screenWidth;
  switch (breakpoint()) {
    case Breakpoint.tablet:
      return width * 0.02;
    case Breakpoint.desktop:
      return width * 0.01;
    case Breakpoint.ultra:
      return width * 0.01;
    case Breakpoint.mobile:
      return width * 0.03;
  }
}

double screenWidthByBreakpoint(double mobile, double? tablet, double desktop, {bool useAbsoluteValueDesktop = false}) {
  double width = ScreenUtil().screenWidth;
  switch (breakpoint()) {
    case Breakpoint.mobile:
      return width * (mobile / 100);
    case Breakpoint.tablet:
      return width * ((tablet ?? desktop) / 100);
    case Breakpoint.desktop:
      return (useAbsoluteValueDesktop) ? desktop : width * (desktop / 100);
    case Breakpoint.ultra:
      return width * (desktop / 100);
  }
}

double screenHeightByBreakpoint(double mobile, double? tablet, double desktop, {bool useAbsoluteValueDesktop = false}) {
  double height = ScreenUtil().screenWidth;
  switch (breakpoint()) {
    case Breakpoint.mobile:
      return height * (mobile / 100);
    case Breakpoint.tablet:
      return height * ((tablet ?? desktop) / 100);
    case Breakpoint.desktop:
      return (useAbsoluteValueDesktop) ? desktop : height * (desktop / 100);
    case Breakpoint.ultra:
      return height * (desktop / 100);
  }
}

double screenWidth(double width) {
  return ScreenUtil().screenWidth * (width / 100);
}

double screenHeight(double height) {
  return ScreenUtil().screenHeight * (height / 100);
}

Breakpoint breakpoint() {
  double width = ScreenUtil().screenWidth;
  if (width > 0 && width <= 450) {
    return Breakpoint.mobile;
  } else if (width > 450 && width <= 820) {
    return Breakpoint.tablet;
  } else if (width > 820 && width <= 1920) {
    return Breakpoint.desktop;
  } else if (width > 1920 && width <= double.infinity) {
    return Breakpoint.ultra;
  } else {
    return Breakpoint.desktop;
  }
}

Widget breakpointWidget(LayoutWidget layout) {
  switch (breakpoint()) {
    case Breakpoint.mobile:
      return layout.mobile;
    case Breakpoint.tablet:
      return layout.tablet ?? layout.desktop;
    case Breakpoint.desktop:
      return layout.desktop;
    case Breakpoint.ultra:
      return layout.desktop;
  }
}

double screenWidth1728(double width) {
  return 1728 * (width / 100);
}

double screenHeight829(double height) {
  return 829 * (height / 100);
}

enum Breakpoint { mobile, tablet, desktop, ultra }
