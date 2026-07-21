import '/backend/api_requests/escrow_api_service.dart';
import '/backend/models/escrow_model.dart';
import '/components/escrow_item/escrow_item_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';
import '/backend/api_requests/wallet_api_service.dart';
import '/backend/api_requests/user_api_service.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EscrowHubWidget extends StatefulWidget {
  const EscrowHubWidget({super.key});

  static String routeName = 'EscrowHub';
  static String routePath = '/escrowHub';

  @override
  State<EscrowHubWidget> createState() => _EscrowHubWidgetState();
}

class _EscrowHubWidgetState extends State<EscrowHubWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool isLoading = false;

  String selectedFilter = 'all';

  List<EscrowModel> escrows = [];

  int activeCount = 0;
  double protectedAmount = 0;

  @override
void initState() {
  super.initState();

  WidgetsBinding.instance.addPostFrameCallback((_) {
    fetchEscrows();
  });
}

  Future<void> searchUsers(String value, TextEditingController controller) async {
    if (value.trim().isEmpty) {
      return;
    }

    try {
      final token = context.read<FFAppState>().accessToken;
      await UserApiService.searchUsers(token: token, query: value.trim());
      if (!mounted) return;
    } catch (_) {
      if (!mounted) return;
    }
  }

  Future<void> fetchEscrows() async {
  if (!mounted) return;

  setState(() {
    isLoading = true;
  });

  try {
    final token = context.read<FFAppState>().accessToken;

    final response = await EscrowApiService.getEscrows(
      token: token,
      status: selectedFilter == 'all'
          ? null
          : selectedFilter,
    );

    if (!mounted) return;

    setState(() {
      escrows = response;

      activeCount =
          escrows.where((e) => e.status == 'active').length;

      protectedAmount = escrows
          .where((e) => e.status == 'active')
          .fold(
            0.0,
            (sum, item) => sum + item.amount,
          );
    });
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to fetch escrows: $e',
        ),
      ),
    );
  } finally {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
}
  Future<void> releaseEscrow(String escrowId, {double? releaseAmount}) async {
    // Find the escrow to get the amount
    final escrow = escrows.firstWhere((e) => e.id == escrowId);
    final releaseFee = escrow.amount * 0.015;
    final amountAfterFee = escrow.amount - releaseFee;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Release'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Release breakdown:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Escrow Amount:'),
                  Text('${escrow.amount.toStringAsFixed(2)} FARM'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Platform Fee (1.5%):'),
                  Text('-${releaseFee.toStringAsFixed(2)} FARM'),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seller Receives:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${amountAfterFee.toStringAsFixed(2)} FARM',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Confirm Release'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final token = context.read<FFAppState>().accessToken;

      await EscrowApiService.releaseEscrow(
        token: token,
        escrowId: escrowId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Funds released successfully. Seller receives ${amountAfterFee.toStringAsFixed(2)} FARM (after 1.5% fee).'),
        ),
      );

      fetchEscrows();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Release failed: $e'),
        ),
      );
    }
  }


  Future<void> disputeEscrow(String escrowId) async {
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Raise Dispute'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter dispute reason',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.trim().isEmpty) {
      return;
    }

    try {
      final token = context.read<FFAppState>().accessToken;

      await EscrowApiService.disputeEscrow(
        token: token,
        escrowId: escrowId,
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute raised'),
        ),
      );

      fetchEscrows();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dispute failed: $e'),
        ),
      );
    }
  }

  Future<void> showCreateEscrowDialog() async {
    final sellerController = TextEditingController();
    final amountController = TextEditingController();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final pinController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double amount = 0;
            double fee = 0;
            double totalRequired = 0;
            List<dynamic> suggestionUsers = [];

            Future<void> searchUsers(String value) async {
              if (!UserApiService.shouldSearchSuggestions(value)) {
                setState(() => suggestionUsers = []);
                return;
              }

              try {
                final token = context.read<FFAppState>().accessToken;
                final users = await UserApiService.searchUsers(
                  token: token,
                  query: value.trim(),
                );
                if (!mounted) return;
                setState(() => suggestionUsers = users);
              } catch (_) {
                if (!mounted) return;
                setState(() => suggestionUsers = []);
              }
            }

            // Update values if amount is valid
            try {
              if (amountController.text.isNotEmpty) {
                amount = double.parse(amountController.text.trim());
                fee = double.parse((amount * 0.015).toStringAsFixed(2));
                totalRequired = amount + fee;
              }
            } catch (_) {}

            return AlertDialog(
              title: Text('Create Escrow'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: sellerController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                            hintText: 'Recipient username or phone number',
                            helperText: 'You can pick a seller by username or phone number',
                            helperStyle: TextStyle(
                              color: FlutterFlowTheme.of(context).secondaryText,
                              fontSize: 12,
                            ),
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).secondaryText.withAlpha(61),
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            searchUsers(value);
                          },
                        ),
                        if (suggestionUsers.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).secondaryText.withAlpha(41),
                              ),
                            ),
                            child: Column(
                              children: suggestionUsers.map((u) {
                                final user = u as Map<String, dynamic>;
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    child: Text(
                                      (user['username'] ?? 'u').toString().trim().isNotEmpty
                                          ? (user['username'] ?? 'u').toString().trim()[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(UserApiService.getSuggestionLabel(user)),
                                  onTap: () {
                                    sellerController.text = UserApiService.getSuggestionValue(user);
                                    setState(() => suggestionUsers = []);
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount (FARM)',
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                    const SizedBox(height: 16),
                    // Fee breakdown section
                    if (amount > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fee Breakdown',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Escrow Amount:'),
                                Text('${amount.toStringAsFixed(2)} FARM'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Platform Fee (1.5%):'),
                                Text('${fee.toStringAsFixed(2)} FARM'),
                              ],
                            ),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Required:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  '${totalRequired.toStringAsFixed(2)} FARM',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'PIN',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final token =
                          context.read<FFAppState>().accessToken;

                      final amount = double.parse(amountController.text.trim());
                      final fee = double.parse((amount * 0.015).toStringAsFixed(2));

                      // Check wallet balance
                      final wallet = await WalletApiService.getWallet(token: token);
                      final available = double.parse(wallet['available_balance'].toString());

                      if (available < amount + fee) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Insufficient balance. You need at least ${(amount + fee).toStringAsFixed(2)} FARM to create this escrow (including ${fee.toStringAsFixed(2)} FARM fee).'),
                          ),
                        );
                        return;
                      }

                      // Create escrow (backend handles fee deduction)
                      await EscrowApiService.createEscrow(
                        token: token,
                        sellerIdentifier: sellerController.text.trim(),
                        amount: amount,
                        title: titleController.text.trim(),
                        description: descriptionController.text.trim(),
                        pin: pinController.text.trim(),
                      );

                      if (mounted) {
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Escrow created successfully. Fee deducted and credited to platform.',
                            ),
                          ),
                        );

                        fetchEscrows();
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$e'),
                        ),
                      );
                    }
                  },
                  child: Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  List<EscrowModel> get filteredEscrows {
    if (selectedFilter == 'all') {
      return escrows;
    }

    return escrows
        .where((e) => e.status == selectedFilter)
        .toList();
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget buildFilterButton(
    String label,
    String value,
  ) {
    final isSelected = selectedFilter == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });

        fetchEscrows();
      },
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primaryText
              : FlutterFlowTheme.of(context)
                  .secondaryBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? FlutterFlowTheme.of(context)
                    .primaryBackground
                : FlutterFlowTheme.of(context).primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget buildEscrowCard(EscrowModel escrow) {
    final isPending = escrow.status == 'active';
    final currentUserId = context.read<FFAppState>().userId;
    final role = escrow.getRoleForUser(currentUserId);
    final counterpartyName = escrow.getCounterpartyDisplayName(currentUserId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          EscrowItemWidget(
            amount: escrow.amount.toStringAsFixed(2),
            date: formatDate(escrow.createdAt),
            is_pending: isPending,
            role: role,
            status:
                escrow.status[0].toUpperCase() +
                    escrow.status.substring(1),
            username: counterpartyName,
          ),

          if (isPending)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => releaseEscrow(escrow.id),
                      child: const Text('Release Funds'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => disputeEscrow(escrow.id),
                      child: const Text('Dispute'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
            FlutterFlowTheme.of(context).primaryBackground,

        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: showCreateEscrowDialog,
          backgroundColor:
              FlutterFlowTheme.of(context).primaryText,
          label: Text(
            'Create Escrow',
            style: TextStyle(
              color:
                  FlutterFlowTheme.of(context)
                      .primaryBackground,
            ),
          ),
          icon: Icon(
            Icons.add,
            color:
                FlutterFlowTheme.of(context)
                    .primaryBackground,
          ),
        ),

        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    FlutterFlowIconButton(
                      borderRadius: 8,
                      buttonSize: 40,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color:
                            FlutterFlowTheme.of(context)
                                .primaryText,
                      ),
                      onPressed: () {
                        context.goNamed('Dashboard');
                      },
                    ),

                    Text(
                      'Escrow Hub',
                      style:
                          FlutterFlowTheme.of(context)
                              .titleLarge
                              .override(
                                font:
                                    GoogleFonts.plusJakartaSans(
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                    ),

                    FlutterFlowIconButton(
                      borderRadius: 8,
                      buttonSize: 40,
                      icon: Icon(
                        Icons.refresh,
                        color:
                            FlutterFlowTheme.of(context)
                                .primaryText,
                      ),
                      onPressed: fetchEscrows,
                    ),
                  ],
                ),
              ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: fetchEscrows,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color:
                                FlutterFlowTheme.of(context)
                                    .primaryText,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Escrow Protection',
                                style: TextStyle(
                                  color:
                                      FlutterFlowTheme.of(
                                              context)
                                          .background70,
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                'Safe & Secure Growth',
                                style:
                                    FlutterFlowTheme.of(
                                            context)
                                        .headlineMedium
                                        .override(
                                          font:
                                              GoogleFonts.plusJakartaSans(
                                            fontWeight:
                                                FontWeight
                                                    .bold,
                                          ),
                                          color:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .primaryBackground,
                                        ),
                              ),

                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          'Active',
                                          style: TextStyle(
                                            color:
                                                FlutterFlowTheme.of(
                                                        context)
                                                    .background50,
                                          ),
                                        ),

                                        Text(
                                          '$activeCount',
                                          style:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .titleLarge
                                                  .override(
                                                    color:
                                                        FlutterFlowTheme.of(context).primaryBackground,
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          'Protected',
                                          style: TextStyle(
                                            color:
                                                FlutterFlowTheme.of(
                                                        context)
                                                    .background50,
                                          ),
                                        ),

                                        Text(
                                          '${protectedAmount.toStringAsFixed(2)} FARM',
                                          style:
                                              FlutterFlowTheme.of(
                                                      context)
                                                  .titleLarge
                                                  .override(
                                                    color:
                                                        FlutterFlowTheme.of(context).primaryBackground,
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              buildFilterButton(
                                'All',
                                'all',
                              ),

                              const SizedBox(width: 12),

                              buildFilterButton(
                                'Active',
                                'active',
                              ),

                              const SizedBox(width: 12),

                              buildFilterButton(
                                'Completed',
                                'completed',
                              ),

                              const SizedBox(width: 12),

                              buildFilterButton(
                                'Disputed',
                                'disputed',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        if (isLoading)
                          Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        else if (filteredEscrows.isEmpty)
                          Container(
                            padding:
                                const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: Text(
                              'No escrows found',
                            ),
                          )
                        else
                          Column(
                            children:
                                filteredEscrows
                                    .map(
                                      (escrow) =>
                                          buildEscrowCard(
                                        escrow,
                                      ),
                                    )
                                    .toList(),
                          ),
                      ],
                    ),
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
