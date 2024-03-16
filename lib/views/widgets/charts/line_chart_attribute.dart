// ignore_for_file: public_member_api_docs, sort_constructors_first
class LineChartAttribute {
  String? label;
  bool darkMode;
  final List<List<LineChartItem>> items;
  final List<String> labels;
  final List<String> legends;
  int? maxY;

  LineChartAttribute({
    this.label,
    this.darkMode = false,
    required this.items,
    required this.labels,
    required this.legends,
    required this.maxY,
  });
}

class LineChartItem {
  DateTime? date;
  String? type;
  double? value;

  LineChartItem({
    required this.date,
    required this.type,
    required this.value,
  });
}
