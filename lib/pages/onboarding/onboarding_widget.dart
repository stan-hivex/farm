import '/components/button/button_widget.dart';
import '/components/step_indicator/step_indicator_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/biometric_unlock_page/biometric_unlock_page_widget.dart';
import '/services/auth/route_guard_service.dart';
import '/services/biometric_lock_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
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
  bool _showAuthActions = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => OnboardingModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runStartupAuthCheck();
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> _runStartupAuthCheck() async {
    if (!mounted) return;

    setState(() {
      _isCheckingAuth = true;
      _showAuthActions = false;
    });

    await Future.delayed(const Duration(milliseconds: 250));

    if (!mounted) return;

    final isAuthenticated = await RouteGuardService().isUserAuthenticated();

    if (!mounted) return;

    if (isAuthenticated) {
      final lockService = BiometricLockService();
      final shouldLock = await lockService.shouldRequireUnlock();
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      if (shouldLock) {
        context.goNamed(BiometricUnlockPageWidget.routeName);
      } else {
        context.goNamed('Dashboard');
      }
      return;
    }

    setState(() {
      _isCheckingAuth = false;
      _showAuthActions = true;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        body: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 40.0, 0.0, 60.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 80.0,
                                height: 80.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context).primary,
                                  borderRadius: BorderRadius.circular(20.0),
                                  shape: BoxShape.rectangle,
                                ),
                                alignment: const AlignmentDirectional(0.0, 0.0),
                                child: SizedBox(
                                  width: 40.0,
                                  height: 50.0,
                                  child: Stack(
                                    alignment:
                                        const AlignmentDirectional(-1.0, -1.0),
                                    children: [
                                      Align(
                                        alignment: const AlignmentDirectional(
                                            0.0, 0.0),
                                        child: Container(
                                          width: 6.0,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .onPrimary,
                                            borderRadius:
                                                BorderRadius.circular(2.0),
                                            shape: BoxShape.rectangle,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: const AlignmentDirectional(
                                            -1.0, -0.6),
                                        child: Container(
                                          width: 24.0,
                                          height: 6.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .onPrimary,
                                            borderRadius:
                                                BorderRadius.circular(2.0),
                                            shape: BoxShape.rectangle,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: const AlignmentDirectional(
                                            -1.0, 0.0),
                                        child: Container(
                                          width: 18.0,
                                          height: 6.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .onPrimary,
                                            borderRadius:
                                                BorderRadius.circular(2.0),
                                            shape: BoxShape.rectangle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'FARM',
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .headlineLarge
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w900,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .headlineLarge
                                                    .fontStyle,
                                          ),
                                          color: primaryTextColor,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w900,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .headlineLarge
                                                  .fontStyle,
                                          lineHeight: 1.2,
                                        ),
                                  ),
                                  Text(
                                    'a loop of growth',
                                    textAlign: TextAlign.center,
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleMedium
                                                    .fontWeight,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          color: secondaryTextColor,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontWeight,
                                          fontStyle: FontStyle.italic,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                ].divide(const SizedBox(height: 4.0)),
                              ),
                            ].divide(const SizedBox(height: 24.0)),
                          ),
                        ),
                        Container(
                          height: 300.0,
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Lottie.network(
                            'https://dimg.dreamflow.cloud/v1/lottie/minimalist+abstract+growing+loop+animation+grayscale',
                            width: 280.0,
                            height: 280.0,
                            fit: BoxFit.contain,
                            animate: true,
                          ),
                        ),
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
                                      fontStyle: FlutterFlowTheme.of(context)
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
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
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
                        Container(
                          height: 32.0,
                        ),
                        wrapWithModel(
                          model: _model.stepIndicatorModel,
                          updateCallback: () => safeSetState(() {}),
                          child: const StepIndicatorWidget(
                            active: true,
                          ),
                        ),
                        Container(
                          height: 32.0,
                        ),
                        if (_isCheckingAuth)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                                          .copyWith(color: secondaryTextColor),
                                    ),
                                    const SizedBox(height: 8.0),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () =>
                                            context.pushNamed('registerpage'),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF111111),
                                            width: 1.2,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16.0),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16.0,
                                          ),
                                          backgroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          'Register',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .copyWith(
                                                color: primaryTextColor,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ].divide(const SizedBox(height: 12.0)),
                          ),
                        Container(
                          height: 24.0,
                        ),
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
                            Text(
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
                          ].divide(const SizedBox(width: 4.0)),
                        ),
                      ],
                    ),
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
