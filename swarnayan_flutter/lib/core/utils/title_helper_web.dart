import 'dart:async';
import 'dart:html' as html;

void setBrowserPageTitle(String title) {
  try {
    html.document.title = title;
    void syncIframeTitles() {
      try {
        for (final iframe in html.document.querySelectorAll('iframe')) {
          try {
            final el = iframe as html.IFrameElement;
            el.title = title;
            (el as dynamic).contentDocument?.title = title;
          } catch (_) {}
        }
      } catch (_) {}
    }

    syncIframeTitles();
    // Synchronize asynchronously in case Printing.layoutPdf injects iframes dynamically
    for (var i = 1; i <= 10; i++) {
      Timer(Duration(milliseconds: i * 500), syncIframeTitles);
    }
  } catch (_) {}
}
