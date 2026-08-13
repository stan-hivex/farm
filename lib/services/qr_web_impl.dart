// Web implementation for saving files via an anchor element.
// This file is imported only when `dart:html` is available.
import 'dart:typed_data';
import 'dart:html' as html;

Future<bool> saveFileWeb(Uint8List bytes, String filename) async {
  try {
    final content = bytes;
    final blob = html.Blob([content], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..download = filename
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {
    return false;
  }
}
