class WebNotificationHelperImpl {
  Future<bool> requestPermission() async => false;
  bool isPermissionGranted() => false;
  void showNotification(String title, String body) {}
}

WebNotificationHelperImpl getWebNotificationHelper() => WebNotificationHelperImpl();
