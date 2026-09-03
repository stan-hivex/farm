import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '/services/transaction_receipt_service.dart';
import '../services/admin_api_service.dart';

class TransactionsManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const TransactionsManagementPage({super.key, this.onGoBack});

  @override
  State<TransactionsManagementPage> createState() =>
      _TransactionsManagementPageState();
}

class _TransactionsManagementPageState
    extends State<TransactionsManagementPage> {
  List<dynamic> _txns = [];
  bool _loading = true;
  String _typeFilter = 'all';
  String _statusFilter = 'all';
  String _search = '';
  int _page = 1;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService.getTransactions(
        page: _page,
        type: _typeFilter == 'all' ? null : _typeFilter,
        status: _statusFilter == 'all' ? null : _statusFilter,
        search: _search.isEmpty ? null : _search,
      );
      setState(() {
        _txns = res['data'] ?? [];
        _total = res['meta']?['total'] ?? 0;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'completed':
        return context.successColor;
      case 'pending':
        return context.warningColor;
      case 'failed':
        return context.errorColor;
      case 'processing':
        return Colors.blue;
      default:
        return context.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Colors.white;
    final cardColor = Colors.white;
    final accent = const Color(0xFFEAF2FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _filters(accent),
            if (_loading && _txns.isEmpty)
              const Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF90CAF9))))
            else
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: _load,
                      color: accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _txns.length + 1,
                        itemBuilder: (_, i) {
                          if (i == _txns.length) {
                            final last = (_total / 20).ceil();
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                        onPressed: _page > 1
                                            ? () {
                                                setState(() => _page--);
                                                _load();
                                              }
                                            : null,
                                        child: Text('← Prev',
                                            style: GoogleFonts.plusJakartaSans(
                                                color: Colors.grey.shade600))),
                                    Text('$_page / $last',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            color: context.onSurface)),
                                    TextButton(
                                        onPressed: _page < last
                                            ? () {
                                                setState(() => _page++);
                                                _load();
                                              }
                                            : null,
                                        child: Text('Next →',
                                            style: GoogleFonts.plusJakartaSans(
                                                color: Colors.grey.shade600))),
                                  ]),
                            );
                          }
                          final t = _txns[i];
                          final color = _statusColor(t['status']);
                          final meta = t['metadata'] as Map? ?? {};
                          final method = (t['method'] ?? meta['payment_method'] ?? meta['method'] ?? '-').toString().toUpperCase();
                          final username = (t['username'] ?? '').toString();
                          final userId = (t['user_id'] ?? '').toString();
                          final reference = (t['transaction_reference'] ?? t['id'] ?? '-').toString();
                          final amountLabel = t['amount_display']?.toString() ??
                              '${double.tryParse(t['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} FARM';
                          final statusLabel = (t['status_display'] ?? t['status'] ?? '-').toString().toUpperCase();
                          final dateLabel = (t['date'] ?? '-').toString();
                          final timeLabel = (t['time'] ?? '-').toString();
                          return InkWell(
                            onTap: () => _showTransactionDetails(t),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: context.onSurface.withOpacity(0.1)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color:
                                        color.withAlpha((0.14 * 255).round()),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.swap_horiz_rounded,
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(
                                        'User: ${username.isNotEmpty ? '@$username' : 'Unknown'}',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: context.onSurface)),
                                    Text('User ID: ${userId.isNotEmpty ? userId : '-'}',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: context.onSurface
                                                .withOpacity(0.54),
                                            fontSize: 11)),
                                    Text('ID: $reference',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: context.onSurface
                                                .withOpacity(0.54),
                                            fontSize: 11)),
                                    Text('Method: $method',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: context.onSurface
                                                .withOpacity(0.54),
                                            fontSize: 11)),
                                    Text('Amount: $amountLabel',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: context.onSurface
                                                .withOpacity(0.54),
                                            fontSize: 11)),
                                    Text('Status: $statusLabel',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: context.onSurface
                                                .withOpacity(0.54),
                                            fontSize: 11)),
                                    Text('Date: $dateLabel',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: context.onSurface
                                                .withOpacity(0.54),
                                            fontSize: 11)),
                                    Text('Time: $timeLabel',
                                        style: GoogleFonts.plusJakartaSans(
                                            color: context.onSurface
                                                .withOpacity(0.54),
                                            fontSize: 11)),
                                  ])),
                              const SizedBox(width: 8),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        amountLabel,
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: context.onSurface)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: color
                                              .withAlpha((0.16 * 255).round()),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(
                                          statusLabel,
                                          style: GoogleFonts.plusJakartaSans(
                                              color: color,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ]),
                            ]),
                            ),
                          );
                        },
                      ))),
          ],
        ),
      ),
    );
  }

  Widget _filters(Color accent) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by username, user ID, or transaction ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _search = value.trim();
                _page = 1;
                _load();
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(children: [
              for (final f in [
                'all',
                'transfer',
                'deposit',
                'withdrawal',
                'escrow_lock',
                'escrow_release',
                'investment'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.replaceAll('_', ' ').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _typeFilter == f ? Colors.white : Colors.black)),
                    selected: _typeFilter == f,
                    selectedColor: _typeFilter == f ? Colors.black : Colors.white,
                    backgroundColor:
                        _typeFilter == f ? Colors.black : Colors.white,
                    side: BorderSide(
                        color: _typeFilter == f
                            ? Colors.black
                            : Colors.black54,
                        width: 1),
                    onSelected: (_) {
                      setState(() {
                        _typeFilter = f;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                ),
            ]),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(children: [
              for (final s in [
                'all',
                'completed',
                'pending',
                'failed',
                'processing'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _statusFilter == s ? Colors.white : Colors.black)),
                    selected: _statusFilter == s,
                    selectedColor:
                        _statusFilter == s ? Colors.black : Colors.white,
                    backgroundColor:
                        _statusFilter == s ? Colors.black : Colors.white,
                    side: BorderSide(
                        color: _statusFilter == s
                            ? Colors.black
                            : Colors.black54,
                        width: 1),
                    onSelected: (_) {
                      setState(() {
                        _statusFilter = s;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                ),
            ]),
          ),
        ],
      );

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    final reference = (transaction['transaction_reference'] ?? transaction['id'] ?? '-').toString();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            runSpacing: 10,
            children: [
              Text('Transaction details', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
              for (final entry in transaction.entries)
                if (entry.value != null && entry.value.toString().isNotEmpty)
                  ListTile(title: Text(entry.key), subtitle: Text(entry.value.toString())),
              Row(children: [
                OutlinedButton.icon(
                  onPressed: () => Clipboard.setData(ClipboardData(text: reference)),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy ID'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await TransactionReceiptService.share([transaction]);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await TransactionReceiptService.download([transaction]);
                    if (mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
