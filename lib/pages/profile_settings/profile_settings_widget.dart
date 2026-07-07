import 'package:http/http.dart' as http;
import '/core/app_config.dart';
import '/components/button/button_widget.dart';
import '/components/profile_info_tile/profile_info_tile_widget.dart';
import '/components/settings_action_tile/settings_action_tile_widget.dart';
import '/backend/services/api_service.dart';
import '/services/auth/auth_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';
import 'package:flutter/material.dart';
import '/pages/change_pin_page/change_pin_page_widget.dart';
import '/pages/forgot_pin_page/forgot_pin_page_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_settings_model.dart';
export 'profile_settings_model.dart';

class ProfileSettingsWidget extends StatefulWidget {
  const ProfileSettingsWidget({super.key});

  static String routeName = 'ProfileSettings';
  static String routePath = '/profileSettings';

  @override
  State<ProfileSettingsWidget> createState() => _ProfileSettingsWidgetState();
}

class _ProfileSettingsWidgetState extends State<ProfileSettingsWidget> {
  late ProfileSettingsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, dynamic>? profileData;

  bool isProfileLoading = true;

  String fullName = '';
  String username = '';
  String email = '';
  String phone = '';
  String kycStatus = '';
  String walletAddress = '';
  String profileImage = '';
  String initials = '';

  bool hasPin = false;
  bool biometricsEnabled = false;
  bool securityLoading = true;
  bool accountLocked = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProfileSettingsModel());

    fetchProfile();
    fetchSecuritySettings();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  Future<void> fetchProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.api}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      print('PROFILE STATUS: ${response.statusCode}');
      print('PROFILE BODY: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final user = data['data'];

        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';

        setState(() {
          profileData = user;

          fullName = '$firstName $lastName';
          username = user['username'] ?? '';
          email = user['email'] ?? '';
          phone = user['phone'] ?? '';
          kycStatus = user['kyc_status'] ?? 'none';

          profileImage = user['profile_image'] ?? '';

          walletAddress = user['wallets'] != null && user['wallets'].length > 0
              ? user['wallets'][0]['wallet_address'] ?? ''
              : '';

          initials = '${firstName.isNotEmpty ? firstName[0] : ''}'
              '${lastName.isNotEmpty ? lastName[0] : ''}';

          isProfileLoading = false;
        });
      } else {
        print('PROFILE FETCH FAILED');

        setState(() {
          isProfileLoading = false;
        });
      }
    } catch (e) {
      print('PROFILE ERROR: $e');

      setState(() {
        isProfileLoading = false;
      });
    }
  }

  Future<void> fetchSecuritySettings() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.api}/security/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${FFAppState().accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          hasPin = data['has_pin'] ?? false;
          biometricsEnabled = data['biometrics_enabled'] ?? false;
          accountLocked = data['pin_locked'] ?? false;

          securityLoading = false;
        });
      } else {
        setState(() {
          securityLoading = false;
        });
      }
    } catch (e) {
      print('SECURITY FETCH ERROR: $e');

      setState(() {
        securityLoading = false;
      });
    }
  }

  Future<void> _showEditContactDialog({
    required String title,
    required String label,
    required String currentValue,
    required String fieldType,
  }) async {
    final formKey = GlobalKey<FormState>();
    final newValueController = TextEditingController(text: currentValue);
    final passwordController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newValueController,
                  decoration: InputDecoration(labelText: label),
                  keyboardType: fieldType == 'phone'
                      ? TextInputType.phone
                      : TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    if (fieldType == 'email' && !value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final newValue = newValueController.text.trim();
                final currentPassword = passwordController.text.trim();

                try {
                  await ApiService.updateEmailOrPhone(
                    email: fieldType == 'email' ? newValue : null,
                    phone: fieldType == 'phone' ? newValue : null,
                    currentPassword: currentPassword,
                  );

                  setState(() {
                    if (fieldType == 'email') {
                      email = newValue;
                    } else {
                      phone = newValue;
                    }
                  });

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$title updated successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Update failed: $e')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> logoutUser() async {
    try {
      await AuthService().logout();
    } catch (e) {
      debugPrint('Logout failed: $e');
    }

    if (!mounted) {
      return;
    }

    context.goNamed('loginpage');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    child: Container(
                      alignment: const AlignmentDirectional(0.0, 0.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: const AlignmentDirectional(0.0, 0.0),
                            children: [
                              (profileImage.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.network(
                                        profileImage,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 80.0,
                                      height: 80.0,
                                      decoration: BoxDecoration(
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment:
                                          const AlignmentDirectional(0.0, 0.0),
                                      child: Text(
                                        isProfileLoading ? '...' : initials,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        style: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .override(
                                              font: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryBackground,
                                              fontSize: 30.4,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                              lineHeight: 1.3,
                                            ),
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                isProfileLoading ? 'Loading...' : fullName,
                                style: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .override(
                                      font: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                      lineHeight: 1.3,
                                    ),
                              ),
                              Text(
                                isProfileLoading ? 'Loading...' : '@$username',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                      lineHeight: 1.5,
                                    ),
                              ),
                            ].divide(const SizedBox(height: 4.0)),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              borderRadius: BorderRadius.circular(9999.0),
                              shape: BoxShape.rectangle,
                              border: Border.all(
                                color: FlutterFlowTheme.of(context).alternate,
                                width: 1.0,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                  16.0, 4.0, 16.0, 4.0),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.verified_user_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 14.0,
                                    ),
                                    Text(
                                      kycStatus.toUpperCase(),
                                      style: FlutterFlowTheme.of(context)
                                          .labelSmall
                                          .override(
                                            font: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelSmall
                                                    .fontStyle,
                                            lineHeight: 1.2,
                                          ),
                                    ),
                                  ].divide(const SizedBox(width: 4.0)),
                                ),
                              ),
                            ),
                          ),
                        ].divide(const SizedBox(height: 16.0)),
                      ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        24.0, 24.0, 24.0, 8.0),
                    child: Container(
                      child: Text(
                        'Personal Information',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                              lineHeight: 1.3,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        24.0, 0.0, 24.0, 0.0),
                    child: Container(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(20.0),
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              wrapWithModel(
                                model: _model.profileInfoTileModel1,
                                updateCallback: () => safeSetState(() {}),
                                child: ProfileInfoTileWidget(
                                  icon: Icon(
                                    Icons.email_outlined,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 20.0,
                                  ),
                                  label: 'Email Address',
                                  show_arrow: true,
                                  value: isProfileLoading
                                      ? 'Loading...'
                                      : (email.isNotEmpty
                                          ? email
                                          : 'Not available'),
                                  onTap: isProfileLoading
                                      ? null
                                      : () => _showEditContactDialog(
                                            title: 'Update Email Address',
                                            label: 'New Email Address',
                                            currentValue: email,
                                            fieldType: 'email',
                                          ),
                                ),
                              ),
                              wrapWithModel(
                                model: _model.profileInfoTileModel2,
                                updateCallback: () => safeSetState(() {}),
                                child: ProfileInfoTileWidget(
                                  icon: Icon(
                                    Icons.phone_outlined,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    size: 20.0,
                                  ),
                                  label: 'Phone Number',
                                  show_arrow: true,
                                  value: phone.isNotEmpty
                                      ? phone
                                      : 'Not available',
                                  onTap: () => _showEditContactDialog(
                                    title: 'Update Phone Number',
                                    label: 'New Phone Number',
                                    currentValue: phone,
                                    fieldType: 'phone',
                                  ),
                                ),
                              ),
                              wrapWithModel(
                                model: _model.profileInfoTileModel3,
                                updateCallback: () => safeSetState(() {}),
                                child: GestureDetector(
                                  onTap: (kycStatus.trim().toLowerCase()=='verified' || kycStatus.trim().toLowerCase()=='approved' || kycStatus.trim().toLowerCase()=='complete' || kycStatus.trim().toLowerCase()=='success')
                                      ? null
                                      : () {
                                          context.pushNamed('KYCPAGE');
                                        },
                                  child: ProfileInfoTileWidget(
                                    icon: Icon(
                                      Icons.fingerprint_rounded,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 20.0,
                                    ),
                                    label: 'KYC Status',
                                    show_arrow: true,
                                    value: kycStatus.toUpperCase(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        24.0, 24.0, 24.0, 8.0),
                    child: Container(
                      child: Text(
                        'Preferences',
                        style: FlutterFlowTheme.of(context).labelLarge.override(
                              font: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .labelLarge
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.bold,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelLarge
                                  .fontStyle,
                              lineHeight: 1.3,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                        24.0, 0.0, 24.0, 0.0),
                    child: Container(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.circular(20.0),
                            shape: BoxShape.rectangle,
                            border: Border.all(
                              color: FlutterFlowTheme.of(context).alternate,
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
// SECURITY & PIN
                              GestureDetector(
                                onTap: () async {
                                  context.pushNamed('pin_setup_page');
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.security_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        size: 22,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Security & PIN',
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                            ),
                                            const SizedBox(height: 4),
                                            if (securityLoading)
                                              Text(
                                                'Loading security status...',
                                                style: TextStyle(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  fontSize: 12,
                                                ),
                                              )
                                            else
                                              Text(
                                                accountLocked
                                                    ? 'Account Locked'
                                                    : hasPin
                                                        ? biometricsEnabled
                                                            ? 'PIN + Biometrics Enabled'
                                                            : 'PIN is set'
                                                        : 'No PIN Configured',
                                                style: TextStyle(
                                                  color: accountLocked
                                                      ? context.errorColor
                                                      : context.successColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

// CHANGE PIN
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(
                                    ChangePinPageWidget.routeName,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.primaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_reset,
                                          color: context.background),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Change PIN',
                                        style: TextStyle(
                                            color: context.background),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.chevron_right,
                                          color: context.background),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

// FORGOT PIN
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed(
                                    ForgotPinPageWidget.routeName,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: context.primaryColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.help_outline,
                                          color: context.background),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Forgot PIN',
                                        style: TextStyle(
                                            color: context.background),
                                      ),
                                      const Spacer(),
                                      Icon(Icons.chevron_right,
                                          color: context.background),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

// DARK MODE
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                activeThumbColor: Colors.green,
                                value: Theme.of(context).brightness ==
                                    Brightness.dark,
                                onChanged: (value) {
                                  setState(() {
                                    FFAppState().setThemeMode(value
                                        ? ThemeMode.dark
                                        : ThemeMode.light);
                                  });
                                },
                                title: Text('Dark Mode'),
                                subtitle: Text(
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 'Dark theme enabled'
                                      : 'Light theme enabled',
                                ),
                              ),

                              const SizedBox(height: 12),

// BIOMETRICS
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                activeThumbColor: Colors.green,
                                value: biometricsEnabled,
                                onChanged: (value) async {
                                  setState(() {
                                    biometricsEnabled = value;
                                  });

                                  try {
                                    await http.put(
                                      Uri.parse(
                                        '${AppConfig.api}/security/biometrics',
                                      ),
                                      headers: {
                                        'Content-Type': 'application/json',
                                        'Authorization':
                                            'Bearer ${FFAppState().accessToken}',
                                      },
                                      body: jsonEncode({
                                        'enabled': value,
                                      }),
                                    );

                                    FFAppState().update(() {
                                      FFAppState().biometricsEnabled = value;
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          value
                                              ? 'Biometrics enabled'
                                              : 'Biometrics disabled',
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    print(e);
                                  }
                                },
                                title: Text('Enable Biometrics'),
                                subtitle: Text(
                                  biometricsEnabled
                                      ? 'Face ID / Fingerprint active'
                                      : 'Biometric authentication disabled',
                                ),
                              ),
                              // NOTIFICATIONS
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed('NotificationSettingsPage');
                                },
                                child: SettingsActionTileWidget(
                                  icon: Icon(
                                    Icons.notifications_none_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                  label: 'Notification Settings',
                                ),
                              ),

// LANGUAGE
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed('LanguageSettingsPage');
                                },
                                child: SettingsActionTileWidget(
                                  icon: Icon(
                                    Icons.language_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                  label: 'Language',
                                ),
                              ),

// SUPPORT / HELP CENTER
                              GestureDetector(
                                onTap: () {
                                  context.pushNamed('SupportHelpCenterPage');
                                },
                                child: SettingsActionTileWidget(
                                  icon: Icon(
                                    Icons.help_outline_rounded,
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                  ),
                                  label: 'Support & Help Center',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding:
                    const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 32.0),
                child: Container(
                  child: Container(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Container(
                        child: wrapWithModel(
                          model: _model.buttonModel,
                          updateCallback: () => safeSetState(() {}),
                          child: ButtonWidget(
                            content: 'Sign Out',
                            icon: Icon(
                              Icons.logout_rounded,
                              color: FlutterFlowTheme.of(context).primaryText,
                              size: 16.0,
                            ),
                            icon_present: true,
                            icon_end_present: false,
                            on_tap: '',
                            onTapCallback: logoutUser,
                            color: FlutterFlowTheme.of(context).primaryText,
                            variant: 'outline',
                            size: 'medium',
                            full_width: true,
                            loading: false,
                            disabled: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 24.0,
                          height: 24.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context).primaryText,
                            borderRadius: BorderRadius.circular(6.0),
                            shape: BoxShape.rectangle,
                          ),
                          alignment: const AlignmentDirectional(0.0, 0.0),
                          child: Text(
                            'F',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .primaryBackground,
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                  lineHeight: 1.5,
                                ),
                          ),
                        ),
                        Text(
                          'FARM',
                          style: FlutterFlowTheme.of(context)
                              .titleMedium
                              .override(
                                font: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                                color: FlutterFlowTheme.of(context).primaryText,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.bold,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleMedium
                                    .fontStyle,
                                lineHeight: 1.4,
                              ),
                        ),
                      ].divide(const SizedBox(width: 4.0)),
                    ),
                    Text(
                      'a loop of growth',
                      style: FlutterFlowTheme.of(context).labelSmall.override(
                            font: GoogleFonts.plusJakartaSans(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .labelSmall
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context).onSurface,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .labelSmall
                                .fontStyle,
                            lineHeight: 1.2,
                          ),
                    ),
                  ].divide(const SizedBox(height: 4.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
