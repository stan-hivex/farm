import '/app_state.dart';
import '/backend/api_requests/user_api_service.dart';
import '/backend/api_requests/wallet_api_service.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class SendReceiveWidget extends StatefulWidget {
  const SendReceiveWidget({super.key});

  static String routeName = 'SendReceive';
  static String routePath = '/sendReceive';

  @override
  State<SendReceiveWidget> createState() =>
      _SendReceiveWidgetState();
}

class _SendReceiveWidgetState
    extends State<SendReceiveWidget>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final recipientController =
      TextEditingController();

  final amountController =
      TextEditingController();

  final pinController =
      TextEditingController();

  final descriptionController =
      TextEditingController();

  bool isLoading = true;
  bool isSending = false;

  bool showReceive = false;

  double balance = 0;

  List<dynamic> transactions = [];
  List<dynamic> userSuggestions = [];

  late AnimationController successController;

  @override
  void initState() {
    super.initState();

    successController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 900,
      ),
    );

    fetchWallet();
  }

  @override
  void dispose() {
    recipientController.dispose();
    amountController.dispose();
    pinController.dispose();
    descriptionController.dispose();
    successController.dispose();

    super.dispose();
  }

  Future<void> fetchWallet() async {
    try {
      final token =
          context.read<FFAppState>().accessToken;

      final wallet =
          await WalletApiService.getWallet(
        token: token,
      );

      final txs =
          await WalletApiService.getTransactions(
        token: token,
      );

      setState(() {
        balance = double.parse(
          wallet['available_balance']
              .toString(),
        );

        transactions = txs;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  Future<void> searchUsers(
    String value,
  ) async {
    if (value.isEmpty) {
      setState(() {
        userSuggestions = [];
      });

      return;
    }

    try {
      final token =
          context.read<FFAppState>().accessToken;

      final users =
          await UserApiService.searchUsers(
        token: token,
        query: value,
      );

      setState(() {
        userSuggestions = users;
      });
    } catch (_) {}
  }

  double get enteredAmount {
    return double.tryParse(
          amountController.text,
        ) ??
        0;
  }

  double get fee {
    return enteredAmount * 0.015;
  }

  double get total {
    return enteredAmount + fee;
  }

  Future<void> sendFunds() async {
    if (recipientController.text.isEmpty ||
        amountController.text.isEmpty ||
        pinController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Fill all required fields. Use recipient username or phone number.',
          ),
        ),
      );

      return;
    }

    try {
      setState(() {
        isSending = true;
      });

      final token =
          context.read<FFAppState>().accessToken;

      await WalletApiService.sendFunds(
        token: token,
        recipient:
            recipientController.text.trim(),
        amount: enteredAmount,
        pin: pinController.text.trim(),
        description:
            descriptionController.text.trim(),
      );

      successController.forward();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(24),
              ),
              content: SizedBox(
                height: 220,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(
                        begin: 0,
                        end: 1,
                      ).animate(
                        CurvedAnimation(
                          parent:
                              successController,
                          curve:
                              Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration:
                            const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Transfer Successful',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '${enteredAmount.toStringAsFixed(2)} FARM sent successfully',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );

        await Future.delayed(
          const Duration(seconds: 2),
        );

        if (mounted) {
          Navigator.pop(context);
        }

        recipientController.clear();
        amountController.clear();
        pinController.clear();
        descriptionController.clear();

        fetchWallet();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  Widget buildInfoRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color:
                FlutterFlowTheme.of(context)
                    .secondaryText,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildTransactionCard(
    dynamic tx,
  ) {
    final outgoing =
        tx['is_outgoing'] == true;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        color:
            FlutterFlowTheme.of(context)
                .secondaryBackground,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outgoing
                  ? Colors.red.shade100
                  : Colors.green.shade100,
            ),
            child: Icon(
              outgoing
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: outgoing
                  ? Colors.red
                  : Colors.green,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  outgoing
                      ? 'Sent FARM'
                      : 'Received FARM',
                  style: const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  tx['transaction_reference'],
                  style: TextStyle(
                    color:
                        FlutterFlowTheme.of(
                                context)
                            .secondaryText,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${tx['amount']} FARM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: outgoing
                  ? Colors.red
                  : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSuggestionCard(
    dynamic user,
  ) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          user['username'][0]
              .toUpperCase(),
        ),
      ),
      title: Text(
        '@${user['username']}',
      ),
      onTap: () {
        recipientController.text =
            user['username'];

        setState(() {
          userSuggestions = [];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor:
            FlutterFlowTheme.of(context)
                .primaryBackground,

        body: SafeArea(
          child: isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(),
                )
              : Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          FlutterFlowIconButton(
                            borderRadius: 8,
                            buttonSize: 40,
                            icon: Icon(
                              Icons
                                  .arrow_back_rounded,
                              color:
                                  FlutterFlowTheme.of(
                                          context)
                                      .primaryText,
                            ),
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                            },
                          ),

                          Text(
                            'Send & Receive',
                            style:
                                FlutterFlowTheme.of(
                                        context)
                                    .titleLarge
                                    .override(
                                      font:
                                          GoogleFonts.plusJakartaSans(
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                          ),

                          FlutterFlowIconButton(
                            borderRadius: 8,
                            buttonSize: 40,
                            icon: Icon(
                              Icons.refresh,
                              color:
                                  FlutterFlowTheme.of(
                                          context)
                                      .primaryText,
                            ),
                            onPressed:
                                fetchWallet,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child:
                          SingleChildScrollView(
                        padding:
                            const EdgeInsets.all(
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .stretch,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets
                                      .all(28),
                              decoration:
                                  BoxDecoration(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  28,
                                ),
                                color:
                                    FlutterFlowTheme.of(
                                            context)
                                        .primaryText,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(
                                          context)
                                      .secondaryText
                                      .withAlpha(41),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withAlpha(20),
                                    blurRadius: 16,
                                    offset:
                                        const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Text(
                                    'Available Balance',
                                    style:
                                        TextStyle(
                                      color:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .primaryBackground,
                                      fontWeight:
                                          FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  Text(
                                    '${balance.toStringAsFixed(2)} FARM',
                                    style:
                                        FlutterFlowTheme.of(
                                                context)
                                            .headlineLarge
                                            .override(
                                              color:
                                                  Colors.white,
                                              font:
                                                  GoogleFonts.plusJakartaSans(
                                                fontWeight:
                                                    FontWeight.bold,
                                              ),
                                            ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 24,
                            ),

                            Row(
                              children: [
                                Expanded(
                                  child:
                                      GestureDetector(
                                    onTap: () {
                                      setState(
                                        () {
                                          showReceive =
                                              false;
                                        },
                                      );
                                    },
                                    child:
                                        Container(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        18,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                        color: !showReceive
                                            ? FlutterFlowTheme.of(
                                                    context)
                                                .primaryBackground
                                            : FlutterFlowTheme.of(
                                                    context)
                                                .primaryText,
                                        border: Border.all(
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText
                                                  .withAlpha(51),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withAlpha(13),
                                            blurRadius: 12,
                                            offset:
                                                const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child:
                                          Center(
                                        child:
                                            Text(
                                          'Send',
                                          style:
                                              TextStyle(
                                            color: !showReceive
                                                ? FlutterFlowTheme.of(context).primaryText
                                                : Colors.white,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 16,
                                ),

                                Expanded(
                                  child:
                                      GestureDetector(
                                    onTap: () {
                                      setState(
                                        () {
                                          showReceive =
                                              true;
                                        },
                                      );
                                    },
                                    child:
                                        Container(
                                      padding:
                                          const EdgeInsets
                                              .all(
                                        18,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                        color: showReceive
                                            ? FlutterFlowTheme.of(
                                                    context)
                                                .primaryBackground
                                            : FlutterFlowTheme.of(
                                                    context)
                                                .primaryText,
                                        border: Border.all(
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText
                                                  .withAlpha(51),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withAlpha(13),
                                            blurRadius: 12,
                                            offset:
                                                const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child:
                                          Center(
                                        child:
                                            Text(
                                          'Receive',
                                          style:
                                              TextStyle(
                                            color: showReceive
                                                ? FlutterFlowTheme.of(context).primaryText
                                                : Colors.white,
                                            fontWeight:
                                                FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 32,
                            ),

                            if (!showReceive)
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,
                                children: [
                                  TextField(
                                    controller:
                                        recipientController,
                                    onChanged:
                                        searchUsers,
                                    decoration:
                                        InputDecoration(
                                      filled: true,
                                      fillColor:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .secondaryBackground,
                                      hintText:
                                          'Recipient username or phone number',
                                      helperText:
                                          'You can send to either a username or phone number',
                                      helperStyle:
                                          TextStyle(
                                        color:
                                            FlutterFlowTheme.of(
                                                    context)
                                                .secondaryText,
                                        fontSize: 12,
                                      ),
                                      prefixIcon:
                                          const Icon(
                                        Icons
                                            .person,
                                      ),
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                        borderSide:
                                            BorderSide(
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText
                                                  .withAlpha(61),
                                        ),
                                      ),
                                    ),
                                  ),

                                  if (userSuggestions
                                      .isNotEmpty)
                                    Container(
                                      margin:
                                          const EdgeInsets
                                              .only(
                                        top: 12,
                                      ),
                                      decoration:
                                          BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                        color: FlutterFlowTheme.of(
                                                context)
                                            .secondaryBackground,
                                        border: Border.all(
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText
                                                  .withAlpha(41),
                                        ),
                                      ),
                                      child:
                                          Column(
                                        children:
                                            userSuggestions
                                                .map(
                                                  (
                                                    u,
                                                  ) =>
                                                      buildSuggestionCard(
                                                    u,
                                                  ),
                                                )
                                                .toList(),
                                      ),
                                    ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  TextField(
                                    controller:
                                        amountController,
                                    keyboardType:
                                        TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .allow(
                                        RegExp(
                                          r'[0-9.]',
                                        ),
                                      ),
                                    ],
                                    onChanged:
                                        (_) {
                                      setState(
                                        () {},
                                      );
                                    },
                                    decoration:
                                        InputDecoration(
                                      filled: true,
                                      fillColor:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .secondaryBackground,
                                      hintText:
                                          'Amount',
                                      prefixText:
                                          'FARM ',
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                        borderSide:
                                            BorderSide(
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText
                                                  .withAlpha(61),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  TextField(
                                    controller:
                                        descriptionController,
                                    maxLines: 3,
                                    decoration:
                                        InputDecoration(
                                      filled: true,
                                      fillColor:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .secondaryBackground,
                                      hintText:
                                          'Description',
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                        borderSide:
                                            BorderSide(
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText
                                                  .withAlpha(61),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 20,
                                  ),

                                  TextField(
                                    controller:
                                        pinController,
                                    obscureText:
                                        true,
                                    keyboardType:
                                        TextInputType.number,
                                    decoration:
                                        InputDecoration(
                                      filled: true,
                                      fillColor:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .secondaryBackground,
                                      hintText:
                                          'Enter PIN',
                                      prefixIcon:
                                          const Icon(
                                        Icons.lock,
                                      ),
                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                          18,
                                        ),
                                        borderSide:
                                            BorderSide(
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .secondaryText
                                                  .withAlpha(61),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 24,
                                  ),

                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .all(24),
                                    decoration:
                                        BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(
                                        24,
                                      ),
                                      color: FlutterFlowTheme.of(
                                              context)
                                          .secondaryBackground,
                                    ),
                                    child:
                                        Column(
                                      children: [
                                        buildInfoRow(
                                          'Amount',
                                          '${enteredAmount.toStringAsFixed(2)} FARM',
                                        ),

                                        const SizedBox(
                                          height:
                                              12,
                                        ),

                                        buildInfoRow(
                                          'Fee',
                                          '${fee.toStringAsFixed(2)} FARM',
                                        ),

                                        const SizedBox(
                                          height:
                                              12,
                                        ),

                                        buildInfoRow(
                                          'Total',
                                          '${total.toStringAsFixed(2)} FARM',
                                        ),

                                        const SizedBox(
                                          height:
                                              12,
                                        ),

                                        buildInfoRow(
                                          'Balance',
                                          '${balance.toStringAsFixed(2)} FARM',
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 24,
                                  ),

                                  SizedBox(
                                    height: 58,
                                    child:
                                        ElevatedButton(
                                      onPressed:
                                          isSending
                                              ? null
                                              : sendFunds,
                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor:
                                            FlutterFlowTheme.of(
                                                    context)
                                                .primaryText,
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                      child:
                                          isSending
                                              ? const CircularProgressIndicator(
                                                  color:
                                                      Colors.white,
                                                )
                                              : const Text(
                                                  'Send FARM',
                                                  style:
                                                      TextStyle(
                                                    fontSize:
                                                        18,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        Colors.white,
                                                  ),
                                                ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                padding:
                                    const EdgeInsets
                                        .all(32),
                                decoration:
                                    BoxDecoration(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    28,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(
                                              context)
                                          .secondaryBackground,
                                  border: Border.all(
                                    color:
                                        FlutterFlowTheme.of(
                                                context)
                                            .secondaryText
                                            .withAlpha(41),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withAlpha(13),
                                      blurRadius: 14,
                                      offset:
                                          const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.qr_code,
                                      size: 180,
                                      color:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .primaryText,
                                    ),

                                    const SizedBox(
                                      height: 24,
                                    ),

                                    Text(
                                      'Receive FARM',
                                      style:
                                          FlutterFlowTheme.of(
                                                  context)
                                              .headlineSmall
                                              .override(
                                                color:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                              ),
                                    ),

                                    const SizedBox(
                                      height: 12,
                                    ),

                                    SelectableText(
                                      context
                                          .read<FFAppState>()
                                          .userName,
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                        fontSize:
                                            20,
                                        color:
                                            FlutterFlowTheme.of(
                                                    context)
                                                .primaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(
                              height: 36,
                            ),

                            Text(
                              'Recent Transactions',
                              style:
                                  FlutterFlowTheme.of(
                                          context)
                                      .titleLarge
                                      .override(
                                        font:
                                            GoogleFonts.plusJakartaSans(
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            if (transactions
                                .isEmpty)
                              const Center(
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(
                                    24,
                                  ),
                                  child: Text(
                                    'No transactions yet',
                                  ),
                                ),
                              )
                            else
                              Column(
                                children:
                                    transactions
                                        .map(
                                          (
                                            tx,
                                          ) =>
                                              buildTransactionCard(
                                            tx,
                                          ),
                                        )
                                        .toList(),
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