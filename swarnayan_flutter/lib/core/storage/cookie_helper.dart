import 'cookie_helper_stub.dart'
    if (dart.library.html) 'cookie_helper_web.dart';

class CookieHelper {
  static void setCookie(String key, String value, int days) {
    getCookieHelper().setCookie(key, value, days);
  }

  static String? getCookie(String key) {
    return getCookieHelper().getCookie(key);
  }

  static void deleteCookie(String key) {
    getCookieHelper().deleteCookie(key);
  }
}
