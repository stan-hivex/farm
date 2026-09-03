import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/services/transaction_receipt_service.dart';

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

  Future<void> _download(BuildContext context) async {
    final path = await TransactionReceiptService.download([transaction]);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Receipt downloaded: $path')),
    );
  }

  Future<void> _share(BuildContext context) async {
    await TransactionReceiptService.share([transaction]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final rows = <MapEntry<String, String>>[
      MapEntry('Type', _value(['transaction_type', 'type'], 'Transaction')),
      MapEntry('Amount', '${_value(['amount', 'value'], '0')} FARM'),
      MapEntry('Status', _value(['status', 'state'])),
      MapEntry('Date', _value(['created_at', 'createdAt', 'timestamp'])),
      MapEntry('Reference', _value(['reference', 'transaction_id', 'id'])),
      MapEntry('Description', _value(['description', 'narration'])),
      MapEntry('From', _value(['sender_username', 'customer_name', 'sender'])),
      MapEntry('To', _value(['recipient_username', 'recipient'])),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
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
              label: const Text('Download receipt'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share receipt'),
            ),
          ],
        ),
      ),
    );
  }
}
