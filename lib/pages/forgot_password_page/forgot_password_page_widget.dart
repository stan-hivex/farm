import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:easy_localization/easy_localization.dart';
import '/services/auth/auth_service.dart';
import '/pages/loginpage/loginpage_widget.dart';
import 'forgot_password_page_model.dart';
export 'forgot_password_page_model.dart';

/// Create a premium black and white fintech forgot password page for FARM
/// App.
///
/// Include:  * FARM logo at the top * Title: "Reset Password" * Phone number
/// input field * Send OTP button * Back to Login text button  Style:  *
/// Modern banking app design * Black and white fintech theme * Minimal and
/// elegant layout * Rounded cards and buttons * Professional and trustworthy
/// appearance * Mobile-first responsive design  Important:  * The page should
/// feel secure and simple * Clean typography and smooth spacing * Premium
/// fintech UI style
class ForgotPasswordPageWidget extends StatefulWidget {
  const ForgotPasswordPageWidget({super.key});

  static String routeName = 'forgot_password_page';
  static String routePath = '/forgotPasswordPage';

  @override
  State<ForgotPasswordPageWidget> createState() =>
      _ForgotPasswordPageWidgetState();
}

class _ForgotPasswordPageWidgetState extends State<ForgotPasswordPageWidget> {
  late ForgotPasswordPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitting = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ForgotPasswordPageModel());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AuthService().sendPasswordReset(
        email: _emailController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _emailSent = true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FlutterFlowIconButton(
                    borderRadius: 14,
                    buttonSize: 44,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: FlutterFlowTheme.of(context).primaryText,
                      size: 20,
                    ),
                    onPressed: () => context.goNamed(LoginpageWidget.routeName),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: FlutterFlowTheme.of(context).alternate,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Lottie.network(
                          'https://dimg.dreamflow.cloud/v1/lottie/secure+shield+lock+animation+black+and+white',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'auth_password_reset.title'.tr(),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                          font: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800),
                          color: FlutterFlowTheme.of(context).primaryText,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'auth_password_reset.description'.tr(),
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                        ),
                  ),
                  const SizedBox(height: 24),
                  if (_emailSent) ...[
                    Text('auth_password_reset.check_email'.tr(), textAlign: TextAlign.center, style: FlutterFlowTheme.of(context).headlineSmall),
                    const SizedBox(height: 12),
                    Text(
                      'auth_password_reset.email_sent'.tr(),
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => context.goNamed(LoginpageWidget.routeName),
                      child: Text('auth_password_reset.back_login'.tr()),
                    ),
                  ] else ...[
                    TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'auth_password_reset.email'.tr(),
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address.';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email address.';
                      }
                      return null;
                    },
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                      label: Text(_isSubmitting ? 'auth_password_reset.sending'.tr() : 'auth_password_reset.send_reset'.tr()),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.goNamed(LoginpageWidget.routeName),
                      child: const Text('Back to sign in'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
