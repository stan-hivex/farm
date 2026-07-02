import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';

class FaqPageWidget extends StatelessWidget {
  const FaqPageWidget({super.key});

  static const List<_FaqItem> _items = [
    _FaqItem(
      question: 'How do I deposit funds?',
      answer: 'Open the deposit screen, choose your payment method, enter the amount and complete the checkout in the browser.',
    ),
    _FaqItem(
      question: 'How long do withdrawals take?',
      answer: 'Most withdrawals are processed within a few minutes, depending on the selected method and network activity.',
    ),
    _FaqItem(
      question: 'How do I verify my account?',
      answer: 'Complete the KYC flow from the profile or dashboard and upload the requested identity documents.',
    ),
    _FaqItem(
      question: 'Can I recover my PIN?',
      answer: 'Use the forgot PIN flow to reset your PIN securely from the login screen.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        title: const Text('FAQs'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ExpansionTile(
              title: Text(item.question, style: theme.titleSmall),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                Text(item.answer, style: theme.bodyMedium),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}