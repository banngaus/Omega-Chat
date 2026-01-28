import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Ключи
  static const _keyToken = 'auth_token';
  static const _keyTheme = 'theme_mode';
  static const _keyNotifications = 'notifications_enabled';
  static const _keyUserId = 'user_id';

  // ============ ТОКЕН ============

  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _keyToken);
  }

  // Алиас для совместимости
  Future<void> deleteToken() async => clearToken();

  // ============ USER ID ============

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _keyUserId, value: userId.toString());
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: _keyUserId);
    return value != null ? int.tryParse(value) : null;
  }

  // ============ НАСТРОЙКИ ============

  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _keyTheme, value: mode);
  }

  Future<String> getThemeMode() async {
    return await _storage.read(key: _keyTheme) ?? 'dark';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _storage.write(key: _keyNotifications, value: enabled.toString());
  }

  Future<bool> getNotificationsEnabled() async {
    final value = await _storage.read(key: _keyNotifications);
    return value != 'false'; // По умолчанию включены
  }

  // ============ ОБЩИЕ ============

  /// Очистить все данные (при выходе)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Проверить авторизован ли пользователь
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}