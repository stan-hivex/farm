import 'dart:async';

import '/components/button/button_widget.dart';
import '/components/step_indicator/step_indicator_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/dashboard/dashboard_widget.dart';
import '/pages/biometric_unlock_page/biometric_unlock_page_widget.dart';
import '/services/auth/route_guard_service.dart';
import '/services/biometric_lock_service.dart';
import '/admin/core/admin_guard.dart';
import '/admin/core/admin_navigation.dart';
import '/admin/pages/admin_shell.dart';
import '/pages/superadmin/superadmin_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_model.dart';
export 'onboarding_model.dart';

class OnboardingWidget extends StatefulWidget {
  const OnboardingWidget({super.key});

  static String routeName = 'Onboarding';
  static String routePath = '/onboarding';

  @override
  State<OnboardingWidget> createState() => _OnboardingWidgetState();
}

class _OnboardingWidgetState extends State<OnboardingWidget> {
  late OnboardingModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isCheckingAuth = true;
  bool _showMarketing = false;
  bool _showAuthActions = false;
  Timer? _startupLogoTimer;
  Timer? _marketingTimer;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingModel());
    // Always show onboarding for a short duration on cold start so users
    // briefly see the intro before automatic navigation when already
    // authenticated (2-4 seconds). Adjust `displayDuration` to change duration.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _runStartupAuthCheck();
    });
  }

  @override
  void dispose() {
    _startupLogoTimer?.cancel();
    _marketingTimer?.cancel();
    _model.dispose();

    super.dispose();
  }

  Future<void> _runStartupAuthCheck() async {
    if (!mounted) return;

    print('AUTH GUARD');
    print('role=${FFAppState().role}');
    print('route=${OnboardingWidget.routePath}');

    setState(() {
      _isCheckingAuth = true;
      _showMarketing = false;
      _showAuthActions = false;
    });

    const logoDisplay = Duration(seconds: 3);
    const marketingDisplay = Duration(seconds: 5);

    _startupLogoTimer = Timer(logoDisplay, () {
      if (!mounted) return;
      setState(() => _showMarketing = true);

      _marketingTimer = Timer(marketingDisplay, () {
        if (!mounted) return;
        _runAuthenticatedFlow();
      });
    });

    await Future<void>.value();
  }

  Future<void> _runAuthenticatedFlow() async {
    if (!mounted) return;

    final isAuthenticated = await RouteGuardService().isUserAuthenticated();

    if (!mounted) return;

    final isAdminAuthenticated = await AdminGuard.isAuthenticated();
    if (isAdminAuthenticated) {
      if (!mounted) return;
      final adminRole = await AdminGuard.getAdminRole();
      if (adminRole.toLowerCase() == 'super_admin') {
        context.go(SuperadminDashboardPage.routePath);
      } else {
        AuthNavigation.replaceAllWithBuilder(
          context,
          (_) => AdminShell(),
        );
      }
      return;
    }

    if (isAuthenticated) {
      final restoredRoute = await _readRestoredRoute();
      if (!mounted) return;
      final lockService = BiometricLockService();
      final shouldLock = await lockService.shouldRequireUnlock();
      if (!mounted) return;
      if (shouldLock) {
        context.goNamed(BiometricUnlockPageWidget.routeName);
      } else {
        context.go(restoredRoute);
      }
      return;
    }

    setState(() {
      _isCheckingAuth = false;
      _showAuthActions = true;
    });
  }

  Future<String> _readRestoredRoute() async {
    final saved = (await SharedPreferences.getInstance())
        .getString('lastAuthenticatedRoute');
    final role = FFAppState().role.toLowerCase();
    final route = saved ?? '';
    if (role == 'super_admin') {
      return route.startsWith('/superadmin')
          ? route
          : SuperadminDashboardPage.routePath;
    }
    if (role == 'admin') {
      return route.startsWith('/admin') ? route : '/admin';
    }
    return route.isNotEmpty &&
            !route.startsWith('/admin') &&
            !route.startsWith('/superadmin') &&
            !RouteGuardService().isPublicRoute(route)
        ? route
        : DashboardWidget.routePath;
  }

  Widget _buildLogoSplash(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 96.0,
          height: 96.0,
          decoration: BoxDecoration(
            color: theme.primary,
            borderRadius: BorderRadius.circular(24.0),
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/images/app_logo.png',
            width: 68.0,
            height: 68.0,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth && !_showMarketing) {
      return _buildLogoSplash(context);
    }

    final theme = FlutterFlowTheme.of(context);
    final primaryTextColor = const Color(0xFF111111);
    final secondaryTextColor = const Color(0xFF4B5563);
    final mutedTextColor = const Color(0xFF6B7280);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final marketingHeight =
                  (constraints.maxHeight * 0.34).clamp(250.0, 310.0);
              final artworkSize = marketingHeight - 24.0;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 96.0,
                          height: 96.0,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/app_logo.png',
                            width: 68.0,
                            height: 68.0,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'onboarding.app_name'.tr(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 42.0,
                            fontWeight: FontWeight.w800,
                            color: primaryTextColor,
                          ),
                        ),
                        Text(
                          'onboarding.tagline'.tr(),
                          style: GoogleFonts.inter(
                            fontSize: 20.0,
                            fontStyle: FontStyle.italic,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Keep the full marketing artwork visible across phone sizes.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 28.0, 24.0, 0.0),
                    child: SizedBox(
                      height: marketingHeight,
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Lottie.network(
                          'https://dimg.dreamflow.cloud/v1/lottie/minimalist+abstract+growing+loop+animation+grayscale',
                          width: artworkSize,
                          height: artworkSize,
                          fit: BoxFit.contain,
                          animate: true,
                        ),
                      ),
                    ),
                  ),
                  // Scrollable content section
                  Expanded(
                    child: SingleChildScrollView(
                      primary: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Tokenize Your Future',
                                  textAlign: TextAlign.center,
                                  style: FlutterFlowTheme.of(context)
                                      .headlineMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineMedium
                                                  .fontStyle,
                                        ),
                                        color: primaryTextColor,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .headlineMedium
                                            .fontStyle,
                                        lineHeight: 1.25,
                                      ),
                                ),
                                Text(
                                  'The first integrated blockchain ecosystem for fast payments and escrow services.',
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  style: FlutterFlowTheme.of(context)
                                      .bodyLarge
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyLarge
                                                  .fontStyle,
                                        ),
                                        color: secondaryTextColor,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .fontStyle,
                                        lineHeight: 1.5,
                                      ),
                                ),
                              ].divide(const SizedBox(height: 16.0)),
                            ),
                            const SizedBox(height: 24.0),
                            wrapWithModel(
                              model: _model.stepIndicatorModel,
                              updateCallback: () => safeSetState(() {}),
                              child: const StepIndicatorWidget(
                                active: true,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            if (_isCheckingAuth)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                child: Column(
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          theme.primary),
                                    ),
                                    const SizedBox(height: 12.0),
                                    Text(
                                      'Preparing your experience…',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .copyWith(color: secondaryTextColor),
                                    ),
                                  ],
                                ),
                              )
                            else if (_showAuthActions)
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  wrapWithModel(
                                    model: _model.buttonModel2,
                                    updateCallback: () => safeSetState(() {}),
                                    child: ButtonWidget(
                                      content: 'Sign In',
                                      icon_present: false,
                                      icon_end_present: false,
                                      on_tap: 'navigate:loginpage',
                                      color: Colors.black,
                                      variant: 'primary',
                                      size: 'large',
                                      full_width: true,
                                      loading: false,
                                      disabled: false,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          "Don't have an account?",
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .copyWith(
                                                  color: secondaryTextColor),
                                        ),
                                        const SizedBox(height: 8.0),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton(
                                            onPressed: () => context
                                                .pushNamed('registerpage'),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Color(0xFF111111),
                                                width: 1.2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16.0),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 16.0,
                                              ),
                                              backgroundColor: Colors.white,
                                            ),
                                            child: Text(
                                              'Register',
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .copyWith(
                                                        color: primaryTextColor,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ].divide(const SizedBox(height: 12.0)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer section - always visible at bottom
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'By continuing, you agree to our',
                              style: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                    ),
                                    color: mutedTextColor,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelSmall
                                        .fontStyle,
                                    lineHeight: 1.2,
                                  ),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.pushNamed('TermsOfServicePage');
                              },
                              child: Text(
                                'Terms of Service',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                      ),
                                      color: primaryTextColor,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                      decoration: TextDecoration.underline,
                                      lineHeight: 1.2,
                                    ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                context.pushNamed('PrivacyPolicyPage');
                              },
                              child: Text(
                                'Privacy Policy',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelSmall
                                            .fontStyle,
                                      ),
                                      color: primaryTextColor,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .fontStyle,
                                      decoration: TextDecoration.underline,
                                      lineHeight: 1.2,
                                    ),
                              ),
                            ),
                          ].divide(const SizedBox(width: 4.0)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
