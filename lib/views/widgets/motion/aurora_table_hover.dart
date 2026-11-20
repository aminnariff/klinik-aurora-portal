import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import 'emil_motion.dart';

DataRow2 withAuroraRowHover(BuildContext context, DataRow2 row) {
  if (MediaQuery.disableAnimationsOf(context)) return row;
  final hovered = ValueNotifier(false);
  return row.clone(
    onHover: (value) {
      hovered.value = value;
      row.onHover?.call(value);
    },
    cells: [
      for (final cell in row.cells)
        DataCell(
          ValueListenableBuilder<bool>(
            valueListenable: hovered,
            child: cell.child,
            builder: (_, lift, child) => TweenAnimationBuilder<double>(
              tween: Tween(end: lift ? -1 : 0),
              duration: const Duration(milliseconds: 150),
              curve: EmilMotion.easeOut,
              child: child,
              builder: (_, dy, child) => Transform.translate(
                offset: Offset(0, dy),
                transformHitTests: false,
                child: child,
              ),
            ),
          ),
          placeholder: cell.placeholder,
          showEditIcon: cell.showEditIcon,
          onTap: cell.onTap,
          onDoubleTap: cell.onDoubleTap,
          onLongPress: cell.onLongPress,
          onTapDown: cell.onTapDown,
          onTapCancel: cell.onTapCancel,
        ),
    ],
  );
}
