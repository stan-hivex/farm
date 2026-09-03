import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../services/admin_api_service.dart';

class DepositsManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const DepositsManagementPage({super.key, this.onGoBack});

  @override
  State<DepositsManagementPage> createState() => _DepositsManagementPageState();
}

class _DepositsManagementPageState extends State<DepositsManagementPage> {
  List<dynamic> _deposits = [];
  bool _loading = true;
  String _statusFilter = 'all';
  String _search = '';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService.getDeposits(
          page: _page,
          status: _statusFilter == 'all' ? null : _statusFilter,
          search: _search.isEmpty ? null : _search);
      setState(() => _deposits = res['data'] ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _sc(String? s) {
    switch (s) {
      case 'completed':
        return context.successColor;
      case 'pending':
        return context.warningColor;
      case 'failed':
        return context.errorColor;
      default:
        return context.textSecondary;
    }
  }

  String _paymentMethodLabel(Map? meta, Map txn) {
    final raw = meta?['method'] ??
        txn['paymentMethod'] ??
        txn['payment_method'] ??
        meta?['payment_method'] ??
        txn['payment_provider'] ??
        meta?['provider'] ??
        txn['provider'];
    final value = raw?.toString().toLowerCase() ?? '';
    if (value.contains('crypto') || value.contains('ivory')) return 'CRYPTO';
    if (value.contains('mobile')) return 'MOBILE';
    if (value.contains('card')) return 'CARD';
    if (value.contains('paystack')) {
      final explicit = (meta?['method'] ??
              txn['method'] ??
              txn['paymentMethod'] ??
              txn['payment_method'])
          ?.toString()
          .toLowerCase();
      if (explicit?.contains('mobile') == true) return 'MOBILE';
      if (explicit?.contains('card') == true) return 'CARD';
      return 'PAYSTACK';
    }
    return value.isNotEmpty ? value.toUpperCase() : 'UNKNOWN';
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search deposits by username or transaction ID',
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
            _filterRow(accent),
            if (_loading && _deposits.isEmpty)
              const Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF90CAF9))))
            else
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: _load,
                      color: accent,
                      child: _deposits.isEmpty
                          ? Center(
                              child: Text('No deposits found',
                                  style: GoogleFonts.plusJakartaSans(
                                      color:
                                          context.onSurface.withOpacity(0.6))))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _deposits.length,
                              itemBuilder: (_, i) {
                                final d = _deposits[i];
                                final meta = d['metadata'] as Map? ?? {};
                                final color = _sc(d['status']);
                                final method = _paymentMethodLabel(meta, d);
                                final username = (d['username'] ?? '').toString();
                                final userId = (d['user_id'] ?? '').toString();
                                final reference = (d['transaction_reference'] ?? d['id'] ?? '-').toString();
                                final amountLabel = d['amount_display']?.toString() ??
                                    '${double.tryParse(d['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'} FARM';
                                final statusLabel = (d['status_display'] ?? d['status'] ?? '-').toString().toUpperCase();
                                final dateLabel = (d['date'] ?? '-').toString();
                                final timeLabel = (d['time'] ?? '-').toString();
                                return InkWell(
                                  onTap: () => _showDetails(d),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                        color:
                                            context.onSurface.withOpacity(0.1)),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                          color: context.successColor
                                              .withAlpha((0.14 * 255).round()),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Icon(Icons.south_west_rounded,
                                          color: context.successColor,
                                          size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              'User: ${username.isNotEmpty ? '@$username' : 'Unknown'}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13)),
                                          Text('User ID: ${userId.isNotEmpty ? userId : '-'}',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface
                                                          .withOpacity(0.7),
                                                      fontSize: 11)),
                                          Text('ID: $reference',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface
                                                          .withOpacity(0.7),
                                                      fontSize: 11)),
                                          Text('Method: $method',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface
                                                          .withOpacity(0.54),
                                                      fontSize: 11)),
                                          Text('Amount: $amountLabel',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface
                                                          .withOpacity(0.54),
                                                      fontSize: 11)),
                                          Text('Status: $statusLabel',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface
                                                          .withOpacity(0.54),
                                                      fontSize: 11)),
                                          Text('Date: $dateLabel',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface
                                                          .withOpacity(0.54),
                                                      fontSize: 11)),
                                          Text('Time: $timeLabel',
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      color: context.onSurface
                                                          .withOpacity(0.54),
                                                      fontSize: 11)),
                                        ])),
                                    const SizedBox(width: 8),
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                              amountLabel,
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color: context
                                                          .successColor)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                                color: color.withAlpha(
                                                    (0.16 * 255).round()),
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            child: Text(
                                                statusLabel,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                        color: color,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                          ),
                                        ]),
                                  ]),
                                  ),
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
        child: Row(children: [
          for (final s in ['all', 'completed', 'pending', 'failed'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _statusFilter == s ? Colors.white : Colors.black)),
                selected: _statusFilter == s,
                selectedColor: _statusFilter == s ? Colors.black : Colors.white,
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
      );

  void _showDetails(Map<String, dynamic> item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text('Deposit details', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
            for (final entry in item.entries)
              if (entry.value != null) ListTile(title: Text(entry.key), subtitle: Text(entry.value.toString())),
          ],
        ),
      ),
    );
  }
}
