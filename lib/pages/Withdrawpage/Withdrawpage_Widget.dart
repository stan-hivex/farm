import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/services/api_service.dart';
// Removed unused import
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/kyc_required_widget.dart';
import '/services/app_session_manager.dart';
import '/services/transaction_authentication_service.dart';
import '/services/transaction_authorization_service.dart';

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
  final _walletCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _pinEntryEnabled = false;
  bool _isBiometricChecking = false;
  TransactionAuthenticationResult? _lastPinAuthResult;

  String selectedMethod = 'BANK';
  String selectedCurrency = 'KES';
  String selectedCryptoAsset = 'USDC';
  String? selectedCryptoNetwork;
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

  final List<String> cryptoAssets = ['USDC', 'USDT'];

  final Map<String, List<String>> cryptoNetworks = {
    'USDC': [
      'BNB Smart Chain (BEP20)',
      'Polygon',
      'Solana',
      'Base',
      'Starknet',
      'Algorand',
    ],
    'USDT': [
      'BNB Smart Chain (BEP20)',
      'Polygon',
      'Solana',
      'Starknet',
    ],
  };

  // Map user-facing display names to IvoryPay provider network codes per-token.
  // Backend/live discovery remains authoritative; this map only ensures
  // the frontend sends provider codes instead of display labels.
  final Map<String, Map<String, String>> tokenNetworkProviderCode = {
    'USDT': {
      'BNB Smart Chain (BEP20)': 'BSC_MAINNET',
      'Polygon': 'POLYGON',
      'Solana': 'SOLANA',
      'Starknet': 'STARKNET_MAINNET',
    },
    'USDC': {
      'BNB Smart Chain (BEP20)': 'BSC_MAINNET',
      'Polygon': 'POLYGON',
      'Solana': 'SOLANA',
      'Starknet': 'STARKNET_MAINNET',
    },
  };

  // Fee rates per method
  final Map<String, double> _fees = {
    'BANK': 0.0,
    'MOBILE_MONEY': 0.0,
    'CRYPTO': 0.0,
  };

  final Map<String, Map<String, double?>> _withdrawLimits = {
    'BANK': {'min': 4999, 'max': 999999},
    // Enforce mobile money minimum withdrawal per product requirement.
    'MOBILE_MONEY': {'min': 1499, 'max': 249999},
    'CRYPTO': {'min': 100, 'max': null},
  };

  double get amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  double get feeRate => _fees[selectedMethod] ?? 0.015;
  double get fee => amount * feeRate;
  double get settlement => amount - fee;
  double get _minimumWithdrawAmount => _withdrawLimits[selectedMethod]?['min'] ?? 10;
  double? get _maximumWithdrawAmount => _withdrawLimits[selectedMethod]?['max'];
  bool get _hasAmountValue => _amountCtrl.text.trim().isNotEmpty;
  String? get _amountValidationError {
    if (!_hasAmountValue) return null;
    if (amount <= 0) {
      return 'Enter a valid amount';
    }
    if (amount < _minimumWithdrawAmount) {
      return 'Minimum withdrawal is FARM ${_minimumWithdrawAmount.toStringAsFixed(0)}';
    }
    if (_maximumWithdrawAmount != null && amount > _maximumWithdrawAmount!) {
      return 'Maximum withdrawal is FARM ${_maximumWithdrawAmount!.toStringAsFixed(0)}';
    }
    if (amount > walletBalance) {
      return 'Insufficient FARM balance';
    }
    return null;
  }
  bool get _amountValid => _hasAmountValue && _amountValidationError == null;

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
    _walletCtrl.dispose();
    _mobileCtrl.dispose();
    _pinCtrl.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _promptBiometricForPinField() async {
    if (_lastPinAuthResult?.biometricUsed == true) {
      return;
    }

    try {
      setState(() => _isBiometricChecking = true);
      final authResult = await TransactionAuthorizationService()
          .authorizeTransaction(
            localizedReason: 'Confirm withdrawal',
          )
          .then((r) => r.toTransactionAuthenticationResult());

      if (authResult.biometricUsed) {
        if (!mounted) return;
        await _createWithdraw(skipConfirm: true, preAuthResult: authResult);
        return;
      }

      if (!mounted) return;
      setState(() {
        _lastPinAuthResult = authResult;
        _pinEntryEnabled = true;
      });
      _pinFocusNode.requestFocus();
    } finally {
      if (!mounted) return;
      setState(() => _isBiometricChecking = false);
    }
  }

  bool get isKycApproved {
    final status = FFAppState().kycStatus.trim().toLowerCase();
    return ['verified', 'approved', 'complete', 'success'].contains(status);
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
      final resp = await ApiService.getWallet();
      if (!mounted) return;
      final data = resp['data'] as Map<String, dynamic>? ?? resp;
      final bal = (data['available_balance'] ?? data['balance'] ?? 0).toString();
      setState(() => walletBalance = double.tryParse(bal) ?? 0);
    } catch (_) {
    } finally {
      if (mounted) setState(() => loadingWallet = false);
    }
  }

  // ── Fetch withdrawal history ─────────────────────────────────────────────
  Future<void> _fetchHistory() async {
    try {
      final resp = await ApiService.getWithdrawalHistory();
      if (!mounted) return;
      final items = resp['data'] is List ? resp['data'] as List : resp['data']?['withdrawals'] as List? ?? [];
      setState(() => history = items);
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
        return selectedCryptoAsset.isNotEmpty &&
            selectedCryptoNetwork != null &&
            _walletCtrl.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  // ── Submit withdrawal ─────────────────────────────────────────────────────
  Future<void> _createWithdraw(
      {bool skipConfirm = false,
      TransactionAuthenticationResult? preAuthResult}) async {
    if (isLoading) return;

    if (amount <= 0) {
      _snack('Enter a valid withdrawal amount');
      return;
    }
    if (amount < _minimumWithdrawAmount) {
      _snack('Minimum withdrawal is FARM ${_minimumWithdrawAmount.toStringAsFixed(0)}');
      return;
    }
    if (_maximumWithdrawAmount != null && amount > _maximumWithdrawAmount!) {
      _snack('Maximum withdrawal is FARM ${_maximumWithdrawAmount!.toStringAsFixed(0)}');
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

    if (!skipConfirm) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: Text(
              'Withdraw ${amount.toStringAsFixed(4)} FARM via ${selectedMethod.replaceAll('_', ' ')}?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(c).pop(false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.of(c).pop(true),
                child: const Text('Confirm')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => isLoading = true);

    try {
      print('[WITHDRAW] Submitting withdrawal request...');

      final authResult = preAuthResult ??
          _lastPinAuthResult ??
          await TransactionAuthorizationService()
              .authorizeTransaction(
                localizedReason: 'Confirm withdrawal',
              )
              .then((r) => r.toTransactionAuthenticationResult());

      final usedBiometric = authResult?.biometricUsed == true;
      if (usedBiometric) {
        final requestBody = {
          'amount': amount,
          'method': _methodToBackend(selectedMethod),
          'pin': null,
          'biometric_auth': true,
          'device_fingerprint': authResult?.deviceFingerprint,
        };

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
            requestBody['cryptoAsset'] = selectedCryptoAsset;
            requestBody['cryptoAddress'] = _walletCtrl.text.trim();
            // Convert user-facing display name into provider network code.
            final displayNetwork = selectedCryptoNetwork ?? '';
            final providerCode = tokenNetworkProviderCode[selectedCryptoAsset]?[displayNetwork] ?? displayNetwork;
            requestBody['network'] = providerCode;
            debugPrint('[WITHDRAW][CRYPTO] displayNetwork=$displayNetwork, providerCode=$providerCode, token=$selectedCryptoAsset');
            break;
        }

        await ApiService.request(
          method: 'POST',
          path: '/withdraw/create',
          body: requestBody,
        );

        if (mounted) {
          await AppSessionManager().syncNow(
            profileTimeoutSeconds: 5,
            walletTimeoutSeconds: 5,
            transactionsTimeoutSeconds: 5,
          );
          _snack('Withdrawal request submitted successfully');
        }
        return;
      }

      if (_pinCtrl.text.trim().isEmpty) {
        _snack('PIN is required to authorize withdrawal');
        return;
      }

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
          requestBody['cryptoAsset'] = selectedCryptoAsset;
          requestBody['cryptoAddress'] = _walletCtrl.text.trim();
          final displayNetwork = selectedCryptoNetwork ?? '';
          final providerCode = tokenNetworkProviderCode[selectedCryptoAsset]?[displayNetwork] ?? displayNetwork;
          requestBody['network'] = providerCode;
          debugPrint('[WITHDRAW][CRYPTO] displayNetwork=$displayNetwork, providerCode=$providerCode, token=$selectedCryptoAsset');
          break;
      }

      await ApiService.request(
        method: 'POST',
        path: '/withdraw/create',
        body: requestBody,
      );

      if (!mounted) return;

      await AppSessionManager().syncNow(
        profileTimeoutSeconds: 5,
        walletTimeoutSeconds: 5,
        transactionsTimeoutSeconds: 5,
      );
      _snack('Withdrawal submitted successfully.');
      _clearFields();
      await _fetchWallet();
      await _fetchHistory();
    } catch (e) {
      if (mounted) _snack('Network error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _clearFields() {
    _amountCtrl.clear();
    _accountCtrl.clear();
    _walletCtrl.clear();
    _mobileCtrl.clear();
    _pinCtrl.clear();
    setState(() {
      _selectedBank = null;
      selectedCryptoAsset = 'USDC';
      selectedCryptoNetwork = null;
    });
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
  Widget _methodCard(
    BuildContext context, {
    required String method,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = selectedMethod == method;
    final cardBackground = selected
        ? (isDark ? const Color(0xFF1F1F1F) : Colors.black)
        : theme.secondaryBackground;
    final cardBorder = selected
        ? (isDark ? const Color(0xFF2A2A2A) : Colors.black)
        : theme.secondaryText.withAlpha(90);
    final textColor = selected ? Colors.white : theme.primaryText;
    final subtitleColor = selected ? Colors.white70 : theme.secondaryText;

    return GestureDetector(
      onTap: () => setState(() => selectedMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, color: subtitleColor)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // ── Notification settings ───────────────────────────────────────────────

  // ── Destination fields ────────────────────────────────────────────────────
  Widget _buildDestinationFields() {
    final theme = FlutterFlowTheme.of(context);
    switch (selectedMethod) {
      case 'BANK':
        return Column(children: [
          // Bank dropdown
          Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              border: Border.all(color: theme.secondaryText.withAlpha(90)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButton<String>(
              value: _selectedBank,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Select Bank',
                    style: TextStyle(color: theme.secondaryText)),
              ),
              isExpanded: true,
              underline: const SizedBox(),
              items: kenyaBanks.map((bank) {
                return DropdownMenuItem(
                  value: bank,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(bank,
                        style: GoogleFonts.plusJakartaSans(
                            color: theme.primaryText)),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                border: Border.all(color: theme.secondaryText.withAlpha(90)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButton<String>(
                value: selectedCryptoAsset,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Crypto Asset',
                      style: TextStyle(color: theme.secondaryText)),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                items: cryptoAssets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(asset,
                          style: GoogleFonts.plusJakartaSans(
                              color: theme.primaryText)),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    selectedCryptoAsset = value;
                    selectedCryptoNetwork = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                border: Border.all(color: theme.secondaryText.withAlpha(90)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: DropdownButton<String>(
                value: selectedCryptoNetwork,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Network',
                      style: TextStyle(color: theme.secondaryText)),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                items: cryptoNetworks[selectedCryptoAsset]!
                    .map((network) => DropdownMenuItem(
                          value: network,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(network,
                                style: GoogleFonts.plusJakartaSans(
                                    color: theme.primaryText)),
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setState(() => selectedCryptoNetwork = value),
              ),
            ),
            const SizedBox(height: 12),
            _inputField(controller: _walletCtrl, hint: 'Wallet Address'),
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
      style: GoogleFonts.plusJakartaSans(
          color: FlutterFlowTheme.of(context).primaryText),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: FlutterFlowTheme.of(context).secondaryText),
        filled: true,
        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color:
                    FlutterFlowTheme.of(context).secondaryText.withAlpha(90))),
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
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!isKycApproved) {
      return Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: KycRequiredWidget(feature: 'withdraw'),
        ),
      );
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.primaryBackground,
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
                    onPressed: () => context.goNamed('Dashboard'),
                  ),
                  Text('Withdraw Funds',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText)),
                  FlutterFlowIconButton(
                    icon: Icon(Icons.info_outline, color: theme.secondaryText),
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
                      color: isDark ? const Color(0xFF111111) : Colors.black,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: loadingWallet
                        ? const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white))
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
                      border:
                          Border.all(color: theme.secondaryText.withAlpha(60)),
                    ),
                    child: Column(
                      children: [
                        Text('Withdrawal Amount',
                            style: GoogleFonts.plusJakartaSans(
                                color: theme.secondaryText, fontSize: 13)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: _amountValid || !_hasAmountValue
                                  ? theme.primaryText
                                  : Colors.red),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: theme.secondaryText),
                            helperText: _amountValidationError,
                            helperStyle: TextStyle(
                                color: _amountValid || !_hasAmountValue
                                    ? theme.secondaryText
                                    : Colors.red,
                                fontSize: 12),
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Min: FARM ${_minimumWithdrawAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                    color: theme.secondaryText, fontSize: 12)),
                            Text(
                                _maximumWithdrawAmount == null
                                    ? 'No max'
                                    : 'Max: FARM ${_maximumWithdrawAmount!.toStringAsFixed(0)}',
                                style: GoogleFonts.plusJakartaSans(
                                    color: theme.secondaryText, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Method selection
                  Text('Select Method',
                      style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: theme.primaryText)),
                  const SizedBox(height: 14),

                  _methodCard(context,
                      method: 'BANK',
                      icon: Icons.account_balance,
                      title: 'Bank Transfer',
                      subtitle: 'Instant'),
                  _methodCard(context,
                      method: 'MOBILE_MONEY',
                      icon: Icons.phone_android,
                      title: 'Mobile Money',
                      subtitle: 'Instant'),
                  _methodCard(context,
                      method: 'CRYPTO',
                      icon: Icons.currency_bitcoin,
                      title: 'Crypto Wallet',
                      subtitle: 'instant'),

                  const SizedBox(height: 20),

                  // Destination inputs
                  _buildDestinationFields(),

                  const SizedBox(height: 16),

                  if (_pinEntryEnabled)
                    TextField(
                      controller: _pinCtrl,
                      focusNode: _pinFocusNode,
                      readOnly: !_pinEntryEnabled || _isBiometricChecking,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      onTap: () async {
                        if (!_pinEntryEnabled && !_isBiometricChecking) {
                          await _promptBiometricForPinField();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Transaction PIN',
                        hintStyle: TextStyle(color: theme.secondaryText),
                        filled: true,
                        fillColor: theme.secondaryBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                              color: theme.secondaryText.withAlpha(90)),
                        ),
                        suffixIcon: _isBiometricChecking
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        counterText: '',
                      ),
                    )
                  else if (!_isBiometricChecking)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: (!_amountValid || isLoading)
                            ? null
                            : _promptBiometricForPinField,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? const Color(0xFF1F1F1F) : Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Continue',
                            style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Fee breakdown
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: theme.secondaryText.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        _feeRow(
                            'FARM Amount', '${amount.toStringAsFixed(4)} FARM'),
                        const SizedBox(height: 12),
                        _feeRow('Fee (${(feeRate * 100).toStringAsFixed(1)}%)',
                            '${fee.toStringAsFixed(4)} FARM'),
                        const Divider(height: 24),
                        _feeRow('You Receive',
                            '${settlement.toStringAsFixed(4)} FARM',
                            bold: true),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),
                  // Submit button
                  if (_pinEntryEnabled)
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isDark ? const Color(0xFF1F1F1F) : Colors.black,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: (isLoading || !_amountValid) ? null : _createWithdraw,
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('Withdraw Funds',
                                style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
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
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: theme.secondaryText.withAlpha(70)),
                  ),
                  child: Center(
                      child: Text('No withdrawal history',
                          style: GoogleFonts.plusJakartaSans(
                              color: theme.secondaryText))),
                )
              else
                ...history.map((w) {
                  final meta = w['metadata'] as Map<String, dynamic>? ?? {};
                  final statusRaw = (w['status'] ?? 'pending').toString();
                  final status = statusRaw.toLowerCase();
                  final isComplete =
                      status == 'completed' || status == 'success';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.secondaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: theme.secondaryText.withAlpha(70)),
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
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryText),
                              ),
                              Text(status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: theme.secondaryText)),
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
