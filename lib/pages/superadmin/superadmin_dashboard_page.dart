import 'package:flutter/material.dart';
import '/core/theme_extensions.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class SuperadminDashboardPage extends StatelessWidget {
  const SuperadminDashboardPage({super.key});

  static String routeName = 'SuperadminDashboardPage';
  static String routePath = '/superadmin';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Superadmin Dashboard'),
        backgroundColor: theme.primary,
        foregroundColor: context.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Operations overview', style: theme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet_rounded),
                title: Text('Wallet & treasury'),
                subtitle: Text('Monitor treasury health and wallet activity.'),
                onTap: () => Navigator.of(context).pushNamed('/superadmin/wallet'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Icon(Icons.admin_panel_settings_rounded),
                title: Text('Admin controls'),
                subtitle: Text('Manage users, fees, and platform policies.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
