import 'package:flutter/material.dart';
import '/app_state.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/services/api_service.dart';
import '/services/app_session_manager.dart';
import '/services/transaction_authorization_service.dart';

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
    _future = ApiService.request(method: 'GET', path: '/payment-requests/pending').then((r) => List<dynamic>.from(r['data'] ?? r));
  }

  Future<void> _pay(String requestId) async {
    final pinCtrl = TextEditingController();
    final authResult = await TransactionAuthorizationService().authorizeTransaction(
      localizedReason: 'Confirm payment',
    ).then((r) => r.toTransactionAuthenticationResult());

    String? pin;
    if (authResult.biometricUsed != true) {
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

      if (ok != true) {
        pinCtrl.dispose();
        return;
      }

      pin = pinCtrl.text.trim();
      pinCtrl.dispose();
      if (pin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter your transaction PIN')));
        return;
      }
    }

    try {
        final res = await ApiService.request(
          method: 'POST',
          path: '/payment-requests/accept',
          body: {
            'request_id': requestId,
            if (authResult.biometricUsed != true) 'pin': pin,
            if (authResult.biometricUsed == true) 'biometric_auth': true,
            if (authResult.deviceFingerprint != null) 'device_fingerprint': authResult.deviceFingerprint,
          },
        );
      await AppSessionManager().syncNow(
        profileTimeoutSeconds: 5,
        walletTimeoutSeconds: 5,
        transactionsTimeoutSeconds: 5,
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Paid')));
      setState(() => _load());
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString().replaceFirst('Exception: ', '')}')));
    }
  }

  Future<void> _decline(String requestId) async {
    try {
      final res = await ApiService.request(method: 'POST', path: '/payment-requests/$requestId/reject');
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
