import 'package:klinik_aurora_portal/views/widgets/size.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget tableAction({
  bool isEdit = true,
  Function()? editAction,
  bool isDelete = false,
  Function()? deleteAction,
  Widget? child,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2),
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
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.edit_outlined,
                    size: isMobile ? 18.w : 18,
                    color: Colors.grey.shade600,
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
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: isMobile ? 18.w : 18,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
