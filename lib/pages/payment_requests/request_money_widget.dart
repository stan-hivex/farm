import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/payment_request_api_service.dart';

class RequestMoneyWidget extends StatefulWidget {
  const RequestMoneyWidget({super.key});

  static const routeName = 'RequestMoney';

  @override
  State<RequestMoneyWidget> createState() => _RequestMoneyWidgetState();
}

class _RequestMoneyWidgetState extends State<RequestMoneyWidget> {
  final _recipientCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _recipientCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final recipient = _recipientCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text.trim()) ?? 0;
    final desc = _descCtrl.text.trim();
    if (recipient.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter valid recipient and amount')));
      return;
    }

    try {
      setState(() => _submitting = true);
      final res = await PaymentRequestApiService.requestPayment(
        token: FFAppState().accessToken,
        recipientIdentifier: recipient,
        amount: amount,
        description: desc,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Request created')));
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Money')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _recipientCtrl,
              decoration: const InputDecoration(labelText: 'Recipient (username, phone or address)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (FARM)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
