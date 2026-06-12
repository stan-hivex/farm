import 'package:flutter/material.dart';

class FraudAlertWidget extends StatelessWidget {
  const FraudAlertWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: EdgeInsets.all(8), child: Text('Fraud Alert')));
  }
}
