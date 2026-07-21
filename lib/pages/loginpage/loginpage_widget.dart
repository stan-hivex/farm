import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'loginpage_model.dart';
export 'loginpage_model.dart';
import '/admin/pages/admin_shell.dart';
import '/pages/superadmin/superadmin_dashboard_page.dart';
import '/services/secure_storage_service.dart';
import '/services/auth/auth_service.dart';
import '/services/auth/biometric_login_service.dart';
import '/pages/forgot_password_page/forgot_password_page_widget.dart';


/// Create a premium black and white fintech login page for FARM App.
///
/// Include:  * FARM logo at the top * Phone number input field * Password
/// input field * Login button * Forgot password text button * "Create
/// Account" button below login  Style:  * Modern banking app design * Black
/// and white theme * Rounded cards and buttons * Minimal and clean layout *
/// Premium fintech appearance * Mobile-first responsive design * Smooth
/// spacing and typography  Important:  * Design should feel like a secure
/// banking app * Professional and trustworthy UI * Keep layout simple and
/// elegant TAKE TIME AND DO IT IN DETAIL
class LoginpageWidget extends StatefulWidget {
  const LoginpageWidget({super.key});

  static String routeName = 'loginpage';
  static String routePath = '/loginpage';

  @override
  State<LoginpageWidget> createState() => _LoginpageWidgetState();
}

class _LoginpageWidgetState extends State<LoginpageWidget> {
  late LoginpageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;
  bool isLoading = false;
  bool _biometricAvailable = false;
  String _biometricButtonLabel = 'Login with Biometric';
  Map<String, String> _selectedCountry = {
    'name': 'Algeria',
    'code': '+213',
    'flag': '🇩🇿',
  };

  final List<Map<String, String>> _africanCountries = [
    {'name': 'Algeria', 'code': '+213', 'flag': '🇩🇿'},
    {'name': 'Angola', 'code': '+244', 'flag': '🇦🇴'},
    {'name': 'Benin', 'code': '+229', 'flag': '🇧🇯'},
    {'name': 'Botswana', 'code': '+267', 'flag': '🇧🇼'},
    {'name': 'Burkina Faso', 'code': '+226', 'flag': '🇧🇫'},
    {'name': 'Burundi', 'code': '+257', 'flag': '🇧🇮'},
    {'name': 'Cabo Verde', 'code': '+238', 'flag': '🇨🇻'},
    {'name': 'Cameroon', 'code': '+237', 'flag': '🇨🇲'},
    {'name': 'Central African Republic', 'code': '+236', 'flag': '🇨🇫'},
    {'name': 'Chad', 'code': '+235', 'flag': '🇹🇩'},
    {'name': 'Comoros', 'code': '+269', 'flag': '🇰🇲'},
    {'name': 'Congo', 'code': '+242', 'flag': '🇨🇬'},
    {'name': 'DR Congo', 'code': '+243', 'flag': '🇨🇩'},
    {'name': 'Cote d\'Ivoire', 'code': '+225', 'flag': '🇨🇮'},
    {'name': 'Djibouti', 'code': '+253', 'flag': '🇩🇯'},
    {'name': 'Egypt', 'code': '+20', 'flag': '🇪🇬'},
    {'name': 'Equatorial Guinea', 'code': '+240', 'flag': '🇬🇶'},
    {'name': 'Eritrea', 'code': '+291', 'flag': '🇪🇷'},
    {'name': 'Eswatini', 'code': '+268', 'flag': '🇸🇿'},
    {'name': 'Ethiopia', 'code': '+251', 'flag': '🇪🇹'},
    {'name': 'Gabon', 'code': '+241', 'flag': '🇬🇦'},
    {'name': 'Gambia', 'code': '+220', 'flag': '🇬🇲'},
    {'name': 'Ghana', 'code': '+233', 'flag': '🇬🇭'},
    {'name': 'Guinea', 'code': '+224', 'flag': '🇬🇳'},
    {'name': 'Guinea-Bissau', 'code': '+245', 'flag': '🇬🇼'},
    {'name': 'Kenya', 'code': '+254', 'flag': '🇰🇪'},
    {'name': 'Lesotho', 'code': '+266', 'flag': '🇱🇸'},
    {'name': 'Liberia', 'code': '+231', 'flag': '🇱🇷'},
    {'name': 'Libya', 'code': '+218', 'flag': '🇱🇾'},
    {'name': 'Madagascar', 'code': '+261', 'flag': '🇲🇬'},
    {'name': 'Malawi', 'code': '+265', 'flag': '🇲🇼'},
    {'name': 'Mali', 'code': '+223', 'flag': '🇲🇱'},
    {'name': 'Mauritania', 'code': '+222', 'flag': '🇲🇷'},
    {'name': 'Mauritius', 'code': '+230', 'flag': '🇲🇺'},
    {'name': 'Morocco', 'code': '+212', 'flag': '🇲🇦'},
    {'name': 'Mozambique', 'code': '+258', 'flag': '🇲🇿'},
    {'name': 'Namibia', 'code': '+264', 'flag': '🇳🇦'},
    {'name': 'Niger', 'code': '+227', 'flag': '🇳🇪'},
    {'name': 'Nigeria', 'code': '+234', 'flag': '🇳🇬'},
    {'name': 'Rwanda', 'code': '+250', 'flag': '🇷🇼'},
    {'name': 'Sao Tome and Principe', 'code': '+239', 'flag': '🇸🇹'},
    {'name': 'Senegal', 'code': '+221', 'flag': '🇸🇳'},
    {'name': 'Seychelles', 'code': '+248', 'flag': '🇸🇨'},
    {'name': 'Sierra Leone', 'code': '+232', 'flag': '🇸🇱'},
    {'name': 'Somalia', 'code': '+252', 'flag': '🇸🇴'},
    {'name': 'South Africa', 'code': '+27', 'flag': '🇿🇦'},
    {'name': 'South Sudan', 'code': '+211', 'flag': '🇸🇸'},
    {'name': 'Sudan', 'code': '+249', 'flag': '🇸🇩'},
    {'name': 'Tanzania', 'code': '+255', 'flag': '🇹🇿'},
    {'name': 'Togo', 'code': '+228', 'flag': '🇹🇬'},
    {'name': 'Tunisia', 'code': '+216', 'flag': '🇹🇳'},
    {'name': 'Uganda', 'code': '+256', 'flag': '🇺🇬'},
    {'name': 'Zambia', 'code': '+260', 'flag': '🇿🇲'},
    {'name': 'Zimbabwe', 'code': '+263', 'flag': '🇿🇼'},
  ];

  final String baseUrl = '${AppConfig.api}/auth';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginpageModel());
    FFAppState().themeMode = ThemeMode.light;
    _initializeBiometric();
  }

  Future<void> _initializeBiometric() async {
    try {
      final biometricService = BiometricLoginService();
      final canUse = await biometricService.canUseBiometrics();
      final hasSession = await biometricService.hasBiometricSession();

      if (mounted && canUse && hasSession) {
        final label = await biometricService.getBiometricButtonLabel();
        setState(() {
          _biometricAvailable = true;
          _biometricButtonLabel = label;
        });
      }
    } catch (e) {
      debugPrint('Error initializing biometric: $e');
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    passwordController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _finalizeSuccessfulLogin(Map<String, dynamic> response) async {
    final accessToken = response['farmJwt'] as String? ?? '';
    final refreshToken = response['refreshToken'] as String? ?? '';
    final data = response['user'] as Map<String, dynamic>?;

    if (accessToken.isNotEmpty && data != null) {
      FFAppState().accessToken = accessToken;
      FFAppState().refreshToken = refreshToken;
      FFAppState().userId = data['id'] ?? '';
      FFAppState().firstName = data['first_name'] ?? '';
      FFAppState().userName = data['username'] ?? '';
      FFAppState().phone = data['phone'] ?? '';
      FFAppState().kycStatus = data['kyc_status'] ?? '';
      FFAppState().emailVerified = data['email_verified'] == true;
      final role = (data['role'] ?? 'user').toString();
      FFAppState().role = role;
      FFAppState().isLoggedIn = true;

      await SecureStorageService.writeAccessToken(accessToken);
      await SecureStorageService.writeRefreshToken(refreshToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', accessToken);
      await prefs.setString('refreshToken', refreshToken);
      await prefs.setString('userId', data['id'] ?? '');
      await prefs.setString('role', role);
      await prefs.setBool('isLoggedIn', true);

      if (role == 'admin' || role == 'super_admin') {
        await prefs.setString('adminToken', accessToken);
        await prefs.setString('adminRefreshToken', refreshToken);
        await prefs.setString('adminRole', role);
        await prefs.setString('adminName', data['first_name'] ?? 'Admin');
      } else {
        await prefs.remove('adminToken');
        await prefs.remove('adminRefreshToken');
        await prefs.remove('adminRole');
        await prefs.remove('adminName');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login successful'),
        backgroundColor: Colors.green,
      ),
    );

    Future.delayed(
      const Duration(seconds: 1),
      () {
        final role = FFAppState().role;
        if (role == 'super_admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SuperadminDashboardPage(),
            ),
          );
        } else if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminShell()),
          );
        } else {
          context.goNamed('Dashboard');
        }
      },
    );
  }

  /// Login with email or phone/password
  Future<void> handleLogin() async {
    final raw = phoneController.text.trim();
    // normalize: keep digits only and remove leading zeros
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final normalizedDigits = digitsOnly.replaceFirst(RegExp(r'^0+'), '');
    final countryCode = _selectedCountry['code']?.replaceAll('+', '') ?? '';
    final identifier = countryCode.isNotEmpty ? '+$countryCode$normalizedDigits' : '+$normalizedDigits';
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await AuthService().login(
        identifier: identifier,
        password: password,
        countryCode: _selectedCountry['code'],
      );

      // Backend handles all authentication - no OTP verification needed
      // Mobile and web flows are now unified
      await _finalizeSuccessfulLogin(response);
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        final isNetworkIssue = errorMsg.contains('Connection closed') ||
            errorMsg.contains('ERR_CONNECTION_CLOSED') ||
            errorMsg.contains('SocketException') ||
            errorMsg.contains('Failed host lookup') ||
            errorMsg.contains('Network');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isNetworkIssue
                ? 'Unable to connect to backend. Please check your network or backend service.'
                : 'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Login with biometric (fingerprint/face ID)
  Future<void> handleBiometricLogin() async {
    setState(() => isLoading = true);

    try {
      debugPrint('[BiometricLogin] Starting biometric authentication...');

      final biometricService = BiometricLoginService();
      final response = await biometricService.authenticateWithBiometric();

      if (!response['success']) {
        throw Exception(
            response['message'] ?? 'Biometric authentication failed');
      }

      final user = response['user'] as Map<String, dynamic>? ?? {};
      final role = (user['role'] ?? 'user').toString();

      debugPrint(
          '[BiometricLogin] Biometric login successful, routing to dashboard...');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric login successful'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(
        const Duration(seconds: 1),
        () {
          if (!mounted) return;

          if (role == 'super_admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const SuperadminDashboardPage(),
              ),
            );
          } else if (role == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminShell()),
            );
          } else {
            context.goNamed('Dashboard');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric login failed: $errorMsg'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  InputDecoration inputDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: FlutterFlowTheme.of(context).secondaryText,
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 18.0,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.0),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
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
        body: SingleChildScrollView(
          primary: false,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// LOGO SECTION
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 72.0,
                      height: 72.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).primaryText,
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: SizedBox(
                        width: 40.0,
                        height: 50.0,
                        child: Stack(
                          alignment: const AlignmentDirectional(-1.0, -1.0),
                          children: [
                            Align(
                              alignment: const AlignmentDirectional(0.0, 0.0),
                              child: Container(
                                width: 6.0,
                                height: 50.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).onPrimary,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(-1.0, -0.6),
                              child: Container(
                                width: 24.0,
                                height: 6.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).onPrimary,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                            ),
                            Align(
                              alignment: const AlignmentDirectional(-1.0, 0.0),
                              child: Container(
                                width: 18.0,
                                height: 6.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).onPrimary,
                                  borderRadius: BorderRadius.circular(2.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'FARM',
                      style:
                          FlutterFlowTheme.of(context).headlineLarge.override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w900,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w900,
                              ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Sign In to Your Account',
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(),
                            color: FlutterFlowTheme.of(context).secondaryText,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 40.0),

                /// FORM SECTION
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    /// Phone Field
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone',
                          style: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final selected = await showModalBottomSheet<Map<String, String>>( 
                                  context: context,
                                  builder: (_) {
                                    return SizedBox(
                                      height: 360,
                                      child: Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Text(
                                              'Select country',
                                              style: FlutterFlowTheme.of(context).titleMedium,
                                            ),
                                          ),
                                          Expanded(
                                            child: ListView.builder(
                                              itemCount: _africanCountries.length,
                                              itemBuilder: (ctx, i) {
                                                final c = _africanCountries[i];
                                                return ListTile(
                                                  leading: Text(c['flag'] ?? ''),
                                                  title: Text(
                                                    c['name'] ?? '',
                                                    style: FlutterFlowTheme.of(context).bodyMedium,
                                                  ),
                                                  trailing: Text(c['code'] ?? ''),
                                                  onTap: () => Navigator.of(ctx).pop(c),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );

                                if (selected != null) {
                                  setState(() {
                                    _selectedCountry = selected;
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                                ),
                                child: Row(
                                  children: [
                                    Text(_selectedCountry['flag'] ?? ''),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${_selectedCountry['name'] ?? ''} ${_selectedCountry['code'] ?? ''}',
                                        style: FlutterFlowTheme.of(context).bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: phoneController,
                                decoration: inputDecoration(context, 'Enter phone number (without country code)'),
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24.0),

                    /// Password Field
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: FlutterFlowTheme.of(context)
                              .labelLarge
                              .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w600,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                              ),
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: passwordController,
                          decoration: inputDecoration(context, 'Enter password')
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(
                                    () => passwordVisible = !passwordVisible);
                              },
                            ),
                          ),
                          obscureText: !passwordVisible,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32.0),

                    /// Login Button
                    FFButtonWidget(
                      onPressed: isLoading ? null : handleLogin,
                      text: isLoading ? 'Signing In...' : 'Sign In',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56.0,
                        padding: const EdgeInsets.symmetric(vertical: 0.0),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color(0xFF1F1F1F)
                            : FlutterFlowTheme.of(context).primary,
                        textStyle:
                            FlutterFlowTheme.of(context).titleSmall.override(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                        borderSide: const BorderSide(
                          color: Colors.transparent,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),

                    const SizedBox(height: 16.0),

                    /// Biometric Login Button (if available)
                    if (_biometricAvailable)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: FlutterFlowTheme.of(context).alternate,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  'Or',
                                  style: FlutterFlowTheme.of(context)
                                      .bodySmall
                                      .override(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: FlutterFlowTheme.of(context).alternate,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          FFButtonWidget(
                            onPressed: isLoading ? null : handleBiometricLogin,
                            text: _biometricButtonLabel,
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 56.0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 0.0),
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                        ],
                      ),

                    TextButton(
                      onPressed: () =>
                          context.pushNamed(ForgotPasswordPageWidget.routeName),
                      child: Text(
                        'Forgot password?',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              color: FlutterFlowTheme.of(context).primary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),

                    /// Create Account Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                        GestureDetector(
                          onTap: () => context.pushNamed('registerpage'),
                          child: Text(
                            'Sign Up',
                            style: FlutterFlowTheme.of(context)
                                .bodySmall
                                .override(
                                  color: FlutterFlowTheme.of(context).primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
