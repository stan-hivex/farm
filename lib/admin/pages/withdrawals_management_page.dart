import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_api_service.dart';

class WithdrawalsManagementPage extends StatefulWidget {
  const WithdrawalsManagementPage({super.key});

  @override
  State<WithdrawalsManagementPage> createState() =>
      _WithdrawalsManagementPageState();
}

class _WithdrawalsManagementPageState
    extends State<WithdrawalsManagementPage> {
  List<dynamic> _withdrawals = [];
  bool _loading = true;
  String _statusFilter = 'all';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService.getWithdrawals(
          page: _page, status: _statusFilter == 'all' ? null : _statusFilter);
      setState(() => _withdrawals = res['data'] ?? []);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _process(String txId, String action) async {
    try {
      debugPrint('Processing withdrawal: txId=$txId, action=$action');
      await AdminApiService.processWithdrawal(txId, action);
      debugPrint('Withdrawal processed successfully');
      _snack(action == 'completed' ? 'Withdrawal approved ✓' : 'Withdrawal rejected',
             action == 'completed' ? Colors.green : Colors.red);
      _load();
    } catch (e) {
      debugPrint('Error processing withdrawal: ${e.toString()}');
      _snack(e.toString(), Colors.red);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  Color _sc(String? s) {
    switch (s) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _paymentMethodLabel(Map? meta, Map txn, {String fallback = 'BANK'}) {
    final raw = meta?['method'] ?? txn['method'] ?? txn['paymentMethod'] ?? txn['payment_method'] ??
        meta?['payment_method'] ?? txn['payment_provider'] ?? meta?['provider'] ?? txn['provider'];
    final value = raw?.toString().toLowerCase() ?? '';
    if (value.contains('crypto') || value.contains('ivory')) return 'CRYPTO';
    if (value.contains('mobile')) return 'MOBILE';
    if (value.contains('card')) return 'CARD';
    if (value.contains('paystack')) {
      final explicit = (meta?['method'] ?? txn['method'] ?? txn['paymentMethod'] ?? txn['payment_method'])?.toString().toLowerCase();
      if (explicit?.contains('mobile') == true) return 'MOBILE';
      if (explicit?.contains('card') == true) return 'CARD';
      return 'PAYSTACK';
    }
    return value.isNotEmpty ? value.toUpperCase() : fallback;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0B1320);
    final cardColor = const Color(0xFF111B2A);
    final accent = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _filterRow(accent),
            if (_loading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37))))
            else
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: _load,
                      color: accent,
                      child: _withdrawals.isEmpty
                          ? Center(
                              child: Text('No withdrawal requests',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white60)))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _withdrawals.length,
                              itemBuilder: (_, i) {
                                final w = _withdrawals[i];
                                final meta = w['metadata'] as Map? ?? {};
                                final method = _paymentMethodLabel(meta, w);
                                final isPending = w['status'] == 'pending';
                                final color = _sc(w['status']);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Row(children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.14),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(10)),
                                                  child: const Icon(
                                                      Icons.north_east_rounded,
                                                      color: Colors.red,
                                                      size: 20),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          '${double.tryParse(w['amount']?.toString() ?? '0')?.toStringAsFixed(2)} FARM',
                                                          style: GoogleFonts
                                                              .plusJakartaSans(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .red)),
                                                        Text(
                                                          method,
                                                          style: GoogleFonts
                                                            .plusJakartaSans(
                                                              color:
                                                                Colors
                                                                  .white54,
                                                              fontSize:
                                                                12)),
                                                    ]),
                                              ]),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10,
                                                    vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: color.withOpacity(
                                                        0.16),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8)),
                                                child: Text(
                                                    (w['status'] ?? '')
                                                        .toUpperCase(),
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                            color: color,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold)),
                                              ),
                                            ]),
                                        const SizedBox(height: 10),
                                        Text(
                                            'Destination: ${meta['destination'] ?? '-'}',
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                                    color: Colors.white70,
                                                    fontSize: 12)),
                                        Text(
                                            'Ref: ${w['transaction_reference'] ?? '-'}',
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                                    color: Colors.white54,
                                                    fontSize: 11),
                                            overflow: TextOverflow.ellipsis),
                                        if (isPending) ...[
                                          const SizedBox(height: 12),
                                          Row(children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                    side: const BorderSide(
                                                        color: Colors.red),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10))),
                                                onPressed: () =>
                                                    _process(w['id'], 'failed'),
                                                child: Text('Reject',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                            color:
                                                                Colors.red)),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10))),
                                                onPressed: () => _process(
                                                    w['id'], 'completed'),
                                                child: Text('Approve',
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                            color: Colors
                                                                .black87)),
                                              ),
                                            ),
                                          ]),
                                        ],
                                      ]),
                                );
                              }))),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(Color accent) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(
            children: [
              for (final s in ['all', 'pending', 'completed', 'failed'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _statusFilter == s
                                ? Colors.black
                                : Colors.white70)),
                    selected: _statusFilter == s,
                    selectedColor:
                        _statusFilter == s ? accent : Colors.transparent,
                    backgroundColor: const Color(0xFF111B2A),
                    side: BorderSide(
                        color: _statusFilter == s
                            ? accent
                            : Colors.white10,
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
      );
}