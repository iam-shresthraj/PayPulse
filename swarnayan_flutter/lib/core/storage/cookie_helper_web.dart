import 'dart:html' as html;

class CookieHelperImpl {
  void setCookie(String key, String value, int days) {
    // Expiration defined in seconds (max-age) for simplicity and reliability
    html.document.cookie = '$key=$value; max-age=${days * 24 * 60 * 60}; path=/;';
  }

  String? getCookie(String key) {
    final cookie = html.document.cookie;
    if (cookie == null || cookie.isEmpty) return null;
    final cookies = cookie.split(';');
    for (var c in cookies) {
      final parts = c.trim().split('=');
      if (parts.length >= 2 && parts[0] == key) {
        return parts.sublist(1).join('=');
      }
    }
    return null;
  }

  void deleteCookie(String key) {
    html.document.cookie = '$key=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;';
  }
}

CookieHelperImpl getCookieHelper() => CookieHelperImpl();
