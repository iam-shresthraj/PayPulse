import 'dart:io';

Future<void> saveFileImpl(List<int> bytes, String fileName, String mimeType) async {
  try {
    final file = File(fileName);
    await file.writeAsBytes(bytes);
    print('Saved file to ${file.absolute.path}');
  } catch (e) {
    print('Failed to save file natively: $e');
  }
}
