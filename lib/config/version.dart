import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

ValueNotifier<AppVersionAttribute> appVersionAttribute = ValueNotifier<AppVersionAttribute>(AppVersionAttribute());

class AppVersion {
  static init() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    appVersionAttribute.value = AppVersionAttribute(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
    );
  }
}

class AppVersionAttribute {
  final String? appName;
  final String? packageName;
  final String? version;
  final String? buildNumber;

  AppVersionAttribute({
    this.appName,
    this.packageName,
    this.version,
    this.buildNumber,
  });
}
