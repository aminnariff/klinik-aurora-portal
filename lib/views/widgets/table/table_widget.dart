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
    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        child ?? const SizedBox(),
        if (isEdit)
          SizedBox(
            width: isMobile ? 10.w : 33,
            child: TextButton(
              onPressed: editAction,
              child: Icon(
                Icons.edit,
                size: isMobile ? 16.w : 4.sp,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        if (isDelete)
          SizedBox(
            width: isMobile ? 10.w : 32,
            child: TextButton(
              onPressed: deleteAction,
              child: Icon(
                Icons.delete_outline_outlined,
                size: isMobile ? 16.w : 3.sp,
                color: Colors.grey.shade400,
              ),
            ),
          )
      ],
    ),
  );
}
