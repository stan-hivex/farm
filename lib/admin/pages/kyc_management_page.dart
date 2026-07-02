import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../services/admin_api_service.dart';

class KycManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const KycManagementPage({super.key, this.onGoBack});

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
    setState(() {
      _loading = true;
      _error = null;
    });
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
          status == 'verified' ? context.successColor : context.errorColor);
      _load();
    } catch (e) {
      _snack(e.toString(), context.errorColor);
    }
  }

  void _showRejectDialog(String docId) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reject KYC',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              hintText: 'Reason for rejection...',
              border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: context.errorColor),
            onPressed: () {
              Navigator.pop(context);
              _review(docId, 'rejected', reason: ctrl.text.trim());
            },
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color c) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: c,
          behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error!),
        ElevatedButton(onPressed: _load, child: Text('Retry'))
      ]));

    return RefreshIndicator(
      onRefresh: _load,
      child: _queue.isEmpty
          ? Center(child: Text('No pending KYC applications'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _queue.length,
              itemBuilder: (_, i) => _kycCard(_queue[i]),
            ),
    );
  }

  Widget _kycCard(Map<String, dynamic> doc) {
    final user = doc['users_kyc_documents_user_idTousers'] as Map? ?? {};
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showKycDetails(doc),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: context.onSurface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              const BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04), blurRadius: 8)
            ],
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: const Color.fromRGBO(255, 165, 0, 0.15),
                  radius: 22,
                  child: Icon(Icons.person_rounded, color: context.warningColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}',
                          style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(user['phone'] ?? '-',
                          style: GoogleFonts.plusJakartaSans(
                              color: context.textSecondary, fontSize: 12)),
                      Text('Doc: ${doc['document_type'] ?? 'N/A'}',
                          style: GoogleFonts.plusJakartaSans(
                              color: context.textSecondary, fontSize: 12)),
                    ])),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 165, 0, 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('PENDING',
                      style: GoogleFonts.plusJakartaSans(
                          color: context.warningColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _showKycDetails(doc),
                  icon: Icon(Icons.info_outline, size: 16),
                  label: Text('View details'),
                ),
              ),
            ),
            if (doc['document_number'] != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text('ID: ${doc['document_number']}',
                    style: GoogleFonts.plusJakartaSans(
                        color: context.textSecondary, fontSize: 12)),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((doc['first_name'] ?? doc['last_name']) != null)
                      _detailRow(
                          'Name',
                          '${doc['first_name'] ?? ''} ${doc['last_name'] ?? ''}'
                              .trim()),
                    if (doc['date_of_birth'] != null)
                      _detailRow(
                          'Date of Birth', doc['date_of_birth']?.toString()),
                    if (doc['gender'] != null)
                      _detailRow('Gender', doc['gender']?.toString()),
                    if (doc['nationality'] != null)
                      _detailRow('Nationality', doc['nationality']?.toString()),
                    if (doc['email'] != null)
                      _detailRow('Email', doc['email']?.toString()),
                    if (doc['phone'] != null)
                      _detailRow('Phone', doc['phone']?.toString()),
                    if (doc['country'] != null ||
                        doc['county'] != null ||
                        doc['city'] != null ||
                        doc['physical_address'] != null ||
                        doc['postal_code'] != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 12, bottom: 6),
                        child: Text('Address',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    if (doc['country'] != null)
                      _detailRow('Country', doc['country']?.toString()),
                    if (doc['county'] != null)
                      _detailRow('State / County', doc['county']?.toString()),
                    if (doc['city'] != null)
                      _detailRow('City', doc['city']?.toString()),
                    if (doc['physical_address'] != null)
                      _detailRow(
                          'Address', doc['physical_address']?.toString()),
                    if (doc['postal_code'] != null)
                      _detailRow('Postal Code', doc['postal_code']?.toString()),
                  ]),
            ),
            // Document images preview row
            if (doc['front_image'] != null)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        side: BorderSide(color: context.errorColor),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    icon: Icon(Icons.close_rounded,
                        color: context.errorColor, size: 16),
                    label: Text('Reject',
                        style: GoogleFonts.plusJakartaSans(color: context.errorColor)),
                    onPressed: () => _showRejectDialog(doc['id']),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.successColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    icon: Icon(Icons.check_rounded, size: 16),
                    label:
                        Text('Approve', style: GoogleFonts.plusJakartaSans()),
                    onPressed: () => _review(doc['id'], 'verified'),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showKycDetails(Map<String, dynamic> doc) {
    final user = doc['users_kyc_documents_user_idTousers'] as Map? ?? {};
    final username = user['username']?.toString();
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          title: Text('KYC Application',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _detailRow('Username', username != null ? '@$username' : null),
              _detailRow(
                  'Name',
                  '${doc['first_name'] ?? user['first_name'] ?? ''} ${doc['last_name'] ?? user['last_name'] ?? ''}'
                      .trim()),
              _detailRow('Email',
                  doc['email']?.toString() ?? user['email']?.toString()),
              _detailRow('Phone',
                  doc['phone']?.toString() ?? user['phone']?.toString()),
              const Divider(height: 24),
              _detailRow('Document type', doc['document_type']?.toString()),
              _detailRow('Document number', doc['document_number']?.toString()),
              _detailRow('Date of birth', doc['date_of_birth']?.toString()),
              _detailRow('Gender', doc['gender']?.toString()),
              _detailRow('Nationality', doc['nationality']?.toString()),
              const Divider(height: 24),
              _detailRow('Country', doc['country']?.toString()),
              _detailRow('State / County', doc['county']?.toString()),
              _detailRow('City', doc['city']?.toString()),
              _detailRow('Address', doc['physical_address']?.toString()),
              _detailRow('Postal code', doc['postal_code']?.toString()),
              if (doc['front_image'] != null ||
                  doc['back_image'] != null ||
                  doc['selfie_image'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Document images',
                            style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 12),
                        Row(children: [
                          if (doc['front_image'] != null)
                            Expanded(
                                child: _docImg('Front', doc['front_image'])),
                          if (doc['back_image'] != null) ...[
                            const SizedBox(width: 8),
                            Expanded(child: _docImg('Back', doc['back_image'])),
                          ],
                          if (doc['selfie_image'] != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                                child: _docImg('Selfie', doc['selfie_image'])),
                          ],
                        ]),
                      ]),
                ),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close')),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showRejectDialog(doc['id']);
              },
              child: Text('Reject', style: TextStyle(color: context.errorColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _review(doc['id'], 'verified');
              },
              style: ElevatedButton.styleFrom(backgroundColor: context.successColor),
              child: Text('Approve'),
            ),
          ],
        );
      },
    );
  }

  Widget _docImg(String label, String? url) => Column(children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(10),
            image: url != null
                ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                : null,
          ),
          child: url == null
              ? Center(
                  child: Icon(Icons.image_not_supported, color: context.textSecondary))
              : null,
        ),
        const SizedBox(height: 4),
        Text(label,
            style:
                GoogleFonts.plusJakartaSans(fontSize: 10, color: context.textSecondary)),
      ]);

  Widget _detailRow(String label, String? value) {
    if (value == null || value.toString().trim().isEmpty)
      return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 110,
          child: Text('$label:',
              style: GoogleFonts.plusJakartaSans(
                  color: context.onBackground.withOpacity(0.87),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value.toString(),
              style: GoogleFonts.plusJakartaSans(
                  color: context.textSecondary, fontSize: 12)),
        ),
      ]),
    );
  }
}
