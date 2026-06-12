import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DepositpageWidget extends StatefulWidget {
  const DepositpageWidget({super.key});

  static String routeName = 'DepositPage';
  static String routePath = '/depositpage';

  @override
  State<DepositpageWidget> createState() => _DepositpageWidgetState();
}

class _DepositpageWidgetState extends State<DepositpageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController amountController = TextEditingController();

  String selectedCurrency = 'KES';
  String selectedMethod = 'CARD';   // CARD | MOBILE_MONEY | CRYPTO

  bool isLoading = false;
  bool loadingWallet = true;

  double walletBalance = 0;
  List<dynamic> recentDeposits = [];

  // Fee percentages per method — keep in sync with backend fee_configurations
  final Map<String, double> _feeRates = {
    'CARD': 0.02,
    'MOBILE_MONEY': 0.015,
    'CRYPTO': 0.005,
  };

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;
  double get feeRate => _feeRates[selectedMethod] ?? 0.02;
  double get fee => amount * feeRate;
  double get total => amount + fee;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
    _fetchHistory();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  // ── Fetch wallet balance ─────────────────────────────────────────────────
  Future<void> _fetchWallet() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.api}/wallet'),
        headers: {'Authorization': 'Bearer ${FFAppState().accessToken}'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          walletBalance =
              (body['data']?['balance'] ?? 0).toDouble();
        });
      }
    } catch (e) {
      debugPrint('fetchWallet error: $e');
    } finally {
      if (mounted) setState(() => loadingWallet = false);
    }
  }

  // ── Fetch deposit history ────────────────────────────────────────────────
  Future<void> _fetchHistory() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.api}/deposit/history'),
        headers: {'Authorization': 'Bearer ${FFAppState().accessToken}'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        
        if (body is List) {
          setState(() => recentDeposits = body);
        } else if (body is Map<String, dynamic>) {
          setState(() => recentDeposits = body['data'] ?? []);
        }
      }
    } catch (e) {
      debugPrint('fetchHistory error: $e');
    }
  }

  // ── Create deposit (Paystack for CARD/MOBILE_MONEY, Ivorypay for CRYPTO) ─
  Future<void> _createDeposit() async {
    if (isLoading) return;

    if (amount < 10) {
      _snack('Minimum deposit is KES 10');
      return;
    }


    setState(() => isLoading = true);

    try {
      // POST /api/v1/payments/deposit  — correct backend endpoint
      final body = {
        'amount_fiat': amount,
        'currency': selectedCurrency,
        'paymentMethod': selectedMethod,
        'payment_provider': selectedMethod == 'CRYPTO' ? 'ivorypay' : 'paystack',
      };

      if (selectedMethod == 'MOBILE_MONEY' && FFAppState().phone.isNotEmpty) {
        body['phone'] = FFAppState().phone;
      }

      if (selectedMethod == 'CRYPTO') {
        body['crypto_network'] = 'ALGORAND';
      }

      final res = await http.post(
        Uri.parse('${AppConfig.api}/deposit/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
        body: jsonEncode(body),
      );

      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final paymentUrl = (data['authorization_url'] ??
                data['payment_url'] ??
                data['data']?['authorization_url'] ??
                data['data']?['payment_url'])
            ?.toString();
        final farmAmount  = data['data']?['amount_farm'];

        if (paymentUrl != null) {
          // Launch Paystack / Ivorypay payment page in browser
          final uri = Uri.parse(paymentUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _snack(
            'Complete payment in browser.\n'
            '~$farmAmount FARM will credit after confirmation.',
          );

          // ONLY poll, do NOT assume payment success. Poll every 10s and stop
          // when we detect a completed deposit instead of using a fixed delay.
          Timer.periodic(const Duration(seconds: 10), (timer) async {
            if (!mounted) {
              timer.cancel();
              return;
            }

            await _fetchHistory();
            await _fetchWallet();

            final latest = recentDeposits.isNotEmpty ? recentDeposits.first : null;
            if (latest != null && latest['status'] == 'completed') {
              timer.cancel();
            }
          });
        }

        amountController.clear();

        // DO NOT refresh immediately
        // wait for webhook / callback confirmation
        _snack('Complete payment to update wallet automatically.');
      } else {
        _snack(
          data['message'] ??
              data['error']?.toString() ??
              'Deposit failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) _snack('Network error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Payment method card ──────────────────────────────────────────────────
  Widget _methodCard({
    required String method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                        color: selected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: selected ? Colors.white70 : Colors.grey,
                      )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FlutterFlowIconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.pop(),
                  ),
                  Text('Deposit Funds',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Icon(Icons.help_outline),
                ],
              ),

              const SizedBox(height: 28),

              // Wallet balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: loadingWallet
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wallet Balance',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            '${walletBalance.toStringAsFixed(4)} FARM',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 28),

              // Amount input
              Center(
                child: TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 36, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '$selectedCurrency  ',
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 36, color: Colors.grey.shade300),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),


              // Payment method
              Text('Payment Method',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _methodCard(
                method: 'CARD',
                icon: Icons.credit_card,
                title: 'Bank Card',
                subtitle: 'Instant • 2% fee — via Paystack',
              ),
              _methodCard(
                method: 'MOBILE_MONEY',
                icon: Icons.phone_android,
                title: 'Mobile Money (M-Pesa)',
                subtitle: '1–5 minutes • 1.5% fee — via Paystack',
              ),
              _methodCard(
                method: 'CRYPTO',
                icon: Icons.currency_bitcoin,
                title: 'Crypto / Algorand',
                subtitle: 'Network time • 0.5% fee — via Ivorypay',
              ),

              const SizedBox(height: 24),

              // Fee breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _feeRow('Amount', 'KES ${amount.toStringAsFixed(2)}'),
                    const SizedBox(height: 10),
                    _feeRow(
                        'Fee (${(feeRate * 100).toStringAsFixed(1)}%)',
                        'KES ${fee.toStringAsFixed(2)}'),
                    const Divider(height: 20),
                    _feeRow('Total', 'KES ${total.toStringAsFixed(2)}',
                        bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Security note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_outline, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Payments are processed securely via Paystack and Ivorypay. '
                        'FARM tokens are credited to your wallet after confirmation.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Deposit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (isLoading || amount <= 0) ? null : _createDeposit,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Deposit Funds',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              ),

              const SizedBox(height: 32),

              // Recent deposits
              Text('Recent Deposits',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (recentDeposits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No deposits yet',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey)),
                  ),
                )
              else
                ...recentDeposits.map((d) {
                  final status = (d['status'] ?? 'pending') as String;
                  final isComplete = status == 'completed';
                  final meta = d['metadata'] as Map<String, dynamic>? ?? {};
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isComplete
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isComplete
                                ? Icons.check_circle_outline
                                : Icons.hourglass_top,
                            color:
                                isComplete ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${meta['currency_fiat'] ?? 'KES'} ${meta['amount_fiat'] ?? d['amount']}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '≈ ${d['amount']} FARM • $status',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          d['description']?.toString().contains('CRYPTO') == true
                              ? 'CRYPTO'
                              : 'FIAT',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),
              const Center(
                child: Text('Secured by FARM 🔒',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feeRow(String label, String value, {bool bold = false}) {
    final style = GoogleFonts.plusJakartaSans(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}