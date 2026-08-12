import 'dart:convert' as convert;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '/app_state.dart';
import '/backend/services/api_service.dart';
import '/core/app_config.dart';

class AddAdminPage extends StatefulWidget {
  const AddAdminPage({super.key});

  static const String routeName = 'add_admin_page';
  static const String routePath = '/superadmin/add-admin';

  @override
  State<AddAdminPage> createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _countryCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.request(
        method: 'POST',
        path: '/auth/admin/create',
        body: {
          'first_name': _firstNameCtrl.text.trim(),
          'last_name': _lastNameCtrl.text.trim(),
          'username': _usernameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
          'password': _passwordCtrl.text,
        },
      );

      final decoded = res;
      final message = decoded['message'] ?? 'Admin created successfully';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.green),
        );
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF162033),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFFD4AF37);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1320),
        foregroundColor: Colors.white,
        title: Text('Create Admin', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a new admin account with restricted access.',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('First Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firstNameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('First name'),
                            validator: (value) => (value?.trim().isEmpty ?? true) ? 'First name is required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Last Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lastNameCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Last name'),
                            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Last name is required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel('Username'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Username'),
                  validator: (value) {
                    if ((value?.trim().isEmpty ?? true)) return 'Username is required';
                    if ((value?.trim().length ?? 0) < 3) return 'Username must be at least 3 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailCtrl,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('Email'),
                            validator: (value) {
                              if ((value?.trim().isEmpty ?? true)) return 'Email is required';
                              if (!value!.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Phone'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneCtrl,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('Phone'),
                            validator: (value) => (value?.trim().isEmpty ?? true) ? 'Phone is required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildLabel('Country'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _countryCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Country'),
                  validator: (value) => (value?.trim().isEmpty ?? true) ? 'Country is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Password'),
                            obscureText: true,
                            validator: (value) {
                              if ((value?.isEmpty ?? true)) return 'Password is required';
                              if ((value?.length ?? 0) < 8) return 'Password must be at least 8 characters';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Confirm Password'),
                            obscureText: true,
                            validator: (value) {
                              if ((value?.isEmpty ?? true)) return 'Confirm password is required';
                              if (value != _passwordCtrl.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.black)),
                          )
                        : Text('Create Admin', style: GoogleFonts.plusJakartaSans(color: Colors.black, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
