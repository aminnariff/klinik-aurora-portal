import 'package:klinik_aurora_portal/config/flavor.dart';

String resolveImageUrl(String? path) {
  if (path == null) return '';
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return '${Environment.imageUrl}$trimmed';
}
