import 'package:flutter/material.dart';
import '/pages/pin_setup_page/pin_setup_page_widget.dart';

class SuperadminPinSetupPage extends StatelessWidget {
  const SuperadminPinSetupPage({super.key});

  static const String routeName = 'superadmin_pin_setup_page';
  static const String routePath = '/superadmin/pinSetupPage';

  @override
  Widget build(BuildContext context) {
    return const PinSetupPageWidget();
  }
}
