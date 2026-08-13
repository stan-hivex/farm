import 'package:flutter/material.dart';
import '/services/auth/auth_service.dart';
import '../../pages/loginpage/loginpage_widget.dart';
import '../core/admin_navigation.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.admin_panel_settings_rounded),
                  SizedBox(width: 8),
                  Text('Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: Container()),
            Padding(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Logout'),
                onTap: () async {
                  try {
                      await AuthService().logout();
                  } catch (_) {
                    // ignore errors from logout request; still clear session locally
                  }
                  if (context.mounted) {
                    AuthNavigation.replaceAllWithBuilder(
                      context,
                      (_) => LoginpageWidget(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
