import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';

class WithdrawpageWidget extends StatefulWidget {
  const WithdrawpageWidget({super.key});

  static String routeName = 'withdrawpage';
  static String routePath = '/withdrawpage';

  @override
  State<WithdrawpageWidget> createState() => _WithdrawpageWidgetState();
}

class _WithdrawpageWidgetState extends State<WithdrawpageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _amountCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  final _cryptoCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  String selectedMethod = 'BANK';
  String selectedCurrency = 'KES';
  bool isLoading = false;
  bool loadingWallet = true;
  bool loadingHistory = true;

  double walletBalance = 0;
  List<dynamic> history = [];

  // Fee rates per method
  final Map<String, double> _fees = {
    'BANK': 0.015,
    'MOBILE_MONEY': 0.020,
    'CRYPTO': 0.005,
  };

  double get amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  double get feeRate => _fees[selectedMethod] ?? 0.015;
  double get fee => amount * feeRate;
  double get settlement => amount - fee;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
    _fetchHistory();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountCtrl.dispose();
    _cryptoCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  // ── Fetch wallet ─────────────────────────────────────────────────────────
  Future<void> _fetchWallet() async {
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.api}/wallet'),
        headers: {'Authorization': 'Bearer ${FFAppState().accessToken}'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() => walletBalance =
            (body['data']?['available_balance'] ?? 0).toDouble());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingWallet = false);
    }
  }

  // ── Fetch withdrawal history ─────────────────────────────────────────────
  Future<void> _fetchHistory() async {
    try {
      final res = await http.get(
        // Correct backend endpoint
        Uri.parse('${AppConfig.api}/payments/withdrawals'),
        headers: {'Authorization': 'Bearer ${FFAppState().accessToken}'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() => history = body['data'] ?? []);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingHistory = false);
    }
  }

  // ── Get destination string from fields ───────────────────────────────────
  String get _destination {
    switch (selectedMethod) {
      case 'BANK':
        return '${_bankNameCtrl.text.trim()} — ${_accountCtrl.text.trim()}';
      case 'MOBILE_MONEY':
        return _mobileCtrl.text.trim();
      case 'CRYPTO':
        return _cryptoCtrl.text.trim();
      default:
        return '';
    }
  }

  // ── Validate destination fields ──────────────────────────────────────────
  bool get _destinationValid {
    switch (selectedMethod) {
      case 'BANK':
        return _bankNameCtrl.text.isNotEmpty && _accountCtrl.text.isNotEmpty;
      case 'MOBILE_MONEY':
        return _mobileCtrl.text.isNotEmpty;
      case 'CRYPTO':
        return _cryptoCtrl.text.isNotEmpty;
      default:
        return false;
    }
  }

  // ── Submit withdrawal ─────────────────────────────────────────────────────
  Future<void> _createWithdraw() async {
    if (isLoading) return;

    if (amount < 10) {
      _snack('Minimum withdrawal is KES 10');
      return;
    }
    if (amount > 70000) {
      _snack('Maximum withdrawal is KES 70,000');
      return;
    }
    if (amount > walletBalance) {
      _snack('Insufficient FARM balance');
      return;
    }
    if (!_destinationValid) {
      _snack('Please fill in your withdrawal destination');
      return;
    }
    if (_pinCtrl.text.trim().isEmpty) {
      _snack('PIN is required to authorize withdrawal');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Build request body with backend-expected field names
      final requestBody = {
        'amount': amount,
        'method': _methodToBackend(selectedMethod),
        'pin': _pinCtrl.text.trim(),
      };

      // Add method-specific fields
      switch (selectedMethod) {
        case 'BANK':
          requestBody['accountName'] = _bankNameCtrl.text.trim();
          requestBody['accountNumber'] = _accountCtrl.text.trim();
          requestBody['bankName'] = _bankNameCtrl.text.trim();
          break;
        case 'MOBILE_MONEY':
          requestBody['phoneNumber'] = _mobileCtrl.text.trim();
          break;
        case 'CRYPTO':
          requestBody['cryptoAddress'] = _cryptoCtrl.text.trim();
          requestBody['network'] = 'ALGORAND';
          break;
      }

      final res = await http.post(
        // Correct backend endpoint for withdrawal
        Uri.parse('${AppConfig.api}/withdraw/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
        body: jsonEncode(requestBody),
      );

      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack(
          'Withdrawal request submitted. Final success depends on payment confirmation via webhook. '
          'Please monitor withdrawal history for the final status.',
        );
        _clearFields();
        await _fetchWallet();
        await _fetchHistory();
      } else {
        _snack(data['message'] ?? 'Withdrawal failed. Please try again.');
      }
    } catch (e) {
      if (mounted) _snack('Network error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _clearFields() {
    _amountCtrl.clear();
    _bankNameCtrl.clear();
    _accountCtrl.clear();
    _cryptoCtrl.clear();
    _mobileCtrl.clear();
    _pinCtrl.clear();
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );

  // ── Convert frontend method names to backend format ───────────────────────
  String _methodToBackend(String method) {
    switch (method) {
      case 'BANK':
        return 'BANK_TRANSFER';
      case 'MOBILE_MONEY':
        return 'MOBILE_MONEY';
      case 'CRYPTO':
        return 'CRYPTO';
      default:
        return method;
    }
  }

  // ── Method card ───────────────────────────────────────────────────────────
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
          border:
              Border.all(color: selected ? Colors.black : Colors.grey.shade300),
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
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: selected ? Colors.white70 : Colors.grey)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── Destination fields ────────────────────────────────────────────────────
  Widget _buildDestinationFields() {
    switch (selectedMethod) {
      case 'BANK':
        return Column(children: [
          _inputField(controller: _bankNameCtrl, hint: 'Bank Name'),
          const SizedBox(height: 12),
          _inputField(
              controller: _accountCtrl,
              hint: 'Account Number',
              type: TextInputType.number),
        ]);
      case 'MOBILE_MONEY':
        return _inputField(
            controller: _mobileCtrl,
            hint: 'Phone Number (e.g. +254700...)',
            type: TextInputType.phone);
      case 'CRYPTO':
        return _inputField(
            controller: _cryptoCtrl, hint: 'Algorand Wallet Address');
      default:
        return const SizedBox();
    }
  }

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: GoogleFonts.plusJakartaSans(),
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Fee row ───────────────────────────────────────────────────────────────
  Widget _feeRow(String label, String value, {bool bold = false}) {
    final style = GoogleFonts.plusJakartaSans(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
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
                  Text('Withdraw Funds',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  FlutterFlowIconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () =>
                        _snack('Withdrawals are processed instantly.'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Balance card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: loadingWallet
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AVAILABLE BALANCE',
                              style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 1)),
                          const SizedBox(height: 8),
                          Text(
                            '${walletBalance.toStringAsFixed(4)} FARM',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 28),

              // Amount input card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text('Withdrawal Amount',
                        style: GoogleFonts.plusJakartaSans(
                            color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 36, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                          border: InputBorder.none, hintText: '0.00'),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Min: FARM 10',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey, fontSize: 12)),
                        Text('Max: FARM 70,000',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Method selection
              Text('Select Method',
                  style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 14),

              _methodCard(
                  method: 'BANK',
                  icon: Icons.account_balance,
                  title: 'Bank Transfer',
                  subtitle: 'instant • 1.5% fee'),
              _methodCard(
                  method: 'MOBILE_MONEY',
                  icon: Icons.phone_android,
                  title: 'Mobile Money',
                  subtitle: 'Instant • 2% fee'),
              _methodCard(
                  method: 'CRYPTO',
                  icon: Icons.currency_bitcoin,
                  title: 'Crypto Wallet (Algorand)',
                  subtitle: 'Near instant • 0.5% fee — via Ivorypay'),

              const SizedBox(height: 20),

              // Destination inputs
              _buildDestinationFields(),

              const SizedBox(height: 16),

              TextField(
                controller: _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  hintText: 'Transaction PIN',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  counterText: '',
                ),
              ),

              const SizedBox(height: 24),

              // Fee breakdown
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _feeRow('FARM Amount', '${amount.toStringAsFixed(4)} FARM'),
                    const SizedBox(height: 12),
                    _feeRow('Fee (${(feeRate * 100).toStringAsFixed(1)}%)',
                        '${fee.toStringAsFixed(4)} FARM'),
                    const Divider(height: 24),
                    _feeRow(
                        'You Receive', '${settlement.toStringAsFixed(4)} FARM',
                        bold: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Security note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Withdrawal is secured by FARM multi-layer verification. '
                        'Funds are locked until processed.',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed:
                      (isLoading || amount <= 0) ? null : _createWithdraw,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Withdraw Funds',
                          style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                ),
              ),

              const SizedBox(height: 32),

              // History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Withdrawals',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  TextButton(
                      onPressed: _fetchHistory, child: const Text('Refresh')),
                ],
              ),

              const SizedBox(height: 14),

              if (loadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                      child: Text('No withdrawal history',
                          style:
                              GoogleFonts.plusJakartaSans(color: Colors.grey))),
                )
              else
                ...history.map((w) {
                  final meta = w['metadata'] as Map<String, dynamic>? ?? {};
                  final status = w['status'] ?? 'pending';
                  final isComplete = status == 'completed';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
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
                            color: isComplete ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meta['method'] ??
                                    w['description'] ??
                                    'Withdrawal',
                                style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(status,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(
                          '-${w['amount']} FARM',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
