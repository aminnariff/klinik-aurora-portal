import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

class Storage {
  static init() async {
    prefs = await SharedPreferences.getInstance();
  }

  static String? getString(String attribute) => prefs.getString(attribute);
  static int? getInt(String attribute) => prefs.getInt(attribute);
  static double? getDouble(String attribute) => prefs.getDouble(attribute);
  static bool? getBool(String attribute) => prefs.getBool(attribute);
  static List<String>? getStringList(String attribute) => prefs.getStringList(attribute);

  static setString(String attribute, String value) => prefs.setString(attribute, value);
  static setBool(String attribute, bool value) => prefs.setBool(attribute, value);
  static setInt(String attribute, int value) => prefs.setInt(attribute, value);
  static setDouble(String attribute, double value) => prefs.setDouble(attribute, value);
  static setStringList(String attribute, List<String> value) => prefs.setStringList(attribute, value);
  static remove(String attribute) => prefs.remove(attribute);

  static removeAll() => prefs.clear();
}
