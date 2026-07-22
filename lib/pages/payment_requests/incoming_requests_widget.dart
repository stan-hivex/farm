import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/payment_request_api_service.dart';

class IncomingRequestsWidget extends StatefulWidget {
  const IncomingRequestsWidget({super.key});

  static const routeName = 'IncomingRequests';

  @override
  State<IncomingRequestsWidget> createState() => _IncomingRequestsWidgetState();
}

class _IncomingRequestsWidgetState extends State<IncomingRequestsWidget> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = PaymentRequestApiService.getPendingRequests(token: FFAppState().accessToken);
  }

  Future<void> _pay(String requestId) async {
    final pinCtrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter PIN to confirm'),
          const SizedBox(height: 8),
          TextField(controller: pinCtrl, keyboardType: TextInputType.number, obscureText: true, decoration: const InputDecoration(labelText: 'PIN')),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')))])
        ]),
      );
    });

    if (ok != true) return;

    try {
      final res = await PaymentRequestApiService.acceptPaymentRequest(token: FFAppState().accessToken, requestId: requestId, pin: pinCtrl.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Paid')));
      setState(() => _load());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  Future<void> _decline(String requestId) async {
    try {
      final res = await PaymentRequestApiService.rejectPaymentRequest(token: FFAppState().accessToken, requestId: requestId);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Declined')));
      setState(() => _load());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Requests')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No pending requests'));
          return RefreshIndicator(
            onRefresh: () async => setState(() => _load()),
            child: ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final r = list[i] as Map<String, dynamic>;
                final requester = r['users_requester'] ?? {};
                return ListTile(
                  title: Text(requester['username'] ?? 'User'),
                  subtitle: Text('${(r['amount'] as num).toString()} FARM'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    TextButton(onPressed: () => _decline(r['id']), child: const Text('Decline')),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: () => _pay(r['id']), child: const Text('Pay')),
                  ]),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
