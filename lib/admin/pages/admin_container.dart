import 'package:flutter/material.dart';

class AdminContainer extends StatelessWidget {
  const AdminContainer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: const Center(child: Text('Admin container')),
    );
  }
}
