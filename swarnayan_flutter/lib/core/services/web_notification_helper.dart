import 'web_notification_helper_stub.dart'
    if (dart.library.html) 'web_notification_helper_web.dart';

class WebNotificationHelper {
  static Future<bool> requestPermission() {
    return getWebNotificationHelper().requestPermission();
  }

  static bool isPermissionGranted() {
    return getWebNotificationHelper().isPermissionGranted();
  }

  static void showNotification(String title, String body) {
    getWebNotificationHelper().showNotification(title, body);
  }
}
