import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/app_state.dart';
import '/core/app_config.dart';
import '/backend/api_requests/api_manager.dart';
import 'dart:convert';

class SuperadminWalletPage extends StatefulWidget {
  const SuperadminWalletPage({super.key});

  static const String routeName = 'superadmin_wallet';
  static const String routePath = '/superadmin/wallet';

  @override
  State<SuperadminWalletPage> createState() => _SuperadminWalletPageState();
}

class _SuperadminWalletPageState extends State<SuperadminWalletPage> {
  Map<String, dynamic>? _walletData;
  bool _loading = true;
  bool _loadingHistory = true;
  String? _error;
  String _selectedWithdrawalMethod = 'MOBILE_MONEY';
  String? _selectedBank;
  List<dynamic> _history = [];

  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _cryptoAddressController = TextEditingController();
  final _cryptoNetworkController = TextEditingController();
  final _pinController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _fetchWithdrawalHistory();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _cryptoAddressController.dispose();
    _cryptoNetworkController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = FFAppState().accessToken;

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

  Future<void> _processWithdrawal() async {
    if (_amountController.text.isEmpty || _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    try {
      final token = FFAppState().accessToken;

      final Map<String, dynamic> body = {
        'amount': double.parse(_amountController.text),
        'method': _selectedWithdrawalMethod,
        'pin': _pinController.text,
      };

      if (_selectedWithdrawalMethod == 'MOBILE_MONEY') {
        if (_phoneController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number required for mobile money')),
          );
          return;
        }
        body['phoneNumber'] = _phoneController.text;
      } else if (_selectedWithdrawalMethod == 'BANK_TRANSFER') {
        if (_selectedBank == null || _accountNumberController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bank and account number required for bank transfer')),
          );
          return;
        }
        body['bankName'] = _selectedBank;
        body['accountNumber'] = _accountNumberController.text;
      } else if (_selectedWithdrawalMethod == 'CRYPTO') {
        if (_cryptoAddressController.text.isEmpty || _cryptoNetworkController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crypto address and network required')),
          );
          return;
        }
        body['cryptoAddress'] = _cryptoAddressController.text;
        body['network'] = _cryptoNetworkController.text;
      }

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminWithdraw',
        apiUrl: '${AppConfig.api}/withdraw/create',
        callType: ApiCallType.POST,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
        bodyType: BodyType.JSON,
        params: {},
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      if (decoded == null || decoded['success'] != true) {
        throw Exception(decoded?['message'] ?? 'Withdrawal failed');
      }

      _clearWithdrawalForm();
      await _loadWalletData();
      await _fetchWithdrawalHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Withdrawal initiated: ${decoded['reference']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _fetchWithdrawalHistory() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      final token = FFAppState().accessToken;
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
    _accountNameController.clear();
    _accountNumberController.clear();
    _bankNameController.clear();
    _cryptoAddressController.clear();
    _cryptoNetworkController.clear();
    _pinController.clear();
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

    final balance = _walletData?['available_balance'] ?? _walletData?['balance'] ?? 0.0;
    final pendingWithdrawals = _walletData?['pending_withdrawals'] ?? 0.0;
    final totalWithdrawn = _walletData?['total_withdrawn'] ?? 0.0;
    final currency = _walletData?['currency'] ?? 'FARM';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
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
                                  color: isComplete ? Colors.green.withOpacity(0.15) : Colors.orange.withOpacity(0.15),
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
          colors: [accent.withOpacity(0.1), accent.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withOpacity(0.3)),
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
              color: accent.withOpacity(0.15),
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
      ('BANK_TRANSFER', 'Bank Transfer', Icons.account_balance_rounded),
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
          ] else if (_selectedWithdrawalMethod == 'BANK_TRANSFER') ...[
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
            _buildInputField('Wallet Address', _cryptoAddressController, 'Your wallet address', accent),
            const SizedBox(height: 14),
            _buildInputField('Network', _cryptoNetworkController, 'e.g. TRON, BSC, ETH', accent),
            const SizedBox(height: 14),
          ],

          _buildInputField('PIN', _pinController, 'Your transaction PIN', accent, isPassword: true),
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
            fillColor: Colors.white.withOpacity(0.05),
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
