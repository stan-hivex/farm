import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';

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
  final _accountCtrl = TextEditingController();
  final _cryptoCtrl = TextEditingController();
  final _networkCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();

  String selectedMethod = 'BANK';
  String selectedCurrency = 'KES';
  bool isLoading = false;
  bool loadingWallet = true;
  bool loadingHistory = true;

  String? _selectedBank; // For bank dropdown selection

  double walletBalance = 0;
  List<dynamic> history = [];
  Timer? _historyTimer;

  // Kenyan banks
  final List<String> kenyaBanks = [
    'ABSA Bank Kenya',
    'Barclays Bank Kenya',
    'CFC Stanbic Bank',
    'Co-operative Bank',
    'Equity Bank',
    'I&M Bank',
    'KCB Bank',
    'Kenya Commercial Bank',
    'Kinetic Bank',
    'National Bank of Kenya',
    'Safaricom (M-Pesa)',
    'Standard Chartered Bank',
    'The One Finance Bank',
    'Transnational Bank',
    'UBA Kenya',
  ];

  // Fee rates per method
  final Map<String, double> _fees = {
    'BANK': 0.0,
    'MOBILE_MONEY': 0.0,
    'CRYPTO': 0.0,
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
    _startHistoryPolling();
  }

  @override
  void dispose() {
    _historyTimer?.cancel();
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    _cryptoCtrl.dispose();
    _networkCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _startHistoryPolling() {
    _historyTimer?.cancel();
    _historyTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      _fetchWallet();
      _fetchHistory();
    });
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
        // Support different backend shapes: { data: { available_balance } } or { balance }
        double bal = 0;
        if (body is Map<String, dynamic>) {
          bal = (body['data']?['available_balance'] ?? body['data']?['balance'] ?? body['available_balance'] ?? body['balance'] ?? 0).toDouble();
        } else {
          bal = 0;
        }
        setState(() => walletBalance = bal);
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
        // Backend withdraw history endpoint
        Uri.parse('${AppConfig.api}/withdraw/history'),
        headers: {'Authorization': 'Bearer ${FFAppState().accessToken}'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is List) {
          setState(() => history = body);
        } else if (body is Map<String, dynamic>) {
          setState(() => history = body['data'] ?? body['withdrawals'] ?? []);
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingHistory = false);
    }
  }

  // ── Validate destination fields ──────────────────────────────────────────
  bool get _destinationValid {
    switch (selectedMethod) {
      case 'BANK':
        return _selectedBank != null && _accountCtrl.text.isNotEmpty;
      case 'MOBILE_MONEY':
        return _mobileCtrl.text.isNotEmpty;
      case 'CRYPTO':
        return _cryptoCtrl.text.isNotEmpty && _networkCtrl.text.isNotEmpty;
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Confirm Withdrawal'),
        content: Text('Withdraw ${amount.toStringAsFixed(4)} FARM via ${selectedMethod.replaceAll('_', ' ')}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => isLoading = true);

    try {
      // Debug: Log submission
      print('[WITHDRAW] Submitting withdrawal request...');

      // Build request body with backend-expected field names
      final requestBody = {
        'amount': amount,
        'method': _methodToBackend(selectedMethod),
        'pin': _pinCtrl.text.trim(),
      };

      // Add method-specific fields
      switch (selectedMethod) {
        case 'BANK':
          requestBody['accountName'] = _selectedBank ?? '';
          requestBody['accountNumber'] = _accountCtrl.text.trim();
          requestBody['bankName'] = _selectedBank ?? '';
          break;
        case 'MOBILE_MONEY':
          requestBody['phoneNumber'] = _mobileCtrl.text.trim();
          break;
        case 'CRYPTO':
          requestBody['cryptoAddress'] = _cryptoCtrl.text.trim();
          requestBody['network'] = _networkCtrl.text.trim();
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

      print('[WITHDRAW] Response Status: ${res.statusCode}');
      print('[WITHDRAW] Response: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        _snack(
          'Withdrawal request submitted successfully. Final processing will continue via Paystack webhook.',
        );
        _clearFields();
        await _fetchWallet();
        await _fetchHistory();
      } else {
        final errorMsg = data['message'] ?? data['error'] ?? 'Withdrawal failed. Please try again.';
        print('[WITHDRAW] Backend Error: $errorMsg');
        _snack(errorMsg);
      }
    } catch (e) {
      if (mounted) _snack('Network error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _clearFields() {
    _amountCtrl.clear();
    _accountCtrl.clear();
    _cryptoCtrl.clear();
    _mobileCtrl.clear();
    _pinCtrl.clear();
    setState(() => _selectedBank = null);
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
          color: selected ? context.background : context.surface,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: selected ? context.background : context.borderColor),
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
                          fontWeight: FontWeight.bold,
                          color: context.onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.onSurface.withOpacity(selected ? 0.7 : 0.6))),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: context.onSurface),
          ],
        ),
      ),
    );
  }

  // ── Notification settings ───────────────────────────────────────────────
  

  // ── Destination fields ────────────────────────────────────────────────────
  Widget _buildDestinationFields() {
    switch (selectedMethod) {
      case 'BANK':
        return Column(children: [
          // Bank dropdown
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.borderColor),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButton<String>(
              value: _selectedBank,
              hint: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Bank'),
              ),
              isExpanded: true,
              underline: const SizedBox(),
              items: kenyaBanks.map((bank) {
                return DropdownMenuItem(
                  value: bank,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(bank, style: GoogleFonts.plusJakartaSans()),
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedBank = value),
            ),
          ),
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
        return Column(
          children: [
            _inputField(controller: _cryptoCtrl, hint: 'Wallet Address'),
            const SizedBox(height: 12),
            _inputField(controller: _networkCtrl, hint: 'Network (e.g. TRON, BSC, ETH)'),
          ],
        );
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
      style: GoogleFonts.plusJakartaSans(color: context.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(color: context.textSecondary),
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
                  Text('Withdraw Funds',
                      style: GoogleFonts.plusJakartaSans(
                          color: context.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  FlutterFlowIconButton(
                    icon: Icon(Icons.info_outline, color: context.onSurface),
                    onPressed: () =>
                        _snack('Withdrawals are processed instantly.'),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Balance card
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: context.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: loadingWallet
                          ? Center(
                              child:
                                  CircularProgressIndicator(color: context.onSurface))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AVAILABLE BALANCE',
                                    style: GoogleFonts.plusJakartaSans(
                                        color: context.onSurface.withOpacity(0.7),
                                        fontSize: 11,
                                        letterSpacing: 1)),
                                const SizedBox(height: 8),
                                Text(
                                  '${walletBalance.toStringAsFixed(4)} FARM',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: context.onSurface,
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
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          Text('Withdrawal Amount',
                              style: GoogleFonts.plusJakartaSans(
                                  color: context.textSecondary, fontSize: 13)),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.plusJakartaSans(
                                color: context.onSurface,
                                fontSize: 36,
                                fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                                hintStyle: GoogleFonts.plusJakartaSans(
                                    color: context.textSecondary)),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Min: FARM 10',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: context.textSecondary, fontSize: 12)),
                              Text('Max: FARM 70,000',
                                  style: GoogleFonts.plusJakartaSans(
                                      color: context.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Method selection
                    Text('Select Method',
                        style: GoogleFonts.plusJakartaSans(
                            color: context.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    const SizedBox(height: 14),

                    _methodCard(
                        method: 'BANK',
                        icon: Icons.account_balance,
                        title: 'Bank Transfer',
                        subtitle: 'Instant • No fee'),
                    _methodCard(
                        method: 'MOBILE_MONEY',
                        icon: Icons.phone_android,
                        title: 'Mobile Money',
                        subtitle: 'Instant • No fee'),
                    _methodCard(
                        method: 'CRYPTO',
                        icon: Icons.currency_bitcoin,
                        title: 'Crypto Wallet',
                        subtitle: 'Near instant • No fee — via Ivorypay'),

                    const SizedBox(height: 20),

                    // Destination inputs
                    _buildDestinationFields(),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _pinCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      style: GoogleFonts.plusJakartaSans(color: context.onSurface),
                      decoration: InputDecoration(
                        hintText: 'Transaction PIN',
                        hintStyle: GoogleFonts.plusJakartaSans(color: context.textSecondary),
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
                        border: Border.all(color: context.borderColor),
                      ),
                      child: Column(
                        children: [
                          _feeRow('FARM Amount',
                              '${amount.toStringAsFixed(4)} FARM'),
                          const SizedBox(height: 12),
                          _feeRow(
                              'Fee (${(feeRate * 100).toStringAsFixed(1)}%)',
                              '${fee.toStringAsFixed(4)} FARM'),
                          const Divider(height: 24),
                          _feeRow(
                              'You Receive',
                              '${settlement.toStringAsFixed(4)} FARM',
                              bold: true),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const SizedBox(height: 28),
                    // Submit button
                    SizedBox(
                                        width: double.infinity,
                                        height: 58,
                                        child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed:
                            (isLoading || amount <= 0) ? null : _createWithdraw,
                        child: isLoading
                            ? CircularProgressIndicator(
                                color: context.onSurface)
                            : Text('Withdraw Funds',
                                style: GoogleFonts.plusJakartaSans(
                            color: FlutterFlowTheme.of(context).onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                      ),
                    ),
                  ],
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
                      onPressed: _fetchHistory, child: Text('Refresh')),
                ],
              ),

              const SizedBox(height: 14),

              if (loadingHistory)
                Center(child: CircularProgressIndicator())
              else if (history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Center(
                      child: Text('No withdrawal history',
                          style:
                              GoogleFonts.plusJakartaSans(color: context.textSecondary))),
                )
              else
                ...history.map((w) {
                  final meta = w['metadata'] as Map<String, dynamic>? ?? {};
                  final statusRaw = (w['status'] ?? 'pending').toString();
                  final status = statusRaw.toLowerCase();
                  final isComplete = status == 'completed' || status == 'success';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.borderColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
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
                            color: isComplete ? context.successColor : context.warningColor,
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
                              Text(status.toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12, color: context.textSecondary)),
                            ],
                          ),
                        ),
                        Text(
                          '-${w['amount']} FARM',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, color: context.errorColor),
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
