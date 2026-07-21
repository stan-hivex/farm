import 'dart:async';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/backend/services/api_service.dart';
import '/components/quick_action/quick_action_widget.dart';
import '/components/transaction_item/transaction_item_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/q_r_scanner/q_r_scanner_widget.dart';
import '/pages/depositpage/depositpage_widget.dart';
import '/pages/withdrawpage/withdrawpage_widget.dart';
import '/pages/send_receive/send_receive_widget.dart';
import '/pages/all_transactions/all_transactions_widget.dart';
import '/pages/growth_tracking_page/growth_tracking_page_widget.dart';
import '/pages/merchant_dashboard/merchant_dashboard_widget.dart';
import '/services/app_session_manager.dart';
import '/utils/transaction_peer_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';

class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'Dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget>
    with WidgetsBindingObserver {
  late DashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  double walletBalance = 0.0;
  double kesEquivalent = 0.0;
  bool isBalanceLoading = true;

  String? profileImageUrl;

  List transactions = [];
  bool isTransactionsLoading = true;

  List<double> growthYValues = [];
  List<String> growthXLabels = [];

  bool isGrowthLoading = true;
  double growthPercentage = 0.0;
  double growthChartMaxY = 72.0;
  bool isNotificationsLoading = false;
  String? notificationsError;
  List<Map<String, dynamic>> notifications = [];
  int unreadNotificationsCount = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _model = createModel(context, () => DashboardModel());
    FFAppState().addListener(_handleAppStateChanged);
    _startPeriodicRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_refreshDashboard());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    FFAppState().removeListener(_handleAppStateChanged);
    WidgetsBinding.instance.removeObserver(this);
    _model.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startPeriodicRefresh();
      unawaited(_refreshDashboard());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _refreshTimer?.cancel();
    }
  }

  void _handleAppStateChanged() {
    if (!mounted) return;
    setState(() {
      walletBalance = FFAppState().walletBalance;
      kesEquivalent = FFAppState().kesEquivalent;
      profileImageUrl = FFAppState().profileImageUrl;
      transactions = FFAppState().recentTransactions;
      isBalanceLoading = false;
      isTransactionsLoading = false;
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    if (!FFAppState().isLoggedIn || FFAppState().accessToken.isEmpty) {
      return;
    }

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted ||
          !FFAppState().isLoggedIn ||
          FFAppState().accessToken.isEmpty) {
        return;
      }
      unawaited(_refreshDashboard());
    });
  }

  Future<void> _refreshDashboard() async {
    if (!mounted ||
        !FFAppState().isLoggedIn ||
        FFAppState().accessToken.isEmpty) {
      return;
    }

    setState(() {
      isBalanceLoading = true;
      isTransactionsLoading = true;
    });

    try {
      await AppSessionManager().syncNow(
        profileTimeoutSeconds: 5,
        walletTimeoutSeconds: 5,
        transactionsTimeoutSeconds: 5,
      );
    } catch (e) {
      debugPrint('Dashboard refresh failed: $e');
    }

    if (!mounted) return;

    setState(() {
      walletBalance = FFAppState().walletBalance;
      kesEquivalent = FFAppState().kesEquivalent;
      profileImageUrl = FFAppState().profileImageUrl;
      transactions = FFAppState().recentTransactions;
      isBalanceLoading = false;
      isTransactionsLoading = false;
    });

    await Future.wait([
      fetchGrowthHistory(),
      loadNotifications(),
    ]);
  }

  Future<void> logoutUser() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.api}/auth/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      print('LOGOUT STATUS: ${response.statusCode}');
      print('LOGOUT BODY: ${response.body}');

      // Clear local session ALWAYS (even if backend fails)
      FFAppState().accessToken = '';
      FFAppState().userName = '';
      FFAppState().isLoggedIn = false;
      FFAppState().themeMode = ThemeMode.light;

      if (mounted) {
        context.goNamed('loginpage');
      }
    } catch (e) {
      print('LOGOUT ERROR: $e');

      // still force logout locally
      FFAppState().accessToken = '';
      FFAppState().userName = '';
      FFAppState().isLoggedIn = false;
      FFAppState().themeMode = ThemeMode.light;

      if (mounted) {
        context.goNamed('loginpage');
      }
    }
  }

  Future<void> fetchWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.api}/wallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      print('BALANCE STATUS: ${response.statusCode}');
      print('BALANCE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          walletBalance =
              double.tryParse(data['data']['balance'].toString()) ?? 0.0;

          kesEquivalent =
              double.tryParse(data['data']['kes_equivalent'].toString()) ?? 0.0;

          isBalanceLoading = false;
        });
      } else {
        setState(() {
          isBalanceLoading = false;
        });
      }
    } catch (e) {
      print('BALANCE ERROR: $e');

      setState(() {
        isBalanceLoading = false;
      });
    }
  }

  Future<void> fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.api}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final kycStatus =
            data['data']?['kyc_status'] ?? data['data']?['kycStatus'];

        if (kycStatus is String) {
          FFAppState().kycStatus = kycStatus;
        }

        setState(() {
          profileImageUrl = data['data']['profile_image'];
        });
      }
    } catch (e) {
      print('PROFILE ERROR: $e');
    }
  }

  String _resolveTransactionPeer(dynamic tx, {required bool outgoing}) {
    return resolveTransactionPeer(tx, outgoing: outgoing);
  }

  String _formatTransactionDate(dynamic value) {
    if (value == null) return 'Date unavailable';
    final parsed =
        value is DateTime ? value : DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return '${parsed.toLocal().day}/${parsed.toLocal().month}/${parsed.toLocal().year} ${parsed.toLocal().hour.toString().padLeft(2, '0')}:${parsed.toLocal().minute.toString().padLeft(2, '0')}';
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${AppConfig.api}/transactions?page=1&limit=5',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      print('TRANSACTIONS STATUS: ${response.statusCode}');
      print('TRANSACTIONS BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          transactions = data['data'];
          isTransactionsLoading = false;
        });
      } else {
        setState(() {
          isTransactionsLoading = false;
        });
      }
    } catch (e) {
      print('TRANSACTIONS ERROR: $e');

      setState(() {
        isTransactionsLoading = false;
      });
    }
  }

  Future<void> loadNotifications() async {
    if (!mounted) return;

    setState(() {
      isNotificationsLoading = true;
      notificationsError = null;
    });

    try {
      final response = await ApiService.getNotifications();
      final rawNotifications = response['data'];
      final items = rawNotifications is List
          ? rawNotifications
              .map((item) => item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map))
              .toList()
          : <Map<String, dynamic>>[];
      final parsed = items.cast<Map<String, dynamic>>();
      final unread = parsed.where((item) {
        final read = item['read'] is bool
            ? item['read'] as bool
            : item['is_read'] is bool
                ? item['is_read'] as bool
                : item['isRead'] is bool
                    ? item['isRead'] as bool
                    : false;
        return !read;
      }).length;

      if (!mounted) return;
      setState(() {
        notifications = parsed;
        unreadNotificationsCount = unread;
        isNotificationsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        notificationsError = e.toString();
        isNotificationsLoading = false;
      });
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await ApiService.markNotificationRead(notificationId: id);
      await loadNotifications();
    } catch (_) {}
  }

  Future<void> _showNotificationsSheet() async {
    await loadNotifications();

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryText,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Notifications',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isNotificationsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (notificationsError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Unable to load notifications right now.\n$notificationsError',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                )
              else if (notifications.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No notifications yet.',
                    style: FlutterFlowTheme.of(context).bodyMedium,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final item = notifications[index];
                      final title = item['title']?.toString() ?? 'Notification';
                      final body = item['body']?.toString() ??
                          item['message']?.toString() ??
                          '';
                      final isRead = item['read'] is bool
                          ? item['read'] as bool
                          : item['is_read'] is bool
                              ? item['is_read'] as bool
                              : item['isRead'] is bool
                                  ? item['isRead'] as bool
                                  : false;
                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (!isRead && item['id'] != null) {
                              await markNotificationRead(item['id'].toString());
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(
                                  isRead
                                      ? Icons.notifications_none_rounded
                                      : Icons.notifications_active_rounded,
                                  color: FlutterFlowTheme.of(context).primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .override(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        body,
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> sendTransaction({
    required String recipient,
    required double amount,
    required String pin,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.api}/wallet/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
        body: jsonEncode({
          "recipient_identifier": recipient,
          "amount": amount,
          "pin": pin,
          "description": description ?? "Transfer",
        }),
      );

      print('SEND STATUS: ${response.statusCode}');
      print('SEND BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchWalletBalance();
        await fetchTransactions();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Transaction successful")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed: ${response.body}")),
          );
        }
      }
    } catch (e) {
      print('SEND ERROR: $e');
    }
  }

  Future<void> fetchGrowthHistory() async {
    if (!mounted) return;

    setState(() {
      isGrowthLoading = true;
    });

    try {
      final response = await ApiService.getGrowthHistory(days: 7);
      final history =
          response['data'] is List ? response['data'] as List : <dynamic>[];

      final parsedValues = <double>[];
      final parsedLabels = <String>[];

      for (final item in history) {
        if (item is! Map<String, dynamic> && item is! Map) {
          continue;
        }

        final rawItem = item is Map<String, dynamic>
            ? item
            : Map<String, dynamic>.from(item as Map);
        final rawValue =
            rawItem['total'] ?? rawItem['value'] ?? rawItem['amount'] ?? 0;
        final value = double.tryParse(rawValue.toString()) ?? 0.0;
        final label = rawItem['date']?.toString() ??
            rawItem['day']?.toString() ??
            rawItem['label']?.toString() ??
            '';

        parsedValues.add(value);
        parsedLabels.add(label.length > 5 && label.contains('-')
            ? label.substring(5)
            : label);
      }

      final firstValue = parsedValues.isNotEmpty ? parsedValues.first : 0.0;
      final lastValue = parsedValues.isNotEmpty ? parsedValues.last : 0.0;
      final computedGrowth = parsedValues.length > 1 && firstValue > 0
          ? ((lastValue - firstValue) / firstValue) * 100
          : 0.0;
      final maxValue = parsedValues.isNotEmpty
          ? parsedValues.reduce((a, b) => a > b ? a : b)
          : 0.0;
      final computedMaxY =
          maxValue > 0 ? (maxValue * 1.2 > 72.0 ? maxValue * 1.2 : 72.0) : 72.0;

      if (!mounted) return;

      setState(() {
        growthYValues = parsedValues;
        growthXLabels = parsedLabels;
        growthPercentage = computedGrowth;
        growthChartMaxY = computedMaxY;
        isGrowthLoading = false;
      });
    } catch (e) {
      print('GROWTH ERROR: $e');

      if (!mounted) return;

      setState(() {
        growthYValues = [];
        growthXLabels = [];
        growthPercentage = 0.0;
        growthChartMaxY = 72.0;
        isGrowthLoading = false;
      });
    }
  }

  bool get isKycApproved {
    final status = FFAppState().kycStatus.trim().toLowerCase();
    return ['verified', 'approved', 'complete', 'success'].contains(status);
  }

  bool get hasKycSubmission {
    final status = FFAppState().kycStatus.trim().toLowerCase();
    return ['pending', 'rejected', 'under review', 'review'].contains(status);
  }

  Future<void> _guardKycAccess({
    required String feature,
    required VoidCallback onAllowed,
  }) async {
    if (isKycApproved) {
      onAllowed();
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('KYC verification is required before using $feature.'),
        action: SnackBarAction(
          label: 'Complete KYC',
          onPressed: () => context.pushNamed('KYCPAGE'),
        ),
      ),
    );
  }

  void openNewTransactionSheet() {
    final recipientController = TextEditingController();
    final amountController = TextEditingController();
    final pinController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("New Transaction",
                  style: FlutterFlowTheme.of(context).titleMedium),
              TextField(
                controller: recipientController,
                decoration: const InputDecoration(labelText: "Recipient"),
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Amount"),
              ),
              TextField(
                controller: pinController,
                obscureText: true,
                decoration: const InputDecoration(labelText: "PIN"),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await sendTransaction(
                    recipient: recipientController.text.trim(),
                    amount: double.tryParse(amountController.text) ?? 0,
                    pin: pinController.text.trim(),
                    description: descController.text,
                  );

                  Navigator.pop(context);
                },
                child: const Text("Send"),
              ),
            ],
          ),
        );
      },
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
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: openNewTransactionSheet,
              backgroundColor: FlutterFlowTheme.of(context).primary,
              icon: Icon(
                Icons.add_rounded,
                color: FlutterFlowTheme.of(context).onPrimary,
                size: 24.0,
              ),
              elevation: 0.0,
              label: Text(
                'New Transaction',
                style: FlutterFlowTheme.of(context).labelLarge.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).labelLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).onPrimary,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).labelLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      lineHeight: 1.3,
                    ),
              ),
            ),
            const SizedBox(height: 12.0),
            FloatingActionButton.extended(
              onPressed: () => _guardKycAccess(
                feature: 'merchants',
                onAllowed: () => context.pushNamed(
                  MerchantDashboardWidget.routeName,
                ),
              ),
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              icon: Icon(
                Icons.storefront_rounded,
                color: FlutterFlowTheme.of(context).primaryText,
                size: 20.0,
              ),
              elevation: 0.0,
              label: Text(
                'Merchants',
                style: FlutterFlowTheme.of(context).labelLarge.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight:
                            FlutterFlowTheme.of(context).labelLarge.fontWeight,
                        fontStyle:
                            FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).primaryText,
                      letterSpacing: 0.0,
                      fontWeight:
                          FlutterFlowTheme.of(context).labelLarge.fontWeight,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelLarge.fontStyle,
                      lineHeight: 1.3,
                    ),
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            primary: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    0.0,
                    MediaQuery.of(context).padding.top > 0 ? 12.0 : 8.0,
                    0.0,
                    32.0,
                  ),
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context).primaryBackground,
                            shape: BoxShape.rectangle,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              24.0,
                              MediaQuery.of(context).padding.top > 0 ? 18.0 : 16.0,
                              24.0,
                              20.0,
                            ),
                            child: Container(
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                              lineHeight: 1.5,
                                            ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            FFAppState().userName.isNotEmpty
                                                ? '@${FFAppState().userName}'
                                                : 'User',
                                            style: FlutterFlowTheme.of(context)
                                                .titleLarge
                                                .override(
                                                  font: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w800,
                                                  lineHeight: 1.3,
                                                ),
                                          ),
                                          if (isKycApproved)
                                            Icon(
                                              Icons.verified_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 18.0,
                                            ),
                                        ].divide(const SizedBox(width: 4.0)),
                                      ),
                                      if (hasKycSubmission &&
                                          !isKycApproved) ...[
                                        const SizedBox(height: 10.0),
                                        SizedBox(
                                          width: 160.0,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                context.pushNamed('KYCPAGE'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .primary,
                                              foregroundColor:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 12.0,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                            ),
                                            child: Text(
                                              'Verify KYC',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleSmall
                                                  .override(
                                                    fontWeight: FontWeight.w600,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          FlutterFlowIconButton(
                                            borderRadius: 8.0,
                                            buttonSize: 44.0,
                                            fillColor: Colors.transparent,
                                            icon: Icon(
                                              Icons.notifications_none_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 24.0,
                                            ),
                                            onPressed: _showNotificationsSheet,
                                          ),
                                          if (unreadNotificationsCount > 0)
                                            Positioned(
                                              right: 6,
                                              top: 6,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                ),
                                                constraints:
                                                    const BoxConstraints(
                                                  minWidth: 16,
                                                  minHeight: 16,
                                                ),
                                                child: Text(
                                                  unreadNotificationsCount > 9
                                                      ? '9+'
                                                      : unreadNotificationsCount
                                                          .toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      FlutterFlowIconButton(
                                        borderRadius: 8.0,
                                        buttonSize: 44.0,
                                        fillColor: Colors.transparent,
                                        icon: (profileImageUrl?.isNotEmpty ??
                                                false)
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                child: Image.network(
                                                  profileImageUrl!,
                                                  width: 28,
                                                  height: 28,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Icon(
                                                Icons.account_circle_outlined,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 28.0,
                                              ),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.all(20),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    ListTile(
                                                      leading: const Icon(
                                                          Icons.person),
                                                      title:
                                                          const Text('Profile'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        context.pushNamed(
                                                            'ProfileSettings');
                                                      },
                                                    ),
                                                    ListTile(
                                                      leading: const Icon(
                                                          Icons.logout),
                                                      title:
                                                          const Text('Logout'),
                                                      onTap: () {
                                                        Navigator.pop(context);
                                                        logoutUser();
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ].divide(const SizedBox(width: 8.0)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          child: Container(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24.0),
                              child: Container(
                                height: MediaQuery.of(context).size.height < 700
                                    ? 200.0
                                    : 230.0,
                                constraints: const BoxConstraints(minHeight: 180.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.black
                                      : FlutterFlowTheme.of(context).primary,
                                  borderRadius: BorderRadius.circular(24.0),
                                  shape: BoxShape.rectangle,
                                ),
                                child: Stack(
                                  alignment:
                                      const AlignmentDirectional(-1.0, -1.0),
                                  children: [
                                    Container(
                                      alignment:
                                          const AlignmentDirectional(1.0, -1.0),
                                      child: Container(
                                        width: 150.0,
                                        height: 150.0,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[900]!.withAlpha(
                                                  (0.3 * 255).toInt())
                                              : FlutterFlowTheme.of(context)
                                                  .onPrimary6,
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                          shape: BoxShape.rectangle,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      alignment:
                                          const AlignmentDirectional(-1.0, 1.0),
                                      child: Container(
                                        width: 100.0,
                                        height: 100.0,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.grey[900]!.withAlpha(
                                                  (0.15 * 255).toInt())
                                              : FlutterFlowTheme.of(context)
                                                  .onPrimary3,
                                          borderRadius:
                                              BorderRadius.circular(9999.0),
                                          shape: BoxShape.rectangle,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.height < 700
                                            ? 18.0
                                            : 24.0,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  SvgPicture.network(
                                                    'https://cdn.simpleicons.org/algorand/ffffff.svg',
                                                    width: 16.0,
                                                    height: 16.0,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  Text(
                                                    'FARM BALANCE',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelSmall
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelSmall
                                                                    .fontStyle,
                                                          ),
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white70
                                                              : FlutterFlowTheme
                                                                      .of(context)
                                                                  .onPrimary70,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                          lineHeight: 1.2,
                                                        ),
                                                  ),
                                                ].divide(
                                                    const SizedBox(width: 4.0)),
                                              ),
                                              Text(
                                                isBalanceLoading
                                                    ? 'Loading...'
                                                    : walletBalance
                                                        .toStringAsFixed(2),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .headlineLarge
                                                    .override(
                                                      font: GoogleFonts
                                                          .plusJakartaSans(
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : FlutterFlowTheme.of(
                                                                  context)
                                                              .onPrimary,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      lineHeight: 1.2,
                                                    ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 8.0),
                                                child: Text(
                                                  'a loop of growth',
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .plusJakartaSans(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FontStyle.italic,
                                                        ),
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white60
                                                            : FlutterFlowTheme
                                                                    .of(context)
                                                                .onPrimary50,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        lineHeight: 1.2,
                                                      ),
                                                ),
                                              ),
                                            ].divide(
                                                SizedBox(
                                                  height: MediaQuery.of(context)
                                                              .size
                                                              .height <
                                                          700
                                                      ? 2.0
                                                      : 4.0,
                                                )),
                                          ),
                                          const Spacer(),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: LayoutBuilder(
                                              builder: (context, constraints) {
                                                final screenWidth =
                                                    constraints.maxWidth;
                                                final isCompact =
                                                    screenWidth < 360;
                                                final isDarkMode =
                                                    Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark;
                                                final buttonColor =
                                                    isDarkMode
                                                        ? Colors.black
                                                        : Colors.white;
                                                final buttonTextColor =
                                                    isDarkMode
                                                        ? Colors.white
                                                        : Colors.black;

                                                Widget buildActionButton({
                                                  required Color color,
                                                  required IconData icon,
                                                  required String label,
                                                  required VoidCallback onTap,
                                                }) {
                                                  return GestureDetector(
                                                    onTap: onTap,
                                                    child: Container(
                                                      width: isCompact
                                                          ? (screenWidth - 24) / 2
                                                          : 96.0,
                                                      decoration: BoxDecoration(
                                                        color: color,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.0),
                                                      ),
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 6.0,
                                                        vertical: 6.0,
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            icon,
                                                            size: 14,
                                                            color:
                                                                buttonTextColor,
                                                          ),
                                                          const SizedBox(
                                                              width: 3.0),
                                                          Flexible(
                                                            child: Text(
                                                              label,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                color:
                                                                    buttonTextColor,
                                                                fontSize: 12.0,
                                                                fontWeight:
                                                                    FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return Wrap(
                                                  alignment: WrapAlignment.end,
                                                  spacing: 6.0,
                                                  runSpacing: 6.0,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    buildActionButton(
                                                      color: buttonColor,
                                                      icon: Icons
                                                          .arrow_downward_rounded,
                                                      label: 'Deposit',
                                                      onTap: () =>
                                                          _guardKycAccess(
                                                        feature: 'deposit',
                                                        onAllowed: () =>
                                                            context.pushNamed(
                                                                DepositpageWidget
                                                                    .routeName),
                                                      ),
                                                    ),
                                                    buildActionButton(
                                                      color: buttonColor,
                                                      icon: Icons
                                                          .arrow_upward_rounded,
                                                      label: 'Withdraw',
                                                      onTap: () =>
                                                          _guardKycAccess(
                                                        feature: 'withdraw',
                                                        onAllowed: () =>
                                                            context.pushNamed(
                                                                WithdrawpageWidget
                                                                    .routeName),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          child: Container(
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    0.0, 12.0, 0.0, 12.0),
                                child: Container(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _guardKycAccess(
                                          feature: 'send & receive',
                                          onAllowed: () => context.pushNamed(
                                            SendReceiveWidget.routeName,
                                          ),
                                        ),
                                        child: wrapWithModel(
                                          model: _model.quickActionModel1,
                                          updateCallback: () =>
                                              safeSetState(() {}),
                                          child: QuickActionWidget(
                                            action: 'navigate:SendReceive',
                                            icon: Icon(
                                              Icons.north_east_rounded,
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                              size: 24.0,
                                            ),
                                            label: 'Send',
                                          ),
                                        ),
                                      ),
                                      wrapWithModel(
                                        model: _model.quickActionModel2,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: QuickActionWidget(
                                          action:
                                              'navigate:${QRScannerWidget.routeName}',
                                          icon: Icon(
                                            Icons.qr_code_scanner_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          label: 'Scan',
                                        ),
                                      ),
                                      wrapWithModel(
                                        model: _model.quickActionModel3,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: QuickActionWidget(
                                          action: 'navigate:EscrowHub',
                                          icon: Icon(
                                            Icons.shield_outlined,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          label: 'Escrow',
                                        ),
                                      ),
                                      wrapWithModel(
                                        model: _model.quickActionModel4,
                                        updateCallback: () =>
                                            safeSetState(() {}),
                                        child: QuickActionWidget(
                                          action:
                                              'navigate:InvestmentMarketplace',
                                          icon: Icon(
                                            Icons.account_balance_rounded,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          label: 'Invest',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              0.0, 0.0, 0.0, 16.0),
                          child: Container(
                            child: Container(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                    24.0, 0.0, 24.0, 0.0),
                                child: Container(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(20.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText
                                              .withValues(alpha: 0.06),
                                          blurRadius: 18.0,
                                          offset: const Offset(0.0, 10.0),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        MediaQuery.of(context).size.height < 700
                                            ? 16.0
                                            : 20.0,
                                      ),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Growth History',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .titleMedium
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .titleMedium
                                                                  .fontStyle,
                                                          lineHeight: 1.4,
                                                        ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      context.pushNamed(
                                                    GrowthTrackingPageWidget
                                                        .routeName,
                                                  ),
                                                  child: Text(
                                                    'View full',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .labelLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .plusJakartaSans(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .primary,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Text(
                                              '${growthPercentage >= 0 ? '+' : ''}${growthPercentage.toStringAsFixed(1)}%',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .labelLarge
                                                  .override(
                                                    font: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelLarge
                                                              .fontStyle,
                                                    ),
                                                    color: growthPercentage >= 0
                                                        ? FlutterFlowTheme.of(
                                                                context)
                                                            .success
                                                        : FlutterFlowTheme.of(
                                                                context)
                                                            .error,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelLarge
                                                            .fontStyle,
                                                    lineHeight: 1.3,
                                                  ),
                                            ),
                                            SizedBox(
                                              height: 110.0,
                                              child: isGrowthLoading
                                                  ? const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    )
                                                  : growthYValues.isEmpty
                                                      ? Center(
                                                          child: Text(
                                                            'No growth data yet',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium,
                                                          ),
                                                        )
                                                      : FlutterFlowLineChart(
                                                          data: [
                                                            FFLineChartData(
                                                              xData:
                                                                  List.generate(
                                                                growthYValues
                                                                    .length,
                                                                (index) => index
                                                                    .toDouble(),
                                                              ),
                                                              yData:
                                                                  growthYValues,
                                                              settings:
                                                                  LineChartBarData(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                barWidth: 2.0,
                                                                isCurved: true,
                                                                dotData:
                                                                    const FlDotData(
                                                                        show:
                                                                            false),
                                                                belowBarData:
                                                                    BarAreaData(
                                                                  show: true,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .primary10,
                                                                ),
                                                              ),
                                                            )
                                                          ],
                                                          chartStylingInfo:
                                                              const ChartStylingInfo(
                                                            backgroundColor:
                                                                Colors
                                                                    .transparent,
                                                            showBorder: false,
                                                          ),
                                                          axisBounds:
                                                              AxisBounds(
                                                            minX: 0.0,
                                                            minY: 0.0,
                                                            maxX: growthYValues
                                                                        .length >
                                                                    1
                                                                ? (growthYValues
                                                                            .length -
                                                                        1)
                                                                    .toDouble()
                                                                : 6.0,
                                                            maxY:
                                                                growthChartMaxY,
                                                          ),
                                                          xLabels:
                                                              growthXLabels,
                                                          xAxisLabelInfo:
                                                              AxisLabelInfo(
                                                            showLabels: true,
                                                            labelTextStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodySmall
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodySmall
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryText,
                                                                      fontSize:
                                                                          10.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodySmall
                                                                          .fontStyle,
                                                                      lineHeight:
                                                                          1.0,
                                                                    ),
                                                            reservedSize: 28.0,
                                                          ),
                                                          yAxisLabelInfo:
                                                              const AxisLabelInfo(
                                                            reservedSize: 0.0,
                                                          ),
                                                        ),
                                            ),
                                          ].divide(
                                              const SizedBox(height: 16.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              24.0, 0.0, 24.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Recent Activity',
                                    style: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .override(
                                          font: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.bold,
                                          lineHeight: 1.4,
                                        ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.pushNamed(
                                      AllTransactionsWidget.routeName,
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'See All',
                                      style: FlutterFlowTheme.of(context)
                                          .labelLarge
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16.0),
                              if (isTransactionsLoading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (transactions.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'No recent transactions',
                                    style:
                                        FlutterFlowTheme.of(context).bodyMedium,
                                  ),
                                )
                              else
                                Column(
                                  children: transactions.map((tx) {
                                    final bool isOutgoing =
                                        tx['is_outgoing'] == true;

                                    final String amount =
                                        '${isOutgoing ? '-' : '+'}${double.parse(tx['amount'].toString()).toStringAsFixed(2)} FARM';

                                    final String status =
                                        tx['status'] ?? 'Completed';

                                    final String peer = _resolveTransactionPeer(
                                        tx,
                                        outgoing: isOutgoing);

                                    final String title = isOutgoing
                                        ? 'Sent to $peer'
                                        : 'Received from $peer';

                                    final String subtitle =
                                        '${tx['transaction_type'] ?? 'Transaction'} • ${_formatTransactionDate(tx['created_at'] ?? tx['createdAt'] ?? tx['timestamp'] ?? tx['date'])}';

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TransactionItemWidget(
                                        amount: amount,
                                        icon: Icon(
                                          isOutgoing
                                              ? Icons.north_east_rounded
                                              : Icons.south_west_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 20.0,
                                        ),
                                        status: status,
                                        subtitle: subtitle,
                                        title: title,
                                        is_negative: isOutgoing,
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
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
