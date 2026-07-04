import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/cookie_helper.dart';

/// Notifier to manage dynamic light/dark mode overrides.
/// - `null`: defaults to system/layout default (light on wide screens, dark on mobile)
/// - `true`: force light mode
/// - `false`: force dark mode
class ThemeModeNotifier extends StateNotifier<bool?> {
  static const _themeKey = 'swarnayan_theme_mode';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ThemeModeNotifier() : super(_getInitialThemeSync()) {
    _loadThemeAsync();
  }

  static bool? _getInitialThemeSync() {
    if (kIsWeb) {
      final value = CookieHelper.getCookie(_themeKey);
      if (value == 'light') return true;
      if (value == 'dark') return false;
    }
    return null;
  }

  Future<void> _loadThemeAsync() async {
    if (kIsWeb) return;
    try {
      final value = await _storage.read(key: _themeKey);
      if (value == 'light') {
        state = true;
      } else if (value == 'dark') {
        state = false;
      }
    } catch (_) {}
  }

  void toggleTheme(bool isCurrentlyLight) {
    final nextState = !isCurrentlyLight;
    state = nextState;
    _saveTheme(nextState);
  }

  void setTheme(bool isLight) {
    state = isLight;
    _saveTheme(isLight);
  }

  Future<void> _saveTheme(bool isLight) async {
    final val = isLight ? 'light' : 'dark';
    if (kIsWeb) {
      CookieHelper.setCookie(_themeKey, val, 365);
    } else {
      await _storage.write(key: _themeKey, value: val);
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool?>((ref) {
  return ThemeModeNotifier();
});
