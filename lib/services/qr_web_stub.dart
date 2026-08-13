// Stub for non-web platforms. saveFileWeb will return false indicating not supported.
import 'dart:typed_data';

Future<bool> saveFileWeb(Uint8List bytes, String filename) async {
  return false;
}
