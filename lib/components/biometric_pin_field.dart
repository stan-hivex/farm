import 'package:flutter/material.dart';
import '/services/transaction_authorization_service.dart';
import '/services/transaction_authentication_service.dart';

typedef BiometricAuthorizedCallback = Future<void> Function(TransactionAuthenticationResult authResult);

typedef DetailsValidationCallback = bool Function();

typedef InvalidDetailsCallback = void Function();

class BiometricPinField extends StatefulWidget {
  const BiometricPinField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.detailsValid,
    required this.onAuthorized,
    required this.localizedReason,
    required this.onInvalidDetails,
    this.onPinFallback,
    this.keyboardType = TextInputType.number,
    this.obscureText = true,
    this.hintText = 'Enter PIN',
    this.labelText,
    this.maxLength,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final DetailsValidationCallback detailsValid;
  final InvalidDetailsCallback onInvalidDetails;
  final BiometricAuthorizedCallback onAuthorized;
  final VoidCallback? onPinFallback;
  final String localizedReason;
  final TextInputType keyboardType;
  final bool obscureText;
  final String hintText;
  final String? labelText;
  final int? maxLength;

  @override
  State<BiometricPinField> createState() => _BiometricPinFieldState();
}

class _BiometricPinFieldState extends State<BiometricPinField> {
  bool _pinEntryEnabled = false;
  bool _isAuthenticating = false;

  Future<TransactionAuthenticationResult?> promptBiometricIfNeeded() async {
    if (_pinEntryEnabled) {
      return const TransactionAuthenticationResult(outcome: TransactionAuthenticationOutcome.pinRequired);
    }

    return await _tryBiometricFirst();
  }

  Future<TransactionAuthenticationResult?> _tryBiometricFirst() async {
    if (!widget.detailsValid()) {
      widget.onInvalidDetails();
      return null;
    }

    setState(() {
      _isAuthenticating = true;
    });

    try {
      final authResult = await TransactionAuthorizationService().authorizeTransaction(
        localizedReason: widget.localizedReason,
      ).then((r) => r.toTransactionAuthenticationResult());

      if (authResult.biometricUsed) {
        await widget.onAuthorized(authResult);
        return authResult;
      }

      setState(() => _pinEntryEnabled = true);
      widget.onPinFallback?.call();
      widget.focusNode.requestFocus();
      return authResult;
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      readOnly: !_pinEntryEnabled || _isAuthenticating,
      onTap: () async {
        if (!_pinEntryEnabled && !_isAuthenticating) {
          await _tryBiometricFirst();
        }
      },
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        counterText: '',
      ),
    );
  }
}
