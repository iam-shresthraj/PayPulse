import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart';

class FileSaverHelper {
  static bool _isSaving = false;
  static String? _lastSavedFile;
  static DateTime? _lastSaveTime;

  static bool _canSave(String fileName) {
    final now = DateTime.now();
    if (_isSaving) return false;
    if (_lastSavedFile == fileName && _lastSaveTime != null) {
      if (now.difference(_lastSaveTime!) < const Duration(milliseconds: 1500)) {
        return false; // Prevent duplicate rapid clicks
      }
    }
    return true;
  }

  static Future<void> _safeSave(List<int> bytes, String fileName, String mimeType) async {
    if (!_canSave(fileName)) return;
    _isSaving = true;
    _lastSavedFile = fileName;
    _lastSaveTime = DateTime.now();
    try {
      await saveFileImpl(bytes, fileName, mimeType);
    } finally {
      Future.delayed(const Duration(milliseconds: 800), () {
        _isSaving = false;
      });
    }
  }

  static Future<void> saveExcelFile(List<int> bytes, String fileName) async {
    await _safeSave(bytes, fileName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  }

  static Future<void> savePdfFile(List<int> bytes, String fileName) async {
    await _safeSave(bytes, fileName, 'application/pdf');
  }

  static Future<void> saveZipFile(List<int> bytes, String fileName) async {
    await _safeSave(bytes, fileName, 'application/zip');
  }

  static Future<void> saveCsvFile(List<int> bytes, String fileName) async {
    await _safeSave(bytes, fileName, 'text/csv');
  }
}
