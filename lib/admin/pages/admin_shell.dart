import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import 'admin_dashboard_page.dart';
import 'superadmins_management_page.dart';
import 'user_management_page.dart';
import 'kyc_management_page.dart';
import 'transactions_management_page.dart';
import 'escrow_management_page.dart';
import 'deposits_management_page.dart';
import 'withdrawals_management_page.dart';
import 'notifications_management_page.dart';
import 'settings_management_page.dart';
import 'fee_management_page.dart';
import 'merchant_kyb_management_page.dart';
import '../services/admin_api_service.dart';
import '../core/admin_guard.dart';
import '../../pages/loginpage/loginpage_widget.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await AdminGuard.isAuthenticated();
      if (!ok && mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginpageWidget()));
      }
    });
  }

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.admin_panel_settings_rounded, label: 'Superadmins'),
    _NavItem(icon: Icons.people_rounded, label: 'Users'),
    _NavItem(icon: Icons.verified_user_rounded, label: 'KYC'),
    _NavItem(icon: Icons.swap_horiz_rounded, label: 'Transactions'),
    _NavItem(icon: Icons.security_rounded, label: 'Escrow'),
    _NavItem(icon: Icons.south_west_rounded, label: 'Deposits'),
    _NavItem(icon: Icons.north_east_rounded, label: 'Withdrawals'),
    _NavItem(icon: Icons.campaign_rounded, label: 'Notifications'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
    _NavItem(icon: Icons.percent_rounded, label: 'Fees'),
    _NavItem(icon: Icons.badge_rounded, label: 'Merchant KYB'),
  ];

  List<Widget> get _pages => [
        const AdminDashboardPage(),
        SuperadminsManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
        UserManagementPage(onGoBack: () => setState(() => _selectedIndex = 0)),
        KycManagementPage(onGoBack: () => setState(() => _selectedIndex = 0)),
        TransactionsManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
        EscrowManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
        DepositsManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
        WithdrawalsManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
        NotificationsManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
        SettingsManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
        FeeManagementPage(onGoBack: () => setState(() => _selectedIndex = 0)),
        MerchantKybManagementPage(
            onGoBack: () => setState(() => _selectedIndex = 0)),
      ];

  Future<void> _logout() async {
    await AdminApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginpageWidget()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Sidebar — only on wide screens
          if (isWide) _buildSidebar(),

          // Main content
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isWide),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ),
        ],
      ),
      // Bottom nav — only on narrow screens
      bottomNavigationBar: isWide ? null : _buildBottomNav(),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.onSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text('FARM',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(width: 8),
                Text('Admin',
                    style: GoogleFonts.plusJakartaSans(
                        color: context.onBackground.withOpacity(0.54),
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final selected = i == _selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? context.onSurface.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon,
                            color: selected
                                ? context.onSurface
                                : context.onSurface.withOpacity(0.38),
                            size: 20),
                        const SizedBox(width: 12),
                        Text(item.label,
                            style: GoogleFonts.plusJakartaSans(
                              color: selected
                                  ? context.onSurface
                                  : context.onSurface.withOpacity(0.54),
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 14,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout
          Padding(
            padding: const EdgeInsets.all(16),
            child: GestureDetector(
              onTap: _logout,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: context.onSurface.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.logout_rounded,
                      color: context.onSurface.withOpacity(0.38), size: 20),
                  const SizedBox(width: 12),
                  Text('Logout',
                      style: GoogleFonts.plusJakartaSans(
                          color: context.onSurface.withOpacity(0.38),
                          fontSize: 14)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isWide) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isWide)
            Text('FARM Admin',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.onSurface)),
          if (isWide)
            Text(_navItems[_selectedIndex].label,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: context.onSurface)),
          Row(children: [
            Icon(Icons.notifications_none_rounded,
                color: context.onSurface.withOpacity(0.7)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _logout,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded,
                        size: 16, color: context.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: GoogleFonts.plusJakartaSans(
                        color: context.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Color(0xFF0A0F18), shape: BoxShape.circle),
              child: Center(
                  child: Text('AD',
                      style: TextStyle(
                          color: context.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(_navItems.length, (i) {
              final item = _navItems[i];
              final selected = i == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = i),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 90,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEAF2FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: selected
                              ? const Color(0xFF0D47A1)
                              : context.onSurface.withOpacity(0.64),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected
                                ? const Color(0xFF0D47A1)
                                : context.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
