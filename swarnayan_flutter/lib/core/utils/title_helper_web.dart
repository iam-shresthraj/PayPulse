import 'dart:html' as html;

void setBrowserPageTitle(String title) {
  try {
    html.document.title = title;
  } catch (_) {}
}
