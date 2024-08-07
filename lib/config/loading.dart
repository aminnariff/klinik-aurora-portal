import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:klinik_aurora_portal/views/widgets/card/card_container.dart';
import 'package:lottie/lottie.dart';

class AppLoading {
  static init() {
    EasyLoading.instance
      // ..displayDuration = const Duration(milliseconds: 2000)
      ..indicatorType = EasyLoadingIndicatorType.threeBounce
      ..loadingStyle = EasyLoadingStyle.custom
      // ..indicatorSize = 200.0
      // ..radius = 10.0
      ..indicatorWidget = CardContainer(
        Lottie.asset(
          'assets/lottie/simple-loading.json',
          width: 140,
        ),
        margin: EdgeInsets.zero,
      )
      ..progressColor = Colors.white
      ..backgroundColor = Colors.transparent
      ..indicatorColor = Colors.white
      ..textColor = Colors.white
      ..maskType = EasyLoadingMaskType.clear
      ..maskColor = Colors.transparent
      ..userInteractions = false
      ..boxShadow = []
      ..dismissOnTap = false;
  }
}

showLoading() {
  EasyLoading.show(
      // status: 'Loading...',
      );
}

dismissLoading() {
  EasyLoading.dismiss();
}
