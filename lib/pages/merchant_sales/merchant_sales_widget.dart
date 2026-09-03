import 'package:flutter/material.dart';
import '/backend/services/api_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/transaction_receipt_service.dart';
import '/pages/transaction_details/transaction_details_page.dart';

class MerchantSalesWidget extends StatefulWidget {
  const MerchantSalesWidget({super.key});

  static String routeName = 'MerchantSales';
  static String routePath = '/merchantSales';

  @override
  State<MerchantSalesWidget> createState() => _MerchantSalesWidgetState();
}

class _MerchantSalesWidgetState extends State<MerchantSalesWidget> {
  bool loading = true;
  String error = '';
  List<Map<String, dynamic>> sales = [];
  final Set<String> _selectedSaleKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final response = await ApiService.getTransactions(
          type: 'merchant_payment', page: 1, limit: 100);
      final raw = response['data'];
      final items = raw is List
          ? raw.map<Map<String, dynamic>>((item) {
              if (item is Map) return Map<String, dynamic>.from(item);
              return <String, dynamic>{};
            }).toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        sales = items;
        _selectedSaleKeys.clear();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return dateTimeFormatEastAfricanTime('MMM d, yyyy • h:mm a', parsed);
  }

  String _saleKey(Map<String, dynamic> sale, int index) {
    return (sale['id'] ??
            sale['transaction_id'] ??
            sale['reference'] ??
            'sale-$index')
        .toString();
  }

  Future<void> _exportSelected({required bool share}) async {
    final selected = sales
        .asMap()
        .entries
        .where((entry) =>
            _selectedSaleKeys.contains(_saleKey(entry.value, entry.key)))
        .map((entry) => entry.value)
        .toList();
    if (selected.isEmpty) return;
    if (share) {
      await TransactionReceiptService.share(selected);
    } else {
      final path = await TransactionReceiptService.download(selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt downloaded: $path')),
      );
    }
  }

  Future<void> _exportAll({required bool share}) async {
    if (sales.isEmpty) return;
    if (share) {
      await TransactionReceiptService.share(sales);
    } else {
      final path = await TransactionReceiptService.download(sales);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Receipt downloaded: $path')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryText),
      ),
      backgroundColor: theme.primaryBackground,
      body: RefreshIndicator(
        onRefresh: _loadSales,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Merchant sales recorded by username',
                    style: theme.titleMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                if (sales.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _exportAll(share: false),
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('Download all'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _exportAll(share: true),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share all'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _selectedSaleKeys.isEmpty
                            ? null
                            : () => _exportSelected(share: false),
                        icon: const Icon(Icons.download_for_offline_outlined),
                        label: const Text('Download selected'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _selectedSaleKeys.isEmpty
                            ? null
                            : () => _exportSelected(share: true),
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('Share selected'),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selectedSaleKeys.length == sales.length) {
                            _selectedSaleKeys.clear();
                          } else {
                            _selectedSaleKeys
                              ..clear()
                              ..addAll(sales.asMap().entries.map(
                                  (entry) => _saleKey(entry.value, entry.key)));
                          }
                        }),
                        child: Text(_selectedSaleKeys.length == sales.length
                            ? 'Clear selection'
                            : 'Select all'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (error.isNotEmpty)
                  Text(error, style: const TextStyle(color: Colors.redAccent))
                else if (sales.isEmpty)
                  Text('No sales records available.', style: theme.bodyMedium)
                else
                  Column(
                    children: sales.map((tx) {
                      final amount = tx['amount']?.toString() ?? '0';
                      final isOutgoing = tx['is_outgoing'] == true;
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final bubbleColor = isDark
                          ? const Color(0xFF4A4A4A)
                          : isOutgoing
                              ? Colors.black
                              : Colors.white;
                      final textColor =
                          isDark || isOutgoing ? Colors.white : Colors.black;
                      final payerUsername = tx['sender_username']
                                  ?.toString()
                                  .trim()
                                  .isNotEmpty ==
                              true
                          ? '@${tx['sender_username']}'
                          : tx['customer_name']?.toString().trim().isNotEmpty ==
                                  true
                              ? tx['customer_name']
                              : tx['username']?.toString().trim().isNotEmpty ==
                                      true
                                  ? '@${tx['username']}'
                                  : 'Unknown';
                      final merchantName =
                          tx['merchant_business_name']?.toString().trim();
                      final title =
                          merchantName != null && merchantName.isNotEmpty
                              ? '$payerUsername • $merchantName'
                              : payerUsername;
                      final status = tx['status']?.toString() ?? 'Unknown';
                      final date = _formatDate(tx['created_at'] ??
                          tx['createdAt'] ??
                          tx['timestamp']);
                      return Align(
                        alignment: isOutgoing
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: MediaQuery.sizeOf(context).width * 0.82,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(16),
                            border: isDark || isOutgoing
                                ? null
                                : Border.all(color: Colors.black12),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailsPage(
                                  transaction: tx,
                                ),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _selectedSaleKeys.contains(
                                          _saleKey(tx, sales.indexOf(tx))),
                                      onChanged: (selected) => setState(() {
                                        final key =
                                            _saleKey(tx, sales.indexOf(tx));
                                        if (selected == true) {
                                          _selectedSaleKeys.add(key);
                                        } else {
                                          _selectedSaleKeys.remove(key);
                                        }
                                      }),
                                    ),
                                    const Text('Select sale'),
                                  ],
                                ),
                                Text(
                                  title,
                                  style: theme.titleSmall.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Amount: $amount FARM',
                                  style: theme.bodyMedium
                                      .copyWith(color: textColor),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Status: $status',
                                  style: theme.bodyMedium.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: theme.bodySmall.copyWith(
                                    color: isDark || isOutgoing
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
