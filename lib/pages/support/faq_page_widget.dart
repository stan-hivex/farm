import 'package:flutter/material.dart';

class FaqPageWidget extends StatelessWidget {
  const FaqPageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FAQs")),
      body: const Center(
        child: Text("Frequently Asked Questions"),
      ),
    );
  }
}