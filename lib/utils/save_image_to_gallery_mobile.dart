import 'dart:typed_data';
import 'dart:io';

import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> saveImageToGallery(Uint8List bytes, String name) async {
  if (Platform.isAndroid) {
    final storageStatus = await Permission.storage.request();
    if (storageStatus.isPermanentlyDenied) return false;
  }

  final result = await ImageGallerySaverPlus.saveImage(
    bytes,
    quality: 100,
    name: name,
  );
  if (result is Map) {
    return result['isSuccess'] == true || result['success'] == true;
  }
  return result == true;
}
