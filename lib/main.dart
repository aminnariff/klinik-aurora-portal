// Coded by Amin (May 2023)
import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:klinik_aurora_portal/config/flavor.dart';
import 'package:klinik_aurora_portal/config/loading.dart';
import 'package:klinik_aurora_portal/config/routes.dart';
import 'package:klinik_aurora_portal/config/storage.dart';
import 'package:klinik_aurora_portal/config/theme.dart';
import 'package:klinik_aurora_portal/config/version.dart';
import 'package:klinik_aurora_portal/controllers/api_controller.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/controllers/dark_mode/dark_mode_controller.dart';
import 'package:klinik_aurora_portal/controllers/top_bar/top_bar_controller.dart';
import 'package:provider/provider.dart';

// Production
// flutter build web -t lib/main_production.dart

// Staging
// flutter build web -t lib/main_staging.dart

// Devlopment
// flutter build web -t lib/main.dart

Future<void> main() async {
  HttpOverrides.global = MyHttpOverrides();
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await EasyLocalization.ensureInitialized();
    environment = Flavor.development;
    AppVersion.init();
    AppLoading.init();
    Storage.init();
    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en', 'US'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en', 'US'),
        child: const MyApp(),
      ),
    );
  }, (exception, stackTrace) async {
    debugPrint(exception.toString());
    // await Sentry.captureException(exception, stackTrace: stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(1728, 829),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
              ChangeNotifierProvider<DarkModeController>(create: (_) => DarkModeController()),
              ChangeNotifierProvider<TopBarController>(create: (_) => TopBarController()),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              title: 'Klinik Aurora Admin',
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              builder: EasyLoading.init(builder: FToastBuilder()),
              debugShowCheckedModeBanner: false,
              theme: theme(context),
            ),
          );
        });
  }
}