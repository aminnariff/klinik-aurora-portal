import 'package:flutter/services.dart';

class FileAttribute {
  String? name;
  Uint8List? value;
  String? path;

  FileAttribute({this.name, this.value, this.path});
}
