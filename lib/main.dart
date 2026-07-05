import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'core/app_theme.dart';
import 'core/config/env.dart';
import 'index.dart';
import 'services/device_fingerprint_service.dart';
import 'backend/api_requests/biometric_api_service.dart';
import 'services/biometric_gate_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the project root .env file.
  await dotenv.load(fileName: '.env');

  // Initialize Supabase with environment variables
  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  // Global Flutter framework error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await EasyLocalization.ensureInitialized();
  await FFAppState().initializePersistedState();
  await FlutterFlowTheme.initialize();

  if (kIsWeb) {
    setUrlStrategy(HashUrlStrategy());
  }

  // Run the app inside a guarded zone to capture uncaught errors with stack traces
  runZonedGuarded(() {
    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('sw'),
          Locale('fr'),
          Locale('es'),
          Locale('ar'),
        ],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => FFAppState()),
          ],
          child: const MyApp(),
        ),
      ),
    );
  }, (error, stack) {
    // Print uncaught errors to console so they appear in the browser devtools
    // and in the terminal running `flutter run`.
    // Use debugPrint if available at runtime.
    try {
      // ignore: avoid_print
      print('Uncaught error: $error');
      // ignore: avoid_print
      print(stack.toString());
    } catch (_) {}
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // =========================================
  // REQUIRED BY FLUTTERFLOW
  // =========================================
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _biometricGateOpen = false;

  late AppStateNotifier _appStateNotifier;

  late GoRouter _router;

  ThemeMode _effectiveThemeMode(String currentLocation) {
    return context.watch<FFAppState>().themeMode;
  }

  // =========================================
  // ROUTE HELPERS
  // =========================================
  String getRoute([RouteMatch? routeMatch]) {
    final routeConfig = _router.routerDelegate.currentConfiguration;
    if (routeConfig.isEmpty) {
      return '';
    }

    final RouteMatch lastMatch = routeMatch ?? routeConfig.last;

    final RouteMatchList matchList =
        lastMatch is ImperativeRouteMatch ? lastMatch.matches : routeConfig;

    if (matchList.uri.path.isEmpty) {
      return '';
    }

    return matchList.uri.path;
  }

  List<String> getRouteStack() {
    final currentConfig = _router.routerDelegate.currentConfiguration;
    if (currentConfig.isEmpty) {
      return <String>[];
    }

    return currentConfig.matches.map((e) => getRoute(e)).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _appStateNotifier = AppStateNotifier.instance;

    _router = createRouter(_appStateNotifier);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _verifyBiometricDeviceAndGate();
      _refreshAppState();
    }
  }

  Future<void> _refreshAppState() async {
    if (!mounted || !FFAppState().isLoggedIn) {
      return;
    }

    try {
      // Refresh app state - user is already logged in
      if (!mounted) return;
    } catch (e) {
      debugPrint('App resume refresh failed: $e');
    }
  }

  Future<void> _verifyBiometricDeviceAndGate() async {
    if (!mounted ||
        _biometricGateOpen ||
        !FFAppState().isLoggedIn ||
        !FFAppState().biometricsEnabled) {
      return;
    }

    final lastVerified = await SecureStorageService.readBiometricLastVerified();
    if (!BiometricGateService.shouldRequireBiometricCheck(lastVerified)) {
      return;
    }

    // Verify device fingerprint with backend
    try {
      final deviceFingerprint =
          await DeviceFingerprintService.getDeviceFingerprint();
      final verification = await BiometricApiService.verifyDevice(
        token: FFAppState().accessToken,
        deviceFingerprint: deviceFingerprint,
      );

      if (!mounted) return;

      if (verification['trusted'] == false) {
        final requiresReauth = verification['requiresReauth'] == true;
        debugPrint('Device verification failed: ${verification['message']}');

        if (requiresReauth) {
          await FFAppState().clearAuthCredentials();
          FFAppState().biometricsEnabled = false;
          await SecureStorageService.clearBiometricData();

          if (mounted) {
            GoRouter.of(context).goNamed(LoginpageWidget.routeName);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade900,
                content: Text(
                  'Security Alert: ${verification['message']}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          return;
        }

        _showBiometricGateIfNeeded();
        return;
      }

      // Device verified, show biometric gate
      _showBiometricGateIfNeeded();
    } catch (e) {
      debugPrint('Device verification error: $e');
      // Continue with biometric gate even if verification fails (offline mode)
      _showBiometricGateIfNeeded();
    }
  }

  void _showBiometricGateIfNeeded() {
    if (!mounted ||
        _biometricGateOpen ||
        !FFAppState().isLoggedIn ||
        !FFAppState().biometricsEnabled) {
      return;
    }

    final currentLocation = getRoute();
    if (currentLocation == BiometricSecurityPageWidget.routePath ||
        currentLocation == LoginpageWidget.routePath ||
        currentLocation == RegisterpageWidget.routePath ||
        currentLocation == OnboardingWidget.routePath) {
      return;
    }

    _biometricGateOpen = true;
    final uri = Uri.parse(currentLocation);
    final returnPath = uri.replace(
      queryParameters: <String, String>{
        ...uri.queryParameters,
        'skipBiometric': 'true',
      },
    ).toString();

    GoRouter.of(context).goNamed(
      BiometricSecurityPageWidget.routeName,
      extra: {'returnPath': returnPath},
    );

    Future.delayed(const Duration(seconds: 1), () {
      _biometricGateOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectiveThemeMode = _effectiveThemeMode(getRoute());

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FARM',
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: effectiveThemeMode,
      routerConfig: _router,
    );
  }
}
