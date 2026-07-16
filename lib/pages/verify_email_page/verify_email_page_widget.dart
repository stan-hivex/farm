import 'package:flutter/material.dart';
import '/services/auth/auth_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

class VerifyEmailPageWidget extends StatefulWidget {
  const VerifyEmailPageWidget({super.key});

  static String routeName = 'verify_email_page';
  static String routePath = '/verify-email';

  @override
  State<VerifyEmailPageWidget> createState() => _VerifyEmailPageWidgetState();
}

class _VerifyEmailPageWidgetState extends State<VerifyEmailPageWidget> {
  bool isLoading = false;
  bool verified = false;
  String? resultMessage;
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final token = Uri.base.queryParameters['token'] ?? '';
    if (token.isNotEmpty) {
      _verifyEmail(token);
    }
  }

  Future<void> _verifyEmail(String token) async {
    setState(() {
      isLoading = true;
      resultMessage = null;
      verified = false;
    });

    try {
      await AuthService().verifyEmail(token: token);
      setState(() {
        verified = true;
        resultMessage = 'Your email has been verified. You can now log in.';
      });
    } catch (e) {
      setState(() {
        resultMessage = 'Email verification failed. ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _resendVerification() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address to resend verification.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      resultMessage = null;
    });

    try {
      await AuthService().resendEmailVerification(email: email);
      setState(() {
        resultMessage = 'Verification email resent. Check your inbox.';
      });
    } catch (e) {
      setState(() {
        resultMessage = 'Unable to resend verification email. ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: FlutterFlowTheme.of(context).primary,
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24.0),
              Text(
                'Email Verification',
                style: FlutterFlowTheme.of(context).titleLarge,
              ),
              const SizedBox(height: 16.0),
              Text(
                'If you clicked a verification link, this page will confirm your email with the backend. If the link has expired, you can request a new one below.',
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
              const SizedBox(height: 24.0),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (verified)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.check_circle_outline, size: 64.0, color: Colors.green),
                    const SizedBox(height: 16.0),
                    Text(resultMessage ?? '', style: FlutterFlowTheme.of(context).bodyLarge),
                    const SizedBox(height: 24.0),
                    FFButtonWidget(
                      onPressed: () => Navigator.pushReplacementNamed(context, 'loginpage'),
                      text: 'Go to Login',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 50.0,
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                        elevation: 3.0,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ],
                )
              else ...[
                if (resultMessage != null) ...[
                  Text(resultMessage!, style: FlutterFlowTheme.of(context).bodyMedium.override(color: Colors.red)),
                  const SizedBox(height: 20.0),
                ],
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    hintText: 'Enter your email to resend verification',
                  ),
                ),
                const SizedBox(height: 16.0),
                FFButtonWidget(
                  onPressed: isLoading ? null : _resendVerification,
                  text: 'Resend Verification Email',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 50.0,
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                    elevation: 3.0,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                const SizedBox(height: 16.0),
                FFButtonWidget(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pushReplacementNamed(context, 'loginpage'),
                  text: 'Back to Login',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 50.0,
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                    elevation: 0.0,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
