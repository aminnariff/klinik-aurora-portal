import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../config/app_colors.dart';

class AppTableSkeleton extends StatelessWidget {
  const AppTableSkeleton({super.key, this.rows = 6, this.rowHeight = 48, this.padding = const EdgeInsets.all(16)});

  final int rows;
  final double rowHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget line(double width, double height) => FractionallySizedBox(
      widthFactor: width,
      alignment: Alignment.centerLeft,
      child: Container(
        height: height,
        decoration: BoxDecoration(color: colors.surfaceSubtle, borderRadius: BorderRadius.circular(8)),
      ),
    );

    Widget columns(int row) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          for (var i = 0; i < 5; i++)
            Expanded(flex: i == 0 ? 2 : 1, child: line(.42 + .12 * ((i + row) % 4), i == 3 && row != 0 ? 18 : 10)),
        ],
      ),
    );

    final content = Padding(
      padding: padding,
      child: Column(
        children: [
          SizedBox(height: 34, child: columns(0)),
          Expanded(
            child: ListView.separated(
              primary: false,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rows,
              separatorBuilder: (_, _) => Divider(height: 1, color: colors.border),
              itemBuilder: (_, index) => SizedBox(height: rowHeight, child: columns(index + 1)),
            ),
          ),
        ],
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) return content;
    return Shimmer.fromColors(
      baseColor: colors.surfaceSubtle,
      highlightColor: colors.surfaceElevated,
      period: const Duration(milliseconds: 1200),
      loop: 2,
      child: content,
    );
  }
}
