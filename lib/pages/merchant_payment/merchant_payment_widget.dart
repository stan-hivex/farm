import 'package:flutter/material.dart';
import '/backend/services/api_service.dart';
import '/services/transaction_authentication_service.dart';
import '/services/transaction_authorization_service.dart';
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
  final FocusNode pinFocusNode = FocusNode();
  bool isLoading = false;
  bool _pinEntryEnabled = false;
  bool _isBiometricChecking = false;
  String error = '';
  TransactionAuthenticationResult? _lastPinAuthResult;

  @override
  void dispose() {
    amountController.dispose();
    pinController.dispose();
    pinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _promptBiometricForPinField() async {
    if (_lastPinAuthResult?.biometricUsed == true) {
      return;
    }

    try {
      setState(() => _isBiometricChecking = true);
      final authResult = await TransactionAuthorizationService()
          .authorizeTransaction(
            localizedReason: 'Confirm payment',
          )
          .then((r) => r.toTransactionAuthenticationResult());

      if (authResult.biometricUsed) {
        if (mounted) {
          setState(() {
            _lastPinAuthResult = authResult;
          });
        }

        await _submitPayment();
        return;
      }

      if (mounted) {
        setState(() {
          _lastPinAuthResult = authResult;
          _pinEntryEnabled = true;
        });
        pinFocusNode.requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _isBiometricChecking = false);
      }
    }
  }

  Future<void> _submitPayment() async {
    if (isLoading) return;
    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    final pin = pinController.text.trim();

    if (amount <= 0) {
      _showSnack('Enter a valid amount');
      return;
    }

    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final authResult = _lastPinAuthResult ??
          await TransactionAuthorizationService()
              .authorizeTransaction(
                localizedReason: 'Confirm payment',
              )
              .then((r) => r.toTransactionAuthenticationResult());

      if (authResult?.biometricUsed == true) {
        await ApiService.merchantPay(
          qrPayload: widget.qrPayload,
          amount: amount,
          pin: null,
          biometricAuth: true,
          deviceFingerprint: authResult?.deviceFingerprint,
        );

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
        return;
      }

      if (authResult?.biometricUsed != true && pin.isEmpty) {
        _showSnack('Enter your transaction PIN');
        return;
      }

      await ApiService.merchantPay(
        qrPayload: widget.qrPayload,
        amount: amount,
        pin: pin,
        biometricAuth: null,
        deviceFingerprint: authResult?.deviceFingerprint,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            Text(
              widget.businessName.isNotEmpty
                  ? 'Pay to ${widget.businessName}'
                  : 'Pay to merchant',
              style: theme.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (widget.businessName.isNotEmpty)
              Text(
                'Business: ${widget.businessName}',
                style: theme.bodyMedium,
              ),
            const SizedBox(height: 4),
            Text('Merchant ID: ${widget.merchantId}', style: theme.bodyMedium),
            const SizedBox(height: 24),
            Text('Amount',
                style: theme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
            if (_pinEntryEnabled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaction PIN',
                      style: theme.bodyMedium
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: pinController,
                    focusNode: pinFocusNode,
                    readOnly: _isBiometricChecking,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    onTap: () async {
                      if (!_pinEntryEnabled && !_isBiometricChecking) {
                        await _promptBiometricForPinField();
                      }
                    },
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
                ],
              )
            else if (!_isBiometricChecking)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _promptBiometricForPinField,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : theme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Continue',
                      style: theme.titleMedium.copyWith(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 24),
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(error,
                    style: const TextStyle(color: Colors.redAccent)),
              ),
            if (_pinEntryEnabled)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : theme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Builder(builder: (context) {
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final textColor = isDark ? Colors.black : Colors.white;
                          return Text('Pay Merchant',
                              style: theme.titleMedium.copyWith(
                                  color: textColor, fontWeight: FontWeight.bold));
                        }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
