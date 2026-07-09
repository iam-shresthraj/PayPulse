import 'dart:html' as html;

class WebNotificationHelperImpl {
  Future<bool> requestPermission() async {
    final status = await html.Notification.requestPermission();
    return status == 'granted';
  }

  bool isPermissionGranted() {
    return html.Notification.permission == 'granted';
  }

  void showNotification(String title, String body) {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    }
  }
}

WebNotificationHelperImpl getWebNotificationHelper() => WebNotificationHelperImpl();
