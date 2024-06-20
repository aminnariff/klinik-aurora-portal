import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:klinik_aurora_portal/controllers/auth/auth_controller.dart';
import 'package:klinik_aurora_portal/views/login/login_page.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';
import 'package:provider/provider.dart';

class NoPermission extends StatelessWidget {
  const NoPermission({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                context.read<AuthController>().logout(context);
                context.pushReplacementNamed(LoginPage.routeName, extra: true);
              },
              icon: const Icon(
                Icons.logout,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenPadding * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/failed/warning.svg',
                height: screenHeightByBreakpoint(40, 40, 15),
                colorFilter: const ColorFilter.mode(Color(0XFFDF184A), BlendMode.srcIn),
              ),
              AppPadding.vertical(denominator: 1 / 3),
              Text(
                'It looks like you\'ve tried to access a page that you don\'t have permission to view. This may be because you manually entered the URL or attempted to navigate to a restricted area of the site.\n\nIf you believe this is an error or you need access to this page, please contact our support team for assistance',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge(context).apply(fontWeightDelta: -2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
