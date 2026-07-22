import 'package:flutter/material.dart';
import '/backend/services/api_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/services/app_session_manager.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MerchantPaymentWidget extends StatefulWidget {
  const MerchantPaymentWidget({
    super.key,
    required this.merchantId,
    required this.businessName,
    required this.qrPayload,
  });

  static String routeName = 'MerchantPayment';
  static String routePath = '/merchantPayment';

  final String merchantId;
  final String businessName;
  final String qrPayload;

  @override
  State<MerchantPaymentWidget> createState() => _MerchantPaymentWidgetState();
}

class _MerchantPaymentWidgetState extends State<MerchantPaymentWidget> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  bool isLoading = false;
  String error = '';

  @override
  void dispose() {
    amountController.dispose();
    pinController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    if (isLoading) return;
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final pin = pinController.text.trim();

    if (amount <= 0) {
      _showSnack('Enter a valid amount');
      return;
    }
    if (pin.isEmpty) {
      _showSnack('Enter your transaction PIN');
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      await ApiService.merchantPay(
        qrPayload: widget.qrPayload,
        amount: amount,
        pin: pin,
      );

      // Optimistic update: ensure the app's main wallet UI reflects
      // the incoming platform credit immediately. The backend should
      // also record this on the server; this client-side increment
      // provides immediate feedback if the server-side platform
      // wallet update is not yet visible.
      final current = FFAppState().walletBalance;
      FFAppState().walletBalance = current + amount;

      await AppSessionManager().syncNow(
        profileTimeoutSeconds: 5,
        walletTimeoutSeconds: 5,
        transactionsTimeoutSeconds: 5,
      );

      if (!mounted) return;
      _showSnack('Payment successful');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
      });
      _showSnack('Payment failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merchant Payment'),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryText),
      ),
      backgroundColor: theme.primaryBackground,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay to ${widget.businessName}',
                style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Merchant ID: ${widget.merchantId}',
                style: theme.bodyMedium),
            const SizedBox(height: 24),
            Text('Amount', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.alternate),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Transaction PIN', style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter PIN',
                filled: true,
                fillColor: theme.secondaryBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: theme.alternate),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(error, style: const TextStyle(color: Colors.redAccent)),
              ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text('Pay Merchant',
                        style: theme.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
