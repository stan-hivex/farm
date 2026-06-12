import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
// import 'package:provider/provider.dart';

import '/backend/services/api_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

import 'kycpage_model.dart';
export 'kycpage_model.dart';

/// Create a premium fintech KYC Verification page for the FARM app.
///
/// Theme:
///
/// * Black, white, and cream colors
/// * Modern fintech design
/// * Professional banking appearance
/// * Mobile-first design
///
/// Page Title:
/// Verify Your Identity
///
/// Subtitle:
/// Complete KYC verification to unlock deposits, withdrawals, escrow
/// services, and higher transaction limits.
///
/// Verification Progress:
///
/// * Step 1: Personal Information
/// * Step 2: Identity Verification
/// * Step 3: Selfie Verification
/// * Step 4: Address Verification
/// * Step 5: Review & Submit
///
/// SECTION 1: Personal Information
///
/// Fields:
///
/// * First Name
/// * Last Name
/// * Date of Birth
/// * Gender
/// * Nationality
/// * National ID Number
/// * Phone Number
/// * Email Address
///
/// SECTION 2: Identity Verification
///
/// Upload Fields:
///
/// * National ID Front
/// * National ID Back
/// * Passport (Optional)
///
/// Requirements:
///
/// * Clear image
/// * No glare
/// * All corners visible
///
/// SECTION 3: Selfie Verification
///
/// Features:
///
/// * Upload Selfie
/// * Face Verification Placeholder
/// * Selfie Guidelines
///
/// SECTION 4: Address Verification
///
/// Upload:
///
/// * Utility Bill
/// * Bank Statement
/// * Government Letter
///
/// Fields:
///
/// * Country
/// * County/State
/// * City
/// * Physical Address
/// * Postal Code
///
/// SECTION 5: Review & Submit
///
/// Display:
///
/// * Personal Information Summary
/// * Uploaded Documents
/// * Terms & Conditions Checkbox
///
/// Buttons:
///
/// * Save Draft
/// * Submit Verification
///
/// Verification Status Cards:
///
/// Pending Review
/// Under Review
/// Approved
/// Rejected
/// Additional Information Required
///
/// Rejected Status Screen:
///
/// * Reason for Rejection
/// * Re-upload Documents Button
///
/// Approved Status Screen:
///
/// * Verification Badge
/// * Verification Date
/// * Verification Level
///
/// Design Requirements:
///
/// * Premium digital banking feel
/// * Large upload cards
/// * Progress indicator
/// * Rounded corners
/// * Soft shadows
/// * FARM branding
/// * Professional compliance experience
///
/// The page should feel like a modern fintech KYC onboarding experience
/// similar to Revolut, Wise, Stripe, or Paystack.
class KycpageWidget extends StatefulWidget {
  const KycpageWidget({super.key});

  static String routeName = 'KYCPAGE';
  static String routePath = '/kycpage';

  @override
  State<KycpageWidget> createState() => _KycpageWidgetState();
}

class _KycpageWidgetState extends State<KycpageWidget> {
  late KycpageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalController = TextEditingController();

  String _documentType = 'National ID';
  bool _termsAccepted = false;
  bool _isSubmitting = false;

  String? _frontImageName;
  String? _backImageName;
  String? _selfieImageName;
  String? _frontImageBase64;
  String? _backImageBase64;
  String? _selfieImageBase64;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => KycpageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _nationalityController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  Future<void> _captureSelfie() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        _selfieImageName = picked.name;
        _selfieImageBase64 = base64Image;
      });
    } catch (e) {
      _snack('Unable to capture selfie.');
    }
  }

  Future<void> _pickOrCaptureDocument(String key) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Choose Photo Source',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt_rounded,
                color: FlutterFlowTheme.of(context).primary,
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture using your camera'),
              onTap: () async {
                Navigator.pop(context);
                await _captureDocumentPhoto(key);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: FlutterFlowTheme.of(context).primary,
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from your device'),
              onTap: () async {
                Navigator.pop(context);
                await _pickDocumentFromGallery(key);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureDocumentPhoto(String key) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        switch (key) {
          case 'front':
            _frontImageName = picked.name;
            _frontImageBase64 = base64Image;
            break;
          case 'back':
            _backImageName = picked.name;
            _backImageBase64 = base64Image;
            break;
        }
      });
    } catch (e) {
      _snack('Unable to capture photo.');
    }
  }

  Future<void> _pickDocumentFromGallery(String key) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);
      setState(() {
        switch (key) {
          case 'front':
            _frontImageName = picked.name;
            _frontImageBase64 = base64Image;
            break;
          case 'back':
            _backImageName = picked.name;
            _backImageBase64 = base64Image;
            break;
        }
      });
    } catch (e) {
      _snack('Unable to pick image.');
    }
  }

  Future<String> uploadToCloudinary(String base64) async {
    try {
      final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/dp4sdp25o/image/upload"
      );
      
      final request = http.MultipartRequest('POST', url);
      request.fields['file'] = 'data:image/png;base64,$base64';
      request.fields['upload_preset'] = 'kyc_uploads';
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['secure_url'];
      } else {
        throw Exception('Cloudinary upload failed: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      _snack('Image upload failed. Please try again.');
      rethrow;
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) {
      _snack('Please complete all required fields.');
      return;
    }

    if (_frontImageBase64 == null) {
      _snack('Please upload your ID front image.');
      return;
    }
    if (_selfieImageBase64 == null) {
      _snack('Please upload a selfie image.');
      return;
    }
    if (!_termsAccepted) {
      _snack('Please accept the terms before submitting.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Upload all images to Cloudinary
      final frontUrl = await uploadToCloudinary(_frontImageBase64!);
      final backUrl = _backImageBase64 != null
          ? await uploadToCloudinary(_backImageBase64!)
          : null;
      final selfieUrl = await uploadToCloudinary(_selfieImageBase64!);

      await ApiService.submitKyc(
        documentType: _documentType,
        frontImageUrl: frontUrl,
        backImageUrl: backUrl,
        selfieImageUrl: selfieUrl,
        documentNumber: _idNumberController.text.trim(),
      );

      _snack('KYC submitted. Your documents will be reviewed shortly.');
      context.pushNamed('Dashboard');
    } catch (e) {
      print('KYC submit error: $e');
      _snack('Submission failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: FlutterFlowTheme.of(context).titleMedium.override(
                font: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: FlutterFlowTheme.of(context).bodySmall,
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: FlutterFlowTheme.of(context).bodySmall,
        filled: true,
        fillColor: FlutterFlowTheme.of(context).secondaryBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _uploadCard(String title, String subtitle, String? fileName, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FlutterFlowTheme.of(context).alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                      ),
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            Text(subtitle, style: FlutterFlowTheme.of(context).bodySmall),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fileName ?? 'Upload file',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                ),
                const Icon(Icons.upload_file_rounded, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, String routeName) {
    return GestureDetector(
      onTap: () => context.pushNamed(routeName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FlutterFlowTheme.of(context).alternate),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: FlutterFlowTheme.of(context).primary, size: 28),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                style: FlutterFlowTheme.of(context).bodyMedium),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFCF8),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        size: 32,
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Verify Your Identity',
                        style: FlutterFlowTheme.of(context)
                            .headlineSmall
                            .override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete KYC verification to unlock deposits, withdrawals, escrow services, and higher transaction limits.',
                        style: FlutterFlowTheme.of(context).bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _sectionHeader(
                        'Personal Information',
                        'Enter your basic details accurately.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _firstNameController,
                        'First Name',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _lastNameController,
                        'Last Name',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _dobController,
                        'Date of Birth',
                        keyboardType: TextInputType.datetime,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _genderController,
                        'Gender',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _nationalityController,
                        'Nationality',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _idNumberController,
                        'ID Number',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _phoneController,
                        'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _emailController,
                        'Email Address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader(
                        'Identity Verification',
                        'Upload your ID documents and selfie.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .secondaryBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate),
                        ),
                        child: DropdownButtonFormField<String>(
                          initialValue: _documentType,
                          decoration: const InputDecoration.collapsed(hintText: ''),
                          items: [
                            'National ID',
                            'Passport',
                            'Driver License',
                          ]
                              .map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _documentType = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _uploadCard(
                        'ID Front',
                        'Front side of your selected document',
                        _frontImageName,
                        () => _pickOrCaptureDocument('front'),
                      ),
                      const SizedBox(height: 12),
                      _uploadCard(
                        'ID Back',
                        'Back side of your selected document (optional)',
                        _backImageName,
                        () => _pickOrCaptureDocument('back'),
                      ),
                      const SizedBox(height: 12),
                      _uploadCard(
                        'Selfie',
                        'Take a selfie with front camera',
                        _selfieImageName,
                        () => _captureSelfie(),
                      ),
                      const SizedBox(height: 24),
                      _sectionHeader(
                        'Address Verification',
                        'Provide a recent proof of address and your location details.',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        _countryController,
                        'Country',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _stateController,
                        'County / State',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _cityController,
                        'City',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _addressController,
                        'Physical Address',
                        maxLines: 2,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _postalController,
                        'Postal Code',
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .secondaryBackground,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Review & Submit',
                                style: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    )),
                            const SizedBox(height: 12),
                            Text(
                              'Check your details before submitting. You can still edit these fields if something is incorrect.',
                              style: FlutterFlowTheme.of(context).bodySmall,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: _termsAccepted,
                                  onChanged: (value) {
                                    setState(() {
                                      _termsAccepted = value ?? false;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'I confirm that the information provided is accurate.',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FFButtonWidget(
                                onPressed: _isSubmitting ? null : _submitKyc,
                                text: _isSubmitting
                                    ? 'Submitting...'
                                    : 'Submit KYC',
                                options: FFButtonOptions(
                                  width: double.infinity,
                                  height: 52,
                                  color: Colors.black,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  elevation: 0,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      _sectionHeader(
                        'Quick Actions',
                        'Jump to dashboard functions once your KYC is ready.',
                      ),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        padding: EdgeInsets.zero,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _quickAction('Send', Icons.send_rounded, 'SendReceive'),
                          _quickAction('QR Scan', Icons.qr_code_rounded, 'QRScanner'),
                          _quickAction('Escrow', Icons.security_rounded, 'EscrowHub'),
                          _quickAction('Invest', Icons.show_chart_rounded, 'InvestmentMarketplace'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
