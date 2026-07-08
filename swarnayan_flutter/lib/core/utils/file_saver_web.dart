import 'dart:async';
import 'dart:html' as html;

Future<void> saveFileImpl(List<int> bytes, String fileName, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName);
  
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  // Delay revocation to give browser enough time to initiate the download task
  Timer(const Duration(milliseconds: 200), () {
    html.Url.revokeObjectUrl(url);
  });
}
