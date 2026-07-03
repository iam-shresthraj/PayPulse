class CookieHelperImpl {
  void setCookie(String key, String value, int days) {}
  String? getCookie(String key) => null;
  void deleteCookie(String key) {}
}

CookieHelperImpl getCookieHelper() => CookieHelperImpl();
