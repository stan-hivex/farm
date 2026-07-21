import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/pages/change_pin_page/change_pin_page_widget.dart';
import '/pages/forgot_pin_page/forgot_pin_page_widget.dart';
import '/pages/splash_page.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/support/faq_page_widget.dart';
import '/pages/support/live_chat_page_widget.dart';
import '/pages/support/email_support_page_widget.dart';
import '/pages/notifications/user_notifications_page_widget.dart';
import '/pages/growth_tracking_page/growth_tracking_page_widget.dart';
import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: OnboardingWidget.routePath,
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
      errorBuilder: (context, state) => const LoginpageWidget(),
      routes: [
        FFRoute(
          name: SplashPage.routeName,
          path: SplashPage.routePath,
          builder: (context, _) => const SplashPage(),
        ),
        FFRoute(
          name: '_initialize',
          path: '/',
          builder: (context, _) => const OnboardingWidget(),
        ),
        FFRoute(
          name: OnboardingWidget.routeName,
          path: OnboardingWidget.routePath,
          builder: (context, params) => const OnboardingWidget(),
        ),
        FFRoute(
          name: DashboardWidget.routeName,
          path: DashboardWidget.routePath,
          builder: (context, params) => const DashboardWidget(),
        ),
        FFRoute(
          name: GrowthTrackingPageWidget.routeName,
          path: GrowthTrackingPageWidget.routePath,
          builder: (context, params) => const GrowthTrackingPageWidget(),
        ),
        FFRoute(
          name: SendReceiveWidget.routeName,
          path: SendReceiveWidget.routePath,
          builder: (context, params) => const SendReceiveWidget(),
        ),
        FFRoute(
          name: KycpageWidget.routeName,
          path: KycpageWidget.routePath,
          builder: (context, params) => const KycpageWidget(),
        ),
        FFRoute(
          name: QRScannerWidget.routeName,
          path: QRScannerWidget.routePath,
          builder: (context, params) => const QRScannerWidget(),
        ),
        FFRoute(
          name: EscrowHubWidget.routeName,
          path: EscrowHubWidget.routePath,
          builder: (context, params) => const EscrowHubWidget(),
        ),
        FFRoute(
          name: InvestmentMarketplaceWidget.routeName,
          path: InvestmentMarketplaceWidget.routePath,
          builder: (context, params) => const InvestmentMarketplaceWidget(),
        ),
        FFRoute(
          name: 'FaqPage',
          path: '/faq',
          builder: (context, params) => const FaqPageWidget(),
        ),
        FFRoute(
          name: 'LiveChatPage',
          path: '/chat',
          builder: (context, params) => const LiveChatPageWidget(),
        ),
        FFRoute(
          name: 'EmailSupportPage',
          path: '/email-support',
          builder: (context, params) => const EmailSupportPageWidget(),
        ),
        FFRoute(
          name: ProjectDetailsWidget.routeName,
          path: ProjectDetailsWidget.routePath,
          builder: (context, params) => ProjectDetailsWidget(
            projectId: params.getParam(
                  'projectId',
                  ParamType.String,
                ) ??
                '',
          ),
        ),
        FFRoute(
          name: MerchantDashboardWidget.routeName,
          path: MerchantDashboardWidget.routePath,
          builder: (context, params) => const MerchantDashboardWidget(),
        ),
        FFRoute(
          name: 'MerchantPayment',
          path: '/merchantPayment',
          builder: (context, params) => MerchantPaymentWidget(
            merchantId: params.getParam('merchantId', ParamType.String) ?? '',
            businessName: params.getParam('businessName', ParamType.String) ?? '',
            qrPayload: params.getParam('qrPayload', ParamType.String) ?? '',
          ),
        ),
        FFRoute(
          name: 'MerchantSales',
          path: '/merchantSales',
          builder: (context, params) => const MerchantSalesWidget(),
        ),
        FFRoute(
          name: AllTransactionsWidget.routeName,
          path: AllTransactionsWidget.routePath,
          builder: (context, params) => const AllTransactionsWidget(),
        ),
        FFRoute(
          name: ProfileSettingsWidget.routeName,
          path: ProfileSettingsWidget.routePath,
          builder: (context, params) => const ProfileSettingsWidget(),
        ),
        FFRoute(
          name: LoginpageWidget.routeName,
          path: LoginpageWidget.routePath,
          builder: (context, params) => const LoginpageWidget(),
        ),
        FFRoute(
          name: RegisterpageWidget.routeName,
          path: RegisterpageWidget.routePath,
          builder: (context, params) => const RegisterpageWidget(),
        ),
        FFRoute(
          name: BiometricUnlockPageWidget.routeName,
          path: BiometricUnlockPageWidget.routePath,
          builder: (context, params) => const BiometricUnlockPageWidget(),
        ),
        FFRoute(
          name: DepositpageWidget.routeName,
          path: DepositpageWidget.routePath,
          builder: (context, params) => const DepositpageWidget(),
        ),
        FFRoute(
          name: WithdrawpageWidget.routeName,
          path: WithdrawpageWidget.routePath,
          builder: (context, params) => const WithdrawpageWidget(),
        ),
        FFRoute(
          name: ForgotPasswordPageWidget.routeName,
          path: ForgotPasswordPageWidget.routePath,
          builder: (context, params) => const ForgotPasswordPageWidget(),
        ),
        FFRoute(
          name: PinSetupPageWidget.routeName,
          path: PinSetupPageWidget.routePath,
          builder: (context, params) => const PinSetupPageWidget(),
        ),
        FFRoute(
          name: ChangePinPageWidget.routeName,
          path: ChangePinPageWidget.routePath,
          builder: (context, params) => const ChangePinPageWidget(),
        ),
        FFRoute(
          name: ForgotPinPageWidget.routeName,
          path: ForgotPinPageWidget.routePath,
          builder: (context, params) => const ForgotPinPageWidget(),
        ),
        FFRoute(
          name: NotificationSettingsPageWidget.routeName,
          path: NotificationSettingsPageWidget.routePath,
          builder: (context, params) => const NotificationSettingsPageWidget(),
        ),
        FFRoute(
          name: UserNotificationsPageWidget.routeName,
          path: UserNotificationsPageWidget.routePath,
          builder: (context, params) => const UserNotificationsPageWidget(),
        ),
        FFRoute(
          name: LanguageSettingsPageWidget.routeName,
          path: LanguageSettingsPageWidget.routePath,
          builder: (context, params) => const LanguageSettingsPageWidget(),
        ),
        FFRoute(
          name: SupportHelpCenterPageWidget.routeName,
          path: SupportHelpCenterPageWidget.routePath,
          builder: (context, params) => const SupportHelpCenterPageWidget(),
        ),
        FFRoute(
          name: SuperadminDashboardPage.routeName,
          path: SuperadminDashboardPage.routePath,
          builder: (context, params) => const SuperadminDashboardPage(),
        ),
        FFRoute(
          name: SuperadminWalletPage.routeName,
          path: SuperadminWalletPage.routePath,
          builder: (context, params) => const SuperadminWalletPage(),
        ),
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  name: state.name,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(
                  key: state.pageKey, name: state.name, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() =>
      const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
