import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

class FileSaverHelper {
  static Future<void> saveExcelFile(List<int> bytes, String fileName) async {
    await saveFileImpl(bytes, fileName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  static Future<void> savePdfFile(List<int> bytes, String fileName) async {
    await saveFileImpl(bytes, fileName, 'application/pdf');
  }
}
