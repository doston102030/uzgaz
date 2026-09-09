import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive prefs (locale, theme, onboarding flag, cached lists).
class LocalStorage {
  LocalStorage(this._prefs);
  final SharedPreferences _prefs;

  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  String? getString(String key) => _prefs.getString(key);
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  bool getBool(String key, {bool defaultValue = false}) =>
      _prefs.getBool(key) ?? defaultValue;
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> remove(String key) => _prefs.remove(key);
}

/// Sensitive data only: tokens, never raw card numbers (per master prompt
/// security rules — card data must go through a tokenizing PSP, not be
/// stored locally at all).
class SecureStorage {
  SecureStorage(this._storage);
  final FlutterSecureStorage _storage;

  static SecureStorage create() =>
      SecureStorage(const FlutterSecureStorage());

  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> deleteAll() => _storage.deleteAll();
}
