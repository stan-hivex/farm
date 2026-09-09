import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/services/transaction_receipt_service.dart';
import '/utils/transaction_reference_clipboard.dart';

class TransactionDetailsPage extends StatelessWidget {
  const TransactionDetailsPage({
    required this.transaction,
    super.key,
  });

  final Map<String, dynamic> transaction;

  String _value(List<String> keys, [String fallback = 'Not available']) {
    for (final key in keys) {
      final value = transaction[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  String _transactionType() {
    return _value(['transaction_type', 'transactionType', 'type'], '')
        .toLowerCase();
  }

  String _methodLabel() {
    dynamic findMethod(dynamic value) {
      if (value is Map) {
        for (final key in [
          'method',
          'payment_method',
          'withdrawal_method',
          'deposit_method',
          'paymentMethod',
          'payment_channel',
          'payment_provider',
          'provider',
        ]) {
          final candidate = value[key];
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            return candidate;
          }
        }
        for (final key in ['metadata', 'data', 'withdrawal', 'deposit']) {
          final nested = findMethod(value[key]);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    final rawMethod = findMethod(transaction);
    final method = rawMethod?.toString().trim().toLowerCase() ?? '';

    if (method.contains('crypto') || method.contains('ivory')) {
      return 'Crypto';
    }
    if (method.contains('mobile') || method.contains('mpesa')) {
      return 'Mobile Money';
    }
    if (method.contains('bank') && method.contains('transfer')) {
      return 'Bank Transfer';
    }
    if (method.contains('card') ||
        method.contains('vcard') ||
        method.contains('paystack')) {
      return 'Bank Card';
    }
    if (method.isEmpty) return 'Method unavailable';
    return method
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _fromLabel() {
    final existing = _value(
      [
        'sender_username',
        'customer_name',
        'sender',
        'buyer_username',
        'buyer_name'
      ],
      '',
    );
    if (existing.isNotEmpty) return existing;
    if (_transactionType().contains('escrow')) return 'Buyer';
    if (_transactionType().contains('deposit')) {
      return 'Deposit (${_methodLabel()})';
    }
    return 'Not available';
  }

  String _toLabel() {
    final existing = _value(
      ['recipient_username', 'recipient', 'seller_username', 'seller_name'],
      '',
    );
    if (existing.isNotEmpty) return existing;
    if (_transactionType().contains('escrow')) return 'Seller';
    if (_transactionType().contains('withdraw')) {
      return 'Withdrawal (${_methodLabel()})';
    }
    return 'Not available';
  }

  Future<void> _download(BuildContext context) async {
    final path = await TransactionReceiptService.download([transaction]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${'ui.receipt_downloaded'.tr()}: $path')),
    );
  }

  Future<void> _share(BuildContext context) async {
    await TransactionReceiptService.share([transaction]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final rows = <MapEntry<String, String>>[
      MapEntry('transactions.type'.tr(),
          _value(['transaction_type', 'type'], 'transactions.title'.tr())),
      MapEntry('transactions.amount'.tr(),
          '${_value(['amount', 'value'], '0')} FARM'),
      MapEntry('transactions.status'.tr(), _value(['status', 'state'])),
      MapEntry('transactions.date'.tr(),
          _value(['created_at', 'createdAt', 'timestamp'])),
      MapEntry(
          'ui.reference'.tr(), _value(['reference', 'transaction_id', 'id'])),
      MapEntry('ui.description'.tr(), _value(['description', 'narration'])),
      MapEntry('transactions.title'.tr(), _value(['title', 'name'])),
      MapEntry('ui.from'.tr(), _fromLabel()),
      MapEntry('ui.to'.tr(), _toLabel()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('ui.transaction_details'.tr()),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
      ),
      backgroundColor: theme.primaryBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: rows
                      .map(
                        (row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 105,
                                child: Text(
                                  row.key,
                                  style: theme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Expanded(child: Text(row.value)),
                              if (row.key == 'ui.reference'.tr() &&
                                  transactionReference(transaction).isNotEmpty)
                                IconButton(
                                  tooltip: 'Copy transaction reference',
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () => copyTransactionReference(
                                      context, transaction),
                                ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _download(context),
              icon: const Icon(Icons.download_rounded),
              label: Text('ui.download_receipt'.tr()),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_rounded),
              label: Text('ui.share_receipt'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
