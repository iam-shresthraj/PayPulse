import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'cookie_helper.dart';

class SecureStorage {
  SecureStorage._();
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  
  static const _keyToken = 'jwt_token';
  static const _keyUser = 'user_data';

  /// In-memory cache to eliminate IndexedDB async race conditions on web.
  /// When login saves a token, it is immediately available in memory
  /// for the Dio interceptor, even before IndexedDB write completes.
  static String? _cachedToken;
  static String? _cachedUserData;

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    if (kIsWeb) {
      CookieHelper.setCookie(_keyToken, token, 30);
    } else {
      await _storage.write(key: _keyToken, value: token);
    }
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    if (kIsWeb) {
      _cachedToken = CookieHelper.getCookie(_keyToken);
    } else {
      _cachedToken = await _storage.read(key: _keyToken);
    }
    return _cachedToken;
  }

  static Future<void> deleteToken() async {
    _cachedToken = null;
    if (kIsWeb) {
      CookieHelper.deleteCookie(_keyToken);
    } else {
      await _storage.delete(key: _keyToken);
    }
  }

  static Future<void> saveUserData(String userDataJson) async {
    _cachedUserData = userDataJson;
    if (kIsWeb) {
      CookieHelper.setCookie(_keyUser, userDataJson, 30);
    } else {
      await _storage.write(key: _keyUser, value: userDataJson);
    }
  }

  static Future<String?> getUserData() async {
    if (_cachedUserData != null) return _cachedUserData;
    if (kIsWeb) {
      _cachedUserData = CookieHelper.getCookie(_keyUser);
    } else {
      _cachedUserData = await _storage.read(key: _keyUser);
    }
    return _cachedUserData;
  }

  static Future<void> clearAll() async {
    _cachedToken = null;
    _cachedUserData = null;
    if (kIsWeb) {
      CookieHelper.deleteCookie(_keyToken);
      CookieHelper.deleteCookie(_keyUser);
    } else {
      await _storage.deleteAll();
    }
  }
}

