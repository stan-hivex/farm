import 'package:flutter/material.dart';
import '/core/theme_extensions.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class SuperadminWalletPage extends StatelessWidget {
  const SuperadminWalletPage({super.key});

  static String routeName = 'SuperadminWalletPage';
  static String routePath = '/superadmin/wallet';

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Superadmin Wallet'),
        backgroundColor: theme.primary,
        foregroundColor: context.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet_rounded),
                title: Text('Treasury balance'),
                subtitle: Text('Available balance: 0.00'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Icon(Icons.swap_horiz_rounded),
                title: Text('Recent operations'),
                subtitle: Text('No recent operations available.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
