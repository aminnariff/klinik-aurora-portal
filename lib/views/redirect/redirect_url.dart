import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klinik_aurora_portal/config/color.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Get Klinik Aurora',
      home: PlatformRedirectPage(),
    );
  }
}

class PlatformRedirectPage extends StatefulWidget {
  const PlatformRedirectPage({super.key});

  @override
  State<PlatformRedirectPage> createState() => _PlatformRedirectPageState();
}

class _PlatformRedirectPageState extends State<PlatformRedirectPage> {
  final String iosUrl = 'https://apps.apple.com/my/app/klinik-aurora/id6511211443';
  final String androidUrl = 'https://play.google.com/store/apps/details?id=my.com.klinikaurora';
  final String huaweiUrl = 'https://play.google.com/store/apps/details?id=my.com.klinikaurora';

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    redirectToPlatformUrl();
  }

  void redirectToPlatformUrl() async {
    String? url;

    final userAgent = html.window.navigator.userAgent.toLowerCase();

    if (userAgent.contains('iphone') || userAgent.contains('ipad') || userAgent.contains('ios')) {
      url = iosUrl;
    } else if (userAgent.contains('android')) {
      if (userAgent.contains('huawei')) {
        url = huaweiUrl;
      } else {
        url = androidUrl;
      }
    }

    if (url != null) {
      await Future.delayed(const Duration(seconds: 1));
      html.window.location.href = url;
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: quaternaryColor,
                    strokeWidth: 4,
                  ),
                  SizedBox(height: 16),
                  Text('Redirecting, please wait...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/failed/warning.svg',
                    height: 100,
                    colorFilter: const ColorFilter.mode(Color(0XFFDF184A), BlendMode.srcIn),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  const Text(
                    'Unsupported platform. Unable to redirect.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
