import '/backend/api_requests/escrow_api_service.dart';
import '/backend/models/escrow_model.dart';
import '/components/escrow_item/escrow_item_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/app_state.dart';

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
  Future<void> releaseEscrow(String escrowId) async {
    try {
      final token = context.read<FFAppState>().accessToken;

      await EscrowApiService.releaseEscrow(
        token: token,
        escrowId: escrowId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funds released successfully'),
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
          title: const Text('Raise Dispute'),
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('Submit'),
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
        return AlertDialog(
          title: const Text('Create Escrow'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: sellerController,
                  decoration: const InputDecoration(
                    labelText: 'Seller Username / Phone',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
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
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final token =
                      context.read<FFAppState>().accessToken;

                  await EscrowApiService.createEscrow(
                    token: token,
                    sellerIdentifier: sellerController.text.trim(),
                    amount:
                        double.parse(amountController.text.trim()),
                    title: titleController.text.trim(),
                    description:
                        descriptionController.text.trim(),
                    pin: pinController.text.trim(),
                  );

                  if (mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Escrow created successfully',
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
              child: const Text('Create'),
            ),
          ],
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          EscrowItemWidget(
            amount: escrow.amount.toStringAsFixed(2),
            date: formatDate(escrow.createdAt),
            is_pending: isPending,
            role: 'Buyer',
            status:
                escrow.status[0].toUpperCase() +
                    escrow.status.substring(1),
            username:
                '@${escrow.sellerUsername ?? 'seller'}',
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
                      onPressed: () {
                        releaseEscrow(escrow.id);
                      },
                      child: const Text(
                        'Release Funds',
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        disputeEscrow(escrow.id);
                      },
                      child: const Text(
                        'Dispute',
                      ),
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
                        Navigator.pop(context);
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
                          const Center(
                            child:
                                CircularProgressIndicator(),
                          )
                        else if (filteredEscrows.isEmpty)
                          Container(
                            padding:
                                const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: const Text(
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