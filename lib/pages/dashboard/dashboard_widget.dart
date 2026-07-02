import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/components/button/button_widget.dart';
import '/components/quick_action/quick_action_widget.dart';
import '/components/transaction_item/transaction_item_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';
import '/core/responsive.dart';
import '/pages/q_r_scanner/q_r_scanner_widget.dart';
import '/pages/depositpage/depositpage_widget.dart';
import '/pages/withdrawpage/withdrawpage_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_model.dart';
export 'dashboard_model.dart';


class DashboardWidget extends StatefulWidget {
  const DashboardWidget({super.key});

  static String routeName = 'Dashboard';
  static String routePath = '/dashboard';

  @override
  State<DashboardWidget> createState() => _DashboardWidgetState();
}

class _DashboardWidgetState extends State<DashboardWidget> {
  late DashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  
  double walletBalance = 0.0;
double kesEquivalent = 0.0;
bool isBalanceLoading = true;

String? profileImageUrl;

List transactions = [];
bool isTransactionsLoading = true;

double? _lastSentAmount;
DateTime? _lastSentAt;
bool _isSendingTransaction = false;

List<double> growthYValues = [];
List<String> growthXLabels = [];

double growthPercentage = 12.5;
bool isGrowthLoading = true;

// Notification variables
int notificationCount = 0;
bool isNotificationCountLoading = true;

// KYC Status Variables
String kycStatus = ''; // pending, level1_pending, level2_pending, level3_pending, level1_approved, level2_approved, level3_approved, rejected
String kycLevel = ''; // 1, 2, 3 (highest level completed)
bool isKycLoading = true;

  @override
  void initState() {
    super.initState();

    _model = createModel(context, () => DashboardModel());

    fetchWalletBalance();
    fetchUserProfile();
    fetchKycStatus();
    fetchTransactions();
    fetchGrowthHistory();
    fetchNotificationCount();
  }
 
  Future<void> fetchNotificationCount() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.api}/users/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      if (response.statusCode != 200) {
        setState(() {
          notificationCount = 0;
          isNotificationCountLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body);
      final items = List<dynamic>.from(data['data'] ?? []);
      final unreadCount = items.where((item) {
        if (item is Map<String, dynamic>) {
          final read = item['read'] ?? item['is_read'] ?? item['isRead'];
          if (read is bool) return !read;
        }
        return true;
      }).length;

      setState(() {
        notificationCount = unreadCount;
        isNotificationCountLoading = false;
      });
    } catch (e) {
      print('NOTIFICATION COUNT ERROR: $e');
      setState(() {
        notificationCount = 0;
        isNotificationCountLoading = false;
      });
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      await prefs.remove('userId');
      await prefs.remove('role');
      await prefs.remove('isLoggedIn');
      await prefs.remove('adminToken');
      await prefs.remove('adminRefreshToken');
      await prefs.remove('adminRole');
      await prefs.remove('adminName');

      FFAppState().accessToken = '';
      FFAppState().refreshToken = '';
      FFAppState().userId = '';
      FFAppState().firstName = '';
      FFAppState().userName = '';
      FFAppState().phone = '';
      FFAppState().role = '';
      FFAppState().isLoggedIn = false;

      if (mounted) {
        context.goNamed('loginpage');
      }
    } catch (e) {
      print('LOGOUT ERROR: $e');

      // still force logout locally
      FFAppState().accessToken = '';
      FFAppState().userName = '';
      FFAppState().isLoggedIn = false;

      if (mounted) {
        context.goNamed('loginpage');
      }
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
      final user = data['data'];

      setState(() {
        profileImageUrl = user['profile_image'];
        // Fallback: some deployments store KYC status on the user profile
        final profileKycStatus = (user['kyc_status'] ?? user['status'] ?? '')?.toString();
        final profileKycLevel = (user['kyc_level'] ?? user['kyc_level_completed'] ?? user['level'])?.toString();

        // Only set if we don't already have a KYC status from /kyc/my
        if (kycStatus.isEmpty && profileKycStatus != null) {
          kycStatus = profileKycStatus;
        }
        if ((kycLevel.isEmpty || kycLevel == '0') && profileKycLevel != null) {
          kycLevel = profileKycLevel;
        }
      });
    }
  } catch (e) {
    print('PROFILE ERROR: $e');
  }
}

  Future<void> fetchKycStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.api}/kyc/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      print('KYC STATUS: ${response.statusCode}');
      print('KYC BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final kycData = data['data'] ?? data;

        // Try multiple field name possibilities
        final status = kycData['status'] ?? kycData['kyc_status'] ?? kycData['verification_status'] ?? '';
        final level = (kycData['level'] ?? kycData['kyc_level'] ?? kycData['completed_level'] ?? kycData['current_level'])?.toString() ?? '';
        final verified = kycData['verified'] ?? kycData['is_verified'] ?? false;

        print('[KYC DEBUG] Status: $status, Level: $level, Verified: $verified');

        setState(() {
          kycStatus = status;
          kycLevel = level;
          isKycLoading = false;
        });
      } else {
        print('[KYC DEBUG] Fetch failed with status ${response.statusCode}');
        setState(() {
          isKycLoading = false;
        });
      }
    } catch (e) {
      print('KYC ERROR: $e');
      setState(() {
        isKycLoading = false;
      });
    }
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

// Helper method to check if user can transact
bool canUserTransact() {
  // User needs at least Level 2 KYC approved to transact.
  // Be permissive: accept "approved" or "verified" status, and allow if level >= 2.
  final status = kycStatus.toLowerCase();
  final level = int.tryParse(kycLevel) ?? 0;

  print('[TRANSACT CHECK] KYC Status: $kycStatus, Level: $kycLevel, Level int: $level');

  // If level is provided and >=2, allow
  if (level >= 2) {
    print('[TRANSACT CHECK] ✓ Allowed (level >= 2)');
    return true;
  }

  // If status suggests verification/approval, allow (covers older users)
  if (status.contains('ver') || status.contains('approv')) {
    print('[TRANSACT CHECK] ✓ Allowed (status contains verified/approved)');
    return true;
  }

  // Otherwise deny
  print('[TRANSACT CHECK] ✗ Denied (insufficient KYC)');
  return false;
}

Future<bool> sendTransaction({
  required String recipient,
  required double amount,
  required String pin,
  String? description,
}) async {
  // Check if user has required KYC level to transact
  if (!canUserTransact()) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete Level 2 KYC to send transactions'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

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
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${response.body}")),
      );
    }
    return false;
  } catch (e) {
    print('SEND ERROR: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error sending transaction")),
      );
    }
    return false;
  }
}

Future<void> fetchGrowthHistory({String period = 'daily'}) async {
  try {
    final response = await http.get(
      Uri.parse(
        '${AppConfig.api}/analytics/growth-history?period=$period',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${FFAppState().accessToken}',
      },
    );

    print('GROWTH STATUS: ${response.statusCode}');
    print('GROWTH BODY: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final payload = data['data'] ?? data['history'] ?? [];
      final List history = payload is List ? payload : [];

      final values = history
          .map<double>((e) {
            final raw = e['total'] ?? e['value'] ?? e['amount'] ?? 0;
            return double.tryParse(raw.toString()) ?? 0.0;
          })
          .toList();

      final labels = history
          .map<String>((e) =>
              e['date']?.toString() ?? e['day']?.toString() ?? e['label']?.toString() ?? '')
          .toList();

      double parsedGrowth = 12.5;
      if (data['growth_percentage'] != null) {
        parsedGrowth = double.tryParse(data['growth_percentage'].toString()) ?? parsedGrowth;
      } else if (values.length > 1 && values.first > 0) {
        parsedGrowth = ((values.last - values.first) / values.first) * 100;
      }

      setState(() {
        growthYValues = values;
        growthXLabels = labels;
        growthPercentage = parsedGrowth;
        isGrowthLoading = false;
      });
    } else {
      setState(() {
        isGrowthLoading = false;
      });
    }
  } catch (e) {
    print('GROWTH ERROR: $e');
    setState(() {
      isGrowthLoading = false;
    });
  }
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
              onPressed: _isSendingTransaction
                  ? null
                  : () async {
                      final recipient = recipientController.text.trim();
                      final amount = double.tryParse(amountController.text) ?? 0;
                      final pin = pinController.text.trim();
                      final description = descController.text;

                      if (recipient.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter recipient identifier')),
                        );
                        return;
                      }

                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid amount')),
                        );
                        return;
                      }

                      if (_lastSentAmount != null &&
                          amount == _lastSentAmount &&
                          _lastSentAt != null &&
                          DateTime.now().difference(_lastSentAt!).inSeconds < 60) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'You already sent $amount FARM within the last minute. Send a different amount or wait.'),
                          ),
                        );
                        amountController.clear();
                        return;
                      }

                      setState(() {
                        _isSendingTransaction = true;
                      });

                      amountController.clear();

                      final success = await sendTransaction(
                        recipient: recipient,
                        amount: amount,
                        pin: pin,
                        description: description,
                      );

                      if (success) {
                        _lastSentAmount = amount;
                        _lastSentAt = DateTime.now();
                      }

                      if (mounted) {
                        setState(() {
                          _isSendingTransaction = false;
                        });
                      }

                      Navigator.pop(context);
                    },
              child: Text("Send"),
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
        floatingActionButton: Stack(
          children: [
            Positioned(
              bottom: 80.0,
              right: 0.0,
              child: FloatingActionButton.extended(
                onPressed: () {
                  // Gate merchants dashboard - requires Level 3 KYC approval
                  if (kycStatus == 'approved' && kycLevel == '3') {
                    context.goNamed('MerchantDashboard');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete all KYC levels to access Merchants Dashboard'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                backgroundColor: context.textSecondary,
                icon: Icon(
                  Icons.store_outlined,
                  color: FlutterFlowTheme.of(context).onPrimary,
                  size: 24.0,
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
                        color: FlutterFlowTheme.of(context).onPrimary,
                        letterSpacing: 0.0,
                        fontWeight:
                            FlutterFlowTheme.of(context).labelLarge.fontWeight,
                        fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        lineHeight: 1.3,
                      ),
                ),
              ),
            ),
            Positioned(
              bottom: 0.0,
              right: 0.0,
              child: FloatingActionButton.extended(
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
                        fontStyle: FlutterFlowTheme.of(context).labelLarge.fontStyle,
                        lineHeight: 1.3,
                      ),
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          primary: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          shape: BoxShape.rectangle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(context.responsiveValue(24.0, minValue: 16.0)),
                          child: Container(
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color: FlutterFlowTheme.of(context)
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
                                    Column(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.start,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          FFAppState().userName.isNotEmpty
              ? '@${FFAppState().userName}'
              : 'User',
          style: FlutterFlowTheme.of(context)
              .titleLarge
              .override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                ),
                color: FlutterFlowTheme.of(context).primaryText,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w800,
                lineHeight: 1.3,
              ),
        ),
        const SizedBox(width: 6.0),
        Icon(
          Icons.verified_rounded,
          color: FlutterFlowTheme.of(context).primaryText,
          size: 18.0,
        ),
      ],
    ),
    const SizedBox(height: 8.0),
    // Show KYC button only if not fully approved (Level 3)
    if (kycStatus != 'approved' || kycLevel != '3')
      ElevatedButton(
        onPressed: () => context.pushNamed('KYCPAGE'),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.primaryColor,
          foregroundColor: context.background,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: TextStyle(fontSize: 13),
        ),
        child: Text('Verify KYC'),
      ),
    if (kycStatus == 'approved' && kycLevel == '3')
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: context.successColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: context.textPrimary, size: 16),
            const SizedBox(width: 4),
            Text(
              'KYC Verified',
              style: TextStyle(color: context.textPrimary, fontSize: 13),
            ),
          ],
        ),
      ),
  ],
),
                                  
                                  ],
                                ),
                                FlutterFlowIconButton(
                                  borderRadius: 8.0,
                                  buttonSize: 44.0,
                                  fillColor: context.surface,
                                  icon: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Icon(
                                        Icons.notifications_none,
                                        color: FlutterFlowTheme.of(context).primaryText,
                                        size: 28.0,
                                      ),
                                      if (!isNotificationCountLoading && notificationCount > 0)
                                        Positioned(
                                          right: 2,
                                          top: 2,
                                          child: Container(
                                            height: 18,
                                            padding: const EdgeInsets.symmetric(horizontal: 5),
                                            decoration: BoxDecoration(
                                              color: context.errorColor,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              notificationCount.toString(),
                                              style: TextStyle(
                                                color: context.onSurface,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onPressed: () async {
                                    await context.pushNamed('UserNotificationsPage');
                                    if (mounted) {
                                      fetchNotificationCount();
                                    }
                                  },
                                ),
                                FlutterFlowIconButton(
                                  borderRadius: 8.0,
                                  buttonSize: 44.0,
                                  fillColor: Colors.transparent,
                                  icon: (profileImageUrl?.isNotEmpty ?? false)
    ? ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.network(
          profileImageUrl!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
        ),
      )
    : Icon(
        Icons.account_circle_outlined,
        color: FlutterFlowTheme.of(context).primaryText,
        size: 28.0,
      ),
                                  onPressed: () {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('ProfileSettings');
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
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
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                            context.responsiveValue(24.0, minValue: 16.0), 0.0, context.responsiveValue(24.0, minValue: 16.0), 0.0),
                        child: Container(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(context.responsiveValue(24.0, minValue: 18.0)),
                            child: Container(
                              height: context.responsiveValue(200.0, minValue: 160.0, maxValue: 260.0),
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).primary,
                                borderRadius: BorderRadius.circular(24.0),
                                shape: BoxShape.rectangle,
                              ),
                              child: Stack(
                                alignment: const AlignmentDirectional(-1.0, -1.0),
                                children: [
                                  Container(
                                    alignment: const AlignmentDirectional(1.0, -1.0),
                                    child: Container(
                                      width: context.responsiveValue(150.0, minValue: 110.0, maxValue: 180.0),
                                      height: context.responsiveValue(150.0, minValue: 110.0, maxValue: 180.0),
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimary6,
                                        borderRadius:
                                            BorderRadius.circular(9999.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    alignment: const AlignmentDirectional(-1.0, 1.0),
                                    child: Container(
                                      width: context.responsiveValue(100.0, minValue: 80.0, maxValue: 120.0),
                                      height: context.responsiveValue(100.0, minValue: 80.0, maxValue: 120.0),
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimary3,
                                        borderRadius:
                                            BorderRadius.circular(9999.0),
                                        shape: BoxShape.rectangle,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                                  'FARM TOKEN BALANCE',
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
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
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
                                              ].divide(const SizedBox(width: 4.0)),
                                            ),
                                            Text(
  isBalanceLoading
      ? 'Loading...'
      : walletBalance.toStringAsFixed(2),
  style: FlutterFlowTheme.of(context)
      .headlineLarge
      .override(
        font: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
        ),
        color: FlutterFlowTheme.of(context).onPrimary,
        letterSpacing: 0.0,
        fontWeight: FontWeight.w800,
        lineHeight: 1.2,
      ),
),
                                          ].divide(const SizedBox(height: 4.0)),
                                        ),
                                        Row(
  mainAxisSize: MainAxisSize.max,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'a loop of growth',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: FlutterFlowTheme.of(context)
                .labelSmall
                .override(
                  font: GoogleFonts.plusJakartaSans(
                    fontWeight: FlutterFlowTheme.of(context)
                        .labelSmall
                        .fontWeight,
                    fontStyle: FontStyle.italic,
                  ),
                  color: FlutterFlowTheme.of(context).onPrimary50,
                  letterSpacing: 0.0,
                  fontWeight: FlutterFlowTheme.of(context)
                      .labelSmall
                      .fontWeight,
                  fontStyle: FontStyle.italic,
                  lineHeight: 1.2,
                ),
          ),
        ],
      ),
    ),
    Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.0),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                // Gate deposit - requires Level 2 KYC approval
                if (canUserTransact()) {
                  context.pushNamed(DepositpageWidget.routeName);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete Level 2 KYC to deposit'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(Icons.arrow_downward_rounded, size: 16),
              label: Text('Deposit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.successColor,
                foregroundColor: context.background,
                minimumSize: const Size(88, 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                textStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                // Gate withdraw - requires Level 2 KYC approval
                if (canUserTransact()) {
                  context.pushNamed(WithdrawpageWidget.routeName);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete Level 2 KYC to withdraw'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: Icon(Icons.arrow_upward_rounded, size: 16),
              label: Text('Withdraw'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.warningColor,
                foregroundColor: context.background,
                minimumSize: const Size(96, 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                textStyle: TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    ),
                                          ],
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
                                  0.0, 24.0, 0.0, 24.0),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        // Gate Send - requires Level 2 KYC approval
                                        if (canUserTransact()) {
                                          context.goNamed('SendReceive');
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Complete Level 2 KYC to send'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 56.0,
                                            height: 56.0,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                              borderRadius: BorderRadius.circular(20.0),
                                              shape: BoxShape.rectangle,
                                              border: Border.all(
                                                color: FlutterFlowTheme.of(context).alternate,
                                                width: 1.0,
                                              ),
                                            ),
                                            alignment: const AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.north_east_rounded,
                                              color: FlutterFlowTheme.of(context).primaryText,
                                              size: 24.0,
                                            ),
                                          ),
                                          Text(
                                            'Send',
                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                  font: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                  lineHeight: 1.3,
                                                ),
                                          ),
                                        ].divide(const SizedBox(height: 4.0)),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        // Gate Scan - requires Level 2 KYC approval
                                        if (canUserTransact()) {
                                          context.goNamed(QRScannerWidget.routeName);
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Complete Level 2 KYC to scan QR'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 56.0,
                                            height: 56.0,
                                            decoration: BoxDecoration(
                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                              borderRadius: BorderRadius.circular(20.0),
                                              shape: BoxShape.rectangle,
                                              border: Border.all(
                                                color: FlutterFlowTheme.of(context).alternate,
                                                width: 1.0,
                                              ),
                                            ),
                                            alignment: const AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.qr_code_scanner_rounded,
                                              color: FlutterFlowTheme.of(context).primaryText,
                                              size: 24.0,
                                            ),
                                          ),
                                          Text(
                                            'Scan',
                                            style: FlutterFlowTheme.of(context).labelMedium.override(
                                                  font: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                    fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(context).secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FlutterFlowTheme.of(context).labelMedium.fontWeight,
                                                  fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
                                                  lineHeight: 1.3,
                                                ),
                                          ),
                                        ].divide(const SizedBox(height: 4.0)),
                                      ),
                                    ),
                                    // KYC quick action removed per request
                                    wrapWithModel(
                                      model: _model.quickActionModel3,
                                      updateCallback: () => safeSetState(() {}),
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
                                      updateCallback: () => safeSetState(() {}),
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
                        padding:
                            const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 24.0),
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
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
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
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Growth History',
                                                  style:
                                                      FlutterFlowTheme.of(context)
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
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '+${growthPercentage.toStringAsFixed(1)}%',
                                                    style:
                                                        FlutterFlowTheme.of(context)
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
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .success,
                                                              letterSpacing: 0.0,
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .labelLarge
                                                                      .fontStyle,
                                                              lineHeight: 1.3,
                                                            ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => context.goNamed('GrowthTrackingPage'),
                                                    child: Text(
                                                      'Track weekly/monthly/yearly',
                                                      style:
                                                          FlutterFlowTheme.of(context)
                                                              .bodySmall
                                                              .override(
                                                                font: GoogleFonts
                                                                    .plusJakartaSans(),
                                                                fontWeight:
                                                                    FontWeight.w600,
                                                              ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 140.0,
                                            child: isGrowthLoading
                                                ? Center(
                                                    child: CircularProgressIndicator(),
                                                  )
                                                : ClipRRect(
                                                    borderRadius: BorderRadius.circular(12.0),
                                                    child: LayoutBuilder(
                                                      builder: (context, constraints) {
                                                        final double maxX = growthYValues.isNotEmpty
                                                            ? (growthYValues.length - 1).toDouble()
                                                            : 6.0;
                                                        final double maxY = growthYValues.isNotEmpty
                                                            ? growthYValues.reduce((a, b) => a > b ? a : b) * 1.2
                                                            : 72.0;

                                                        return Container(
                                                          width: constraints.maxWidth,
                                                          height: constraints.maxHeight,
                                                          color: Colors.transparent,
                                                          child: FlutterFlowLineChart(
                                                            data: [
                                                              FFLineChartData(
                                                                xData: List.generate(
                                                                  growthYValues.length,
                                                                  (index) => index.toDouble(),
                                                                ),
                                                                yData: growthYValues,
                                                                settings: LineChartBarData(
                                                                  color: FlutterFlowTheme.of(context).primary,
                                                                  barWidth: 2.0,
                                                                  isCurved: true,
                                                                  dotData: const FlDotData(show: false),
                                                                  belowBarData: BarAreaData(
                                                                    show: true,
                                                                    color: FlutterFlowTheme.of(context).primary10,
                                                                  ),
                                                                ),
                                                              )
                                                            ],
                                                            chartStylingInfo: const ChartStylingInfo(
                                                              backgroundColor: Colors.transparent,
                                                              showBorder: false,
                                                            ),
                                                            axisBounds: AxisBounds(
                                                              minX: 0.0,
                                                              minY: 0.0,
                                                              maxX: maxX,
                                                              maxY: maxY,
                                                            ),
                                                            xLabels: growthXLabels,
                                                            xAxisLabelInfo: AxisLabelInfo(
                                                              showLabels: true,
                                                              labelTextStyle: FlutterFlowTheme.of(context).bodySmall.override(
                                                                font: GoogleFonts.inter(
                                                                  fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(context).secondaryText,
                                                                fontSize: 10.0,
                                                                letterSpacing: 0.0,
                                                                fontWeight: FlutterFlowTheme.of(context).bodySmall.fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                                                                lineHeight: 1.0,
                                                              ),
                                                              reservedSize: 28.0,
                                                            ),
                                                            yAxisLabelInfo: const AxisLabelInfo(reservedSize: 0.0),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                            ),
                                        ].divide(const SizedBox(height: 16.0)),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          wrapWithModel(
            model: _model.buttonModel,
            updateCallback: () => safeSetState(() {}),
            child: ButtonWidget(
              content: 'See All',
              icon_present: false,
              icon_end_present: false,
              on_tap: 'navigate:AllTransactions',
              color: FlutterFlowTheme.of(context).primaryText,
              variant: 'ghost',
              size: 'small',
              full_width: false,
              loading: false,
              disabled: false,
            ),
          ),
        ],
      ),

      const SizedBox(height: 16.0),

      if (isTransactionsLoading)
        Center(
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
            style: FlutterFlowTheme.of(context).bodyMedium,
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

            final String title =
                tx['transaction_type'] ?? 'Transaction';

            final String subtitle =
                isOutgoing
                    ? 'Sent transaction'
                    : 'Received transaction';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TransactionItemWidget(
                amount: amount,
                icon: Icon(
                  isOutgoing
                      ? Icons.north_east_rounded
                      : Icons.south_west_rounded,
                  color:
                      FlutterFlowTheme.of(context)
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
    );
  }
}