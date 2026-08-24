import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '/flutter_flow/flutter_flow_theme.dart';

class LegalDocumentPageWidget extends StatelessWidget {
  const LegalDocumentPageWidget({
    required this.title,
    required this.assetPath,
    super.key,
  });

  static const privacyPolicyRouteName = 'PrivacyPolicyPage';
  static const privacyPolicyRoutePath = '/privacyPolicy';
  static const termsRouteName = 'TermsOfServicePage';
  static const termsRoutePath = '/termsOfService';

  final String title;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.primaryBackground,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(assetPath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load $title.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: SelectableText(
              snapshot.data ?? '',
              style: theme.bodyMedium.copyWith(height: 1.5),
            ),
          );
        },
      ),
    );
  }
}