import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '/utils/download_file.dart';
import '/utils/save_image_to_gallery.dart';

class TransactionReceiptService {
  static String _value(Map<String, dynamic> transaction, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = transaction[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  static String receiptText(List<Map<String, dynamic>> transactions) {
    final buffer = StringBuffer('FARM TRANSACTION RECEIPT\n');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Transactions: ${transactions.length}');
    buffer.writeln('----------------------------------------');

    for (var index = 0; index < transactions.length; index++) {
      final transaction = transactions[index];
      final amount = _value(transaction, ['amount', 'value'], '0');
      final type = _value(
        transaction,
        ['transaction_type', 'type'],
        'Transaction',
      );
      final status = _value(transaction, ['status', 'state'], 'Unknown');
      final reference = _value(
        transaction,
        ['reference', 'transaction_id', 'id'],
        'Not available',
      );
      final date = _value(
        transaction,
        ['created_at', 'createdAt', 'timestamp'],
        'Not available',
      );
      final description = _value(
        transaction,
        ['description', 'narration'],
        'Not available',
      );
      final sender = _value(
        transaction,
        ['sender_username', 'customer_name', 'sender'],
        'Not available',
      );
      final recipient = _value(
        transaction,
        ['recipient_username', 'recipient'],
        'Not available',
      );

      buffer
        ..writeln('Transaction ${index + 1}')
        ..writeln('Type: $type')
        ..writeln('Amount: $amount FARM')
        ..writeln('Status: $status')
        ..writeln('Date: $date')
        ..writeln('Reference: $reference')
        ..writeln('Description: $description')
        ..writeln('From: $sender')
        ..writeln('To: $recipient')
        ..writeln('----------------------------------------');
    }

    return buffer.toString();
  }

  static Future<String> download(
    List<Map<String, dynamic>> transactions,
  ) async {
    final text = receiptText(transactions);
    final bytes = Uint8List.fromList(utf8.encode(text));
    final suffix = transactions.length == 1 ? 'transaction' : 'transactions';
    final path = await saveFileFromBytes(
      bytes,
      'farm_${suffix}_receipt_${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    try {
      final imageBytes = await _receiptImageBytes(text);
      await saveImageToGallery(
        imageBytes,
        'farm_${suffix}_receipt_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (_) {
      // Keep the normal receipt download available if gallery access is unavailable.
    }
    return path;
  }

  static Future<Uint8List> _receiptImageBytes(String text) async {
    const width = 1200.0;
    const horizontalPadding = 64.0;
    const topPadding = 72.0;
    const lineHeight = 38.0;
    final lines = text.split('\n');
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final height = topPadding + lineHeight * lines.length + 72.0;
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, width, height),
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );

    for (var index = 0; index < lines.length; index++) {
      final painter = TextPainter(
        text: TextSpan(
          text: lines[index],
          style: TextStyle(
            color: const Color(0xFF111111),
            fontSize: index == 0 ? 30 : 22,
            fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '...',
      )..layout(maxWidth: width - horizontalPadding * 2);
      painter.paint(
        canvas,
        ui.Offset(horizontalPadding, topPadding + index * lineHeight),
      );
    }

    final image = await recorder.endRecording().toImage(
          width.toInt(),
          height.toInt(),
        );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('Unable to create receipt image');
    return data.buffer.asUint8List();
  }

  static Future<void> share(List<Map<String, dynamic>> transactions) async {
    final bytes = Uint8List.fromList(utf8.encode(receiptText(transactions)));
    final suffix = transactions.length == 1 ? 'transaction' : 'transactions';
    await SharePlus.instance.share(
      ShareParams(
        subject: 'FARM $suffix receipt',
        text: 'FARM $suffix receipt',
        files: [
          XFile.fromData(
            bytes,
            name: 'farm_${suffix}_receipt.txt',
            mimeType: 'text/plain',
          ),
        ],
      ),
    );
  }
}
