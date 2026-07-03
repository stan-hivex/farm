import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '/app_state.dart';
import '/core/app_config.dart';
import '/backend/api_requests/api_manager.dart';
import '/pages/loginpage/loginpage_widget.dart';
import '/pages/superadmin/superadmin_wallet_page.dart';
import 'dart:convert';

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  static const String routeName = 'superadmin_dashboard';
  static const String routePath = '/superadmin/dashboard';

  @override
  State<SuperadminDashboardPage> createState() => _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage> {
  Map<String, dynamic>? _dashboardData;
  bool _loading = true;
  String? _error;

  bool _loadingExchangeRates = true;
  bool _savingExchangeRates = false;
  final TextEditingController _kesToFarmCtrl = TextEditingController();
  final TextEditingController _farmToKesCtrl = TextEditingController();

  List<dynamic> _systemUsers = [];
  bool _loadingUsers = true;
  String? _usersError;
  bool _processingUserAction = false;

  final _createAdminFormKey = GlobalKey<FormState>();
  final TextEditingController _adminFirstNameCtrl = TextEditingController();
  final TextEditingController _adminLastNameCtrl = TextEditingController();
  final TextEditingController _adminUsernameCtrl = TextEditingController();
  final TextEditingController _adminPhoneCtrl = TextEditingController();
  final TextEditingController _adminEmailCtrl = TextEditingController();
  final TextEditingController _adminCountryCtrl = TextEditingController();
  final TextEditingController _adminPasswordCtrl = TextEditingController();
  final TextEditingController _adminConfirmPasswordCtrl = TextEditingController();
  bool _isCreatingAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadExchangeRates();
    _loadUsers();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) {
        throw Exception('Not authenticated');
      }

      // Fetch dashboard data from backend
      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminDashboard',
        apiUrl: '${AppConfig.api}/superadmin/dashboard',
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
        throw Exception('Invalid dashboard response');
      }

      if (decoded['status'] == 'success' || decoded['data'] != null) {
        setState(() => _dashboardData = decoded['data'] ?? decoded);
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load dashboard');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _adminFirstNameCtrl.dispose();
    _adminLastNameCtrl.dispose();
    _adminUsernameCtrl.dispose();
    _adminPhoneCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminCountryCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _adminConfirmPasswordCtrl.dispose();
    _kesToFarmCtrl.dispose();
    _farmToKesCtrl.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await FFAppState().clearAuthCredentials();
    if (mounted) {
      context.go(LoginpageWidget.routePath);
    }
  }

  void _resetAdminForm() {
    _createAdminFormKey.currentState?.reset();
    _adminFirstNameCtrl.clear();
    _adminLastNameCtrl.clear();
    _adminUsernameCtrl.clear();
    _adminPhoneCtrl.clear();
    _adminEmailCtrl.clear();
    _adminCountryCtrl.clear();
    _adminPasswordCtrl.clear();
    _adminConfirmPasswordCtrl.clear();
  }

  Future<void> _loadExchangeRates() async {
    setState(() { _loadingExchangeRates = true; });
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) throw Exception('Not authenticated');

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminExchangeRates',
        apiUrl: '${AppConfig.api}/admin/exchange-rates',
        callType: ApiCallType.GET,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      if (decoded == null) throw Exception('Invalid exchange rate response');
      final rates = decoded['data'] as List<dynamic>? ?? [];

      String kesFarm = '1';
      String farmKes = '1';
      for (final item in rates) {
        final base = item['base_currency']?.toString().toUpperCase();
        final target = item['target_currency']?.toString().toUpperCase();
        final rate = item['rate']?.toString() ?? '';
        if (base == 'KES' && target == 'FARM') {
          kesFarm = rate;
        }
        if (base == 'FARM' && target == 'KES') {
          farmKes = rate;
        }
      }

      if (mounted) {
        _kesToFarmCtrl.text = kesFarm;
        _farmToKesCtrl.text = farmKes;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load exchange rates: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() { _loadingExchangeRates = false; });
    }
  }

  Future<void> _saveExchangeRates() async {
    if (_kesToFarmCtrl.text.isEmpty || _farmToKesCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both KES→FARM and FARM→KES rates')),
      );
      return;
    }

    setState(() { _savingExchangeRates = true; });
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) throw Exception('Not authenticated');

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminUpdateExchangeRates',
        apiUrl: '${AppConfig.api}/admin/exchange-rates',
        callType: ApiCallType.PUT,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        body: jsonEncode({
          'rates': [
            {
              'base_currency': 'KES',
              'target_currency': 'FARM',
              'rate': double.parse(_kesToFarmCtrl.text.trim()),
            },
            {
              'base_currency': 'FARM',
              'target_currency': 'KES',
              'rate': double.parse(_farmToKesCtrl.text.trim()),
            },
          ],
        }),
        bodyType: BodyType.JSON,
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      final message = decoded?['message'] ?? 'Exchange rates updated';
      if (!response.succeeded) throw Exception(message);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
      }
      await _loadExchangeRates();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exchange rates: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _savingExchangeRates = false; });
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) throw Exception('Not authenticated');

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminGetUsers',
        apiUrl: '${AppConfig.api}/admin/users?page=1',
        callType: ApiCallType.GET,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      setState(() {
        _systemUsers = decoded?['data'] as List<dynamic>? ?? [];
      });
    } catch (e) {
      setState(() => _usersError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loadingUsers = false);
    }
  }

  Future<void> _updateUser(String userId, Map<String, dynamic> payload) async {
    setState(() => _processingUserAction = true);
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) throw Exception('Not authenticated');

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminUpdateUser',
        apiUrl: '${AppConfig.api}/admin/users/$userId',
        callType: ApiCallType.PATCH,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        body: jsonEncode(payload),
        bodyType: BodyType.JSON,
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      final message = decoded?['message'] ?? 'User updated successfully';
      if (!response.succeeded) throw Exception(message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating user: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processingUserAction = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _processingUserAction = true);
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) throw Exception('Not authenticated');

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminDeleteUser',
        apiUrl: '${AppConfig.api}/admin/users/$userId',
        callType: ApiCallType.DELETE,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      final message = decoded?['message'] ?? 'User deleted successfully';
      if (!response.succeeded) throw Exception(message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      await _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _processingUserAction = false);
    }
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final firstName = TextEditingController(text: user['first_name'] ?? '');
    final lastName = TextEditingController(text: user['last_name'] ?? '');
    final email = TextEditingController(text: user['email'] ?? '');
    final phone = TextEditingController(text: user['phone'] ?? '');
    final country = TextEditingController(text: user['country'] ?? '');
    final username = TextEditingController(text: user['username'] ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit User', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstName,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: lastName,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (!value!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: country,
                  decoration: const InputDecoration(labelText: 'Country'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context);
              await _updateUser(user['id'], {
                'first_name': firstName.text.trim(),
                'last_name': lastName.text.trim(),
                'username': username.text.trim(),
                'email': email.text.trim(),
                'phone': phone.text.trim(),
                'country': country.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemUsersSection(Color cardColor, Color accent, Color muted) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Users',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.people, color: accent),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingUsers) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (_usersError != null) ...[
            Text(_usersError!, style: GoogleFonts.plusJakartaSans(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _loadUsers, style: ElevatedButton.styleFrom(backgroundColor: accent), child: Text('Retry', style: GoogleFonts.plusJakartaSans(color: Colors.black))),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _systemUsers.length,
              separatorBuilder: (_, __) => const Divider(color: Colors.white10),
              itemBuilder: (_, idx) {
                final user = _systemUsers[idx] as Map<String, dynamic>;
                final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  title: Text(name.isEmpty ? (user['username'] ?? 'Unknown') : name, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(user['email'] ?? '', style: GoogleFonts.plusJakartaSans(color: Colors.white54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70),
                        onPressed: _processingUserAction ? null : () => _showEditUserDialog(user),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: _processingUserAction
                            ? null
                            : () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm delete'),
                                    content: const Text('Are you sure you want to delete this user?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await _deleteUser(user['id']);
                                }
                              },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _createAdmin() async {
    setState(() => _isCreatingAdmin = true);
    try {
      final token = FFAppState().accessToken;
      if (token.isEmpty) {
        throw Exception('Not authenticated');
      }

      final body = jsonEncode({
        'first_name': _adminFirstNameCtrl.text.trim(),
        'last_name': _adminLastNameCtrl.text.trim(),
        'username': _adminUsernameCtrl.text.trim(),
        'phone': _adminPhoneCtrl.text.trim(),
        'email': _adminEmailCtrl.text.trim(),
        'country': _adminCountryCtrl.text.trim(),
        'password': _adminPasswordCtrl.text,
      });

      final response = await ApiManager.instance.makeApiCall(
        callName: 'superadminCreateAdmin',
        apiUrl: '${AppConfig.api}/admin/superadmin/create',
        callType: ApiCallType.POST,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        body: body,
        bodyType: BodyType.JSON,
        returnBody: true,
      );

      final decoded = response.jsonBody as Map<String, dynamic>?;
      final message = decoded?['message'] ?? 'Admin created successfully';

      if (response.succeeded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
        }
        _resetAdminForm();
        await _loadDashboardData();
        await _loadUsers();
      } else {
        throw Exception(message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingAdmin = false);
    }
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
                'Error loading dashboard',
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
                onPressed: _loadDashboardData,
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

    final data = _dashboardData ?? {};

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          edgeOffset: 0,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(accent, muted),
                const SizedBox(height: 28),
                _buildKPICards(data, cardColor, accent),
                const SizedBox(height: 28),
                _buildExchangeRatesSection(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildKYCEarnings(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildSystemHealth(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildMonitoringCards(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildAddAdminSection(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildSystemUsersSection(cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildRecentActivities(data, cardColor, muted),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, Color muted) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title column. On small screens show a visible logout button here.
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Superadmin Dashboard',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor all platform activities and metrics',
              style: GoogleFonts.plusJakartaSans(
                color: muted,
                fontSize: 13,
              ),
            ),
            if (isPhone) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: Tooltip(
                      message: 'Logout',
                      child: InkWell(
                        onTap: _logout,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.logout_rounded,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),

        // Right-side quick actions (wallet + logout). Shield icon removed.
        Row(
          children: [
            Material(
              color: Colors.transparent,
              child: Tooltip(
                message: 'Wallet',
                child: InkWell(
                  onTap: () => context.push(SuperadminWalletPage.routePath),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Keep the logout here for non-phone layouts as well.
            if (!isPhone)
              Material(
                color: Colors.transparent,
                child: Tooltip(
                  message: 'Logout',
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.logout_rounded,
                        color: Colors.red,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      filled: true,
      fillColor: const Color(0xFF111B2A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: Color(0xFF2A3F5F), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildAdminActivityCard(String title, String value, Color accent, Color cardColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddAdminSection(Map<String, dynamic> data, Color cardColor, Color accent, Color muted) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Admin',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create a new admin account and monitor approval activity.',
                    style: GoogleFonts.plusJakartaSans(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.admin_panel_settings_rounded,
                  color: accent,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _buildAdminActivityCard('Pending KYC', '${data['pending_kyc'] ?? 0}', accent, cardColor),
              const SizedBox(width: 12),
              _buildAdminActivityCard('Flagged Tx', '${data['flagged_transactions'] ?? 0}', Colors.orange, cardColor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAdminActivityCard('Open Tickets', '${data['support_tickets'] ?? 0}', Colors.blue, cardColor),
              const SizedBox(width: 12),
              _buildAdminActivityCard('Disputes', '${data['pending_disputes'] ?? 0}', Colors.red, cardColor),
            ],
          ),
          const SizedBox(height: 22),
          Form(
            key: _createAdminFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin details',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('First Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adminFirstNameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('First name'),
                            validator: (value) => value?.isEmpty ?? true ? 'First name is required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Last Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adminLastNameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Last name'),
                            validator: (value) => value?.isEmpty ?? true ? 'Last name is required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel('Username'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _adminUsernameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Username'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Username is required';
                    if (value!.length < 3) return 'Username must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adminEmailCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Email'),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Email is required';
                              if (!value!.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Phone'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adminPhoneCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Phone'),
                            keyboardType: TextInputType.phone,
                            validator: (value) => value?.isEmpty ?? true ? 'Phone is required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel('Country'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _adminCountryCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Country'),
                  validator: (value) => value?.isEmpty ?? true ? 'Country is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adminPasswordCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Password is required';
                              if (value!.length < 8) return 'Password must be at least 8 characters';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _adminConfirmPasswordCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Confirm Password'),
                            obscureText: true,
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Confirm password is required';
                              if (value != _adminPasswordCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isCreatingAdmin ? null : _createAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isCreatingAdmin
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                            ),
                          )
                        : Text(
                            'Create Admin',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(Map<String, dynamic> data, Color cardColor, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Performance Indicators',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          children: [
            _kpiCard('Total Users', '${data['total_users'] ?? 0}', 'users', accent, cardColor),
            _kpiCard('Total Revenue', '\$${data['total_revenue'] ?? 0}', 'revenue', accent, cardColor),
            _kpiCard('Active Transactions', '${data['active_transactions'] ?? 0}', 'pending', accent, cardColor),
            _kpiCard('System Health', '${data['system_health'] ?? 98}%', 'operational', accent, cardColor),
          ],
        ),
      ],
    );
  }

  Widget _kpiCard(String title, String value, String subtitle, Color accent, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.trending_up, size: 14, color: accent),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white54,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKYCEarnings(Map<String, dynamic> data, Color cardColor, Color accent, Color muted) {
    final totalEscrowEarnings = data['escrow_total_earnings'] ?? 0.0;
    final creationEarnings = data['escrow_creation_earnings'] ?? 0.0;
    final releaseEarnings = data['escrow_release_earnings'] ?? 0.0;
    final totalEscrowCount = data['total_escrow_count'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Escrow Revenue',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total KYC Earnings Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Escrow Earnings',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${totalEscrowEarnings.toStringAsFixed(2)} FARM',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From $totalEscrowCount escrow fees',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.verified_user_rounded,
                      color: accent,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Divider
              Divider(color: Colors.white10, thickness: 1),
              const SizedBox(height: 16),
              // Earnings Breakdown
              Row(
                children: [
                  Expanded(
                    child: _earningsBreakdownCard(
                      'Creation Fee',
                      '${creationEarnings.toStringAsFixed(2)} FARM',
                      '1.5% per escrow creation',
                      Colors.green,
                      cardColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _earningsBreakdownCard(
                      'Release Fee',
                      '${releaseEarnings.toStringAsFixed(2)} FARM',
                      '1.5% per escrow release',
                      Colors.blue,
                      cardColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _earningsBreakdownCard(String title, String amount, String description, Color colorAccent, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colorAccent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.plusJakartaSans(
              color: colorAccent,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemHealth(Map<String, dynamic> data, Color cardColor, Color accent, Color muted) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Health',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Operational',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _healthItem('API Servers', '99.8%', Colors.green, cardColor),
          const SizedBox(height: 12),
          _healthItem('Database', '99.9%', Colors.green, cardColor),
          const SizedBox(height: 12),
          _healthItem('Payment Gateway', '99.5%', Colors.green, cardColor),
          const SizedBox(height: 12),
          _healthItem('Storage', '98.7%', Colors.orange, cardColor),
        ],
      ),
    );
  }

  Widget _healthItem(String name, String status, Color statusColor, Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          name,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 13,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: GoogleFonts.plusJakartaSans(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeRatesSection(Map<String, dynamic> data, Color cardColor, Color accent, Color muted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Exchange Rates',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust the KES ⇄ FARM conversion rates used by wallet balance displays and payment calculations.',
            style: GoogleFonts.plusJakartaSans(color: muted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_loadingExchangeRates)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildRateField('KES → FARM', _kesToFarmCtrl, 'Example: 1.00', accent),
            const SizedBox(height: 16),
            _buildRateField('FARM → KES', _farmToKesCtrl, 'Example: 1.00', accent),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _savingExchangeRates ? null : _saveExchangeRates,
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: Text(
                    _savingExchangeRates ? 'Saving...' : 'Save Rates',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Changes here are reflected in user wallet balance interfaces and deposit/withdraw conversion calculations.',
                    style: GoogleFonts.plusJakartaSans(color: muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRateField(String label, TextEditingController controller, String hint, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.plusJakartaSans(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white30),
            filled: true,
            fillColor: const Color(0xFF0A121F),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: accent),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildMonitoringCards(Map<String, dynamic> data, Color cardColor, Color accent, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Platform Monitoring',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        _monitoringCard('Pending KYC Reviews', '${data['pending_kyc'] ?? 0}', accent, cardColor, Icons.verified_user),
        const SizedBox(height: 12),
        _monitoringCard('Flagged Transactions', '${data['flagged_transactions'] ?? 0}', accent, cardColor, Icons.warning_rounded),
        const SizedBox(height: 12),
        _monitoringCard('Support Tickets', '${data['support_tickets'] ?? 0}', accent, cardColor, Icons.support_agent),
        const SizedBox(height: 12),
        _monitoringCard('Pending Disputes', '${data['pending_disputes'] ?? 0}', accent, cardColor, Icons.gavel_rounded),
      ],
    );
  }

  Widget _monitoringCard(String title, String count, Color accent, Color cardColor, IconData icon) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count,
              style: GoogleFonts.plusJakartaSans(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(Map<String, dynamic> data, Color cardColor, Color muted) {
    final activities = data['recent_activities'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activities',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: activities.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'No recent activities',
                      style: GoogleFonts.plusJakartaSans(
                        color: muted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (activities.length > 5 ? 5 : activities.length),
                  separatorBuilder: (_, __) => Divider(
                    color: Colors.white10,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final activity = activities[index] as Map<String, dynamic>?;
                    return Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity?['description'] ?? 'Activity',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity?['timestamp'] ?? '',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              activity?['type'] ?? '',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
