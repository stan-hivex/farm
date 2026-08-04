import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/auth/auth_service.dart';
import '/services/auth/delete_account_validator.dart';

class DeleteAccountPageWidget extends StatefulWidget {
  const DeleteAccountPageWidget({super.key});

  static String routeName = 'delete_account_page';
  static String routePath = '/deleteAccountPage';

  @override
  State<DeleteAccountPageWidget> createState() => _DeleteAccountPageWidgetState();
}

class _DeleteAccountPageWidgetState extends State<DeleteAccountPageWidget> {
  final TextEditingController _passwordController = TextEditingController();
  bool _acknowledged = false;
  bool _confirmDelete = false;
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitDelete() async {
    final validation = DeleteAccountValidator.validate(
      password: _passwordController.text,
      acknowledged: _acknowledged,
      confirmDelete: _confirmDelete,
    );

    if (!validation.isValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.error ?? 'Unable to delete account')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await AuthService().deleteAccount(
        password: _passwordController.text.trim(),
        acknowledged: _acknowledged,
        confirmDelete: _confirmDelete,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );
      context.goNamed('loginpage');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: const Text('Delete Account'),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Permanently delete your account',
                style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'This action is permanent. It will sign you out, remove your local credentials, and delete your account after backend verification.',
                style: theme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'Current password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _passwordVisible = !_passwordVisible);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('I understand this action is permanent.'),
                        value: _acknowledged,
                        onChanged: (value) {
                          setState(() => _acknowledged = value ?? false);
                        },
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('I want to delete my account permanently.'),
                        value: _confirmDelete,
                        onChanged: (value) {
                          setState(() => _confirmDelete = value ?? false);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitDelete,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_forever_rounded),
                  label: Text(_isLoading ? 'Deleting account...' : 'Delete account permanently'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
