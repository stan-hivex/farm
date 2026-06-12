import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard_page.dart';
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
    _NavItem(icon: Icons.dashboard_rounded,     label: 'Dashboard'),
    _NavItem(icon: Icons.people_rounded,         label: 'Users'),
    _NavItem(icon: Icons.verified_user_rounded,  label: 'KYC'),
    _NavItem(icon: Icons.swap_horiz_rounded,     label: 'Transactions'),
    _NavItem(icon: Icons.security_rounded,       label: 'Escrow'),
    _NavItem(icon: Icons.south_west_rounded,     label: 'Deposits'),
    _NavItem(icon: Icons.north_east_rounded,     label: 'Withdrawals'),
    _NavItem(icon: Icons.campaign_rounded,       label: 'Notifications'),
    _NavItem(icon: Icons.settings_rounded,       label: 'Settings'),
    _NavItem(icon: Icons.percent_rounded,        label: 'Fees'),
    _NavItem(icon: Icons.badge_rounded,          label: 'Merchant KYB'),
  ];

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    UserManagementPage(),
    KycManagementPage(),
    TransactionsManagementPage(),
    EscrowManagementPage(),
    DepositsManagementPage(),
    WithdrawalsManagementPage(),
    NotificationsManagementPage(),
    SettingsManagementPage(),
    FeeManagementPage(),
    MerchantKybManagementPage(),
  ];

  Future<void> _logout() async {
    await AdminApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginpageWidget()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
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
      color: const Color(0xFF0C1320),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text('FARM', style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(width: 8),
                Text('Admin', style: GoogleFonts.plusJakartaSans(
                    color: Colors.black54, fontSize: 13)),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(item.icon,
                            color: selected ? Colors.white : Colors.white38,
                            size: 20),
                        const SizedBox(width: 12),
                        Text(item.label,
                            style: GoogleFonts.plusJakartaSans(
                              color: selected ? Colors.white : Colors.white54,
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
                  border: Border.all(color: Colors.white12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.logout_rounded,
                      color: Colors.white38, size: 20),
                  const SizedBox(width: 12),
                  Text('Logout',
                      style: GoogleFonts.plusJakartaSans(
                          color: Colors.white38, fontSize: 14)),
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
      decoration: const BoxDecoration(
        color: Color(0xFF111B2A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E2A3C))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!isWide)
            Text('FARM Admin',
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
          if (isWide)
            Text(_navItems[_selectedIndex].label,
                style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
          Row(children: [
            Icon(Icons.notifications_none_rounded, color: Colors.white70),
            const SizedBox(width: 16),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: Color(0xFF0A0F18), shape: BoxShape.circle),
              child: const Center(
                  child: Text('AD',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF111B2A),
      currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white54,
      type: BottomNavigationBarType.fixed,
      items: _navItems.take(5).map((n) => BottomNavigationBarItem(
            icon: Icon(n.icon),
            label: n.label,
          )).toList(),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}