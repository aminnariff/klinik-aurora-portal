import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

abstract class AppPadding {
  const AppPadding({Key? key});

  static Widget horizontal({double denominator = 1}) {
    return SizedBox(
      width: screenPadding / denominator,
    );
  }

  static Widget vertical({double denominator = 1}) {
    return SizedBox(
      height: screenPaddingVertical() / denominator,
    );
  }
}
