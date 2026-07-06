import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../services/admin_api_service.dart';

class EscrowManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const EscrowManagementPage({super.key, this.onGoBack});

  @override
  State<EscrowManagementPage> createState() => _EscrowManagementPageState();
}

class _EscrowManagementPageState extends State<EscrowManagementPage> {
  List<dynamic> _escrows = [];
  bool _loading = true;
  String _filter = 'all';
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService.getEscrows(
          page: _page, status: _filter == 'all' ? null : _filter);
      setState(() => _escrows = res['data'] ?? []);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resolve(String escrowId, String winner) async {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text('Resolve Dispute — Award to $winner',
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold, color: context.onSurface)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: context.onSurface),
          decoration: InputDecoration(
              hintText: 'Resolution note...',
              hintStyle: TextStyle(color: context.onSurface.withOpacity(0.54)),
              border: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.onSurface.withOpacity(0.1))),
              enabledBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.onSurface.withOpacity(0.1)))),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel',
                  style: GoogleFonts.plusJakartaSans(
                      color: context.onSurface.withOpacity(0.7)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF90CAF9)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await AdminApiService.resolveDispute(
                    escrowId, winner, ctrl.text.trim());
                _snack('Dispute resolved — $winner wins', context.successColor);
                _load();
              } catch (e) {
                _snack(e.toString(), context.errorColor);
              }
            },
            child: Text('Confirm',
                style: GoogleFonts.plusJakartaSans(
                    color: context.onBackground.withOpacity(0.87))),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));

  Color _escrowColor(String? s) {
    switch (s) {
      case 'active':
        return Colors.blue;
      case 'completed':
        return context.successColor;
      case 'disputed':
        return context.errorColor;
      case 'refunded':
        return context.warningColor;
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
            _filterRow(accent),
            if (_loading)
              const Expanded(
                  child: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF90CAF9))))
            else
              Expanded(
                  child: RefreshIndicator(
                      onRefresh: _load,
                      color: accent,
                      child: _escrows.isEmpty
                          ? Center(
                              child: Text('No escrow contracts',
                                  style: GoogleFonts.plusJakartaSans(
                                      color:
                                          context.onSurface.withOpacity(0.6))))
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _escrows.length,
                              itemBuilder: (_, i) =>
                                  _escrowCard(_escrows[i], cardColor, accent),
                            ))),
          ],
        ),
      ),
    );
  }

  Widget _filterRow(Color accent) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Row(children: [
          for (final f in [
            'all',
            'active',
            'completed',
            'disputed',
            'refunded'
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: _filter == f
                            ? context.background
                            : context.onSurface.withOpacity(0.7))),
                selected: _filter == f,
                selectedColor: _filter == f ? accent : Colors.transparent,
                backgroundColor: Colors.white,
                side: BorderSide(
                    color: _filter == f
                        ? accent
                        : context.onSurface.withOpacity(0.1),
                    width: 1),
                onSelected: (_) {
                  setState(() {
                    _filter = f;
                    _page = 1;
                  });
                  _load();
                },
              ),
            ),
        ]),
      );

  Widget _escrowCard(Map<String, dynamic> e, Color cardColor, Color accent) {
    final buyer = e['users_escrow_contracts_buyer_idTousers'] as Map? ?? {};
    final seller = e['users_escrow_contracts_seller_idTousers'] as Map? ?? {};
    final color = _escrowColor(e['status']);
    final isDisputed = e['status'] == 'disputed';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: isDisputed
            ? Border.all(
                color: context.errorColor.withAlpha((0.4 * 255).round()),
                width: 1.5)
            : Border.all(color: context.onSurface.withOpacity(0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(e['reference_code'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold, fontSize: 13, color: accent)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: color.withAlpha((0.16 * 255).round()),
                borderRadius: BorderRadius.circular(8)),
            child: Text((e['status'] ?? '').toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                    color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 12),
        _escrowDetail('Title', e['title'] ?? '-'),
        _escrowDetail('Amount',
            '${double.tryParse(e['amount']?.toString() ?? '0')?.toStringAsFixed(2)} FARM'),
        _escrowDetail('Buyer',
            '${buyer['first_name'] ?? ''} ${buyer['last_name'] ?? ''}'),
        _escrowDetail('Seller',
            '${seller['first_name'] ?? ''} ${seller['last_name'] ?? ''}'),
        if (isDisputed) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () => _resolve(e['id'], 'buyer'),
                child: Text('Award Buyer',
                    style: GoogleFonts.plusJakartaSans(color: Colors.blue)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: context.successColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () => _resolve(e['id'], 'seller'),
                child: Text('Award Seller',
                    style: GoogleFonts.plusJakartaSans(
                        color: context.onBackground.withOpacity(0.87))),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  Widget _escrowDetail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: [
          SizedBox(
              width: 70,
              child: Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      color: context.onSurface.withOpacity(0.54),
                      fontSize: 12))),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  color: context.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ]),
      );
}
