import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';

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
    'CARD': 0.0,
    'BANK_TRANSFER': 0.0,
    'MOBILE_MONEY': 0.0,
    'CRYPTO': 0.0,
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
      // POST /api/v1/deposit/create — backend deposit creation endpoint
      final paymentMethodRaw = selectedMethod == 'CARD'
          ? 'card'
          : selectedMethod == 'BANK_TRANSFER'
              ? 'bank_transfer'
              : selectedMethod == 'MOBILE_MONEY'
                  ? 'mobile_money'
                  : 'crypto';

      final body = {
        'amount_fiat': amount,
        'currency': selectedCurrency,
        'paymentMethod': selectedMethod,
        'payment_method': paymentMethodRaw,
        'method': paymentMethodRaw,
        'payment_channel': paymentMethodRaw,
        'payment_provider': selectedMethod == 'CRYPTO' ? 'ivorypay' : 'paystack',
        'provider': selectedMethod == 'CRYPTO' ? 'ivorypay' : 'paystack',
      };

      if (selectedMethod == 'MOBILE_MONEY' && FFAppState().phone.isNotEmpty) {
        body['phone'] = FFAppState().phone;
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
        final depositRef = data['data']?['reference'] ?? 
                          data['data']?['transaction_reference'] ??
                          data['reference'] ??
                          data['transaction_reference'];

        if (paymentUrl != null) {
          // Launch Paystack / Ivorypay payment page in browser
          final uri = Uri.parse(paymentUrl);
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          _snack(
            'Complete payment in browser.\n'
            '~$farmAmount FARM will credit after confirmation.',
          );

          // Poll with timeout and handle all statuses: completed, failed, cancelled
          int pollAttempts = 0;
          const maxAttempts = 60; // ~10 minutes (60 * 10 seconds)
          
          Timer.periodic(const Duration(seconds: 10), (timer) async {
            if (!mounted) {
              timer.cancel();
              return;
            }

            pollAttempts++;

            // Timeout after 10 minutes
            if (pollAttempts > maxAttempts) {
              timer.cancel();
              if (mounted) {
                _snack(
                  'Payment verification timed out. '
                  'Please check your transaction status on the dashboard.',
                );
              }
              return;
            }

            await _fetchHistory();
            await _fetchWallet();

            // Find the specific deposit by reference if available
            Map<String, dynamic>? targetDeposit;
            if (depositRef != null) {
              targetDeposit = recentDeposits.firstWhere(
                (d) => d['reference'] == depositRef || 
                       d['transaction_reference'] == depositRef,
                orElse: () => {},
              );
              if ((targetDeposit?.isEmpty ?? false)) targetDeposit = null;
            }
            
            // Fallback to latest if no specific reference found
            final deposit = targetDeposit ?? 
                           (recentDeposits.isNotEmpty ? recentDeposits.first : null);

            if (deposit != null) {
              final status = (deposit['status'] ?? '').toString().toLowerCase();

              // Accept backend `SUCCESS`/`success` as completed as well as legacy `completed`
              if (status == 'completed' || status == 'success') {
                timer.cancel();
                if (mounted && FFAppState().accessToken.isNotEmpty) {
                  _snack('Payment confirmed! Redirecting to dashboard...');
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    if (mounted) context.go('/dashboard');
                  });
                }
              } else if (status == 'failed' || status == 'cancelled' || status == 'error') {
                timer.cancel();
                if (mounted) {
                  _snack(
                    'Payment ${status == 'cancelled' ? 'cancelled' : 'failed'}. '
                    'No funds were deducted. Please try again.',
                  );

                  // Refresh history and wallet to reflect backend state. Do not call a
                  // non-existent DELETE endpoint; backend controls lifecycle.
                  await _fetchHistory();
                  await _fetchWallet();
                }
              }
            }
          });
        }

        amountController.clear();
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

  // ── Delete failed deposit ────────────────────────────────────────────────
  Future<void> _deleteFailedDeposit(dynamic depositIdOrRef) async {
    try {
      final res = await http.delete(
        Uri.parse('${AppConfig.api}/deposit/$depositIdOrRef'),
        headers: {'Authorization': 'Bearer ${FFAppState().accessToken}'},
      );
      
      if (res.statusCode == 200 || res.statusCode == 204) {
        debugPrint('Failed deposit $depositIdOrRef removed from history');
        if (mounted) {
          // Refresh history to show cleaned up list
          await _fetchHistory();
        }
      } else {
        debugPrint('Could not delete deposit: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error cleaning up failed deposit: $e');
    }
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
          color: selected ? context.background : context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? context.background : context.borderColor,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? context.onSurface : context.onSurface.withOpacity(0.7)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                        color: context.onSurface,
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: context.onSurface.withOpacity(selected ? 0.7 : 0.6),
                      )),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: context.onSurface),
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
      backgroundColor: context.background,
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
                    icon: Icon(Icons.arrow_back_ios_new),
                    onPressed: () => context.goNamed('Dashboard'),
                  ),
                  Text('Deposit Funds',
                      style: GoogleFonts.plusJakartaSans(
                          color: context.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.help_outline, color: context.onSurface),
                ],
              ),

              const SizedBox(height: 28),

              // Wallet balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: loadingWallet
                    ? Center(
                        child: CircularProgressIndicator(color: context.onSurface))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wallet Balance',
                              style: GoogleFonts.plusJakartaSans(
                                  color: context.onSurface.withOpacity(0.7), fontSize: 12)),
                          const SizedBox(height: 6),
                          Text(
                            '${walletBalance.toStringAsFixed(4)} FARM',
                            style: GoogleFonts.plusJakartaSans(
                              color: context.onSurface,
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
                      color: context.onSurface,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: '$selectedCurrency  ',
                    prefixStyle: GoogleFonts.plusJakartaSans(color: context.onSurface),
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 36, color: context.textSecondary),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 24),


              // Payment method
              Text('Payment Method',
                  style: GoogleFonts.plusJakartaSans(
                      color: context.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              _methodCard(
                method: 'CARD',
                icon: Icons.credit_card,
                title: 'Bank Card',
                subtitle: 'Instant • No fee — via Paystack',
              ),
              _methodCard(
                method: 'BANK_TRANSFER',
                icon: Icons.account_balance,
                title: 'Bank Transfer',
                subtitle: '1–2 business days • No fee — via Paystack',
              ),
              _methodCard(
                method: 'MOBILE_MONEY',
                icon: Icons.phone_android,
                title: 'Mobile Money (M-Pesa)',
                subtitle: '1–5 minutes • No fee — via Paystack',
              ),
              _methodCard(
                method: 'CRYPTO',
                icon: Icons.currency_bitcoin,
                title: 'Crypto',
                subtitle: 'Network time • No fee — via Ivorypay',
              ),

              const SizedBox(height: 24),

              // Fee breakdown
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.borderColor),
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

              const SizedBox(height: 24),

              // Deposit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: (isLoading || amount <= 0) ? null : _createDeposit,
                  child: isLoading
                      ? CircularProgressIndicator(color: context.onSurface)
                      : Text('Deposit Funds',
                          style: GoogleFonts.plusJakartaSans(
                              color: FlutterFlowTheme.of(context).onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              ),

              const SizedBox(height: 32),

              // Recent deposits
              Text('Recent Deposits',
                  style: GoogleFonts.plusJakartaSans(
                      color: context.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (recentDeposits.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No deposits yet',
                        style: GoogleFonts.plusJakartaSans(
                            color: context.textSecondary)),
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
                      border: Border.all(color: context.borderColor),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isComplete
                                ? context.successColor.withOpacity(0.2)
                                : context.warningColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isComplete
                                ? Icons.check_circle_outline
                                : Icons.hourglass_top,
                            color:
                                isComplete ? context.successColor : context.warningColor,
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
                                    color: context.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          d['description']?.toString().contains('CRYPTO') == true
                              ? 'CRYPTO'
                              : 'FIAT',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, color: context.textSecondary),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 20),
              Center(
                child: Text('Secured by FARM 🔒',
                    style: TextStyle(color: context.textSecondary, fontSize: 12)),
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
