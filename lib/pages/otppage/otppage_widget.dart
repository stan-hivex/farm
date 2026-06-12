import 'dart:async';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import 'otppage_model.dart';
export 'otppage_model.dart';

class OtppageWidget extends StatefulWidget {
  const OtppageWidget({
    super.key,
    required this.phone,
  });

  final String phone;

  static String routeName = 'otppage';
  static String routePath = '/otppage';

  @override
  State<OtppageWidget> createState() => _OtppageWidgetState();
}

class _OtppageWidgetState extends State<OtppageWidget> {
  late OtppageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// ✅ FIXED BASE URL
  final String baseUrl = '${AppConfig.api}/auth';

  Timer? _timer;
  int secondsRemaining = 60;

  final FocusNode focus1 = FocusNode();
  final FocusNode focus2 = FocusNode();
  final FocusNode focus3 = FocusNode();
  final FocusNode focus4 = FocusNode();
  final FocusNode focus5 = FocusNode();
  final FocusNode focus6 = FocusNode();

  @override
  void initState() {
    super.initState();

    _model = createModel(context, () => OtppageModel());

    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    focus1.dispose();
    focus2.dispose();
    focus3.dispose();
    focus4.dispose();
    focus5.dispose();
    focus6.dispose();

    _model.dispose();
    super.dispose();
  }

  /// ================= TIMER =================
  void startTimer() {
    secondsRemaining = 60;

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (secondsRemaining == 0) {
          timer.cancel();

          setState(() {
            _model.canResend = true;
          });
        } else {
          setState(() {
            secondsRemaining--;
          });
        }
      },
    );
  }

  String formatTime() {
    final minutes = (secondsRemaining ~/ 60)
        .toString()
        .padLeft(2, '0');

    final seconds = (secondsRemaining % 60)
        .toString()
        .padLeft(2, '0');

    return "$minutes:$seconds";
  }

  /// ================= GET OTP =================
  String getOtp() {
    return _model.otp1.text +
        _model.otp2.text +
        _model.otp3.text +
        _model.otp4.text +
        _model.otp5.text +
        _model.otp6.text;
  }

  /// ================= VERIFY OTP =================
Future<void> verifyOtp() async {
  final otp = getOtp();

  if (otp.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please enter full OTP"),
      ),
    );
    return;
  }

  setState(() {
    _model.isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/verify-otp"),
      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "phone": widget.phone,
        "otp_code": otp,
        "purpose": "phone_verification",
      }),
    );

    print("VERIFY STATUS: ${response.statusCode}");
    print("VERIFY BODY: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["success"] == true) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("OTP Verified Successfully"),
        ),
      );

      /// REDIRECT TO DASHBOARD
      Future.delayed(
        const Duration(seconds: 1),
        () {
          context.pushNamed(
            'Dashboard',
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data["message"] ?? "Invalid OTP",
          ),
        ),
      );
    }
  } catch (e) {
    print(e);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error: $e"),
      ),
    );
  }

  setState(() {
    _model.isLoading = false;
  });
}

 /// ================= RESEND OTP =================
Future<void> resendOtp() async {
  if (!_model.canResend) return;

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/resend-otp"),
      headers: {
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "phone": widget.phone,
      }),
    );

    print("RESEND STATUS: ${response.statusCode}");
    print("RESEND BODY: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data["success"] == true) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("OTP Resent Successfully"),
        ),
      );

      setState(() {
        _model.canResend = false;
      });

      startTimer();

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            data["message"] ?? "Resend failed",
          ),
        ),
      );
    }

  } catch (e) {
    print(e);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Resend failed: $e"),
      ),
    );
  }
}

  /// ================= OTP BOX =================
  Widget otpField({
    required TextEditingController controller,
    required FocusNode currentFocus,
    FocusNode? nextFocus,
    FocusNode? previousFocus,
  }) {
    return Container(
      width: 52,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: TextField(
        controller: controller,
        focusNode: currentFocus,
        autofocus: false,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: FlutterFlowTheme.of(context)
              .secondaryBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: FlutterFlowTheme.of(context)
                  .alternate,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color:
                  FlutterFlowTheme.of(context).primary,
              width: 2,
            ),
          ),
        ),

        onChanged: (value) {
          /// AUTO NEXT
          if (value.isNotEmpty && nextFocus != null) {
            FocusScope.of(context)
                .requestFocus(nextFocus);
          }

          /// AUTO BACK
          if (value.isEmpty && previousFocus != null) {
            FocusScope.of(context)
                .requestFocus(previousFocus);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),

      child: Scaffold(
        key: scaffoldKey,
        backgroundColor:
            FlutterFlowTheme.of(context)
                .primaryBackground,

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [

                /// HEADER
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 12,
                      buttonSize: 44,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color:
                            FlutterFlowTheme.of(context)
                                .primaryText,
                      ),
                      onPressed: () {
                        context.pop();
                      },
                    ),

                    Text(
                      "FARM",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(width: 44),
                  ],
                ),

                const SizedBox(height: 30),

                Lottie.network(
                  'https://dimg.dreamflow.cloud/v1/lottie/secure+shield+verification',
                  width: 140,
                  height: 140,
                ),

                const SizedBox(height: 20),

                Text(
                  "Verify Your Phone",
                  style:
                      FlutterFlowTheme.of(context)
                          .headlineSmall
                          .override(
                            font: GoogleFonts.inter(),
                            fontWeight:
                                FontWeight.bold,
                          ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Enter the 6-digit verification code sent to your number",
                  textAlign: TextAlign.center,
                  style:
                      FlutterFlowTheme.of(context)
                          .bodyMedium,
                ),

                const SizedBox(height: 40),

                /// OTP BOXES
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [

                    otpField(
                      controller: _model.otp1,
                      currentFocus: focus1,
                      nextFocus: focus2,
                    ),

                    otpField(
                      controller: _model.otp2,
                      currentFocus: focus2,
                      previousFocus: focus1,
                      nextFocus: focus3,
                    ),

                    otpField(
                      controller: _model.otp3,
                      currentFocus: focus3,
                      previousFocus: focus2,
                      nextFocus: focus4,
                    ),

                    otpField(
                      controller: _model.otp4,
                      currentFocus: focus4,
                      previousFocus: focus3,
                      nextFocus: focus5,
                    ),

                    otpField(
                      controller: _model.otp5,
                      currentFocus: focus5,
                      previousFocus: focus4,
                      nextFocus: focus6,
                    ),

                    otpField(
                      controller: _model.otp6,
                      currentFocus: focus6,
                      previousFocus: focus5,
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// TIMER
                Text(
                  formatTime(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                /// VERIFY BUTTON
                FFButtonWidget(
                  onPressed:
                      _model.isLoading
                          ? null
                          : verifyOtp,

                  text: _model.isLoading
                      ? "Verifying..."
                      : "Confirm OTP",

                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 56,
                    color:
                        FlutterFlowTheme.of(context)
                            .primary,
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),

                const SizedBox(height: 20),

                /// RESEND
                TextButton(
                  onPressed:
                      _model.canResend
                          ? resendOtp
                          : null,

                  child: Text(
                    _model.canResend
                        ? "Resend OTP"
                        : "Resend available in ${formatTime()}",
                  ),
                ),

                const Spacer(),

                const Text(
                  "Secure 256-bit encrypted verification",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}