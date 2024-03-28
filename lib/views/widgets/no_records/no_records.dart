import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/selectable_text/app_selectable_text.dart';

class NoRecordsWidget extends StatelessWidget {
  const NoRecordsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.center,
      child: AppSelectableText('No Records'),
    );
  }
}
