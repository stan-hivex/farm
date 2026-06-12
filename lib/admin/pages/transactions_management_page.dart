import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_api_service.dart';

class TransactionsManagementPage extends StatefulWidget {
  const TransactionsManagementPage({super.key});

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
      );
      setState(() {
        _txns = res['data'] ?? [];
        _total = res['meta']?['total'] ?? 0;
      });
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      case 'processing': return Colors.blue;
      default: return Colors.grey;
    }
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
            _filters(accent),
            if (_loading)
              const Expanded(
                  child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37))))
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                        onPressed: _page > 1
                                            ? () {
                                                setState(() => _page--);
                                                _load();
                                              }
                                            : null,
                                        child: Text('← Prev',
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                                    color: Colors
                                                        .white70))),
                                    Text('$_page / $last',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    TextButton(
                                        onPressed: _page < last
                                            ? () {
                                                setState(() => _page++);
                                                _load();
                                              }
                                            : null,
                                        child: Text('Next →',
                                            style: GoogleFonts
                                                .plusJakartaSans(
                                                    color: Colors
                                                        .white70))),
                                  ]),
                            );
                          }
                          final t = _txns[i];
                          final color = _statusColor(t['status']);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: color.withOpacity(0.14),
                                    borderRadius:
                                        BorderRadius.circular(10)),
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
                                        (t['transaction_type'] ?? '')
                                            .toString()
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        style: GoogleFonts
                                            .plusJakartaSans(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white)),
                                    Text(
                                        t['transaction_reference'] ?? '',
                                        style: GoogleFonts
                                            .plusJakartaSans(
                                                color: Colors.white54,
                                                fontSize: 11),
                                        overflow:
                                            TextOverflow.ellipsis),
                                  ])),
                              Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                        '${double.tryParse(t['amount']?.toString() ?? '0')?.toStringAsFixed(2)} FARM',
                                        style: GoogleFonts
                                            .plusJakartaSans(
                                                fontWeight:
                                                    FontWeight.bold,
                                                fontSize: 13,
                                                color: Colors.white)),
                                    Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: color.withOpacity(0.16),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: Text(
                                          (t['status'] ?? '')
                                              .toUpperCase(),
                                          style: GoogleFonts
                                              .plusJakartaSans(
                                                  color: color,
                                                  fontSize: 9,
                                                  fontWeight:
                                                      FontWeight
                                                          .bold)),
                                    ),
                                  ]),
                            ]),
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
                children: [
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
                        label: Text(
                            f.replaceAll('_', ' ').toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: _typeFilter == f
                                    ? Colors.black
                                    : Colors.white70)),
                        selected: _typeFilter == f,
                        selectedColor:
                            _typeFilter == f ? accent : Colors.transparent,
                        backgroundColor: const Color(0xFF111B2A),
                        side: BorderSide(
                            color: _typeFilter == f
                                ? accent
                                : Colors.white10,
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
            child: Row(
                children: [
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
                                color: _statusFilter == s
                                    ? Colors.black
                                    : Colors.white70)),
                        selected: _statusFilter == s,
                        selectedColor: _statusFilter == s
                            ? accent
                            : Colors.transparent,
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
          ),
        ],
      );
}