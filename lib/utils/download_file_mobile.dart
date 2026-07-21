import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<String> saveFileFromBytes(Uint8List bytes, String fileName) async {
  Directory? directory;

  try {
    directory = await getDownloadsDirectory();
  } catch (_) {
    directory = null;
  }

  if (directory == null) {
    try {
      directory = await getApplicationDocumentsDirectory();
    } catch (_) {
      directory = null;
    }
  }

  directory ??= Directory.systemTemp;
  final filePath = '${directory.path}${Platform.pathSeparator}$fileName';
  final file = File(filePath);
  await file.writeAsBytes(bytes);
  return file.path;
}
