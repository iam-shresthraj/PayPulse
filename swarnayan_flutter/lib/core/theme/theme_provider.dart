import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier to manage dynamic light/dark mode overrides.
/// - `null`: defaults to system/layout default (light on wide screens, dark on mobile)
/// - `true`: force light mode
/// - `false`: force dark mode
class ThemeModeNotifier extends StateNotifier<bool?> {
  ThemeModeNotifier() : super(null);

  void toggleTheme(bool isCurrentlyLight) {
    state = !isCurrentlyLight;
  }

  void setTheme(bool isLight) {
    state = isLight;
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, bool?>((ref) {
  return ThemeModeNotifier();
});
