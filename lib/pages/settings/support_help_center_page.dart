import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class SupportHelpCenterPageWidget extends StatefulWidget {
  const SupportHelpCenterPageWidget({super.key});

  static String routeName = 'SupportHelpCenterPage';
  static String routePath = '/support';

  @override
  State<SupportHelpCenterPageWidget> createState() =>
      _SupportHelpCenterPageWidgetState();
}

class _SupportHelpCenterPageWidgetState
    extends State<SupportHelpCenterPageWidget> {

  void safeNavigate(String routeName) {
    try {
      context.pushNamed(routeName);
    } catch (e) {
      debugPrint('NAVIGATION ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Page not available: $routeName',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          FlutterFlowTheme.of(context).primaryBackground,

      appBar: AppBar(
        backgroundColor:
            FlutterFlowTheme.of(context).primaryBackground,
        title: const Text('Support & Help Center'),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              'How can we help you?',
              style:
                  FlutterFlowTheme.of(context).titleMedium,
            ),

            const SizedBox(height: 16),

            // ================= FAQ =================
            ListTile(
              leading: Icon(
                Icons.question_answer_rounded,
                color: FlutterFlowTheme.of(context).primary,
              ),
              title: const Text('FAQs'),
              subtitle: const Text(
                'Browse frequently asked questions',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: () {
                safeNavigate('FaqPage');
              },
            ),

            const Divider(),

            // ================= LIVE CHAT =================
            ListTile(
              leading: Icon(
                Icons.chat_rounded,
                color: FlutterFlowTheme.of(context).primary,
              ),
              title: const Text('Live Chat'),
              subtitle: const Text(
                'Chat with support team',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: () {
                safeNavigate('LiveChatPage');
              },
            ),

            const Divider(),

            // ================= EMAIL SUPPORT =================
            ListTile(
              leading: Icon(
                Icons.email_rounded,
                color: FlutterFlowTheme.of(context).primary,
              ),
              title: const Text('Email Support'),
              subtitle: const Text(
                'Send a support request',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: () {
                safeNavigate('EmailSupportPage');
              },
            ),

            const Divider(),

            const SizedBox(height: 30),

            Center(
              child: Text(
                'Support is available 24/7',
                style:
                    FlutterFlowTheme.of(context).bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}