import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core/theme_extensions.dart';
import '../services/admin_api_service.dart';

class NotificationsManagementPage extends StatefulWidget {
  final VoidCallback? onGoBack;

  const NotificationsManagementPage({super.key, this.onGoBack});

  @override
  State<NotificationsManagementPage> createState() =>
      _NotificationsManagementPageState();
}

class _NotificationsManagementPageState
    extends State<NotificationsManagementPage> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _type = 'system';
  String _audience = 'all';
  bool _sending = false;

  Future<void> _send() async {
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      _snack('Please fill in title and message', context.warningColor);
      return;
    }
    setState(() => _sending = true);
    try {
      await AdminApiService.sendNotification({
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'type': _type,
        'audience': _audience,
      });
      _titleCtrl.clear();
      _bodyCtrl.clear();
      _snack('Notification sent ✓', context.successColor);
    } catch (e) {
      _snack(e.toString().replaceAll('Exception: ', ''), context.errorColor);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _snack(String msg, Color c) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c, behavior: SnackBarBehavior.floating));

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0B1320);
    final cardColor = const Color(0xFF111B2A);
    final accent = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Broadcast Notification',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20, color: context.onSurface)),
            const SizedBox(height: 6),
            Text('Send a notification to your users',
                style: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.6), fontSize: 13)),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.onSurface.withOpacity(0.1)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Notification Title'),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleCtrl,
                  style: TextStyle(color: context.onSurface),
                  decoration: _inputDec('e.g. System Maintenance Notice'),
                ),
                const SizedBox(height: 20),

                _label('Message Content'),
                const SizedBox(height: 8),
                TextField(
                  controller: _bodyCtrl,
                  maxLines: 5,
                  style: TextStyle(color: context.onSurface),
                  decoration: _inputDec('Write your notification message here...'),
                ),
                const SizedBox(height: 20),

                _label('Notification Type'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in ['system', 'security', 'transaction', 'merchant', 'investment'])
                    ChoiceChip(
                      label: Text(t.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _type == t ? context.background : context.onSurface.withOpacity(0.7))),
                      selected: _type == t,
                      selectedColor: accent,
                      backgroundColor: cardColor,
                      side: BorderSide(color: _type == t ? accent : context.onSurface.withOpacity(0.1)),
                      onSelected: (_) => setState(() => _type = t),
                    ),
                ]),
                const SizedBox(height: 20),

                _label('Target Audience'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final a in ['all', 'verified', 'merchants', 'investors'])
                    ChoiceChip(
                      label: Text(a.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _audience == a ? context.background : context.onSurface.withOpacity(0.7))),
                      selected: _audience == a,
                      selectedColor: accent,
                      backgroundColor: cardColor,
                      side: BorderSide(color: _audience == a ? accent : context.onSurface.withOpacity(0.1)),
                      onSelected: (_) => setState(() => _audience = a),
                    ),
                ]),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: context.onSurface, strokeWidth: 2))
                        : Icon(Icons.send_rounded, color: context.onBackground.withOpacity(0.87)),
                    label: Text(_sending ? 'Sending...' : 'Send Notification',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: context.onBackground.withOpacity(0.87))),
                  ),
                ),
              ]),
            ),

            const SizedBox(height: 28),
            Text('Quick Templates',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: context.onSurface)),
            const SizedBox(height: 12),
            ...[
              {'title': 'System Maintenance', 'body': 'FARM platform will undergo scheduled maintenance on [DATE] from [TIME] to [TIME]. Services may be temporarily unavailable.', 'type': 'system'},
              {'title': 'Security Alert', 'body': 'We detected unusual activity on the platform. Please ensure your account is secure and contact support if needed.', 'type': 'security'},
              {'title': 'New Feature Available', 'body': 'Exciting news! A new feature is now available on the FARM platform. Check it out in the app.', 'type': 'system'},
            ].map((t) => GestureDetector(
              onTap: () => setState(() {
                _titleCtrl.text = t['title']!;
                _bodyCtrl.text = t['body']!;
                _type = t['type']!;
              }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.onSurface.withOpacity(0.1)),
                ),
                child: Row(children: [
                  Icon(Icons.article_rounded, size: 18, color: context.onSurface.withOpacity(0.7)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t['title']!, style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600, fontSize: 13, color: context.onSurface)),
                    Text(t['body']!, style: GoogleFonts.plusJakartaSans(
                        color: context.onSurface.withOpacity(0.6), fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.onSurface.withOpacity(0.54)),
                ]),
              ),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600, fontSize: 13, color: context.onSurface.withOpacity(0.7)));

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.plusJakartaSans(color: context.onSurface.withOpacity(0.54), fontSize: 13),
    filled: true, fillColor: const Color(0xFF0F1724),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.onSurface.withOpacity(0.1))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.onSurface.withOpacity(0.1))),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
