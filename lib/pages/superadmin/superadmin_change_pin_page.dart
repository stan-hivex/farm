import 'package:flutter/material.dart';
import '/pages/change_pin_page/change_pin_page_widget.dart';

class SuperadminChangePinPage extends StatelessWidget {
  const SuperadminChangePinPage({super.key});

  static const String routeName = 'superadmin_change_pin_page';
  static const String routePath = '/superadmin/changePinPage';

  @override
  Widget build(BuildContext context) {
    return const ChangePinPageWidget();
  }
}
