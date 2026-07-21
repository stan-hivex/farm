import '/backend/api_requests/user_api_service.dart';
import '/backend/api_requests/wallet_api_service.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/components/kyc_required_widget.dart';
import '/utils/send_amount_cooldown.dart';
import '/utils/transaction_peer_resolver.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

enum TransferRequestCardState {
  pending,
  expired,
  failed,
  successful,
}

DateTime? _parseRequestDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

TransferRequestCardState getTransferRequestCardState(
  dynamic req, {
  DateTime? now,
}) {
  final status = (req['status'] ?? '').toString().trim().toLowerCase();
  if (status == 'success' ||
      status == 'successful' ||
      status == 'completed' ||
      status == 'accepted' ||
      status == 'approved') {
    return TransferRequestCardState.successful;
  }
  if (status == 'failed' ||
      status == 'rejected' ||
      status == 'declined' ||
      status == 'expired') {
    return TransferRequestCardState.failed;
  }

  final referenceTime = now ?? DateTime.now();
  final expiresAt = _parseRequestDate(req['expires_at']);
  if (expiresAt != null && referenceTime.isAfter(expiresAt)) {
    return TransferRequestCardState.expired;
  }

  final createdAt = _parseRequestDate(req['created_at']);
  if (createdAt != null && referenceTime.difference(createdAt).inHours >= 24) {
    return TransferRequestCardState.expired;
  }

  return TransferRequestCardState.pending;
}

bool shouldHideTransferRequest(dynamic req, {DateTime? now}) {
  final state = getTransferRequestCardState(req, now: now);
  if (state == TransferRequestCardState.successful) {
    return false;
  }

  final referenceTime = now ?? DateTime.now();
  final createdAt = _parseRequestDate(req['created_at']);
  if (createdAt != null && referenceTime.difference(createdAt).inHours >= 24) {
    return true;
  }

  final expiresAt = _parseRequestDate(req['expires_at']);
  if (expiresAt != null) {
    return referenceTime.isAfter(expiresAt);
  }

  return false;
}

class SendReceiveWidget extends StatefulWidget {
  const SendReceiveWidget({super.key});

  static String routeName = 'SendReceive';
  static String routePath = '/sendReceive';

  @override
  State<SendReceiveWidget> createState() => _SendReceiveWidgetState();
}

class _SendReceiveWidgetState extends State<SendReceiveWidget>
    with TickerProviderStateMixin {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final recipientController = TextEditingController();

  final amountController = TextEditingController();

  final pinController = TextEditingController();

  final descriptionController = TextEditingController();

  bool isLoading = true;
  bool isSending = false;

  double? _lastSentAmount;
  DateTime? _lastSentAt;

  bool showReceive = false;
  bool isRequesting = false;
  List<dynamic> pendingRequests = [];
  List<dynamic> myTransferRequests = [];

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
    fetchPendingRequests();
    fetchMyTransferRequests();
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

  bool get isKycApproved {
    final status = FFAppState().kycStatus.trim().toLowerCase();
    return ['verified', 'approved', 'complete', 'success'].contains(status);
  }

  Future<void> fetchWallet() async {
    try {
      final token = context.read<FFAppState>().accessToken;

      final wallet = await WalletApiService.getWallet(
        token: token,
      );

      final txs = await WalletApiService.getTransactions(
        token: token,
      );

      final walletData = Map<String, dynamic>.from(wallet);

      setState(() {
        balance = _parseNumericValue(
          walletData['available_balance'] ??
              walletData['balance'] ??
              walletData['wallet_balance'],
        );

        transactions = List<dynamic>.from(txs);

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    }
  }

  Future<void> searchUsers(
    String value,
  ) async {
    if (!UserApiService.shouldSearchSuggestions(value)) {
      setState(() {
        userSuggestions = [];
      });

      return;
    }

    try {
      final token = context.read<FFAppState>().accessToken;

      final users = await UserApiService.searchUsers(
        token: token,
        query: value.trim(),
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

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final raw = value.toString().trim();
    if (raw.isEmpty) return 0.0;
    return double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
  }

  double _parseNumericValue(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) return fallback;
      return double.tryParse(normalized.replaceAll(',', '.')) ?? fallback;
    }
    return fallback;
  }

  String _parseStringValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Future<void> sendFunds() async {
    final amount = enteredAmount;

    if (recipientController.text.isEmpty ||
        amountController.text.isEmpty ||
        pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fill all required fields. Use recipient username or phone number.',
          ),
        ),
      );

      return;
    }

    if (SendAmountCooldown.shouldBlockDuplicateSend(
      amount: amount,
      lastSentAmount: _lastSentAmount,
      lastSentAt: _lastSentAt,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can only resend the same amount after 1 minute.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      setState(() {
        isSending = true;
      });

      final token = context.read<FFAppState>().accessToken;

      amountController.clear();

      await WalletApiService.sendFunds(
        token: token,
        recipient: recipientController.text.trim(),
        amount: amount,
        pin: pinController.text.trim(),
        description: descriptionController.text.trim(),
      );

      _lastSentAmount = amount;
      _lastSentAt = DateTime.now();

      successController.forward();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              content: SizedBox(
                height: 220,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(
                        begin: 0,
                        end: 1,
                      ).animate(
                        CurvedAnimation(
                          parent: successController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${amount.toStringAsFixed(2)} FARM sent successfully',
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
      ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> requestFunds() async {
    if (recipientController.text.isEmpty || amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both recipient and amount'),
        ),
      );
      return;
    }

    try {
      setState(() => isRequesting = true);
      final token = context.read<FFAppState>().accessToken;
      final amount = enteredAmount;

      await WalletApiService.requestFunds(
        token: token,
        senderIdentifier: recipientController.text.trim(),
        amount: amount,
        description: descriptionController.text.trim(),
      );

      successController.forward();
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: SizedBox(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                          parent: successController, curve: Curves.elasticOut),
                    ),
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                          color: Colors.blue, shape: BoxShape.circle),
                      child: const Icon(Icons.check,
                          color: Colors.white, size: 50),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Request Sent',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text('${amount.toStringAsFixed(2)} FARM requested',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
        recipientController.clear();
        amountController.clear();
        descriptionController.clear();
        await fetchPendingRequests();
        await fetchMyTransferRequests();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => isRequesting = false);
    }
  }

  Future<void> fetchPendingRequests() async {
    try {
      final String token = context.read<FFAppState>().accessToken;
      final requests = await WalletApiService.getPendingRequests(token: token);
      if (mounted) {
        setState(() {
          pendingRequests =
              requests.where((req) => !shouldHideTransferRequest(req)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> fetchMyTransferRequests() async {
    try {
      final String token = context.read<FFAppState>().accessToken;
      final requests = await WalletApiService.getTransferRequestHistory(
        token: token,
      );
      if (mounted) {
        setState(() {
          myTransferRequests =
              requests.where((req) => !shouldHideTransferRequest(req)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  void _prepareSendFlowFromRequest(dynamic req, {required bool incoming}) {
    final person = incoming ? req['users_requester'] : req['users_sender'];
    final username = _parseStringValue(person?['username']);
    final phoneNumber = _parseStringValue(person?['phone_number']);
    final identifier = username.isNotEmpty ? username : phoneNumber;
    final amount = _parseAmount(req['amount']).toStringAsFixed(2);
    final description = _parseStringValue(req['description']);

    setState(() {
      showReceive = false;
      recipientController.text = identifier;
      amountController.text = amount;
      descriptionController.text = description;
      pinController.clear();
      userSuggestions = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Send form updated for ${identifier.isNotEmpty ? identifier : 'the selected request'}',
          ),
        ),
      );
    }
  }

  Future<void> acceptTransferRequest(String requestId, String pin) async {
    try {
      final token = context.read<FFAppState>().accessToken;
      await WalletApiService.acceptTransferRequest(
          token: token, requestId: requestId, pin: pin);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Transfer completed successfully'),
              backgroundColor: Colors.green),
        );
      }
      fetchWallet();
      await fetchPendingRequests();
      await fetchMyTransferRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> rejectTransferRequest(String requestId) async {
    try {
      final token = context.read<FFAppState>().accessToken;
      await WalletApiService.rejectTransferRequest(
          token: token, requestId: requestId);
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Request rejected')));
      await fetchPendingRequests();
      await fetchMyTransferRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('$e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> cancelTransferRequest(String requestId) async {
    try {
      final token = context.read<FFAppState>().accessToken;
      await WalletApiService.cancelTransferRequest(
        token: token,
        requestId: requestId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
      }
      await fetchPendingRequests();
      await fetchMyTransferRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  void _showPinConfirmDialog(
      String requestId, String requesterUsername, double amount) {
    final tempPin = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Confirm Transfer'),
        content: SizedBox(
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Send ${amount.toStringAsFixed(2)} FARM to @$requesterUsername?',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: tempPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter PIN',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              rejectTransferRequest(requestId);
            },
            child: const Text('Reject'),
          ),
          ElevatedButton(
            onPressed: () {
              if (tempPin.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter PIN')));
                return;
              }
              Navigator.pop(context);
              acceptTransferRequest(requestId, tempPin.text);
              tempPin.dispose();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(
    String title,
    String value,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: FlutterFlowTheme.of(context).secondaryText,
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

  String _formatTransactionDate(dynamic value) {
    if (value == null) return 'Date unavailable';
    final parsed =
        value is DateTime ? value : DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return '${parsed.toLocal().day}/${parsed.toLocal().month}/${parsed.toLocal().year} ${parsed.toLocal().hour.toString().padLeft(2, '0')}:${parsed.toLocal().minute.toString().padLeft(2, '0')}';
  }

  String _resolveTransactionPeer(dynamic tx, {required bool outgoing}) {
    return resolveTransactionPeer(tx, outgoing: outgoing);
  }

  Widget buildTransactionCard(
    dynamic tx,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final outgoing = tx['is_outgoing'] == true;
    final amount = _parseNumericValue(tx['amount']);
    final reference =
        _parseStringValue(tx['transaction_reference'], fallback: 'Transaction');
    final peer = _resolveTransactionPeer(tx, outgoing: outgoing);
    final dateText = _formatTransactionDate(
      tx['created_at'] ?? tx['createdAt'] ?? tx['timestamp'] ?? tx['date'],
    );

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: FlutterFlowTheme.of(context).secondaryBackground,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outgoing ? Colors.red.shade100 : Colors.green.shade100,
            ),
            child: Icon(
              outgoing ? Icons.arrow_upward : Icons.arrow_downward,
              color: outgoing ? Colors.red : Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outgoing ? 'Sent FARM' : 'Received FARM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  outgoing ? 'To $peer' : 'From $peer',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$reference • $dateText',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} FARM',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: outgoing ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRequestCard(dynamic req) {
    final theme = FlutterFlowTheme.of(context);
    final requester = req['users_requester'];
    final requesterName = requester != null
        ? '${requester['first_name']} ${requester['last_name']}'
        : 'Requester';
    final requesterUsername =
        requester != null ? requester['username'] : 'unknown';
    final amount = _parseAmount(req['amount']);

    return GestureDetector(
      onTap: () => _showRequestDetailSheet(req, incoming: true),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: FlutterFlowTheme.of(context).secondaryBackground,
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.shade100,
                  ),
                  child: Icon(
                    Icons.call_received,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$requesterName requested',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$requesterUsername',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(2)} FARM',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _showPinConfirmDialog(
                        req['id'],
                        requesterUsername,
                        amount.toDouble(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text('Send'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {
                    rejectTransferRequest(req['id']);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOutgoingRequestCard(dynamic req) {
    final theme = FlutterFlowTheme.of(context);
    final recipient = req['users_sender'];
    final recipientName = recipient != null
        ? '${recipient['first_name']} ${recipient['last_name']}'
        : 'Recipient';
    final recipientUsername =
        recipient != null ? recipient['username'] : 'unknown';
    final amount = _parseAmount(req['amount']);
    final state = getTransferRequestCardState(req);
    final isPending = state == TransferRequestCardState.pending;
    final isActionable = state == TransferRequestCardState.expired ||
        state == TransferRequestCardState.failed;
    final isSuccessful = state == TransferRequestCardState.successful;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = isSuccessful
        ? (isDark ? Colors.green.shade400 : Colors.green.shade700)
        : (isActionable
            ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
            : (isDark ? Colors.blue.shade400 : Colors.blue.shade700));
    final statusLabel = isSuccessful
        ? 'SUCCESSFUL'
        : (isActionable
            ? (state == TransferRequestCardState.expired ? 'EXPIRED' : 'FAILED')
            : 'PENDING');

    return GestureDetector(
      onTap: () => _showRequestDetailSheet(req, incoming: false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: FlutterFlowTheme.of(context).secondaryBackground,
          border: Border.all(color: statusColor.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    Icons.call_made,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You requested',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@$recipientUsername',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipientName,
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(2)} FARM',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (isActionable)
                          ElevatedButton(
                            onPressed: () => _prepareSendFlowFromRequest(
                              req,
                              incoming: false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: statusColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text('Accept'),
                          ),
                        if (isPending || isActionable)
                          OutlinedButton(
                            onPressed: () async {
                              if (isActionable) {
                                await cancelTransferRequest(req['id']);
                              } else {
                                await cancelTransferRequest(req['id']);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: statusColor,
                              side: BorderSide(color: statusColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(isActionable ? 'Cancel' : 'Cancel'),
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
    );
  }

  String _formatRequestDate(dynamic value) {
    if (value == null) return 'Not available';
    final parsed =
        value is DateTime ? value : DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();
    return '${parsed.toLocal().day}/${parsed.toLocal().month}/${parsed.toLocal().year} ${parsed.toLocal().hour.toString().padLeft(2, '0')}:${parsed.toLocal().minute.toString().padLeft(2, '0')}';
  }

  void _showRequestDetailSheet(dynamic req, {required bool incoming}) {
    final theme = FlutterFlowTheme.of(context);
    final person = incoming ? req['users_requester'] : req['users_sender'];
    final personName = person != null
        ? '${person['first_name']} ${person['last_name']}'
        : (incoming ? 'Requester' : 'Recipient');
    final personUsername = person != null ? person['username'] : 'unknown';
    final amount = _parseAmount(req['amount']);
    final status = (req['status'] ?? 'pending').toString();
    final description = req['description']?.toString() ?? '';
    final expiresAt = _formatRequestDate(req['expires_at']);
    final createdAt = _formatRequestDate(req['created_at']);
    final isPending = status.toLowerCase() == 'pending';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: incoming
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                    ),
                    child: Icon(
                      incoming ? Icons.call_received : Icons.call_made,
                      color: incoming
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incoming ? '$personName requested' : 'You requested',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@$personUsername',
                          style: TextStyle(color: theme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    '${amount.toStringAsFixed(2)} FARM',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (description.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(color: theme.secondaryText),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailRow('Created', createdAt),
              const SizedBox(height: 8),
              _buildDetailRow('Expires', expiresAt),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (incoming)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showPinConfirmDialog(
                              req['id'], personUsername, amount);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Approve'),
                      ),
                    ),
                  if (incoming) const SizedBox(width: 12),
                  if (incoming)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          rejectTransferRequest(req['id']);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                  if (!incoming && isPending)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          cancelTransferRequest(req['id']);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text('Cancel request'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: FlutterFlowTheme.of(context).secondaryText,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: FlutterFlowTheme.of(context).primaryText),
          ),
        ),
      ],
    );
  }

  Widget buildSuggestionCard(
    dynamic user,
  ) {
    final username = _parseStringValue(user['username'], fallback: 'user');
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return ListTile(
      leading: CircleAvatar(
        child: Text(initial),
      ),
      title: Text('@$username'),
      onTap: () {
        recipientController.text = username;

        setState(() {
          userSuggestions = [];
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedTabBackground =
        isDark ? const Color(0xFF1F1F1F) : Colors.black;
    final selectedTabTextColor = Colors.white;
    final unselectedTabBackground = theme.primaryBackground;
    final unselectedTabTextColor = theme.primaryText;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        body: SafeArea(
          child: !isKycApproved
              ? const KycRequiredWidget(feature: 'send & receive')
              : isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(
                            24,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              FlutterFlowIconButton(
                                borderRadius: 8,
                                buttonSize: 40,
                                icon: Icon(
                                  Icons.arrow_back_rounded,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                                onPressed: () {
                                  context.goNamed('Dashboard');
                                },
                              ),
                              Text(
                                'Send & Receive',
                                style: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                              ),
                              FlutterFlowIconButton(
                                borderRadius: 8,
                                buttonSize: 40,
                                icon: Icon(
                                  Icons.refresh,
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                ),
                                onPressed: fetchWallet,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(
                              24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(28),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      28,
                                    ),
                                    color: isDark ? Colors.black : Colors.white,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black12,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(20),
                                        blurRadius: 16,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Available Balance',
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Text(
                                        '${balance.toStringAsFixed(2)} FARM',
                                        style: FlutterFlowTheme.of(context)
                                            .headlineLarge
                                            .override(
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
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
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(
                                            () {
                                              showReceive = false;
                                            },
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            18,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            color: !showReceive
                                                ? unselectedTabBackground
                                                : selectedTabBackground,
                                            border: Border.all(
                                              color: theme.secondaryText
                                                  .withAlpha(51),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(13),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Send',
                                              style: TextStyle(
                                                color: !showReceive
                                                    ? unselectedTabTextColor
                                                    : selectedTabTextColor,
                                                fontWeight: FontWeight.bold,
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
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(
                                            () {
                                              showReceive = true;
                                            },
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(
                                            18,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            color: showReceive
                                                ? unselectedTabBackground
                                                : selectedTabBackground,
                                            border: Border.all(
                                              color: theme.secondaryText
                                                  .withAlpha(51),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(13),
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Receive',
                                              style: TextStyle(
                                                color: showReceive
                                                    ? unselectedTabTextColor
                                                    : selectedTabTextColor,
                                                fontWeight: FontWeight.bold,
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
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      TextField(
                                        controller: recipientController,
                                        onChanged: searchUsers,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          hintText:
                                              'Recipient username or phone number',
                                          helperText:
                                              'You can send to either a username or phone number',
                                          helperStyle: TextStyle(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryText,
                                            fontSize: 12,
                                          ),
                                          prefixIcon: const Icon(
                                            Icons.person,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText
                                                      .withAlpha(61),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (userSuggestions.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                            border: Border.all(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText
                                                      .withAlpha(41),
                                            ),
                                          ),
                                          child: Column(
                                            children: userSuggestions
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
                                        controller: amountController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(
                                              r'[0-9.]',
                                            ),
                                          ),
                                        ],
                                        onChanged: (_) {
                                          setState(
                                            () {},
                                          );
                                        },
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          hintText: 'Amount',
                                          prefixText: 'FARM ',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
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
                                        controller: descriptionController,
                                        maxLines: 3,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          hintText: 'Description',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
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
                                        controller: pinController,
                                        obscureText: true,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          hintText: 'Enter PIN',
                                          prefixIcon: const Icon(
                                            Icons.lock,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            borderSide: BorderSide(
                                              color:
                                                  FlutterFlowTheme.of(context)
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
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                        ),
                                        child: Column(
                                          children: [
                                            buildInfoRow(
                                              'Amount',
                                              '${enteredAmount.toStringAsFixed(2)} FARM',
                                            ),
                                            const SizedBox(
                                              height: 12,
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
                                        child: ElevatedButton(
                                          onPressed:
                                              isSending ? null : sendFunds,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                selectedTabBackground,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                18,
                                              ),
                                            ),
                                          ),
                                          child: isSending
                                              ? const CircularProgressIndicator(
                                                  color: Colors.white,
                                                )
                                              : const Text(
                                                  'Send FARM',
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        28,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText
                                            .withAlpha(41),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(13),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Request FARM',
                                          style: FlutterFlowTheme.of(context)
                                              .headlineSmall
                                              .override(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                              ),
                                        ),
                                        const SizedBox(
                                          height: 20,
                                        ),
                                        TextField(
                                          controller: recipientController,
                                          onChanged: searchUsers,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            hintText:
                                                'Sender username or phone number',
                                            helperText:
                                                'Enter the user you are requesting from',
                                            helperStyle: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 12,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.person,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                18,
                                              ),
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText
                                                        .withAlpha(61),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (userSuggestions.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              top: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                18,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              border: Border.all(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText
                                                        .withAlpha(41),
                                              ),
                                            ),
                                            child: Column(
                                              children: userSuggestions
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
                                          controller: amountController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(
                                                r'[0-9.]',
                                              ),
                                            ),
                                          ],
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            hintText: 'Amount',
                                            prefixText: 'FARM ',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                18,
                                              ),
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                          controller: descriptionController,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            hintText: 'Description (optional)',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                18,
                                              ),
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText
                                                        .withAlpha(61),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 24,
                                        ),
                                        SizedBox(
                                          height: 58,
                                          child: ElevatedButton(
                                            onPressed: isRequesting
                                                ? null
                                                : requestFunds,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  selectedTabBackground,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  18,
                                                ),
                                              ),
                                            ),
                                            child: isRequesting
                                                ? const CircularProgressIndicator(
                                                    color: Colors.white,
                                                  )
                                                : const Text(
                                                    'Request FARM',
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(
                                  height: 36,
                                ),
                                if (pendingRequests.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pending Requests',
                                        style: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        children: pendingRequests
                                            .map(
                                              (
                                                req,
                                              ) =>
                                                  buildRequestCard(
                                                req,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                      const SizedBox(height: 36),
                                    ],
                                  ),
                                if (myTransferRequests.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your Requests',
                                        style: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        children: myTransferRequests
                                            .map(
                                              (req) =>
                                                  buildOutgoingRequestCard(req),
                                            )
                                            .toList(),
                                      ),
                                      const SizedBox(height: 36),
                                    ],
                                  ),
                                Text(
                                  'Recent Transactions',
                                  style: FlutterFlowTheme.of(context)
                                      .titleLarge
                                      .override(
                                        font: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                if (transactions.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(
                                        24,
                                      ),
                                      child: Text(
                                        'No transactions yet',
                                      ),
                                    ),
                                  )
                                else
                                  Column(
                                    children: transactions
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
