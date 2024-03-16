extension StringExtension on String {
  String capitalize() => length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
  String titleCase() {
    try {
      return replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.capitalize()).join(' ');
    } catch (e) {
      return 'N/A';
    }
  }
}
