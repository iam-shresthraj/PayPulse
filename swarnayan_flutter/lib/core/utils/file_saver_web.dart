import 'dart:async';
import 'dart:html' as html;

Future<void> saveFileImpl(List<int> bytes, String fileName, String mimeType) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..setAttribute("download", fileName);
  
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  
  // Delay revocation to ensure the browser finishes initiating the download
  Timer(const Duration(seconds: 20), () {
    html.Url.revokeObjectUrl(url);
  });
}
