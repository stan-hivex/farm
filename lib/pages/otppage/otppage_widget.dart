import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart' as auth_platform;
import 'package:flutter/foundation.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/utils/browser_platform_stub.dart'
    if (dart.library.html) '/utils/browser_platform_web.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/auth/auth_service.dart';

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
    this.identifier = '',
    this.password = '',
    this.countryCode,
  });

  final String phone;
  final String identifier;
  final String password;
  final String? countryCode;

  static String routeName = 'otppage';
  static String routePath = '/otppage';

  @override
  State<OtppageWidget> createState() => _OtppageWidgetState();
}

class _OtppageWidgetState extends State<OtppageWidget> {
  late OtppageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController otpController = TextEditingController();
  // Web-only confirmation result
  ConfirmationResult? _webConfirmationResult;
  RecaptchaVerifier? _recaptchaVerifier;
  // Shared RecaptchaVerifier across widget instances to avoid double render
  static RecaptchaVerifier? _sharedRecaptchaVerifier;
  static bool _sharedVerifierRendered = false;
  bool _otpRequestInProgress = false;
  bool _verificationStarted = false;

  Timer? _fallbackTimer;
  String _statusTitle = 'Verifying your phone number...';
  String _statusMessage = 'Please wait while we verify your phone automatically.';
  bool _showManualOtpField = false;
  bool _isVerifying = true;
  String? _verificationId;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OtppageModel());

    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (FFAppState().isLoggedIn) {
          context.goNamed('Dashboard');
        } else {
          context.goNamed('loginpage');
        }
      });
      return;
    }

    _startFallbackTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_verificationStarted) {
        _verificationStarted = true;
        _startPhoneVerification();
      }
    });
  }

  String _normalizePhoneNumberForFirebase(String? value, {String? fallbackCountryCode}) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return '';
    }

    final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return '';
    }

    if (raw.startsWith('+')) {
      return '+$digitsOnly';
    }

    if (raw.startsWith('00')) {
      return '+${digitsOnly.substring(2)}';
    }

    final countryCode = (fallbackCountryCode ?? widget.countryCode ?? '')
        .replaceAll(RegExp(r'\D'), '');

    if (countryCode.isNotEmpty) {
      final withoutLeadingZero = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
      return '+$countryCode$withoutLeadingZero';
    }

    return '+$digitsOnly';
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    // Do not clear the shared verifier here; it will be cleared explicitly on resend.
    try {
      // clear any local reference only
      _recaptchaVerifier = null;
    } catch (_) {}
    otpController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _showManualOtpField = true;
          _statusTitle = 'Automatic detection timed out';
          _statusMessage = 'Enter the code manually to continue.';
          _isVerifying = false;
        });
        return;
      }

      setState(() {
        _secondsRemaining--;
      });
    });
  }

  Future<void> _startPhoneVerification() async {
    if (!mounted) return;

    if (kIsWeb) {
      debugPrint('[OTP] Web route opened; skipping Firebase OTP flow');
      if (mounted) {
        if (FFAppState().isLoggedIn) {
          context.goNamed('Dashboard');
        } else {
          context.goNamed('loginpage');
        }
      }
      return;
    }

    debugPrint('[OTP] platform=${getBrowserPlatformLabel()} hostname=${getBrowserHostname()} phone=${widget.phone}');
    debugPrint('[OTP] Starting Firebase phone verification');

    setState(() {
      _isVerifying = true;
      _statusTitle = 'Verifying your phone number...';
      _statusMessage = 'Please wait while we verify your phone automatically.';
    });

    try {
      if (kIsWeb) {
        // prevent duplicate requests
        if (_otpRequestInProgress) {
          debugPrint('[OTP] startPhoneVerification: request already in progress');
          return;
        }
        _otpRequestInProgress = true;

        // clear any previous confirmation result
        _webConfirmationResult = null;

        final firebasePhone = _normalizePhoneNumberForFirebase(
          widget.identifier.isNotEmpty ? widget.identifier : widget.phone,
          fallbackCountryCode: widget.countryCode,
        );

        if (firebasePhone.isEmpty) {
          _otpRequestInProgress = false;
          throw Exception('Phone number was empty after normalization');
        }

        debugPrint('[OTP] web phone auth using RecaptchaVerifier');
        debugPrint('[OTP] normalized phone for Firebase=$firebasePhone');
        debugPrint('[OTP] hostname=${getBrowserHostname()} platform=${getBrowserPlatformLabel()}');

        // Initialize a shared RecaptchaVerifier and render it only once
        if (_sharedRecaptchaVerifier == null) {
          final verifier = RecaptchaVerifier(
            auth: auth_platform.FirebaseAuthPlatform.instance,
            onSuccess: () {
              debugPrint('[OTP] reCAPTCHA completed');
            },
            onError: (e) {
              debugPrint('[OTP] reCAPTCHA error code=${e.code} message=${e.message}');
            },
            onExpired: () {
              debugPrint('[OTP] reCAPTCHA expired');
            },
          );
          _sharedRecaptchaVerifier = verifier;
          _recaptchaVerifier = verifier;
          debugPrint('[OTP] reCAPTCHA initialized (invisible) - new shared verifier');
          try {
            await _sharedRecaptchaVerifier!.render();
            _sharedVerifierRendered = true;
            debugPrint('[OTP] reCAPTCHA rendered (shared)');
          } catch (e, st) {
            debugPrint('[OTP] reCAPTCHA render failed: $e');
            debugPrintStack(label: '[OTP] reCAPTCHA render stack', stackTrace: st);
          }
        } else {
          // reuse the shared verifier
          _recaptchaVerifier = _sharedRecaptchaVerifier;
          debugPrint('[OTP] reCAPTCHA reused (shared) rendered=$_sharedVerifierRendered');
        }

        try {
          // prevent accidental duplicate API calls
          if (_otpRequestInProgress) {
            debugPrint('[OTP] signInWithPhoneNumber skipped: already in progress');
          } else {
            _otpRequestInProgress = true;
            debugPrint('[OTP] Calling Firebase signInWithPhoneNumber');
            _webConfirmationResult = await FirebaseAuth.instance.signInWithPhoneNumber(
              firebasePhone,
              _recaptchaVerifier!,
            );
            debugPrint('[OTP] Firebase SMS request finished confirmationResult=${_webConfirmationResult != null}');
          }
        } on FirebaseAuthException catch (e, st) {
          debugPrint('[FirebaseAuthException] code=${e.code} message=${e.message}');
          debugPrintStack(label: '[FirebaseAuthException] stackTrace', stackTrace: st);
          // map common errors to user-friendly state
          if (e.code == 'quota-exceeded' || e.code == 'auth/quota-exceeded' || e.code == 'too-many-requests' || e.code == 'auth/too-many-requests') {
            _statusTitle = 'Too many requests';
            _statusMessage = 'SMS quota exceeded or too many attempts. Try again later.';
          } else if (e.code == 'captcha-check-failed' || e.code == 'auth/captcha-check-failed') {
            _statusTitle = 'Captcha failed';
            _statusMessage = 'Captcha verification failed. Please try again.';
          } else if (e.code == 'invalid-phone-number' || e.code == 'auth/invalid-phone-number') {
            _statusTitle = 'Invalid phone number';
            _statusMessage = 'The provided phone number is not valid.';
          } else if (e.code == 'network-request-failed' || e.code == 'auth/network-request-failed') {
            _statusTitle = 'Network error';
            _statusMessage = 'Network error. Check your connection.';
          }
          // Clear shared verifier on fatal errors so a fresh verifier can be created on resend
          try {
            _sharedRecaptchaVerifier?.clear();
          } catch (_) {}
          _sharedRecaptchaVerifier = null;
          _sharedVerifierRendered = false;
          rethrow;
        } catch (e, st) {
          debugPrint('[OTP] signInWithPhoneNumber unexpected error: $e');
          debugPrintStack(label: '[OTP] unexpected stack', stackTrace: st);
          try {
            _sharedRecaptchaVerifier?.clear();
          } catch (_) {}
          _sharedRecaptchaVerifier = null;
          _sharedVerifierRendered = false;
          rethrow;
        } finally {
          _otpRequestInProgress = false;
        }

        if (!mounted) return;
        setState(() {
          _statusTitle = 'SMS sent';
          _statusMessage = 'Enter the code sent to your phone.';
          _showManualOtpField = true;
          _isVerifying = false;
        });
        return;
      }

      // Mobile platforms
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('[OTP] mobile verificationCompleted with credential');
          if (!mounted) return;
          await _completeFirebaseVerification(credential);
        },
        verificationFailed: (FirebaseAuthException error) async {
          debugPrint('[FirebaseAuthException] code=${error.code} message=${error.message}');
          debugPrintStack(label: '[FirebaseAuthException] stackTrace', stackTrace: StackTrace.current);
          if (!mounted) return;
          setState(() {
            _isVerifying = false;
            _statusTitle = 'Phone verification failed';
            _statusMessage = error.message ?? 'Unable to verify the phone number right now.';
            _showManualOtpField = true;
          });
        },
        codeSent: (String verificationId, int? resendToken) async {
          debugPrint('[OTP] mobile codeSent verificationId=$verificationId resendToken=$resendToken');
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _statusTitle = 'SMS sent';
            _statusMessage = 'We are waiting for the code to arrive automatically.';
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('[OTP] mobile codeAutoRetrievalTimeout verificationId=$verificationId');
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _showManualOtpField = true;
            _statusTitle = 'Automatic detection timed out';
            _statusMessage = 'Enter the code manually to continue.';
            _isVerifying = false;
          });
        },
      );
    } catch (e) {
      if (e is FirebaseAuthException) {
        debugPrint('[FirebaseAuthException] code=${e.code} message=${e.message}');
        debugPrintStack(label: '[FirebaseAuthException] stackTrace', stackTrace: StackTrace.current);
      } else {
        debugPrint('[OTP] startPhoneVerification failed: $e');
      }
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _statusTitle = 'Phone verification failed';
        _statusMessage = _friendlyError(e);
        _showManualOtpField = true;
      });
    }
  }

  Future<void> _completeFirebaseVerification(PhoneAuthCredential credential) async {
    if (!mounted) return;

    setState(() {
      _isVerifying = true;
      _statusTitle = 'Verification successful';
      _statusMessage = 'Finishing the secure login process...';
    });

    try {
      debugPrint('[OTP] completeFirebaseVerification signing in with credential');
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseToken = await userCredential.user?.getIdToken() ?? '';
      debugPrint('[OTP] completeFirebaseVerification firebaseToken length=${firebaseToken.length} user=${userCredential.user?.uid}');

      if (firebaseToken.isEmpty) {
        throw Exception('Unable to obtain a Firebase ID token.');
      }

      // Use authorized backend verify endpoint (password was already used)
      final response = await AuthService().verifyPhone(
        firebaseIdToken: firebaseToken,
      );
      debugPrint('[OTP] completeFirebaseVerification backend verifyPhone response=${response.toString()}');

      if (!mounted) return;

      if (response['success'] == true) {
        debugPrint('[OTP] completeFirebaseVerification succeeded');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone verified. Logging you in...'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          context.goNamed('Dashboard');
        });
      } else {
        debugPrint('[OTP] completeFirebaseVerification failed response=${response.toString()}');
        throw Exception(response['message'] ?? 'Unable to complete login.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _statusTitle = 'Verification failed';
        _statusMessage = e.toString();
        _showManualOtpField = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification failed: $e')),
      );
    }
  }

  Future<void> _verifyManualCode() async {
    final otp = otpController.text.trim();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit code.')),
      );
      return;
    }

    if (kIsWeb) {
      debugPrint('[OTP] Starting Firebase phone verification via confirmation.confirm');
      debugPrint('[OTP] verifyManualCode web otp=$otp');
      try {
        final confirmation = _webConfirmationResult;
        if (confirmation == null) {
          debugPrint('[OTP] verifyManualCode missing confirmation result');
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirmation result missing. Please resend code.')));
          return;
        }
        final userCredential = await confirmation.confirm(otp);
        debugPrint('[OTP] Firebase confirmation result received; user=${userCredential.user?.uid}');
        final firebaseToken = await userCredential.user?.getIdToken() ?? '';
        debugPrint('[OTP] verifyManualCode firebaseToken length=${firebaseToken.length}');
        if (firebaseToken.isEmpty) throw Exception('Unable to obtain Firebase ID token.');

        final response = await AuthService().verifyPhone(
          firebaseIdToken: firebaseToken,
        );

        if (!mounted) return;
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone verified. Logging you in...'), backgroundColor: Colors.green));
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            context.goNamed('Dashboard');
          });
          return;
        }
        throw Exception(response['message'] ?? 'Unable to complete login.');
      } catch (e) {
        if (e is FirebaseAuthException) {
          debugPrint('[Firebase ERROR] verifyManualCode code=${e.code} message=${e.message}');
        }
        if (!mounted) return;
        setState(() {
          _isVerifying = false;
          _statusTitle = 'Verification failed';
          _statusMessage = _friendlyError(e);
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: ${_friendlyError(e)}')));
        return;
      }
    }

    // Mobile fallback
    final credential = PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: otp,
    );

    await _completeFirebaseVerification(credential);
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('invalid-verification-code') || msg.contains('INVALID_CODE')) return 'The code you entered is invalid.';
    if (msg.contains('session-expired') || msg.contains('EXPIRED')) return 'The verification session has expired. Request a new code.';
    if (msg.contains('too-many-requests')) return 'Too many requests. Try again later.';
    if (msg.contains('network-request-failed')) return 'Network error. Check your connection.';
    if (msg.contains('captcha-check-failed') || msg.contains('recaptcha')) return 'Captcha verification failed. Please try again.';
    return msg;
  }

  Future<void> _resendCode() async {
    if (!mounted) return;
    setState(() {
      _showManualOtpField = false;
      _isVerifying = true;
      _statusTitle = 'Resending SMS';
      _statusMessage = 'Please wait while a new code is sent.';
      _secondsRemaining = 30;
    });
    _startFallbackTimer();
    // ensure previous verifier/confirmation cleared before resending: clear shared verifier
    try {
      _sharedRecaptchaVerifier?.clear();
    } catch (_) {}
    _sharedRecaptchaVerifier = null;
    _sharedVerifierRendered = false;
    _recaptchaVerifier = null;
    _webConfirmationResult = null;
    _otpRequestInProgress = false;
    await _startPhoneVerification();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 12,
                      buttonSize: 44,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: FlutterFlowTheme.of(context).primaryText,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    Text(
                      'FARM',
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
                  'Phone Verification',
                  style: FlutterFlowTheme.of(context).headlineSmall.override(
                        font: GoogleFonts.inter(),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  '✓ Password verified',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  _statusTitle,
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.phone,
                  style: FlutterFlowTheme.of(context).bodyLarge.override(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                if (_isVerifying)
                  const CircularProgressIndicator()
                else
                  const Icon(Icons.phone_android_rounded, size: 42),
                const SizedBox(height: 24),
                if (_showManualOtpField) ...[
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit code',
                      filled: true,
                      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: FlutterFlowTheme.of(context).alternate),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FFButtonWidget(
                    onPressed: _model.isLoading ? null : _verifyManualCode,
                    text: _model.isLoading ? 'Verifying...' : 'Verify Code',
                    options: FFButtonOptions(
                      width: double.infinity,
                      height: 56,
                      color: FlutterFlowTheme.of(context).primary,
                      textStyle: TextStyle(
                        color: context.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _resendCode,
                    child: const Text('Resend Code'),
                  ),
                ] else ...[
                  Text(
                    'Automatic detection is in progress. If it does not complete within 30 seconds, the manual entry field will appear.',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                ],
                const Spacer(),
                Text(
                  'Secure 256-bit encrypted verification',
                  style: FlutterFlowTheme.of(context).bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
