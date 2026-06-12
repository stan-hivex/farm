import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EmailSupportPageWidget extends StatelessWidget {
  const EmailSupportPageWidget({super.key});

  Future<void> _openEmail() async {
    await launchURL('mailto:support@farmapp.africa');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Support')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send us an email at',
                style: FlutterFlowTheme.of(context).titleMedium,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _openEmail,
                child: Text(
                  'support@farmapp.africa',
                  style: TextStyle(
                    color: FlutterFlowTheme.of(context).primary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tap the email address above to open your default mail app.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}