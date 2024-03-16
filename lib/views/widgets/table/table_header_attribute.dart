import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

class TableHeaderAttribute {
  String attribute;
  String label;
  String? tooltip;
  ColumnSize? columnSize;
  double? width;
  Widget? child;
  bool allowFiltering;
  bool allowSorting;
  bool isVisible;
  Color? colorHeader;
  bool isSort;
  SortType sort;
  bool numeric;

  TableHeaderAttribute({
    required this.attribute,
    required this.label,
    this.tooltip,
    this.child,
    this.columnSize,
    this.width,
    this.allowFiltering = true,
    this.allowSorting = true,
    this.isVisible = true,
    this.colorHeader,
    this.isSort = false,
    this.sort = SortType.asc,
    this.numeric = false,
  });
}

enum SortType {
  asc,
  desc,
}
