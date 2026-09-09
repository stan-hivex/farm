import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String transactionReference(Map<String, dynamic> transaction) {
  for (final key in [
    'reference',
    'transaction_reference',
    'transaction_id',
    'id',
  ]) {
    final value = transaction[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}

Future<void> copyTransactionReference(
  BuildContext context,
  Map<String, dynamic> transaction,
) async {
  final reference = transactionReference(transaction);
  if (reference.isEmpty) return;
  await copyTextToClipboard(context, reference, 'Transaction reference copied');
}

Future<void> copyTextToClipboard(
  BuildContext context,
  String text,
  String message,
) async {
  if (text.trim().isEmpty) return;
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
