import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveFileImpl(List<int> bytes, String fileName, String mimeType) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    print('Saved file to ${file.absolute.path}');
    
    // Share file so user can save/send it
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: fileName,
    );
  } catch (e) {
    print('Failed to save or share file natively: $e');
  }
}
