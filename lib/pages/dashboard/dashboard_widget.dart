import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/components/button/button_widget.dart';
import '/components/quick_action/quick_action_widget.dart';
import '/components/transaction_item/transaction_item_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/q_r_scanner/q_r_scanner_widget.dart';
import '/pages/depositpage/depositpage_widget.dart';
import '/pages/withdrawpage/withdrawpage_widget.dart';
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

class _DashboardWidgetState extends State<DashboardWidget> {
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

  @override
void initState() {
  super.initState();

  _model = createModel(context, () => DashboardModel());

  fetchWalletBalance();
  fetchUserProfile();
  fetchTransactions();
  fetchGrowthHistory();
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

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
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

      setState(() {
        profileImageUrl = data['data']['profile_image'];
      });
    }
  } catch (e) {
    print('PROFILE ERROR: $e');
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
try {
final response = await http.get(
Uri.parse(
'${AppConfig.api}/analytics/growth-history?days=7',
),
headers: {
'Content-Type': 'application/json',
'Authorization':
'Bearer ${FFAppState().accessToken}',
},
);


print('GROWTH STATUS: ${response.statusCode}');
print('GROWTH BODY: ${response.body}');

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);

  final List history = data['data'];

  setState(() {
    growthYValues = history
        .map<double>(
          (e) => double.parse(
            e['total'].toString(),
          ),
        )
        .toList();

    growthXLabels = history
        .map<String>(
          (e) =>
              e['date']
                  .toString()
                  .substring(5),
        )
        .toList();

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
        floatingActionButton: FloatingActionButton.extended(
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
                          padding: const EdgeInsets.all(24.0),
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
    Icon(
      Icons.verified_rounded,
      color: FlutterFlowTheme.of(context).primaryText,
      size: 18.0,
    ),
  ].divide(const SizedBox(width: 4.0)),
),
const SizedBox(height: 8.0),
ElevatedButton(
  onPressed: () {
    context.pushNamed('KYCPAGE');
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: FlutterFlowTheme.of(context).primary,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  child: Text(
    'Verify KYC',
    style: FlutterFlowTheme.of(context).labelLarge.override(
          font: GoogleFonts.plusJakartaSans(),
          color: FlutterFlowTheme.of(context).onPrimary,
          fontWeight: FontWeight.bold,
        ),
  ),
),
                                  ],
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
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('ProfileSettings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
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
                        padding: const EdgeInsetsDirectional.fromSTEB(
                            24.0, 0.0, 24.0, 0.0),
                        child: Container(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: Container(
                              height: 200.0,
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
                                      width: 150.0,
                                      height: 150.0,
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
                                      width: 100.0,
                                      height: 100.0,
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
                                           Text(
  isBalanceLoading
      ? 'Fetching balance...'
      : '≈ ${kesEquivalent.toStringAsFixed(2)} KES',
  style: FlutterFlowTheme.of(context)
      .bodySmall
      .override(
        font: GoogleFonts.inter(),
        color: FlutterFlowTheme.of(context).onPrimary60,
        letterSpacing: 0.0,
        lineHeight: 1.4,
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
        color: FlutterFlowTheme.of(context).onPrimary,
                                                borderRadius:
                                                    BorderRadius.circular(14.0),
                                                shape: BoxShape.rectangle,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 8.0, 16.0, 8.0),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        context.pushNamed(DepositpageWidget.routeName);
                                                      },
                                                      icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                                                      label: const Text('Deposit'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.green,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                        textStyle: const TextStyle(fontSize: 12),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        context.pushNamed(WithdrawpageWidget.routeName);
                                                      },
                                                      icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                                                      label: const Text('Withdraw'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.orange,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                        textStyle: const TextStyle(fontSize: 12),
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
                                    wrapWithModel(
                                      model: _model.quickActionModel1,
                                      updateCallback: () => safeSetState(() {}),
                                      child: QuickActionWidget(
                                        action: 'navigate:SendReceive',
                                        icon: Icon(
                                          Icons.north_east_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        label: 'Send',
                                      ),
                                    ),
                                    wrapWithModel(
  model: _model.quickActionModel2,
  updateCallback: () => safeSetState(() {}),
  child: QuickActionWidget(
    action: 'navigate:${QRScannerWidget.routeName}',
    icon: Icon(
      Icons.qr_code_scanner_rounded,
      color: FlutterFlowTheme.of(context).primaryText,
      size: 24.0,
    ),
    label: 'Scan',
  ),
),
                                    // KYC quick action inserted between Scan and Escrow
                                    wrapWithModel(
                                      model: _model.quickActionModel5,
                                      updateCallback: () => safeSetState(() {}),
                                      child: QuickActionWidget(
                                        action: 'navigate:KYCPAGE',
                                        icon: Icon(
                                          Icons.verified_user_rounded,
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          size: 24.0,
                                        ),
                                        label: 'KYC',
                                      ),
                                    ),
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
                                              Text(
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
                                              Text(
                                                '+12.5%',
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
                                            ],
                                          ),
                                          SizedBox(
                                            height: 120.0,
                                            child: isGrowthLoading
                                                ? const Center(
                                                    child: CircularProgressIndicator(),
                                                  )
                                                : FlutterFlowLineChart(
                                                data: [
                                                  FFLineChartData(
                                                    xData: List.generate(
growthYValues.length,
(index) => index.toDouble(),
),

yData: growthYValues,

                                                    settings: LineChartBarData(
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primary,
                                                      barWidth: 2.0,
                                                      isCurved: true,
                                                      dotData: const FlDotData(
                                                          show: false),
                                                      belowBarData: BarAreaData(
                                                        show: true,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary10,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                                chartStylingInfo:
                                                    const ChartStylingInfo(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  showBorder: false,
                                                ),
                                                axisBounds: const AxisBounds(
                                                  minX: 0.0,
                                                  minY: 0.0,
                                                  maxX: 6.0,
                                                  maxY: 72.0,
                                                ),
                                                xLabels: growthXLabels,

                                                xAxisLabelInfo: AxisLabelInfo(
                                                  showLabels: true,
                                                  labelTextStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                            ),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryText,
                                                            fontSize: 10.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                            lineHeight: 1.0,
                                                          ),
                                                  reservedSize: 28.0,
                                                ),
                                                yAxisLabelInfo: const AxisLabelInfo(
                                                  reservedSize: 0.0,
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
              on_tap: 'navigate:MerchantDashboard',
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