import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/admin_api_service.dart';

class KycManagementPage extends StatefulWidget {
  const KycManagementPage({super.key});

  @override
  State<KycManagementPage> createState() => _KycManagementPageState();
}

class _KycManagementPageState extends State<KycManagementPage> {
  List<dynamic> _queue = [];
  bool _loading = true;
  String? _error;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await AdminApiService.getKycQueue(page: _page);
      setState(() => _queue = res['data'] ?? []);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _review(String docId, String status, {String? reason}) async {
    try {
      await AdminApiService.reviewKyc(docId, status, rejectionReason: reason);
      _snack(status == 'verified' ? 'KYC Approved ✓' : 'KYC Rejected', 
             status == 'verified' ? Colors.green : Colors.red);
      _load();
    } catch (e) {
      _snack(e.toString(), Colors.red);
    }
  }

  void _showRejectDialog(String docId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject KYC', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              hintText: 'Reason for rejection...', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _review(docId, 'rejected', reason: ctrl.text.trim());
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: c,
          behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(_error!), ElevatedButton(onPressed: _load, child: const Text('Retry'))
        ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: _queue.isEmpty
          ? const Center(child: Text('No pending KYC applications'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _queue.length,
              itemBuilder: (_, i) => _kycCard(_queue[i]),
            ),
    );
  }

  Widget _kycCard(Map<String, dynamic> doc) {
    final user = doc['users_kyc_documents_user_idTousers'] as Map? ?? {};
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.15),
              radius: 22,
              child: const Icon(Icons.person_rounded, color: Colors.orange),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(user['phone'] ?? '-',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
              Text('Doc: ${doc['document_type'] ?? 'N/A'}',
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: Text('PENDING',
                  style: GoogleFonts.plusJakartaSans(
                      color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
        if (doc['document_number'] != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('ID: ${doc['document_number']}',
                style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)),
          ),
        // Document images preview row
        if (doc['front_image'] != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Expanded(child: _docImg('Front ID', doc['front_image'])),
              if (doc['back_image'] != null) ...[
                const SizedBox(width: 8),
                Expanded(child: _docImg('Back ID', doc['back_image'])),
              ],
              if (doc['selfie_image'] != null) ...[
                const SizedBox(width: 8),
                Expanded(child: _docImg('Selfie', doc['selfie_image'])),
              ],
            ]),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.close_rounded, color: Colors.red, size: 16),
                label: Text('Reject', style: GoogleFonts.plusJakartaSans(color: Colors.red)),
                onPressed: () => _showRejectDialog(doc['id']),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text('Approve', style: GoogleFonts.plusJakartaSans()),
                onPressed: () => _review(doc['id'], 'verified'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _docImg(String label, String? url) => Column(children: [
    Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        image: url != null
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url == null
          ? const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))
          : null,
    ),
    const SizedBox(height: 4),
    Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.grey)),
  ]);
}