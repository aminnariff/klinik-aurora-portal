import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../widgets/aurora/aurora_empty_state.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.error});

  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: AuroraEmptyState(
            icon: Icons.search_off_rounded,
            illustration: SvgPicture.asset(
              'assets/icons/aurora-404.svg',
              width: 120,
              colorFilter: ColorFilter.mode(context.appColors.brandText, BlendMode.srcIn),
            ),
            height: 150,
            title: 'Page not found',
            message: 'This page may have moved or is temporarily unavailable.',
            actionLabel: 'Return to Home',
            onAction: () => context.go('/'),
          ),
        ),
      ),
    );
  }
}
