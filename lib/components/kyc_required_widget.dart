import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class KycRequiredWidget extends StatelessWidget {
  final String feature;
  const KycRequiredWidget({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined,
                size: 60, color: theme.primary),
            const SizedBox(height: 24),
            Text(
              'KYC Verification Required',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.primaryText,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KYC verification is required before using $feature. Please complete your KYC details to continue.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.secondaryText,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.goNamed('KYCPAGE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.secondaryBackground,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Complete KYC',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.secondaryBackground,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your submission will be reviewed by admin before access is granted.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: theme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
