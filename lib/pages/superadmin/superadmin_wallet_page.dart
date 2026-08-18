import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/app_state.dart';
import '/core/app_config.dart';
import '/backend/api_requests/api_manager.dart';
import '/pages/superadmin/superadmin_dashboard_page.dart';
import '/pages/superadmin/superadmin_pin_setup_page.dart';
import '/pages/superadmin/superadmin_change_pin_page.dart';
import '/services/app_session_manager.dart';
import '/admin/services/admin_api_service.dart';
import '/services/transaction_authentication_service.dart';
import '/services/transaction_authorization_service.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SuperadminWalletPage extends StatefulWidget {
  const SuperadminWalletPage({super.key});

  static const String routeName = 'superadmin_wallet';
  static const String routePath = '/superadmin/wallet';

  @override
  State<SuperadminWalletPage> createState() => _SuperadminWalletPageState();
}

class _SuperadminWalletPageState extends State<SuperadminWalletPage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _walletData;
  bool _loading = true;
  bool _loadingHistory = true;
  String? _error;
  String _selectedWithdrawalMethod = 'MOBILE_MONEY';
  String? _selectedBank;
  String _selectedCryptoAsset = 'USDC';
  String? _selectedCryptoNetwork;
  List<dynamic> _history = [];

  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _cryptoAddressController = TextEditingController();
  final _cryptoNetworkController = TextEditingController();
  final _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  bool _pinEntryEnabled = false;
  bool _isBiometricChecking = false;
  TransactionAuthenticationResult? _lastPinAuthResult;

  final List<String> _banks = [
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

  final List<String> _cryptoAssets = ['USDC', 'USDT'];

  final Map<String, List<String>> _cryptoNetworks = {
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
  final Map<String, Map<String, String>> _tokenNetworkProviderCode = {
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

  final Map<String, Map<String, double?>> _withdrawLimits = {
    'BANK': {'min': 4999, 'max': 999999},
    // Superadmin UI uses same limits; enforce mobile money min = 1499
    'MOBILE_MONEY': {'min': 1499, 'max': 249999},
    'CRYPTO': {'min': 100, 'max': null},
  };

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  Map<String, double?> get _activeWithdrawLimits =>
      _withdrawLimits[_selectedWithdrawalMethod] ?? _withdrawLimits['BANK']!;

  double get _activeWithdrawMin => _activeWithdrawLimits['min'] ?? 10;

  double? get _activeWithdrawMax => _activeWithdrawLimits['max'];

  bool get _hasValidWithdrawAmount =>
      _amount > 0 &&
      _amount >= _activeWithdrawMin &&
      (_activeWithdrawMax == null || _amount <= _activeWithdrawMax!);

  String get _withdrawValidationMessage {
    if (_amount <= 0) {
      return 'Range: FARM ${_formatAmount(_activeWithdrawMin)}${_activeWithdrawMax == null ? '+' : ' - FARM ${_formatAmount(_activeWithdrawMax!)}'}';
    }
    if (_hasValidWithdrawAmount) {
      return 'Range: FARM ${_formatAmount(_activeWithdrawMin)}${_activeWithdrawMax == null ? '+' : ' - FARM ${_formatAmount(_activeWithdrawMax!)}'}';
    }
    final maxText = _activeWithdrawMax == null
        ? ' and above'
        : ' and FARM ${_formatAmount(_activeWithdrawMax!)}';
    return 'Amount must be between FARM ${_formatAmount(_activeWithdrawMin)}$maxText';
  }

  String _methodToBackend(String method) {
    return method == 'BANK' ? 'BANK_TRANSFER' : method;
  }

  String _formatAmount(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWalletData();
    _fetchWithdrawalHistory();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _amountController.dispose();
    _phoneController.dispose();
    _accountNumberController.dispose();
    _cryptoAddressController.dispose();
    _cryptoNetworkController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startPeriodicRefresh();
      unawaited(_refreshSessionAndReload());
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _refreshTimer?.cancel();
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (!mounted) return;
      unawaited(_refreshSessionAndReload());
    });
  }

  Future<void> _refreshSessionAndReload() async {
    if (!mounted) return;
    try {
      final refreshed = await AdminApiService.ensureValidSession(force: true);
      if (refreshed) {
        await Future.wait([
          _loadWalletData(),
          _fetchWithdrawalHistory(),
        ]);
      }
    } catch (_) {}
  }

  Future<void> _promptBiometricForPinField() async {
    if (_lastPinAuthResult?.biometricUsed == true) {
      return;
    }

    try {
      setState(() => _isBiometricChecking = true);
      final authResult = await TransactionAuthorizationService().authorizeTransaction(
        localizedReason: 'Confirm withdrawal',
      ).then((r) => r.toTransactionAuthenticationResult());

      if (authResult.biometricUsed) {
        if (!mounted) return;
        await _processWithdrawal(preAuthResult: authResult);
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

  Future<void> _loadWalletData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await FFAppState().getActiveAccessToken();

      if (token.isEmpty) {
        throw Exception('Not authenticated');
      }

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminWallet',
        apiUrl: '${AppConfig.api}/admin/wallet',
        callType: ApiCallType.GET,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      if (decoded == null) {
        throw Exception('Invalid wallet response');
      }

      setState(() => _walletData = decoded['data'] ?? decoded);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _processWithdrawal({bool skipConfirm = false, TransactionAuthenticationResult? preAuthResult}) async {
    if (!_hasValidWithdrawAmount) {
      _snack(_withdrawValidationMessage);
      return;
    }

    if (!_isDestinationValid()) {
      _snack('Please complete your withdrawal destination');
      return;
    }

    if (!skipConfirm) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: Text(
            'Withdraw ${_amount.toStringAsFixed(4)} FARM via ${_selectedWithdrawalMethod.replaceAll('_', ' ')}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(c).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      final authResult = preAuthResult ??
          _lastPinAuthResult ??
          await TransactionAuthorizationService()
              .authorizeTransaction(
                localizedReason: 'Confirm withdrawal',
              )
              .then((r) => r.toTransactionAuthenticationResult());

      final usedBiometric = authResult?.biometricUsed == true;
      final token = await FFAppState().getActiveAccessToken();
      final body = {
        'amount': _amount,
        'method': _methodToBackend(_selectedWithdrawalMethod),
        'pin': usedBiometric ? null : _pinController.text.trim(),
      };

      if (usedBiometric) {
        body['biometric_auth'] = true;
        body['device_fingerprint'] = authResult?.deviceFingerprint;
      }

      switch (_selectedWithdrawalMethod) {
        case 'BANK':
          body['accountName'] = _selectedBank ?? '';
          body['bankName'] = _selectedBank ?? '';
          body['accountNumber'] = _accountNumberController.text.trim();
          break;
        case 'MOBILE_MONEY':
          body['phoneNumber'] = _phoneController.text.trim();
          break;
        case 'CRYPTO':
          body['cryptoAddress'] = _cryptoAddressController.text.trim();
          body['cryptoAsset'] = _selectedCryptoAsset;
          final displayNetwork = _cryptoNetworkController.text.trim();
          final providerCode = _tokenNetworkProviderCode[_selectedCryptoAsset]?[displayNetwork] ?? displayNetwork;
          body['network'] = providerCode;
          debugPrint('[SUPERADMIN][WITHDRAW][CRYPTO] displayNetwork=$displayNetwork, providerCode=$providerCode, token=$_selectedCryptoAsset');
          break;
      }

      if (usedBiometric) {
        if (_selectedWithdrawalMethod == 'MOBILE_MONEY' && _phoneController.text.isEmpty) {
          _snack('Phone number required for mobile money');
          return;
        }
        if (_selectedWithdrawalMethod == 'BANK' && (_selectedBank == null || _accountNumberController.text.isEmpty)) {
          _snack('Bank and account number required for bank transfer');
          return;
        }
        if (_selectedWithdrawalMethod == 'CRYPTO' && (_cryptoAddressController.text.isEmpty || _cryptoNetworkController.text.isEmpty)) {
          _snack('Crypto address and network required');
          return;
        }
      } else {
        if (_pinController.text.trim().isEmpty) {
          _snack('PIN is required to authorize withdrawal');
          return;
        }
      }

      final response = await http.post(
        Uri.parse('${AppConfig.api}/withdraw/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final decoded = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await AppSessionManager().syncNow(
          profileTimeoutSeconds: 5,
          walletTimeoutSeconds: 5,
          transactionsTimeoutSeconds: 5,
        );
        _clearWithdrawalForm();
        await _loadWalletData();
        await _fetchWithdrawalHistory();
        _snack('Withdrawal request submitted successfully');
      } else {
        final errorMsg = decoded is Map<String, dynamic>
            ? decoded['message'] ?? decoded['error'] ?? 'Withdrawal failed'
            : 'Withdrawal failed';
        _snack(errorMsg.toString());
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  bool _isDestinationValid() {
    switch (_selectedWithdrawalMethod) {
      case 'BANK':
        return _selectedBank != null && _accountNumberController.text.isNotEmpty;
      case 'MOBILE_MONEY':
        return _phoneController.text.trim().isNotEmpty;
      case 'CRYPTO':
        return _selectedCryptoAsset.isNotEmpty &&
            _selectedCryptoNetwork?.trim().isNotEmpty == true &&
            _cryptoAddressController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _fetchWithdrawalHistory() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      final token = await FFAppState().getActiveAccessToken();
      if (token.isEmpty) throw Exception('Not authenticated');

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminWithdrawHistory',
        apiUrl: '${AppConfig.api}/withdraw/history',
        callType: ApiCallType.GET,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        returnBody: true,
      );

      final decoded = response.jsonBody;
      if (decoded == null) throw Exception('Invalid withdraw history response');

      final data = decoded is Map<String, dynamic>
          ? decoded['data'] ?? decoded['withdrawals'] ?? []
          : decoded;

      setState(() => _history = List<dynamic>.from(data as List));
    } catch (_) {
      setState(() => _history = []);
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _clearWithdrawalForm() {
    _amountController.clear();
    _phoneController.clear();
    _accountNumberController.clear();
    _cryptoAddressController.clear();
    _cryptoNetworkController.clear();
    _pinController.clear();
    setState(() {
      _selectedBank = null;
      _selectedCryptoAsset = 'USDC';
      _selectedCryptoNetwork = null;
    });
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return '';
    final dateString = dateValue.toString();
    final date = DateTime.tryParse(dateString);
    if (date != null) {
      final y = date.year.toString().padLeft(4, '0');
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }
    return dateString.split('T').first;
  }

  String _resolveHistoryMethod(Map<String, dynamic> item) {
    final rawMethod = item['method'] ?? item['payment_method'] ?? item['withdrawal_method'] ?? item['metadata']?['method'] ?? item['metadata']?['payment_method'];
    if (rawMethod == null) return 'Unknown';
    return rawMethod.toString().replaceAll('_', ' ').toUpperCase();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0B1320);
    final cardColor = const Color(0xFF111B2A);
    final accent = const Color(0xFFD4AF37);
    final muted = Colors.white70;

    if (_loading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error loading wallet',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: muted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadWalletData,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: Text(
                  'Retry',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final balance = _toDouble(_walletData?['available_balance'] ?? _walletData?['balance'] ?? 0.0);
    final pendingWithdrawals = _toDouble(_walletData?['pending_withdrawals'] ?? 0.0);
    final totalWithdrawn = _toDouble(_walletData?['total_withdrawn'] ?? 0.0);
    final currency = _walletData?['currency'] ?? 'FARM';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
              return;
            }
            context.go(SuperadminDashboardPage.routePath);
          },
        ),
        title: Text(
          'Superadmin Wallet',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              _buildBalanceCard(balance, pendingWithdrawals, currency, accent, cardColor, muted),
              const SizedBox(height: 24),

              // Withdrawal Stats
              _buildWithdrawalStats(totalWithdrawn, currency, accent, cardColor, muted),
              const SizedBox(height: 20),

              // Superadmin PIN Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Actions',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push(SuperadminPinSetupPage.routePath),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Create PIN',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.push(SuperadminChangePinPage.routePath),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white12,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Change PIN',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Withdrawal Method Selection
              Text(
                'Withdraw Funds',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),

              // Method Selection Tabs
              _buildMethodTabs(accent, cardColor),
              const SizedBox(height: 16),

              // Dynamic Form Fields
              _buildWithdrawalForm(accent, cardColor, muted),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _processWithdrawal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Withdraw Funds',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Withdrawal History
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Withdrawal History',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextButton(
                    onPressed: _fetchWithdrawalHistory,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_loadingHistory)
                const Center(child: CircularProgressIndicator())
              else if (_history.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    'No withdrawal history available',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white54),
                  ),
                )
              else
                Column(
                  children: _history.map((item) {
                    final statusRaw = (item['status'] ?? 'pending').toString();
                    final status = statusRaw.toLowerCase();
                    final isComplete = status == 'completed' || status == 'success';
                    final method = _resolveHistoryMethod(item as Map<String, dynamic>);
                    final date = _formatDate(item['created_at'] ?? item['createdAt'] ?? item['processed_at'] ?? item['date']);
                    final amount = item['amount'] ?? item['settlement'] ?? item['balance'] ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                method,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                date,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'FARM ${double.tryParse(amount.toString())?.toStringAsFixed(4) ?? amount.toString()}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isComplete ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: isComplete ? Colors.greenAccent : Colors.orangeAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, double pending, String currency, Color accent, Color cardColor, Color muted) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.1), accent.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available Balance',
            style: GoogleFonts.plusJakartaSans(
              color: muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${currency.toUpperCase()} ${balance.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currency.toUpperCase()} ${pending.toStringAsFixed(2)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.orange,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalStats(double totalWithdrawn, String currency, Color accent, Color cardColor, Color muted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Withdrawn',
                style: GoogleFonts.plusJakartaSans(
                  color: muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${currency.toUpperCase()} ${totalWithdrawn.toStringAsFixed(2)}',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.account_balance_wallet_rounded, color: accent, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTabs(Color accent, Color cardColor) {
    final methods = [
      ('MOBILE_MONEY', 'Mobile Money', Icons.phone_android_rounded),
      ('BANK', 'Bank Transfer', Icons.account_balance_rounded),
      ('CRYPTO', 'Crypto', Icons.currency_bitcoin_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: methods.map((method) {
          final isSelected = _selectedWithdrawalMethod == method.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedWithdrawalMethod = method.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? accent : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? accent : Colors.white10,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      method.$3,
                      color: isSelected ? Colors.black : accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      method.$2,
                      style: GoogleFonts.plusJakartaSans(
                        color: isSelected ? Colors.black : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWithdrawalForm(Color accent, Color cardColor, Color muted) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInputField('Amount (FARM)', _amountController, 'Enter amount', accent, isNumeric: true),
          const SizedBox(height: 14),

          if (_selectedWithdrawalMethod == 'MOBILE_MONEY') ...[
            _buildInputField('Phone Number', _phoneController, 'e.g. +254712345678', accent),
            const SizedBox(height: 14),
          ] else if (_selectedWithdrawalMethod == 'BANK') ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(14),
                color: cardColor,
              ),
              child: DropdownButton<String>(
                value: _selectedBank,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Bank', style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: cardColor,
                items: _banks.map((bank) {
                  return DropdownMenuItem(
                    value: bank,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(bank, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedBank = value),
              ),
            ),
            const SizedBox(height: 14),
            _buildInputField('Account Number', _accountNumberController, 'Bank account number', accent),
            const SizedBox(height: 14),
          ] else if (_selectedWithdrawalMethod == 'CRYPTO') ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(14),
                color: cardColor,
              ),
              child: DropdownButton<String>(
                value: _selectedCryptoAsset,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Crypto Asset', style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: cardColor,
                items: _cryptoAssets.map((asset) {
                  return DropdownMenuItem(
                    value: asset,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(asset, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedCryptoAsset = value;
                    _selectedCryptoNetwork = null;
                  });
                },
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10),
                borderRadius: BorderRadius.circular(14),
                color: cardColor,
              ),
              child: DropdownButton<String>(
                value: _selectedCryptoNetwork,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Select Network', style: GoogleFonts.plusJakartaSans(color: Colors.white70)),
                ),
                isExpanded: true,
                underline: const SizedBox(),
                dropdownColor: cardColor,
                items: _cryptoNetworks[_selectedCryptoAsset]!.map((network) {
                  return DropdownMenuItem(
                    value: network,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(network, style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedCryptoNetwork = value),
              ),
            ),
            const SizedBox(height: 14),
            _buildInputField('Crypto Address', _cryptoAddressController, 'Your wallet address', accent),
            const SizedBox(height: 14),
          ],

          if (_pinEntryEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PIN',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  readOnly: !_pinEntryEnabled || _isBiometricChecking,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'Your transaction PIN',
                    hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.white10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: accent),
                    ),
                    suffixIcon: _isBiometricChecking
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                  ),
                  onTap: () async {
                    if (!_pinEntryEnabled && !_isBiometricChecking) {
                      await _promptBiometricForPinField();
                    }
                  },
                ),
              ],
            )
          else if (!_isBiometricChecking)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _promptBiometricForPinField,
                child: const Text('Continue'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, Color accent,
      {bool isPassword = false, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: accent),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
