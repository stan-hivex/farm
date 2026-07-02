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
          page: _page, status: _statusFilter == 'all' ? null : _statusFilter);
      setState(() => _deposits = res['data'] ?? []);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _sc(String? s) {
    switch (s) {
      case 'completed': return context.successColor;
      case 'pending': return context.warningColor;
      case 'failed': return context.errorColor;
      default: return context.textSecondary;
    }
  }

  String _paymentMethodLabel(Map? meta, Map txn) {
    final raw = meta?['method'] ?? txn['paymentMethod'] ?? txn['payment_method'] ??
        meta?['payment_method'] ?? txn['payment_provider'] ?? meta?['provider'] ??
        txn['provider'];
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
    return value.isNotEmpty ? value.toUpperCase() : 'UNKNOWN';
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
                      child: _deposits.isEmpty
                          ? Center(
                              child: Text('No deposits found',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: context.onSurface.withOpacity(0.6))))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _deposits.length,
                              itemBuilder: (_, i) {
                                final d = _deposits[i];
                                final meta = d['metadata'] as Map? ?? {};
                                final color = _sc(d['status']);
                                final method = _paymentMethodLabel(meta, d);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: context.onSurface.withOpacity(0.1)),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                          color: context.successColor.withAlpha((0.14 * 255).round()),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Icon(Icons.south_west_rounded,
                                          color: context.successColor, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text(
                                              '${meta['currency_fiat'] ?? 'KES'} ${meta['amount_fiat'] ?? '-'}',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                      color: context.onSurface,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14)),
                                            Text(
                                              d['transaction_reference'] ?? '',
                                              style: GoogleFonts
                                                .plusJakartaSans(
                                                  color: context.onSurface.withOpacity(0.7),
                                                  fontSize: 11),
                                              overflow: TextOverflow.ellipsis),
                                            Text(
                                              method,
                                              style: GoogleFonts
                                                .plusJakartaSans(
                                                  color: context.onSurface.withOpacity(0.54),
                                                  fontSize: 11)),
                                        ])),
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                              '${double.tryParse(d['amount']?.toString() ?? '0')?.toStringAsFixed(2)} FARM',
                                              style: GoogleFonts
                                                  .plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                      color: context.successColor)),
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                                color: color.withAlpha((0.16 * 255).round()),
                                                borderRadius:
                                                    BorderRadius.circular(6)),
                                            child: Text(
                                                (d['status'] ?? '')
                                                    .toUpperCase(),
                                                style: GoogleFonts
                                                    .plusJakartaSans(
                                                        color: color,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                          ),
                                        ]),
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
              for (final s in ['all', 'completed', 'pending', 'failed'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(s.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: _statusFilter == s
                                ? context.background
                                : context.onSurface.withOpacity(0.7))),
                    selected: _statusFilter == s,
                    selectedColor:
                        _statusFilter == s ? accent : Colors.transparent,
                    backgroundColor: const Color(0xFF111B2A),
                    side: BorderSide(
                        color: _statusFilter == s
                            ? accent
                            : context.onSurface.withOpacity(0.1),
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
