import 'dart:async';
import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/app_state.dart';
import '/core/app_config.dart';
import '/backend/api_requests/api_manager.dart';
import '/pages/loginpage/loginpage_widget.dart';
import '/pages/superadmin/add_admin_page.dart';
import '/pages/superadmin/superadmin_wallet_page.dart';
import '/admin/pages/user_management_page.dart';
import '/services/auth/session_store_service.dart';
import '/admin/core/admin_navigation.dart';
import '/admin/services/admin_api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '/services/auth/auth_service.dart';

class SuperadminDashboardPage extends StatefulWidget {
  const SuperadminDashboardPage({super.key});

  static const String routeName = 'superadmin_dashboard';
  static const String routePath = '/superadmin/dashboard';

  @override
  State<SuperadminDashboardPage> createState() => _SuperadminDashboardPageState();
}

class _SuperadminDashboardPageState extends State<SuperadminDashboardPage>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _superadminWallet;
  bool _loading = true;
  String? _error;

  bool _loadingExchangeRates = true;
  bool _savingExchangeRates = false;
  final TextEditingController _kesToFarmCtrl = TextEditingController();
  final TextEditingController _farmToKesCtrl = TextEditingController();

  bool _isCreatingAdmin = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[SuperadminDashboardPage] initState: starting dashboard initialization');
    _loadDashboardData();
    _loadSuperadminWallet();
    _loadExchangeRates();
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _kesToFarmCtrl.dispose();
    _farmToKesCtrl.dispose();
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
          _loadDashboardData(),
          _loadSuperadminWallet(),
          _loadExchangeRates(),
        ]);
      }
    } catch (_) {}
  }

  Future<void> _loadSuperadminWallet() async {
    try {
      final token = await FFAppState().getActiveAccessToken();
      if (token.isEmpty) throw Exception('Not authenticated');

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
      if (decoded == null) throw Exception('Invalid wallet response');
      setState(() => _superadminWallet = decoded['data'] ?? decoded);
    } catch (e) {
      debugPrint('[SuperadminDashboardPage] _loadSuperadminWallet failed: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    debugPrint('[SuperadminDashboardPage] _loadDashboardData started');
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await FFAppState().getActiveAccessToken();
      debugPrint('[SuperadminDashboardPage] _loadDashboardData token length=${token.length}');
      if (token.isEmpty) {
        throw Exception('Not authenticated');
      }

      // Fetch dashboard data from backend
      debugPrint('[SuperadminDashboardPage] _loadDashboardData calling ${AppConfig.api}/superadmin/dashboard');
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
      debugPrint('[SuperadminDashboardPage] _loadDashboardData response status=${response.statusCode} body=${response.bodyText}');

      final decoded = response.jsonBody as Map<String, dynamic>?;
      if (decoded == null) {
        throw Exception('Invalid dashboard response');
      }

      if (decoded['status'] == 'success' || decoded['data'] != null) {
        setState(() => _dashboardData = decoded['data'] ?? decoded);
      } else {
        throw Exception(decoded['message'] ?? 'Failed to load dashboard');
      }
    } catch (e, st) {
      debugPrint('[SuperadminDashboardPage] _loadDashboardData failed: $e');
      debugPrint(st.toString());
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
      // Refresh superadmin wallet info when dashboard refresh completes
      _loadSuperadminWallet();
    }
  }

  Widget _wrapWithWillPop(Widget child) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          return;
        }
        if (kIsWeb) {
          Navigator.of(context).maybePop();
          return;
        }
        try {
          await SystemNavigator.pop();
        } catch (_) {}
      },
      child: child,
    );
  }

  Future<void> _logout() async {
    debugPrint('[SuperadminDashboardPage] _logout called');
    try {
      await AuthService().logout();
    } catch (e) {
      debugPrint('[SuperadminDashboardPage] logout error: $e');
    }
    if (mounted) {
      AuthNavigation.replaceAllWithBuilder(
        context,
        (_) => LoginpageWidget(),
      );
    }
  }

  Future<void> _loadExchangeRates() async {
    setState(() { _loadingExchangeRates = true; });
    try {
      final token = await FFAppState().getActiveAccessToken();
      debugPrint('[SuperadminDashboardPage] _loadExchangeRates token length=${token.length}');
      if (token.isEmpty) throw Exception('Not authenticated');

      debugPrint('[SuperadminDashboardPage] _loadExchangeRates calling ${AppConfig.api}/admin/exchange-rates');
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
    } catch (e, st) {
      debugPrint('[SuperadminDashboardPage] _loadExchangeRates failed: $e');
      debugPrint(st.toString());
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
      final token = await FFAppState().getActiveAccessToken();
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
        body: convert.jsonEncode({
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

  Future<void> _openSystemUsersPage() async {
    if (!mounted) return;
    context.push(UserManagementPage.routePath);
  }

  Widget _buildSystemUsersCard(Color cardColor, Color accent, Color muted) {
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
                    'System Users',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Open the dedicated users page to manage accounts, roles, and KYC statuses.',
                    style: GoogleFonts.plusJakartaSans(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Icon(Icons.people, color: accent),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openSystemUsersPage,
              icon: const Icon(Icons.open_in_new_rounded, color: Colors.black),
              label: Text('Open System Users',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddAdminPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddAdminPage()),
    );
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0B1320);
    final cardColor = const Color(0xFF111B2A);
    final accent = const Color(0xFFD4AF37);
    final muted = Colors.white70;

    if (_loading) {
      return _wrapWithWillPop(Scaffold(
        backgroundColor: bgColor,
        body: const Center(child: CircularProgressIndicator()),
      ));
    }

    if (_error != null) {
      return _wrapWithWillPop(Scaffold(
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
      ));
    }

    final data = _dashboardData ?? {};

    return _wrapWithWillPop(Scaffold(
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
                _buildSuperadminFees(_superadminWallet, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildKYCEarnings(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildSystemHealth(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildMonitoringCards(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildAddAdminSection(data, cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildSystemUsersCard(cardColor, accent, muted),
                const SizedBox(height: 28),
                _buildRecentActivities(data, cardColor, muted),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    ));
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
                  onTap: () {
                    debugPrint('[SuperadminDashboardPage] wallet icon tapped');
                    context.go(SuperadminWalletPage.routePath);
                  },
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
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isCreatingAdmin ? null : _openAddAdminPage,
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.black),
              label: Text('Create Admin', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _openSystemUsersPage,
              icon: const Icon(Icons.people_rounded, color: Colors.black),
              label: Text('System Users', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
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
    final creationEarnings = data['escrow_creation_earnings'] ?? 0.0;
    final releaseEarnings = data['escrow_release_earnings'] ?? 0.0;
    final withdrawEarnings = data['withdraw_fee_earnings'] ?? 0.0;
    final creationCount = data['escrow_creation_count'] ?? 0;
    final releaseCount = data['escrow_release_count'] ?? 0;
    final withdrawCount = data['withdraw_transaction_count'] ?? data['withdraw_count'] ?? 0;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Platform fee breakdown',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      color: accent,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _earningsBreakdownCard(
                      'Creation Fee',
                      '${creationEarnings.toStringAsFixed(2)} FARM',
                      'From $creationCount escrow creations',
                      Colors.green,
                      cardColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _earningsBreakdownCard(
                      'Release Fee',
                      '${releaseEarnings.toStringAsFixed(2)} FARM',
                      'From $releaseCount escrow releases',
                      Colors.blue,
                      cardColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _earningsBreakdownCard(
                'Withdraw Fee',
                '${withdrawEarnings.toStringAsFixed(2)} FARM',
                'From $withdrawCount withdraws',
                Colors.purple,
                cardColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuperadminFees(Map<String, dynamic>? wallet, Color cardColor, Color accent, Color muted) {
    final balance = wallet == null ? 0.0 : (wallet['available_balance'] ?? wallet['balance'] ?? 0.0);
    final displayBalance = (balance is num) ? (balance).toDouble() : double.tryParse(balance.toString()) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Revenues',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => context.go(SuperadminWalletPage.routePath),
          child: Container(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Escrow + Withdrawals',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${displayBalance.toStringAsFixed(2)} FARM',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Operations wallet balance',
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
                    Icons.account_balance_wallet_rounded,
                    color: accent,
                    size: 28,
                  ),
                ),
              ],
            ),
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
