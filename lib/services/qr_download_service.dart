import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Conditional import for web download helper
import 'qr_web_stub.dart'
  if (dart.library.html) 'qr_web_impl.dart' as qr_web;

const _kQrDownloadChannel = 'farm.qr_download_service';

enum QrDownloadDestination {
  androidDownloads,
  androidPictures,
  iosPhotos,
  temp,
  unknown,
}

class QrDownloadResult {
  QrDownloadResult({
    required this.success,
    required this.message,
    this.fileUri,
    this.destination = QrDownloadDestination.unknown,
  });

  final bool success;
  final String message;
  final String? fileUri;
  final QrDownloadDestination destination;
}

class QrDownloadService {
  QrDownloadService._();

  static final QrDownloadService instance = QrDownloadService._();

  final MethodChannel _channel = const MethodChannel(_kQrDownloadChannel);

  Uint8List? _lastSavedBytes;
  String? _lastSavedFileName;
  bool get hasSavedQr => _lastSavedBytes != null;

  String _createFileName() {
    final now = DateTime.now().toUtc();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
    return 'farm_merchant_qr_$timestamp.png';
  }

  QrDownloadDestination _destinationFromString(String? value) {
    switch (value) {
      case 'downloads':
        return QrDownloadDestination.androidDownloads;
      case 'pictures':
        return QrDownloadDestination.androidPictures;
      case 'photos':
        return QrDownloadDestination.iosPhotos;
      case 'temp':
        return QrDownloadDestination.temp;
      default:
        return QrDownloadDestination.unknown;
    }
  }

  Future<QrDownloadResult> downloadQr(
    Uint8List bytes, {
    String? fileName,
  }) async {
    final name = fileName ?? _createFileName();
    if (kIsWeb) {
      final ok = await qr_web.saveFileWeb(bytes, name);
      return QrDownloadResult(
        success: ok,
        message: ok ? 'Download started' : 'Failed to start download',
        destination: ok ? QrDownloadDestination.temp : QrDownloadDestination.unknown,
      );
    }

    if (Platform.isAndroid || Platform.isIOS) {
      try {
        // Ensure permissions where necessary
        final permissionOk = await _ensureSavePermission();
        if (!permissionOk) {
          return QrDownloadResult(success: false, message: 'Permission denied. Please enable storage/photos permission in Settings.', destination: QrDownloadDestination.unknown);
        }

        // Save to temporary file first
        final tempFile = await _writeTemporaryFile(bytes, name);
        
        // On Android, delegate to native MediaStore saver via MethodChannel; on iOS, open with share dialog
        if (Platform.isAndroid) {
          try {
            final Map<dynamic, dynamic>? response = await _channel.invokeMethod('downloadQr', {
              'bytes': bytes,
              'fileName': name,
            });

            if (response == null) {
              // Fallback to temp
              _lastSavedBytes = bytes;
              _lastSavedFileName = name;
              return QrDownloadResult(
                success: true,
                message: 'QR code saved to temporary file.',
                fileUri: tempFile.path,
                destination: QrDownloadDestination.temp,
              );
            }

            final success = response['success'] == true;
            final message = response['message']?.toString() ?? '';
            final fileUri = response['fileUri']?.toString();
            final destStr = response['destination']?.toString();

            _lastSavedBytes = bytes;
            _lastSavedFileName = name;

            return QrDownloadResult(
              success: success,
              message: message,
              fileUri: fileUri,
              destination: _destinationFromString(destStr),
            );
          } catch (e) {
            // Channel failed — fallback to temporary file
            _lastSavedBytes = bytes;
            _lastSavedFileName = name;
            return QrDownloadResult(
              success: true,
              message: 'Saved to temporary file (native save failed): $e',
              fileUri: tempFile.path,
              destination: QrDownloadDestination.temp,
            );
          }
        } else if (Platform.isIOS) {
          // On iOS, write temp file and open share sheet so user can save to Photos
          _lastSavedBytes = bytes;
          _lastSavedFileName = name;
          try {
            final xfile = XFile(tempFile.path);
            await SharePlus.instance.share(
              ShareParams(text: 'Scan this Farm QR code.', files: [xfile]),
            );
          } catch (_) {}
          return QrDownloadResult(
            success: true,
            message: 'QR code saved to temporary file and share sheet opened.',
            fileUri: tempFile.path,
            destination: QrDownloadDestination.iosPhotos,
          );
        }
      } catch (e) {
        return QrDownloadResult(success: false, message: 'Failed to save QR code: $e', destination: QrDownloadDestination.unknown);
      }
    }

    return _saveToTemporaryDirectory(bytes, name);
  }

  Future<bool> _ensureSavePermission() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt ?? 0;

        PermissionStatus status;
        if (sdkInt >= 33) {
          status = await Permission.photos.request();
        } else {
          status = await Permission.storage.request();
        }

        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          // Ask user to enable via settings
          await openAppSettings();
          return false;
        }
        return false;
      } catch (_) {
        final status = await Permission.storage.request();
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }
        return false;
      }
    }

    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      return false;
    }

    return true;
  }

  Future<void> shareQr(
    Uint8List bytes, {
    String subject = 'Farm QR Code',
    String text = 'Scan this Farm QR code.',
  }) async {
    File file;
    try {
      file = await _writeTemporaryFile(bytes, _lastSavedFileName ?? _createFileName());
    } on MissingPluginException {
      // Fallback to system temp directory if path_provider is not registered
      final tmp = Directory.systemTemp;
      final path = '${tmp.path}${Platform.pathSeparator}${_lastSavedFileName ?? _createFileName()}';
      file = File(path);
      await file.writeAsBytes(bytes, flush: true);
    }

    final xfile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(text: text, subject: subject, files: [xfile]),
    );
  }

  Future<void> openSavedQr() async {
    if (_lastSavedBytes == null) {
      throw StateError('No QR code has been saved yet.');
    }
    final file = await _writeTemporaryFile(_lastSavedBytes!, _lastSavedFileName ?? _createFileName());
    final uri = Uri.file(file.path);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Unable to open saved QR code.');
    }
  }

  Future<void> deleteTemporaryFiles() async {
    final directory = await getTemporaryDirectory();
    final entries = directory.listSync();
    for (final entry in entries) {
      if (entry is File && entry.path.contains('farm_merchant_qr_')) {
        try {
          await entry.delete();
        } catch (_) {
          // Ignore deletion failures for temp cleanup.
        }
      }
    }
  }

  Future<File> _writeTemporaryFile(Uint8List bytes, String fileName) async {
    Directory directory;
    try {
      directory = await getTemporaryDirectory();
    } on MissingPluginException {
      directory = Directory.systemTemp;
    }
    final path = '${directory.path}${Platform.pathSeparator}$fileName';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<QrDownloadResult> _saveToTemporaryDirectory(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final file = await _writeTemporaryFile(bytes, fileName);
      _lastSavedBytes = bytes;
      _lastSavedFileName = fileName;
      return QrDownloadResult(
        success: true,
        message: 'Saved to temporary file: ${file.path}',
        fileUri: file.path,
        destination: QrDownloadDestination.temp,
      );
    } catch (error) {
      return QrDownloadResult(
        success: false,
        message: 'Failed to save QR code: $error',
        destination: QrDownloadDestination.unknown,
      );
    }
  }
}
