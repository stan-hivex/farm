import '/flutter_flow/flutter_flow_util.dart';
import 'otppage_widget.dart' show OtppageWidget;
import 'package:flutter/material.dart';

class OtppageModel extends FlutterFlowModel<OtppageWidget> {
  /// OTP controllers
  final TextEditingController otp1 = TextEditingController();
  final TextEditingController otp2 = TextEditingController();
  final TextEditingController otp3 = TextEditingController();
  final TextEditingController otp4 = TextEditingController();
  final TextEditingController otp5 = TextEditingController();
  final TextEditingController otp6 = TextEditingController();

  /// loading state
  bool isLoading = false;

  /// timer state (optional UI upgrade)
  int resendTimer = 60;
  bool canResend = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    otp1.dispose();
    otp2.dispose();
    otp3.dispose();
    otp4.dispose();
    otp5.dispose();
    otp6.dispose();
  }
}