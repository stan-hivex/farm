import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../core/admin_guard.dart';
import '../core/admin_navigation.dart';
import '../services/admin_api_service.dart';
import '/services/auth/auth_service.dart';
import '/pages/loginpage/loginpage_widget.dart';
import 'add_superadmin_page.dart';
import 'deposits_management_page.dart';
import 'escrow_management_page.dart';
import 'notifications_management_page.dart';
import 'user_management_page.dart';
import 'withdrawals_management_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const AdminDashboardPage({super.key, this.onGoBack});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic> _stats = <String, dynamic>{};
  bool _loading = true;
  String? _error;
  String _adminName = 'Admin';
  String _adminRole = 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
      _stats = <String, dynamic>{};
    });

    debugPrint('Loading admin profile...');
    try {
      _adminName = await AdminGuard.getAdminName();
      _adminRole = await AdminGuard.getAdminRole();
      debugPrint('Current admin = $_adminName');
      debugPrint('Permissions = $_adminRole');
    } catch (e) {
      debugPrint('Admin profile load failed: $e');
      _adminName = 'Admin';
      _adminRole = 'admin';
    }

    debugPrint('Loading dashboard statistics...');
    try {
      final res = await AdminApiService.getDashboardStats();
      final normalized = _normalizeDashboardPayload(res);
      if (normalized.isEmpty) {
        throw Exception('Dashboard payload was empty or malformed.');
      }
      if (!mounted) return;
      setState(() {
        _stats = normalized;
      });
      debugPrint('Dashboard statistics loaded.');
      debugPrint('Stats payload = $_stats');
    } catch (e) {
      debugPrint('Dashboard statistics load failed: $e');
      if (mounted) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic> _normalizeDashboardPayload(dynamic payload) {
    if (payload is! Map<String, dynamic> && payload is! Map) {
      debugPrint('Dashboard payload was not a map: ${payload.runtimeType}');
      return <String, dynamic>{};
    }

    final root = payload is Map<String, dynamic>
        ? payload
        : Map<String, dynamic>.from(payload as Map<dynamic, dynamic>);
    final maybeData = root['data'];
    if (maybeData is Map<String, dynamic>) {
      return maybeData;
    }
    if (maybeData is Map) {
      return Map<String, dynamic>.from(maybeData);
    }

    debugPrint('Dashboard payload did not contain a usable data map.');
    return <String, dynamic>{};
  }

  void _navigateTo(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading dashboard data...',
                style: GoogleFonts.plusJakartaSans(
                  color: context.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return _errorView(_error ?? 'Unable to load dashboard data.');
    }

    final s = _stats;
    final bgColor = Colors.white;
    final cardColor = Colors.white;
    final accent = const Color(0xFFEAF2FF);
    final muted = context.onSurface.withOpacity(0.7);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          edgeOffset: 0,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(accent, muted),
                const SizedBox(height: 24),
                _buildOverviewRow(s, cardColor, accent),
                const SizedBox(height: 24),
                _buildAnalyticsCard(cardColor, accent),
                const SizedBox(height: 24),
                _buildQuickActions(cardColor, accent),
                const SizedBox(height: 24),
                _buildTransactionsSection(cardColor, muted),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, Color muted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withAlpha((0.16 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('FARM',
                    style: GoogleFonts.plusJakartaSans(
                        color: accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 14),
              Text('Admin Dashboard',
                  style: GoogleFonts.plusJakartaSans(
                      color: context.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(
                'Signed in as $_adminName ($_adminRole)',
                style: GoogleFonts.plusJakartaSans(
                  color: muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A unified admin control panel for users, deposits, withdrawals, and compliance.',
                style: GoogleFonts.plusJakartaSans(
                    color: muted, fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () async {
                try {
                  await AuthService().logout();
                } catch (_) {}
                if (!mounted) return;
                AuthNavigation.replaceAllWithBuilder(
                  context,
                  (_) => LoginpageWidget(),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 22,
              backgroundColor: context.onSurface,
              child: Text('AD',
                  style: GoogleFonts.plusJakartaSans(
                      color: context.background,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewRow(
      Map<String, dynamic> s, Color cardColor, Color accent) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.55,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _metricCard('Total Users', '${s['total_users'] ?? 0}', 'Active people',
            cardColor, accent),
        _metricCard('Active Escrows', '${s['active_escrows'] ?? 0}',
            'Escrow flows', cardColor, accent),
        _metricCard('Pending KYC', '${s['pending_kyc'] ?? 0}', 'Review queue',
            cardColor, accent),
        _metricCard('Pending Payouts', '${s['pending_payouts'] ?? 0}',
            'Awaiting settlement', cardColor, accent),
      ],
    );
  }

  Widget _metricCard(String title, String value, String caption,
      Color cardColor, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.onSurface.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
              color: context.background.withAlpha((0.18 * 255).round()),
              blurRadius: 18,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.plusJakartaSans(
                      color: context.onSurface.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withAlpha((0.12 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.trending_up_rounded, size: 18, color: accent),
              ),
            ],
          ),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                  color: context.onSurface,
                  fontSize: 26,
                  fontWeight: FontWeight.w900)),
          Text(caption,
              style: GoogleFonts.plusJakartaSans(
                  color: context.onSurface.withOpacity(0.54), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(Color cardColor, Color accent) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
              color: context.background.withAlpha((0.14 * 255).round()),
              blurRadius: 18,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Revenue Overview',
                      style: GoogleFonts.plusJakartaSans(
                          color: context.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Last 7 days performance',
                      style: GoogleFonts.plusJakartaSans(
                          color: context.onSurface.withOpacity(0.54),
                          fontSize: 12)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withAlpha((0.18 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text('+14.8%',
                    style: GoogleFonts.plusJakartaSans(
                        color: accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(colors: [
                        context.onSurface.withOpacity(0.12),
                        context.onSurface.withOpacity(0.1)
                      ]),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MiniLineChartPainter(accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(Color cardColor, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Quick Actions',
                style: GoogleFonts.plusJakartaSans(
                    color: context.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text('Manage the platform',
                style: GoogleFonts.plusJakartaSans(
                    color: context.onSurface.withOpacity(0.54), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _actionChip(
                'Add Superadmin',
                Icons.admin_panel_settings_rounded,
                accent,
                cardColor,
                () => _navigateTo(const AddSuperadminPage())),
            _actionChip('Manage Users', Icons.manage_accounts_rounded, accent,
                cardColor, () => _navigateTo(const UserManagementPage())),
            _actionChip(
                'Review Deposits',
                Icons.account_balance_rounded,
                accent,
                cardColor,
                () => _navigateTo(const DepositsManagementPage())),
            _actionChip('Withdrawals', Icons.outbox_rounded, accent, cardColor,
                () => _navigateTo(const WithdrawalsManagementPage())),
            _actionChip('Escrows', Icons.verified_user_rounded, accent,
                cardColor, () => _navigateTo(const EscrowManagementPage())),
            _actionChip(
                'Notifications',
                Icons.campaign_rounded,
                accent,
                cardColor,
                () => _navigateTo(const NotificationsManagementPage())),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(Color cardColor, Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Activity',
            style: GoogleFonts.plusJakartaSans(
                color: context.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.onSurface.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: _recentTransactions(),
          ),
        ),
      ],
    );
  }

  Widget _actionChip(String label, IconData icon, Color accent, Color cardColor,
      VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.onSurface.withOpacity(0.12)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withAlpha((0.16 * 255).round()),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                      color: context.onSurface, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentTransactions() => FutureBuilder<Map<String, dynamic>>(
        future: AdminApiService.getTransactions(page: 1),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final list = (snap.data?['data'] as List? ?? []).take(5).toList();
          return list.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No transactions yet')))
              : Column(
                  children: list.map((t) {
                    final isCredit = ['deposit', 'escrow_release', 'roi_payout']
                        .contains(t['transaction_type']);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: context.onSurface.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isCredit
                                ? context.successColor
                                    .withAlpha((0.16 * 255).round())
                                : context.errorColor
                                    .withAlpha((0.16 * 255).round()),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.south_west_rounded
                                : Icons.north_east_rounded,
                            color: isCredit
                                ? context.successColor
                                : context.errorColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          (t['transaction_type'] ?? '')
                              .toString()
                              .replaceAll('_', ' ')
                              .toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                              color: context.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                        subtitle: Text(t['transaction_reference'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                                color: context.onSurface.withOpacity(0.7),
                                fontSize: 11)),
                        trailing: Text(
                          '${isCredit ? '+' : '-'}${_fmt(t['amount'] ?? 0)} FARM',
                          style: GoogleFonts.plusJakartaSans(
                            color: isCredit
                                ? context.successColor
                                : context.errorColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
        },
      );

  Widget _errorView(String msg) => Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: context.errorColor),
                const SizedBox(height: 12),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(color: context.onSurface),
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );

  String _fmt(dynamic v) {
    final n = double.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(2);
  }
}

class _MiniLineChartPainter extends CustomPainter {
  final Color accent;

  _MiniLineChartPainter(this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.33, size.height * 0.6),
      Offset(size.width * 0.5, size.height * 0.35),
      Offset(size.width * 0.68, size.height * 0.44),
      Offset(size.width * 0.84, size.height * 0.28),
      Offset(size.width, size.height * 0.18),
    ];

    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
