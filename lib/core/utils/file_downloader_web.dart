// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

void downloadPdfFile(Uint8List bytes, String filename) {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(const Duration(seconds: 15), () {
      html.Url.revokeObjectUrl(url);
    });
  } catch (e) {
    // Fallback if Blob fails
    final base64Data = Uri.encodeComponent(
      String.fromCharCodes(bytes),
    );
    final anchor = html.AnchorElement(
      href: 'data:application/pdf;base64,$base64Data',
    )..download = filename;
    anchor.click();
  }
}

void openPdfFile(Uint8List bytes, String filename) {
  try {
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(seconds: 30), () {
      html.Url.revokeObjectUrl(url);
    });
  } catch (_) {}
}
