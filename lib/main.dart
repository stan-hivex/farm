import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'core/app_theme.dart';
import 'web_url_strategy.dart';
import 'services/app_session_manager.dart';
import 'services/biometric_lock_service.dart';
import 'services/notification_service.dart';
import 'services/socket_service.dart';
import 'services/auth/startup_authenticator.dart';
import 'services/auth/route_guard_service.dart';
import 'services/localization_service.dart';
import 'pages/biometric_unlock_page/biometric_unlock_page_widget.dart';

Widget buildSafeErrorWidget(FlutterErrorDetails details) {
  debugPrint('Suppressing app error overlay: ${details.exception}');
  return const SizedBox.shrink();
}

void main() async {
  print('APP START');
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

  ErrorWidget.builder =
      (FlutterErrorDetails details) => buildSafeErrorWidget(details);

  await EasyLocalization.ensureInitialized();
  
  // Get saved locale before Firebase initialization
  final savedLocale = await LocalizationService.getSavedLocale();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('Reading stored session...');
  final storedRole = await SharedPreferences.getInstance()
      .then((prefs) => prefs.getString('role') ?? '');
  print('Stored role = $storedRole');
  final storedAccessToken = await SharedPreferences.getInstance()
      .then((prefs) => prefs.getString('accessToken'));
  final storedRefreshToken = await SharedPreferences.getInstance()
      .then((prefs) => prefs.getString('refreshToken'));
  print('Stored access token exists = ${storedAccessToken != null}');
  print('Stored refresh token exists = ${storedRefreshToken != null}');
  await FFAppState().initializePersistedState();
  // Attempt to restore persisted session and perform a silent refresh before
  // the app is started so routing decisions can use restored auth state.
  await StartupAuthenticator().restoreSession();
  await NotificationService.initialize();
  await SocketService.initialize();
  await FlutterFlowTheme.initialize();

  if (FFAppState().isLoggedIn &&
      FFAppState().refreshToken.isNotEmpty &&
      FFAppState().isUser) {
    Future.microtask(() {
      AppSessionManager().refreshAppData().catchError((e) {
        debugPrint('[Main] Initial app refresh failed: $e');
      });
    });
  }

  configureUrlStrategy();

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
        startLocale: savedLocale,
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
  const MyApp({super.key, this.initialLocation});

  final String? initialLocation;

  @override
  State<MyApp> createState() => _MyAppState();

  // =========================================
  // REQUIRED BY FLUTTERFLOW
  // =========================================
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late AppStateNotifier _appStateNotifier;

  late GoRouter _router;
  Timer? _refreshTimer;

  ThemeMode _effectiveThemeMode(String currentLocation) {
    try {
      return context.watch<FFAppState>().themeMode;
    } on ProviderNotFoundException {
      return FFAppState().themeMode;
    }
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

    _router = createRouter(
      _appStateNotifier,
      initialLocation: widget.initialLocation,
    );
    final currentLocation = getRoute();
    print('Current route before redirect = $currentLocation');
    _startPeriodicRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      debugPrint('[APP] Resumed - session preserved');
      _startPeriodicRefresh();
      _refreshAppState();
      _handleResumeLock();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      debugPrint('[APP] Backgrounded - session preserved');
      unawaited(_persistCurrentAuthenticatedRoute());
      _refreshTimer?.cancel();
    }
  }

  Future<void> _persistCurrentAuthenticatedRoute() async {
    if (!FFAppState().isLoggedIn) return;
    final location = getRoute();
    if (location.isEmpty || RouteGuardService().isPublicRoute(location) ||
        location == BiometricUnlockPageWidget.routePath) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastAuthenticatedRoute', location);
    debugPrint('[AUTH ROUTE] Saved last authenticated route');
  }

  Future<void> _handleResumeLock() async {
    if (!mounted) return;
    if (!FFAppState().isLoggedIn || !FFAppState().isBiometricAllowed) {
      return;
    }

    final lockService = BiometricLockService();
    if (lockService.isAuthenticating) {
      debugPrint(
          '[Main] Biometric auth already in progress; skipping resume lock check.');
      return;
    }

    final shouldLock = await lockService.shouldRequireUnlock();
    if (shouldLock && getRoute() != BiometricUnlockPageWidget.routePath) {
      print('Navigating to ${BiometricUnlockPageWidget.routePath}');
      print('Navigating to ${BiometricUnlockPageWidget.routePath}');
      _router.go(BiometricUnlockPageWidget.routePath);
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    if (!mounted ||
        !FFAppState().isLoggedIn ||
        FFAppState().accessToken.isEmpty ||
        !FFAppState().isUser) {
      return;
    }

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted ||
          !FFAppState().isLoggedIn ||
          FFAppState().accessToken.isEmpty) {
        return;
      }
      unawaited(_refreshAppState());
    });
  }

  Future<void> _refreshAppState() async {
    if (!mounted || !FFAppState().isLoggedIn) {
      return;
    }

    try {
      await AppSessionManager().refreshAppData();
    } catch (e) {
      debugPrint('App resume coordinated refresh failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveThemeMode = _effectiveThemeMode(getRoute());
    Locale locale = const Locale('en');
    Iterable<Locale> supportedLocales = const [Locale('en')];
    List<LocalizationsDelegate<dynamic>> localizationDelegates = const [];
    try {
      locale = context.locale;
      supportedLocales = context.supportedLocales;
      localizationDelegates = context.localizationDelegates;
    } catch (_) {}

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FARM',
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationDelegates,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: effectiveThemeMode,
      routerConfig: _router,
      builder: (context, child) => PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !kIsWeb) {
            debugPrint('[APP] Android back - preserving session');
            SystemNavigator.pop();
          }
        },
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
