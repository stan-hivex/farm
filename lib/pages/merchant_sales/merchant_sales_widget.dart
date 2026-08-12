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
                    children: sales.map((tx) {
                      final amountValue = tx['amount'] ?? tx['value'] ?? 0;
                      final amount = double.tryParse(amountValue.toString())?.toStringAsFixed(2) ?? amountValue.toString();
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

                      // Determine direction: outgoing = merchant paid someone, incoming = merchant received
                      final type = (tx['transaction_type'] ?? tx['type'] ?? '').toString().toLowerCase();
                      final isOutgoing = tx['is_outgoing'] == true || type.contains('send') || type.contains('sent') || type.contains('outgoing');

                      // Bubble layout
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      final screenWidth = MediaQuery.of(context).size.width;
                      final bubbleWidth = screenWidth * 0.78; // consistent width similar to chat apps

                      Color bubbleColor;
                      Color textColor;
                      if (!isDark) {
                        // Light mode
                        if (!isOutgoing) {
                          // incoming -> left: white bg, black text
                          bubbleColor = Colors.white;
                          textColor = Colors.black;
                        } else {
                          // outgoing -> right: black bg, white text
                          bubbleColor = Colors.black;
                          textColor = Colors.white;
                        }
                      } else {
                        // Dark mode
                        if (!isOutgoing) {
                          // incoming -> left: white bg, black text for visibility in dark mode
                          bubbleColor = Colors.white;
                          textColor = Colors.black;
                        } else {
                          // outgoing -> right: grey bg, white text
                          bubbleColor = Colors.grey.shade800;
                          textColor = Colors.white;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: isOutgoing ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Container(
                              width: bubbleWidth,
                              constraints: BoxConstraints(maxWidth: bubbleWidth),
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: theme.titleSmall.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                                  const SizedBox(height: 8),
                                  Text('Amount: $amount FARM', style: theme.bodyMedium.copyWith(color: textColor)),
                                  const SizedBox(height: 4),
                                  Text('Status: $status', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: textColor)),
                                  const SizedBox(height: 4),
                                  Text(date, style: theme.bodySmall.copyWith(color: textColor.withOpacity(0.9))),
                                ],
                              ),
                            ),
                          ],
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
