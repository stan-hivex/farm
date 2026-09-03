import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/backend/services/api_service.dart';
import '/core/responsive.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/utils/transaction_peer_resolver.dart';
import '/services/transaction_receipt_service.dart';
import '/pages/transaction_details/transaction_details_page.dart';
import 'all_transactions_model.dart';

export 'all_transactions_model.dart';

class AllTransactionsWidget extends StatefulWidget {
  const AllTransactionsWidget({super.key});

  static String routeName = 'AllTransactions';
  static String routePath = '/allTransactions';

  @override
  State<AllTransactionsWidget> createState() => _AllTransactionsWidgetState();
}

class _AllTransactionsWidgetState extends State<AllTransactionsWidget> {
  late AllTransactionsModel _model;

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _transactions = [];
  String _selectedType = 'all';
  String _selectedStatus = 'all';
  String _search = '';
  final Set<String> _selectedTransactionKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AllTransactionsModel());
    _loadTransactions();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final response = await ApiService.getTransactions(
        page: 1,
        limit: 50,
        type: _selectedType == 'all' ? null : _selectedType,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );

      final raw = response['data'];
      final items = raw is List
          ? raw.map<Map<String, dynamic>>((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            }).toList()
          : <Map<String, dynamic>>[];

      final filtered = items.where((tx) => _matchesFilters(tx)).toList();
      final searched = filtered.where(_matchesSearch).toList();
      if (!mounted) return;
      setState(() {
        _transactions = searched;
        _selectedTransactionKeys.clear();
        _loading = false;
      });
    } catch (e) {
      try {
        final fallback = await ApiService.getTransactions(page: 1, limit: 100);
        final rawAll = fallback['data'];
        final all = rawAll is List
            ? rawAll.map<Map<String, dynamic>>((item) {
                if (item is Map) return Map<String, dynamic>.from(item);
                return <String, dynamic>{};
              }).toList()
            : <Map<String, dynamic>>[];

        final filtered = all.where((tx) => _matchesFilters(tx) && _matchesSearch(tx)).toList();
        if (!mounted) return;
        setState(() {
          _transactions = filtered;
          _selectedTransactionKeys.clear();
          _loading = false;
        });
      } catch (inner) {
        if (!mounted) return;
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  bool _matchesSearch(Map<String, dynamic> tx) {
    if (_search.isEmpty) return true;
    final haystack = tx.values.map((value) => value.toString().toLowerCase()).join(' ');
    return haystack.contains(_search.toLowerCase());
  }

  bool _matchesFilters(Map<String, dynamic> tx) {
    if (_selectedType != 'all') {
      final type =
          (tx['transaction_type'] ?? tx['type'] ?? '').toString().toLowerCase();
      final isOutgoing = (tx['is_outgoing'] == true) ||
          type.contains('send') ||
          type.contains('sent') ||
          type.contains('outgoing');
      final isIncoming = !isOutgoing ||
          type.contains('receive') ||
          type.contains('received') ||
          type.contains('incoming');

      switch (_selectedType) {
        case 'send':
          if (!isOutgoing) return false;
          break;
        case 'receive':
          if (!isIncoming) return false;
          break;
        case 'deposit':
          if (!(type.contains('deposit') || type.contains('topup')))
            return false;
          break;
        case 'withdraw':
          if (!(type.contains('withdraw') || type.contains('withdrawal')))
            return false;
          break;
        default:
          break;
      }
    }

    if (_selectedStatus != 'all') {
      final status =
          (tx['status'] ?? tx['state'] ?? '').toString().toLowerCase();
      switch (_selectedStatus) {
        case 'completed':
          if (!(status.contains('complete') ||
              status.contains('success') ||
              status.contains('approved'))) return false;
          break;
        case 'pending':
          if (!(status.contains('pending') || status.contains('processing')))
            return false;
          break;
        case 'failed':
          if (!(status.contains('fail') ||
              status.contains('rejected') ||
              status.contains('error'))) return false;
          break;
        default:
          break;
      }
    }

    return true;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return dateTimeFormatEastAfricanTime('MMM d, yyyy • h:mm a', parsed);
  }

  String _resolveTransactionPeer(Map<String, dynamic> tx,
      {required bool isOutgoing}) {
    return resolveTransactionPeer(tx, outgoing: isOutgoing);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'approved':
        return Colors.green;
      case 'pending':
      case 'processing':
        return Colors.orange;
      case 'failed':
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String _transactionKey(Map<String, dynamic> transaction, int index) {
    return (transaction['id'] ??
            transaction['transaction_id'] ??
            transaction['reference'] ??
            'transaction-$index')
        .toString();
  }

  Future<void> _exportSelected({required bool share}) async {
    final selected = _transactions
        .asMap()
        .entries
        .where((entry) => _selectedTransactionKeys
            .contains(_transactionKey(entry.value, entry.key)))
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
    if (_transactions.isEmpty) return;
    if (share) {
      await TransactionReceiptService.share(_transactions);
    } else {
      final path = await TransactionReceiptService.download(_transactions);
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
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: context.responsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your transaction history',
                  style:
                      theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search transactions',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() => _search = value.trim());
                    _loadTransactions();
                  },
                ),
                if (_transactions.isNotEmpty) ...[
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
                        onPressed: _selectedTransactionKeys.isEmpty
                            ? null
                            : () => _exportSelected(share: false),
                        icon: const Icon(Icons.download_for_offline_outlined),
                        label: const Text('Download selected'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _selectedTransactionKeys.isEmpty
                            ? null
                            : () => _exportSelected(share: true),
                        icon: const Icon(Icons.ios_share_outlined),
                        label: const Text('Share selected'),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selectedTransactionKeys.length ==
                              _transactions.length) {
                            _selectedTransactionKeys.clear();
                          } else {
                            _selectedTransactionKeys
                              ..clear()
                              ..addAll(_transactions.asMap().entries.map(
                                  (entry) =>
                                      _transactionKey(entry.value, entry.key)));
                          }
                        }),
                        child: Text(_selectedTransactionKeys.length ==
                                _transactions.length
                            ? 'Clear selection'
                            : 'Select all'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip('All', 'all'),
                    _filterChip('Sent', 'send'),
                    _filterChip('Received', 'receive'),
                    _filterChip('Deposit', 'deposit'),
                    _filterChip('Withdraw', 'withdraw'),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusChip('All', 'all'),
                    _statusChip('Pending', 'pending'),
                    _statusChip('Completed', 'completed'),
                    _statusChip('Failed', 'failed'),
                  ],
                ),
                const SizedBox(height: 16),
                if (_loading && _transactions.isEmpty)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator()))
                else if (_error.isNotEmpty && _transactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error,
                          style: const TextStyle(color: Colors.redAccent)),
                    ),
                  )
                else if (_transactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No transactions match your filters yet.',
                          style: theme.bodyMedium),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      final type = (tx['transaction_type'] ??
                              tx['type'] ??
                              'Transaction')
                          .toString();
                      final amount = tx['amount'] ?? tx['value'] ?? 0;
                      final isOutgoing = tx['is_outgoing'] == true ||
                          type.toLowerCase().contains('send');
                      final status = (tx['status'] ?? 'Completed').toString();
                      final merchantName =
                          tx['merchant_business_name']?.toString().trim() ?? '';
                      final peer =
                          _resolveTransactionPeer(tx, isOutgoing: isOutgoing);
                      final payerUsername = !isOutgoing
                          ? (tx['sender_username']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? '@${tx['sender_username']}'
                              : peer)
                          : (tx['recipient_username']
                                      ?.toString()
                                      .trim()
                                      .isNotEmpty ==
                                  true
                              ? '@${tx['recipient_username']}'
                              : peer);
                      final peerWithMerchant = merchantName.isNotEmpty
                          ? '$payerUsername ($merchantName)'
                          : payerUsername;
                      final isMerchantPayment =
                          type.toLowerCase() == 'merchant_payment';
                      final amountText =
                          '${isOutgoing ? '-' : '+'}${double.tryParse(amount.toString())?.toStringAsFixed(2) ?? amount} FARM';
                      final dateText = _formatDate(tx['created_at'] ??
                          tx['createdAt'] ??
                          tx['timestamp']);
                      final peerLabel = isMerchantPayment
                          ? '${isOutgoing ? 'To' : 'From'} $peerWithMerchant'
                          : '${isOutgoing ? 'To' : 'From'} $peer';

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TransactionDetailsPage(
                                transaction: tx,
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _selectedTransactionKeys
                                      .contains(_transactionKey(tx, index)),
                                  onChanged: (selected) => setState(() {
                                    final key = _transactionKey(tx, index);
                                    if (selected == true) {
                                      _selectedTransactionKeys.add(key);
                                    } else {
                                      _selectedTransactionKeys.remove(key);
                                    }
                                  }),
                                ),
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: theme.secondaryBackground,
                                  child: Icon(
                                    isOutgoing
                                        ? Icons.north_east_rounded
                                        : Icons.south_west_rounded,
                                    color: theme.primaryText,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              type,
                                              style: theme.titleSmall.copyWith(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusColor(status)
                                                  .withAlpha(
                                                      (0.12 * 255).round()),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _statusColor(status),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        tx['description']?.toString() ??
                                            tx['reference']?.toString() ??
                                            'Transaction updated',
                                        style: theme.bodyMedium,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '$peerLabel • $dateText',
                                        style: theme.bodySmall.copyWith(
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Transaction ID: ${tx['transaction_reference'] ?? tx['transaction_id'] ?? tx['id'] ?? '-'}',
                                              style: theme.bodySmall,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Copy transaction ID',
                                            icon: const Icon(Icons.copy, size: 17),
                                            onPressed: () => Clipboard.setData(ClipboardData(text: (tx['transaction_reference'] ?? tx['transaction_id'] ?? tx['id'] ?? '').toString())),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _formatDate(tx['created_at'] ??
                                                  tx['createdAt'] ??
                                                  tx['timestamp']),
                                              style: theme.bodySmall,
                                            ),
                                          ),
                                          Text(
                                            amountText,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: isOutgoing
                                                  ? Colors.redAccent
                                                  : Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).textTheme.bodyMedium?.color,
      ),
      shape: const StadiumBorder(),
      onSelected: (_) {
        setState(() => _selectedType = value);
        _loadTransactions();
      },
    );
  }

  Widget _statusChip(String label, String value) {
    final selected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).colorScheme.surface,
      labelStyle: TextStyle(
        color: selected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).textTheme.bodyMedium?.color,
      ),
      shape: const StadiumBorder(),
      onSelected: (_) {
        setState(() => _selectedStatus = value);
        _loadTransactions();
      },
    );
  }
}
