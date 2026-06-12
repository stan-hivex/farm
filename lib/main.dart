import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await EasyLocalization.ensureInitialized();
  await FFAppState().initializePersistedState();

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

class _MyAppState extends State<MyApp> {

  ThemeMode _themeMode = ThemeMode.light;

  late AppStateNotifier _appStateNotifier;

  late GoRouter _router;

  // =========================================
  // ROUTE HELPERS
  // =========================================
  String getRoute([RouteMatch? routeMatch]) {

    final RouteMatch lastMatch =
        routeMatch ??
            _router.routerDelegate.currentConfiguration.last;

    final RouteMatchList matchList =
        lastMatch is ImperativeRouteMatch
            ? lastMatch.matches
            : _router.routerDelegate.currentConfiguration;

    return matchList.uri.path;
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();

  // =========================================
  // THEME SWITCHING
  // =========================================
  void setThemeMode(ThemeMode mode) {

    setState(() {
      _themeMode = mode;
      FlutterFlowTheme.saveThemeMode(mode);
    });
  }

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;

    _router = createRouter(_appStateNotifier);
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp.router(
  debugShowCheckedModeBanner: false,
  title: 'FARM',

  locale: context.locale,

  supportedLocales: context.supportedLocales,

  localizationsDelegates: context.localizationDelegates,

  theme: ThemeData(
    brightness: Brightness.light,
    useMaterial3: false,
  ),

  darkTheme: ThemeData(
    brightness: Brightness.dark,
    useMaterial3: false,
  ),

  themeMode: _themeMode,

  routerConfig: _router,
);
  }
}