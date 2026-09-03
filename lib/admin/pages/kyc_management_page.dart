import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
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
  String _statusFilter = 'pending';

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
      final res = await AdminApiService.getKycQueue(page: _page, status: _statusFilter);
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
    if (_loading && _queue.isEmpty) return Center(child: CircularProgressIndicator());
    if (_error != null && _queue.isEmpty)
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error!),
        ElevatedButton(onPressed: _load, child: Text('Retry'))
      ]));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              for (final status in ['pending', 'rejected', 'verified'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: _statusFilter == status,
                    onSelected: (_) {
                      setState(() {
                        _statusFilter = status;
                        _page = 1;
                      });
                      _load();
                    },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _queue.isEmpty
          ? Center(child: Text('No pending KYC applications'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _queue.length,
              itemBuilder: (_, i) => _kycCard(_queue[i]),
            ),
          ),
        ),
      ],
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
                  child: Text((doc['status'] ?? _statusFilter).toString().toUpperCase(),
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
            if (_statusFilter == 'pending') Padding(
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
    // Fetch full doc from API to ensure we display all available fields and images
    showDialog(
      context: context,
      builder: (_) => FutureBuilder<Map<String, dynamic>>(
        future: AdminApiService.getKycDoc(doc['id']?.toString() ?? ''),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          if (snap.hasError) return AlertDialog(title: const Text('Error'), content: Text(snap.error.toString()), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))]);
          final d = (snap.data?['data'] ?? {}) as Map<String, dynamic>;
          final user = d['users_kyc_documents_user_idTousers'] as Map? ?? {};
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            title: Text('KYC Application', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Prominent uploader info
                  Row(children: [
                    CircleAvatar(radius: 22, backgroundColor: const Color(0xFFEAF2FF), child: Icon(Icons.person, color: context.primaryColor)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (user['username'] != null) Text('@${user['username']}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        if (user['email'] != null) Text(user['email'], style: GoogleFonts.plusJakartaSans(color: context.textSecondary, fontSize: 12)),
                        if (user['phone'] != null) Text(user['phone'], style: GoogleFonts.plusJakartaSans(color: context.textSecondary, fontSize: 12)),
                      ]),
                    )
                  ]),
                  const SizedBox(height: 12),
                  _detailRow('Name', '${d['first_name'] ?? user['first_name'] ?? ''} ${d['last_name'] ?? user['last_name'] ?? ''}'.trim()),
                  _detailRow('Email', d['email']?.toString() ?? user['email']?.toString()),
                  _detailRow('Phone', d['phone']?.toString() ?? user['phone']?.toString()),
                const Divider(height: 24),
                _detailRow('Document type', d['document_type']?.toString()),
                _detailRow('Document number', d['document_number']?.toString()),
                _detailRow('Date of birth', d['date_of_birth']?.toString()),
                _detailRow('Gender', d['gender']?.toString()),
                _detailRow('Nationality', d['nationality']?.toString()),
                const Divider(height: 24),
                _detailRow('Country', d['country']?.toString()),
                _detailRow('State / County', d['county']?.toString()),
                _detailRow('City', d['city']?.toString()),
                _detailRow('Address', d['physical_address']?.toString()),
                _detailRow('Postal code', d['postal_code']?.toString()),
                finalImgsSection(d),
                if (d['additional_documents'] != null && d['additional_documents'] is List)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Additional documents', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        ...List<Widget>.from((d['additional_documents'] as List).map((doc) {
                          final url = doc is Map ? (doc['url'] ?? doc['src'])?.toString() : null;
                          if (url == null) return const SizedBox();
                          return GestureDetector(
                            onTap: () => _openImageGallery([(url)], 0),
                            child: Container(
                              width: 120,
                              height: 80,
                              decoration: BoxDecoration(
                                color: context.surface,
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                              ),
                            ),
                          );
                        }))
                      ])
                    ]),
                  ),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRejectDialog(d['id']);
                  },
                  child: Text('Reject', style: TextStyle(color: context.errorColor))),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _review(d['id'], 'verified');
                },
                style: ElevatedButton.styleFrom(backgroundColor: context.successColor),
                child: const Text('Approve'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _largeImg(String? url) => Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(12),
          image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        ),
        child: url == null ? Center(child: Icon(Icons.image_not_supported, color: context.textSecondary)) : null,
      );

  Widget finalImgsSection(Map<String, dynamic> d) {
    final List<String> imgs = [];
    void addIf(dynamic v) {
      if (v == null) return;
      if (v is String && v.isNotEmpty) imgs.add(v);
      if (v is Map && v['url'] != null) imgs.add(v['url'].toString());
    }

    addIf(d['front_image_url'] ?? d['front_image'] ?? d['front_image_path']);
    addIf(d['back_image_url'] ?? d['back_image']);
    addIf(d['selfie_image_url'] ?? d['selfie_image']);
    if (d['additional_documents'] != null && d['additional_documents'] is List) {
      for (final doc in d['additional_documents']) {
        if (doc is String) imgs.add(doc);
        if (doc is Map && doc['url'] != null) imgs.add(doc['url'].toString());
      }
    }

    if (imgs.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Document images', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: imgs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final url = imgs[i];
              return GestureDetector(
                onTap: () => _openImageGallery(imgs, i),
                child: Container(
                  width: 160,
                  height: 110,
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        )
      ]),
    );
  }

  void _openImageGallery(List<String> urls, int initialIndex) {
    final controller = PageController(initialPage: initialIndex);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(0),
        child: Stack(children: [
          PageView.builder(
            controller: controller,
            itemCount: urls.length,
            itemBuilder: (context, i) => InteractiveViewer(child: Image.network(urls[i], fit: BoxFit.contain)),
          ),
          Positioned(
            top: 24,
            left: 12,
            child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          Positioned(
            top: 24,
            right: 12,
            child: Row(children: [
              IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white),
                  onPressed: () async {
                    final url = urls[controller.hasClients ? controller.page?.round() ?? initialIndex : initialIndex];
                    await Clipboard.setData(ClipboardData(text: url));
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image URL copied to clipboard')));
                  }),
            ]),
          )
        ]),
      ),
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
