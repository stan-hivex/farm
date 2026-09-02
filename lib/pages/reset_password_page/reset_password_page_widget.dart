import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/loginpage/loginpage_widget.dart';
import '/pages/forgot_password_page/forgot_password_page_widget.dart';
import '/services/auth/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ResetPasswordPageWidget extends StatefulWidget {
  const ResetPasswordPageWidget({
    super.key,
    this.token = '',
    this.email = '',
  });

  static String routeName = 'reset_password_page';
  static String routePath = '/reset-password';

  final String token;
  final String email;

  @override
  State<ResetPasswordPageWidget> createState() => _ResetPasswordPageWidgetState();
}

class _ResetPasswordPageWidgetState extends State<ResetPasswordPageWidget> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isCheckingLink = true;
  bool _linkIsValid = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _linkMessage = 'auth_password_reset.checking';
  late String _token;
  late String _email;

  @override
  void initState() {
    super.initState();
    _token = widget.token.isNotEmpty ? widget.token : Uri.base.queryParameters['token'] ?? '';
    _email = widget.email.isNotEmpty ? widget.email : Uri.base.queryParameters['email'] ?? '';
    if (_token.isEmpty) {
      _token = Uri.base.queryParameters['oobCode'] ?? '';
    }
    _verifyResetCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_linkIsValid || _isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AuthService().confirmPasswordReset(
        token: _token,
        email: _email,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset successful. You can now sign in with your new password.'),
        backgroundColor: Colors.green,
      ));
      if (mounted) context.goNamed(LoginpageWidget.routeName);
    } catch (e) {
      if (!mounted) {
        return;
      }

      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyResetCode() async {
    if (_token.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isCheckingLink = false;
        _linkMessage = 'auth_password_reset.invalid';
      });
      return;
    }
    try {
      _email = await FirebaseAuth.instance.verifyPasswordResetCode(_token);
      if (!mounted) return;
      setState(() {
        _isCheckingLink = false;
        _linkIsValid = true;
        _linkMessage = 'auth_password_reset.description';
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isCheckingLink = false;
        _linkMessage = error.code == 'expired-action-code'
            ? 'auth_password_reset.expired'
            : 'auth_password_reset.used';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingLink = false;
        _linkMessage = 'auth_password_reset.invalid';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Password'),
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        foregroundColor: FlutterFlowTheme.of(context).primaryText,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('auth_password_reset.title'.tr(), style: FlutterFlowTheme.of(context).headlineSmall),
                const SizedBox(height: 16),
                Text(_linkMessage.tr(), style: FlutterFlowTheme.of(context).bodyMedium),
                if (_isCheckingLink) ...[
                  const SizedBox(height: 32),
                  const Center(child: CircularProgressIndicator()),
                ] else if (_linkIsValid) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'auth_password_reset.new_password'.tr(),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || !RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^\da-zA-Z]).{12,}$').hasMatch(value)) {
                        return 'auth_password_reset.requirements'.tr();
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_showConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'auth_password_reset.confirm_password'.tr(),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) return 'auth_password_reset.password_mismatch'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submit,
                    icon: _isSubmitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_reset),
                    label: Text(_isSubmitting ? 'auth_password_reset.updating'.tr() : 'auth_password_reset.reset'.tr()),
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.goNamed(ForgotPasswordPageWidget.routeName),
                    icon: const Icon(Icons.mark_email_read_outlined),
                    label: Text('auth_password_reset.request_new'.tr()),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.goNamed(LoginpageWidget.routeName),
                  child: const Text('Back to sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
