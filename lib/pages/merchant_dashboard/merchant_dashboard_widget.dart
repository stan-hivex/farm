import '/components/button/button_widget.dart';
import '/components/merchant_stat_card/merchant_stat_card_widget.dart';
import '/components/merchant_transaction_item/merchant_transaction_item_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'merchant_dashboard_model.dart';


class MerchantDashboardWidget extends StatefulWidget {
  const MerchantDashboardWidget({super.key});

  static String routeName = 'MerchantDashboard';
  static String routePath = '/merchantDashboard';

  @override
  State<MerchantDashboardWidget> createState() =>
      _MerchantDashboardWidgetState();
}

class _MerchantDashboardWidgetState extends State<MerchantDashboardWidget> {
  late MerchantDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool loading = true;
  bool payoutLoading = false;
  bool regeneratingQr = false;
  bool applyingMerchant = false;
  bool merchantNotFound = false;

  Map<String, dynamic>? merchant;
  Map<String, dynamic>? stats;

  List<dynamic> recentTransactions = [];
  List<double> weeklyData = [120, 300, 220, 480, 600, 540, 650];

  final TextEditingController amountController = TextEditingController();
  final TextEditingController accountNameController = TextEditingController();
  final TextEditingController accountNumberController = TextEditingController();

  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController businessTypeController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController countryController = TextEditingController();
  final TextEditingController cityController = TextEditingController();

  String payoutMethod = 'M-PESA';

  final String baseUrl = "https://farm-backend-9b8u.onrender.com/api/v1";

  Future<String?> getToken() async {
    return FFAppState().accessToken;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MerchantDashboardModel());
    fetchDashboard();
  }

  @override
  void dispose() {
    _model.dispose();
    amountController.dispose();
    accountNameController.dispose();
    accountNumberController.dispose();
    businessNameController.dispose();
    businessTypeController.dispose();
    emailController.dispose();
    phoneController.dispose();
    countryController.dispose();
    cityController.dispose();
    super.dispose();
  }

  Future<void> fetchDashboard() async {
    try {
      setState(() {
        loading = true;
        merchantNotFound = false;
      });

      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/merchant/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = body['data'];
        setState(() {
          merchant = data['merchant'];
          stats = data['stats'];
          recentTransactions = data['recent_transactions'] ?? [];
          loading = false;
        });
      } else {
        final message = body['message']?.toString() ?? '';
        if (message.contains('Merchant account not found')) {
          setState(() {
            merchantNotFound = true;
            loading = false;
          });
          return;
        }
        setState(() {
          loading = false;
        });
        showError(message);
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      showError(e.toString());
    }
  }

  Future<void> applyMerchant() async {
    try {
      setState(() {
        applyingMerchant = true;
      });

      final token = FFAppState().accessToken;
      final response = await http.post(
        Uri.parse('$baseUrl/merchant/apply'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'business_name': businessNameController.text.trim(),
          'business_type': businessTypeController.text.trim(),
          'business_email': emailController.text.trim(),
          'business_phone': phoneController.text.trim(),
          'country': countryController.text.trim(),
          'city': cityController.text.trim(),
        }),
      );

      final body = jsonDecode(response.body);
      setState(() {
        applyingMerchant = false;
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        Navigator.pop(context);
        showSuccess(body['message'] ?? 'Merchant application submitted');
        fetchDashboard();
      } else {
        showError(body['message'] ?? 'Failed to apply');
      }
    } catch (e) {
      setState(() {
        applyingMerchant = false;
      });
      showError(e.toString());
    }
  }

  Future<void> regenerateQr() async {
    try {
      setState(() {
        regeneratingQr = true;
      });

      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/merchant/qr/regenerate'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final body = jsonDecode(response.body);
      setState(() {
        regeneratingQr = false;
      });

      if (response.statusCode == 200) {
        showSuccess('QR regenerated successfully');
        fetchDashboard();
      } else {
        showError(body['message'] ?? 'Failed to regenerate QR');
      }
    } catch (e) {
      setState(() {
        regeneratingQr = false;
      });
      showError(e.toString());
    }
  }

  Future<void> requestPayout() async {
    try {
      setState(() {
        payoutLoading = true;
      });

      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/merchant/payout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amount': double.parse(amountController.text),
          'payout_method': payoutMethod,
          'account_name': accountNameController.text,
          'account_number': accountNumberController.text,
        }),
      );

      final body = jsonDecode(response.body);
      setState(() {
        payoutLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        showSuccess('Payout request submitted');
        fetchDashboard();
      } else {
        showError(body['message']);
      }
    } catch (e) {
      setState(() {
        payoutLoading = false;
      });
      showError(e.toString());
    }
  }

  void openApplyMerchantModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Create Merchant Account',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 28),
                buildInput(businessNameController, 'Business Name'),
                const SizedBox(height: 18),
                buildInput(businessTypeController, 'Business Type'),
                const SizedBox(height: 18),
                buildInput(emailController, 'Business Email'),
                const SizedBox(height: 18),
                buildInput(phoneController, 'Business Phone'),
                const SizedBox(height: 18),
                buildInput(countryController, 'Country'),
                const SizedBox(height: 18),
                buildInput(cityController, 'City'),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: applyingMerchant ? null : applyMerchant,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlutterFlowTheme.of(context).primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: applyingMerchant
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void openPayoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Request Payout',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),
                    buildInput(amountController, 'Amount'),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: payoutMethod,
                      items: ['M-PESA', 'Bank Transfer', 'Wallet']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setModalState(() {
                          payoutMethod = value!;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Payout Method',
                        filled: true,
                        fillColor: const Color(0xFF111B2A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    buildInput(accountNameController, 'Account Name'),
                    const SizedBox(height: 18),
                    buildInput(accountNumberController, 'Account Number'),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: payoutLoading ? null : requestPayout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: payoutLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Submit Payout Request'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(message),
      ),
    );
  }

  void showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text(message),
      ),
    );
  }

  String formatAmount(dynamic amount) {
    return (amount ?? 0).toString();
  }

  Widget buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFF111B2A),
        hintStyle: const TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
      style: const TextStyle(color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (merchantNotFound) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(
                      Icons.storefront_rounded,
                      size: 60,
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Create Merchant Account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      color: FlutterFlowTheme.of(context).primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'You do not yet have a merchant account.\nApply now and start receiving payments.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: openApplyMerchantModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Apply Merchant Account',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SingleChildScrollView(
          primary: false,
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
                  padding: EdgeInsets.all(24),
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
                              'Merchant Portal',
                              style: FlutterFlowTheme.of(context)
                                  .headlineMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .headlineMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineMedium
                                        .fontStyle,
                                    lineHeight: 1.25,
                                  ),
                            ),
                            Text(
                              'a loop of growth',
                              style: FlutterFlowTheme.of(context)
                                  .labelMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryText,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .labelMedium
                                        .fontStyle,
                                    lineHeight: 1.3,
                                  ),
                            ),
                          ],
                        ),
                        FlutterFlowIconButton(
                          borderRadius: 8,
                          buttonSize: 40,
                          fillColor: Colors.transparent,
                          icon: Icon(
                            Icons.settings_rounded,
                            color: FlutterFlowTheme.of(context).primaryText,
                            size: 24,
                          ),
                          onPressed: () {
                            print('IconButton pressed ...');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 24, 0, 24),
                child: Container(
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                      borderRadius: BorderRadius.circular(24),
                      shape: BoxShape.rectangle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Total Earnings',
                                  style: FlutterFlowTheme.of(context)
                                      .labelLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelLarge
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimary80,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .fontStyle,
                                        lineHeight: 1.3,
                                      ),
                                ),
                                SvgPicture.network(
                                  'https://cdn.simpleicons.org/algorand/ffffff.svg',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                            Text(
                              '${formatAmount(stats?['total_revenue'])} FARM',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color:
                                        FlutterFlowTheme.of(context).onPrimary,
                                    fontSize: 32,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FlutterFlowTheme.of(context)
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
                                Icon(
                                  Icons.trending_up_rounded,
                                  color: FlutterFlowTheme.of(context).onPrimary,
                                  size: 16,
                                ),
                                Text(
                                  '+12% from last month',
                                  style: FlutterFlowTheme.of(context)
                                      .labelSmall
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelSmall
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .onPrimary90,
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
                              ].divide(SizedBox(width: 8)),
                            ),
                          ].divide(SizedBox(height: 16)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 1,
                      child: wrapWithModel(
                        model: _model.merchantStatCardModel1,
                        updateCallback: () => safeSetState(() {}),
                        child: MerchantStatCardWidget(
                          label: 'Sales Today',
                          value: '${stats?['sales_today_count'] ?? 0}',
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: wrapWithModel(
                        model: _model.merchantStatCardModel2,
                        updateCallback: () => safeSetState(() {}),
                        child: MerchantStatCardWidget(
                          label: 'Revenue',
                          value: '${formatAmount(stats?['sales_today'])}',
                        ),
                      ),
                    ),
                  ].divide(SizedBox(width: 16)),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Container(
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      borderRadius: BorderRadius.circular(20),
                      shape: BoxShape.rectangle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  'Business QR Code',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Icon(
                                  Icons.qr_code_2_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 24,
                                ),
                              ],
                            ),
                            Container(
                              alignment: AlignmentDirectional(0, 0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  shape: BoxShape.rectangle,
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(context).alternate,
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: merchant?['qr_code'] != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: CachedNetworkImage(
                                            imageUrl: merchant!['qr_code'],
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                                    child:
                                                        CircularProgressIndicator()),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Center(
                                                        child: Icon(
                                                            Icons
                                                                .qr_code_2_rounded,
                                                            size: 120,
                                                            color: Colors
                                                                .white24)),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 120,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0, 0),
                              child: Text(
                                merchant?['business_name'] ?? '@merchant',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.5,
                                    ),
                              ),
                            ),
                            wrapWithModel(
                              model: _model.buttonModel1,
                              updateCallback: () => safeSetState(() {}),
                              child: ButtonWidget(
                                content: 'Download Kit',
                                icon: Icon(
                                  Icons.download_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 16,
                                ),
                                icon_present: true,
                                icon_end_present: false,
                                on_tap: 'navigate:Dashboard',
                                color: FlutterFlowTheme.of(context).primaryText,
                                variant: 'outline',
                                size: 'medium',
                                full_width: true,
                                loading: false,
                                disabled: false,
                              ),
                            ),
                          ].divide(SizedBox(height: 24)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(0, 0, 0, 24),
                child: Container(
                  child: Container(
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
                      child: Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Weekly Performance',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                            ),
                            Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(20),
                                shape: BoxShape.rectangle,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 1,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Container(
                                  child: Container(
                                    height: 168,
                                    child: FlutterFlowBarChart(
                                      barData: [
                                        FFBarChartData(
                                          yData: (weeklyData),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                        )
                                      ],
                                      xLabels: ([
                                        'M',
                                        'T',
                                        'W',
                                        'T',
                                        'F',
                                        'S',
                                        'S'
                                      ]),
                                      barWidth: 20,
                                      barBorderRadius: BorderRadius.circular(4),
                                      groupSpace: 12,
                                      alignment: BarChartAlignment.spaceEvenly,
                                      chartStylingInfo: ChartStylingInfo(
                                        backgroundColor: Colors.transparent,
                                        showBorder: false,
                                      ),
                                      axisBounds: AxisBounds(
                                        minY: 0,
                                        maxX: 6,
                                        maxY: 720,
                                      ),
                                      xAxisLabelInfo: AxisLabelInfo(
                                        showLabels: true,
                                        labelTextStyle: FlutterFlowTheme.of(
                                                context)
                                            .bodySmall
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodySmall
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 10,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontStyle,
                                              lineHeight: 1,
                                            ),
                                        reservedSize: 20,
                                      ),
                                      yAxisLabelInfo: AxisLabelInfo(
                                        reservedSize: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 16)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(24, 0, 24, 0),
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
                          'Recent Sales',
                          style:
                              FlutterFlowTheme.of(context).titleMedium.override(
                                    font: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                    lineHeight: 1.4,
                                  ),
                        ),
                        wrapWithModel(
                          model: _model.buttonModel2,
                          updateCallback: () => safeSetState(() {}),
                          child: ButtonWidget(
                            content: 'View All',
                            icon_present: false,
                            icon_end_present: false,
                            on_tap: 'navigate:Dashboard',
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
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: recentTransactions.isEmpty
                          ? [
                              Center(
                                child: Text(
                                  'No recent transactions',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium,
                                ),
                              ),
                            ]
                          : recentTransactions
                              .asMap()
                              .entries
                              .map((entry) {
                                int index = entry.key;
                                dynamic tx = entry.value;
                                return wrapWithModel(
                                  model: index == 0
                                      ? _model.merchantTransactionItemModel1
                                      : index == 1
                                          ? _model.merchantTransactionItemModel2
                                          : index == 2
                                              ? _model
                                                  .merchantTransactionItemModel3
                                              : _model
                                                  .merchantTransactionItemModel4,
                                  updateCallback: () => safeSetState(() {}),
                                  child: MerchantTransactionItemWidget(
                                    amount: '${tx['amount'] ?? 0}',
                                    customer: tx['customer_name'] ?? '@user',
                                    date: tx['created_at'] ?? '',
                                    icon: Icon(
                                      Icons.person_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24,
                                    ),
                                    status: tx['status'] ?? 'COMPLETED',
                                  ),
                                );
                              })
                              .toList(),
                    ),
                  ].divide(SizedBox(height: 16)),
                ),
              ),
              Container(
                height: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
