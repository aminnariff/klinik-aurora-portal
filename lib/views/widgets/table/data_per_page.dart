// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_attribute.dart';
import 'package:klinik_aurora_portal/views/widgets/dropdown/dropdown_field.dart';

class PerPageWidget extends StatefulWidget {
  final String? perPage;
  final DropdownAttributeList dropdownAttributeList;

  const PerPageWidget(
    this.perPage,
    this.dropdownAttributeList, {
    super.key,
  });

  @override
  State<PerPageWidget> createState() => _PerPageWidgetState();

  static List<DropdownAttribute> perPageOptions() {
    return [
      DropdownAttribute('15', '15'),
      DropdownAttribute('30', '30'),
      DropdownAttribute('50', '50'),
    ];
  }
}

class _PerPageWidgetState extends State<PerPageWidget> {
  @override
  Widget build(BuildContext context) {
    return AppDropdown(
      attributeList: DropdownAttributeList(
        PerPageWidget.perPageOptions(),
        value: widget.perPage,
        width: 80,
        onChanged: widget.dropdownAttributeList.onChanged,
        fieldColor: Colors.transparent,
        borderColor: Colors.transparent,
      ),
    );
  }
}
