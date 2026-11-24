import 'dart:io';
import 'dart:typed_data';

void downloadPdfFile(Uint8List bytes, String filename) {
  try {
    String? path;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'] ?? '.';
      path = '$userProfile\\Downloads\\$filename';
    } else {
      final home = Platform.environment['HOME'] ?? '.';
      path = '$home/Downloads/$filename';
    }
    final file = File(path);
    file.writeAsBytesSync(bytes);
  } catch (_) {}
}

void openPdfFile(Uint8List bytes, String filename) {
  downloadPdfFile(bytes, filename);
}
