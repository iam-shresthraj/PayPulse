import 'title_helper_stub.dart'
    if (dart.library.html) 'title_helper_web.dart';

void updateBrowserTitle(String title) {
  setBrowserPageTitle(title);
}
