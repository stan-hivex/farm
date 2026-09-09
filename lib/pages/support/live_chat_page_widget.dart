import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';

class LiveChatPageWidget extends StatefulWidget {
  const LiveChatPageWidget({super.key});

  @override
  State<LiveChatPageWidget> createState() => _LiveChatPageWidgetState();
}

class _LiveChatPageWidgetState extends State<LiveChatPageWidget> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final msg = _messageController.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('notifications.no_message'.tr())),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final user = FFAppState().userName;
      final subject = Uri.encodeComponent(
          'FARM Live Chat from ${user.isNotEmpty ? user : 'User'}');
      final body = Uri.encodeComponent(msg);

      await launchURL(
          'mailto:support@farmapp.africa?subject=$subject&body=$body');
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('errors.unable_load'.tr())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        elevation: 0,
        title: Text('support.live_chat'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.support_agent_rounded, color: theme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'ui.support_chat_description'.tr(),
                        style: theme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  hintText: 'ui.optional_description'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendMessage,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _sending
                    ? CircularProgressIndicator(color: context.onSurface)
                    : Text('support.email_support'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
