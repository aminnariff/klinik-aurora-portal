import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:klinik_aurora_portal/views/widgets/size.dart';

Widget tableAction({
  bool isEdit = true,
  Function()? editAction,
  bool isDelete = false,
  Function()? deleteAction,
  Widget? child,
}) {
  return Builder(
    builder: (context) {
      final muted = Theme.of(context).colorScheme.onSurfaceVariant;
      final error = Theme.of(context).colorScheme.error;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            child ?? const SizedBox(),
            if (isEdit)
              Tooltip(
                message: 'Kemaskini',
                child: Semantics(
                  label: 'Kemaskini rekod',
                  button: true,
                  child: InkWell(
                    onTap: editAction,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      child: Center(
                        child: Icon(
                          Icons.edit_outlined,
                          size: isMobile ? 18.w : 18,
                          color: muted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (isDelete)
              Tooltip(
                message: 'Padam',
                child: Semantics(
                  label: 'Padam rekod',
                  button: true,
                  child: InkWell(
                    onTap: deleteAction,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                      child: Center(
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: isMobile ? 18.w : 18,
                          color: error,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
