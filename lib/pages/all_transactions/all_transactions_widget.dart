
import 'package:flutter/material.dart';

import '/backend/services/api_service.dart';
import '/core/responsive.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
      if (!mounted) return;
      setState(() {
        _transactions = filtered;
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

        final filtered = all.where((tx) => _matchesFilters(tx)).toList();
        if (!mounted) return;
        setState(() {
          _transactions = filtered;
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

  bool _matchesFilters(Map<String, dynamic> tx) {
    if (_selectedType != 'all') {
      final type = (tx['transaction_type'] ?? tx['type'] ?? '').toString().toLowerCase();
      final isOutgoing = (tx['is_outgoing'] == true) || type.contains('send') || type.contains('sent') || type.contains('outgoing');
      final isIncoming = !isOutgoing || type.contains('receive') || type.contains('received') || type.contains('incoming');

      switch (_selectedType) {
        case 'send':
          if (!isOutgoing) return false;
          break;
        case 'receive':
          if (!isIncoming) return false;
          break;
        case 'deposit':
          if (!(type.contains('deposit') || type.contains('topup'))) return false;
          break;
        case 'withdraw':
          if (!(type.contains('withdraw') || type.contains('withdrawal'))) return false;
          break;
        default:
          break;
      }
    }

    if (_selectedStatus != 'all') {
      final status = (tx['status'] ?? tx['state'] ?? '').toString().toLowerCase();
      switch (_selectedStatus) {
        case 'completed':
          if (!(status.contains('complete') || status.contains('success') || status.contains('approved'))) return false;
          break;
        case 'pending':
          if (!(status.contains('pending') || status.contains('processing'))) return false;
          break;
        case 'failed':
          if (!(status.contains('fail') || status.contains('rejected') || status.contains('error'))) return false;
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
    return dateTimeFormat('MMM d, yyyy • h:mm a', parsed);
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
                  style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
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
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 24), child: CircularProgressIndicator()))
                else if (_error.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error, style: const TextStyle(color: Colors.redAccent)),
                    ),
                  )
                else if (_transactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No transactions match your filters yet.', style: theme.bodyMedium),
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
                    final type = (tx['transaction_type'] ?? tx['type'] ?? 'Transaction').toString();
                    final amount = tx['amount'] ?? tx['value'] ?? 0;
                    final isOutgoing = tx['is_outgoing'] == true || type.toLowerCase().contains('send');
                    final status = (tx['status'] ?? 'Completed').toString();
                    final amountText = '${isOutgoing ? '-' : '+'}${double.tryParse(amount.toString())?.toStringAsFixed(2) ?? amount} FARM';

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: theme.secondaryBackground,
                              child: Icon(
                                isOutgoing ? Icons.north_east_rounded : Icons.south_west_rounded,
                                color: theme.primaryText,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          type,
                                          style: theme.titleSmall.copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withAlpha((0.12 * 255).round()),
                                          borderRadius: BorderRadius.circular(999),
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
                                    tx['description']?.toString() ?? tx['reference']?.toString() ?? 'Transaction updated',
                                    style: theme.bodyMedium,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _formatDate(tx['created_at'] ?? tx['createdAt'] ?? tx['timestamp']),
                                          style: theme.bodySmall,
                                        ),
                                      ),
                                      Text(
                                        amountText,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: isOutgoing ? Colors.redAccent : Colors.green,
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
        color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color,
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
        color: selected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color,
      ),
      shape: const StadiumBorder(),
      onSelected: (_) {
        setState(() => _selectedStatus = value);
        _loadTransactions();
      },
    );
  }
}
