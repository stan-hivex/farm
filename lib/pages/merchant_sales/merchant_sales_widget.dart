import 'package:flutter/material.dart';
import '/backend/services/api_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

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
      final response = await ApiService.getTransactions(type: 'merchant_payment', page: 1, limit: 100);
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

  DateTime _parseSaleDate(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(value.toString());
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final currentUsername = FFAppState().userName.trim().toLowerCase();
    final sortedSales = sales.toList();
    sortedSales.sort((a, b) => _parseSaleDate(b['created_at'] ?? b['createdAt'] ?? b['timestamp'])
        .compareTo(_parseSaleDate(a['created_at'] ?? a['createdAt'] ?? a['timestamp'])));

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
                Text('Merchant sales recorded by username', style: theme.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (loading)
                  const Center(child: CircularProgressIndicator())
                else if (error.isNotEmpty)
                  Text(error, style: const TextStyle(color: Colors.redAccent))
                else if (sales.isEmpty)
                  Text('No sales records available.', style: theme.bodyMedium)
                else
                  Column(
                    children: sortedSales.map((tx) {
                          final amount = tx['amount']?.toString() ?? '0';
                          final payerUsername = tx['sender_username']?.toString().trim().isNotEmpty == true
                              ? '@${tx['sender_username']}'
                              : tx['customer_name']?.toString().trim().isNotEmpty == true
                                  ? tx['customer_name']
                                  : tx['username']?.toString().trim().isNotEmpty == true
                                      ? '@${tx['username']}'
                                      : 'Unknown';
                          final merchantName = tx['merchant_business_name']?.toString().trim();
                          final title = merchantName != null && merchantName.isNotEmpty
                              ? '$payerUsername • $merchantName'
                              : payerUsername;
                          final status = tx['status']?.toString() ?? 'Unknown';
                          final date = _formatDate(tx['created_at'] ?? tx['createdAt'] ?? tx['timestamp']);
                          final senderUsername = tx['sender_username']?.toString().trim().toLowerCase();
                          final isMine = senderUsername != null && senderUsername.isNotEmpty && senderUsername == currentUsername;
                          final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                          final bubbleColor = isMine
                              ? Colors.white
                              : (isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFF262626));
                          final textColor = isMine
                              ? (isDarkMode ? Colors.black : theme.primaryText)
                              : Colors.white;
                          final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
                          final borderRadius = isMine
                              ? const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(0),
                                )
                              : const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(0),
                                  bottomRight: Radius.circular(16),
                                );

                          return Align(
                            alignment: alignment,
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.92,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: borderRadius,
                                border: Border.all(
                                  color: isMine ? Colors.grey.shade300 : Colors.transparent,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title,
                                        style: theme.titleSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        )),
                                    const SizedBox(height: 8),
                                    Text('Amount: $amount FARM', style: theme.bodyMedium.copyWith(color: textColor)),
                                    const SizedBox(height: 4),
                                    Text('Status: $status', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: textColor)),
                                    const SizedBox(height: 4),
                                    Text(date, style: theme.bodySmall.copyWith(color: textColor.withOpacity(0.8))),
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
