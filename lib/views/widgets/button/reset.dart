// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/padding/app_padding.dart';

class ResetButton extends StatelessWidget {
  final Function()? onChanged;
  final bool showIcon;
  final EdgeInsets? margin;

  const ResetButton(
    this.onChanged, {
    super.key,
    this.showIcon = false,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: TextButton(
        onPressed: onChanged,
        child: Row(
          children: [
            if (showIcon) ...[
              const Icon(
                Icons.refresh,
                color: Colors.blue,
              ),
              AppPadding.horizontal(denominator: 2),
            ],
            Text(
              'Reset',
              style: Theme.of(context).textTheme.bodyMedium!.apply(color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
