import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'core/app_theme.dart';
import 'index.dart';
import 'backend/services/api_service.dart';
import 'services/device_fingerprint_service.dart';
import 'backend/api_requests/biometric_api_service.dart';
import 'services/biometric_gate_service.dart';
import 'services/secure_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load dotenv early to avoid NotInitializedError when Env is referenced.
  try {
    await dotenv.load();
    debugPrint('Loaded environment variables from .env');
  } catch (e) {
    debugPrint('Could not load .env (it may be missing): $e');
  }

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
      _refreshAppState();
    }
  }

  Future<void> _refreshAppState() async {
    if (!mounted || !FFAppState().isLoggedIn) {
      return;
    }

    try {
      await ApiService.getProfile();
    } catch (e) {
      debugPrint('App resume refresh failed: $e');
    }
  }

  Future<void> _verifyBiometricDeviceAndGate() async {
    debugPrint('Biometric gate disabled; login screen remains available.');
  }

  void _showBiometricGateIfNeeded() {
    debugPrint('Biometric gate disabled; login screen remains available.');
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
