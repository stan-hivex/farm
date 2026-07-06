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
import '/services/auth/biometric_login_service.dart';
import '/pages/forgot_password_page/forgot_password_page_widget.dart';
import '/components/turnstile_widget.dart';
import '/core/config/env.dart';
import '/backend/services/api_service.dart';
import 'login_identifier.dart';

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

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool passwordVisible = false;
  bool isLoading = false;
  bool _biometricAvailable = false;
  String _biometricButtonLabel = 'Login with Biometric';
  String _turnstileToken = '';

  final String baseUrl = '${AppConfig.api}/auth';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginpageModel());
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
    identifierController.dispose();
    passwordController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _showLoginSecurityNotice() async {
    try {
      final response = await ApiService.getNotifications();
      final rawNotifications = response['data'];
      final notifications = rawNotifications is List
          ? rawNotifications.whereType<Map>().toList()
          : <Map>[];

      final latestLoginNotice = notifications.firstWhere(
        (item) {
          final title = (item['title'] ?? '').toString().toLowerCase();
          final body = (item['body'] ?? '').toString().toLowerCase();
          return title.contains('new login detected') ||
              body.contains('new login detected');
        },
        orElse: () => <String, dynamic>{},
      );

      if (!mounted) return;

      final noticeBody =
          ((latestLoginNotice['body'] ?? 'New login detected') as String?)
              ?.toString()
              .trim();
      final summary = (noticeBody ?? 'New login detected')
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .join(' • ');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summary.isNotEmpty ? summary : 'New login detected'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New login detected'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Login with email/phone number and password.
  Future<void> handleLogin() async {
    final identifier = normalizeLoginIdentifier(identifierController.text);
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

    if (Env.turnstileSiteKey.isNotEmpty && _turnstileToken.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Please complete the security check before continuing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await ApiService.login(
        identifier: identifier,
        password: password,
        turnstileToken: _turnstileToken,
      );

      final payload = response['data'] as Map<String, dynamic>? ?? {};
      final accessToken = payload['access_token'] as String? ?? '';
      final refreshToken = payload['refresh_token'] as String? ?? '';
      final data = payload['user'] as Map<String, dynamic>?;

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

      await _showLoginSecurityNotice();

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
        setState(() => isLoading = false);
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

      await _showLoginSecurityNotice();

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
        setState(() => isLoading = false);
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
                    /// Identifier Field
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email or Phone Number',
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
                          controller: identifierController,
                          decoration: inputDecoration(
                            context,
                            'Enter your email or phone number',
                          ),
                          keyboardType: TextInputType.text,
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

                    if (Env.turnstileSiteKey.isNotEmpty) ...[
                      TurnstileWidget(
                        siteKey: Env.turnstileSiteKey,
                        onTokenChanged: (token) {
                          setState(() => _turnstileToken = token);
                        },
                      ),
                      const SizedBox(height: 16.0),
                    ],

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
