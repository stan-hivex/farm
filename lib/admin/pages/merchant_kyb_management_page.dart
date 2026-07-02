import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../services/admin_api_service.dart';

class MerchantKybManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const MerchantKybManagementPage({super.key, this.onGoBack});

  @override
  State<MerchantKybManagementPage> createState() => _MerchantKybManagementPageState();
}

class _MerchantKybManagementPageState extends State<MerchantKybManagementPage> {
  final _bgColor = const Color(0xFF0B1320);
  final _cardColor = const Color(0xFF111B2A);
  final _accent = const Color(0xFFD4AF37);

  List<dynamic> _merchants = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'pending';
  final Map<String, bool> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await AdminApiService.getMerchants(
        page: 1,
        status: _statusFilter != 'all' ? _statusFilter : null,
      );
      setState(() => _merchants = res['data'] as List? ?? []);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reviewMerchant(String merchantId, String status) async {
    setState(() => _processing[merchantId] = true);
    try {
      await AdminApiService.decideMerchant(merchantId, status);
      _snack(
          status == 'approved' ? 'Merchant KYB approved ✓' : 'Merchant KYB rejected',
          status == 'approved' ? context.successColor : context.errorColor);
      _load();
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), context.errorColor);
    } finally {
      if (mounted) setState(() => _processing[merchantId] = false);
    }
  }

  void _showRejectDialog(String merchantId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardColor,
        title: Text('Reject Merchant KYB', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: context.onSurface)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: context.onSurface),
          decoration: InputDecoration(
            hintText: 'Reason for rejection',
            hintStyle: TextStyle(color: context.onSurface.withOpacity(0.38)),
            filled: true,
            fillColor: const Color(0xFF0F1724),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: _accent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.errorColor),
            onPressed: () {
              Navigator.pop(context);
              _reviewMerchant(merchantId, 'rejected');
            },
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
      );

  String _merchantId(dynamic merchant) {
    return merchant['id']?.toString() ?? merchant['merchant_id']?.toString() ?? '';
  }

  String _merchantStatus(dynamic merchant) {
    return merchant['kyb_status']?.toString().toLowerCase() ?? merchant['status']?.toString().toLowerCase() ?? 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: _accent,
          backgroundColor: _bgColor,
          child: _loading
              ? ListView(children: const [SizedBox(height: 120), Center(child: CircularProgressIndicator())])
              : ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Merchant KYB',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 22, fontWeight: FontWeight.bold, color: context.onSurface)),
                  const SizedBox(height: 6),
                  Text('Review merchant KYB applications and decide onboarding status.',
                      style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.7), fontSize: 13)),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final status in ['all', 'pending', 'approved', 'rejected', 'active'])
                        ChoiceChip(
                          label: Text(status.toUpperCase(), style: GoogleFonts.plusJakartaSans(color: _statusFilter == status ? context.background : context.onSurface.withOpacity(0.7), fontSize: 12)),
                          selected: _statusFilter == status,
                          selectedColor: _accent,
                          backgroundColor: _cardColor,
                          side: BorderSide(color: _statusFilter == status ? _accent : context.onSurface.withOpacity(0.1)),
                          onSelected: (_) {
                            setState(() => _statusFilter = status);
                            _load();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.errorColor.withAlpha((0.14 * 255).round()),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: context.errorColor.withAlpha((0.2 * 255).round())),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: context.errorColorAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(_error!, style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.7))),
                        ),
                        TextButton(onPressed: _load, child: Text('Retry', style: TextStyle(color: _accent))),
                      ]),
                    ),

                  if (_merchants.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: _cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.onSurface.withOpacity(0.1)),
                      ),
                      child: Column(children: [
                        Icon(Icons.badge_rounded, size: 32, color: context.onSurface.withOpacity(0.24)),
                        const SizedBox(height: 14),
                        Text('No merchant KYB records found',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.54), fontSize: 14)),
                      ]),
                    )
                  else
                    ..._merchants.map((merchant) {
                      final id = _merchantId(merchant);
                      final status = _merchantStatus(merchant);
                      final processing = _processing[id] == true;
                      final business = merchant['business_name'] ?? merchant['name'] ?? 'Merchant';
                      final email = merchant['email'] ?? merchant['contact_email'] ?? '-';
                      final phone = merchant['phone'] ?? merchant['contact_phone'] ?? '-';
                      final created = merchant['created_at'] ?? merchant['createdAt'] ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: context.onSurface.withOpacity(0.1)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text(business,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold, fontSize: 15, color: context.onSurface)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: status == 'approved'
                                    ? context.successColor.withAlpha((0.15 * 255).round())
                                    : status == 'rejected'
                                        ? context.errorColor.withAlpha((0.15 * 255).round())
                                        : context.warningColor.withAlpha((0.14 * 255).round()),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                      color: status == 'approved'
                                          ? context.successColorAccent
                                          : status == 'rejected'
                                              ? context.errorColorAccent
                                              : context.warningColorAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            )
                          ]),
                          const SizedBox(height: 10),
                          Text(email, style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.6), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(phone, style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.6), fontSize: 12)),
                          if (created.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Applied: $created',
                                style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.38), fontSize: 11)),
                          ],
                          const SizedBox(height: 18),
                          if (status == 'pending')
                            Row(children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: context.errorColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    foregroundColor: context.errorColor,
                                  ),
                                  onPressed: processing ? null : () => _showRejectDialog(id),
                                  child: Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: processing ? null : () => _reviewMerchant(id, 'approved'),
                                  child: processing
                                      ? SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(color: context.onBackground.withOpacity(0.87), strokeWidth: 2),
                                        )
                                      : Text('Approve', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: context.onBackground.withOpacity(0.87))),
                                ),
                              ),
                            ])
                          else
                            Row(children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: status == 'approved' ? context.successColor : context.errorColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  onPressed: processing ? null : () => _reviewMerchant(id, status == 'approved' ? 'rejected' : 'approved'),
                                  child: Text(
                                    status == 'approved' ? 'Mark Rejected' : 'Mark Approved',
                                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: context.onBackground.withOpacity(0.87)),
                                  ),
                                ),
                              ),
                            ]),
                        ]),
                      );
                    }),
                ]),
        ),
      ),
    );
  }
}
