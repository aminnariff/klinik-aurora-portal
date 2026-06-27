import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secureStorage = FlutterSecureStorage(
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  webOptions: WebOptions(dbName: 'klinik_aurora_portal', publicKey: 'klinik_aurora_portal_key'),
);

// In-memory cache — populated on init(), updated on every write.
// Reads are synchronous (from cache); writes persist to secure storage asynchronously.
Map<String, String> _cache = {};

late SecurePrefs prefs;

class Storage {
  static Future<void> init() async {
    prefs = await SecurePrefs._init();
  }
}

class SecurePrefs {
  SecurePrefs._();

  static Future<SecurePrefs> _init() async {
    _cache = Map.from(await _secureStorage.readAll());
    return SecurePrefs._();
  }

  // ── Synchronous reads (from cache) ──────────────────────────────────────

  String? getString(String key) => _cache[key];

  bool? getBool(String key) {
    final v = _cache[key];
    if (v == null) return null;
    return v == 'true';
  }

  int? getInt(String key) {
    final v = _cache[key];
    return v == null ? null : int.tryParse(v);
  }

  double? getDouble(String key) {
    final v = _cache[key];
    return v == null ? null : double.tryParse(v);
  }

  List<String>? getStringList(String key) {
    final v = _cache[key];
    if (v == null) return null;
    try {
      return List<String>.from(jsonDecode(v));
    } catch (_) {
      return null;
    }
  }

  // ── Async writes (cache first, then persist) ─────────────────────────────

  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    await _secureStorage.write(key: key, value: value);
  }

  Future<void> setBool(String key, bool value) async {
    _cache[key] = value.toString();
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<void> setInt(String key, int value) async {
    _cache[key] = value.toString();
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<void> setDouble(String key, double value) async {
    _cache[key] = value.toString();
    await _secureStorage.write(key: key, value: value.toString());
  }

  Future<void> setStringList(String key, List<String> value) async {
    final encoded = jsonEncode(value);
    _cache[key] = encoded;
    await _secureStorage.write(key: key, value: encoded);
  }

  Future<void> remove(String key) async {
    _cache.remove(key);
    await _secureStorage.delete(key: key);
  }

  Future<void> clear() async {
    _cache.clear();
    await _secureStorage.deleteAll();
  }
}
