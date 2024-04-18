import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:klinik_aurora_portal/views/widgets/typography/typography.dart';

class MobileView extends StatelessWidget {
  const MobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/icons/failed/warning.svg',
          height: screenWidth(50),
          colorFilter: const ColorFilter.mode(Color(0XFFDF184A), BlendMode.srcIn),
        ),
        AppPadding.vertical(),
        Text(
          'Apologies, this Aurora Admin portal is only compatible with webview. Thank you for your understanding.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyLarge(context).apply(fontWeightDelta: -2),
        ),
      ],
    );
  }
}
