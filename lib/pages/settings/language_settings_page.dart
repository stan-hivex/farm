
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/backend/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/localization_service.dart';

class LanguageSettingsPageWidget extends StatefulWidget {
  const LanguageSettingsPageWidget({super.key});

  static String routeName = 'LanguageSettingsPage';
  static String routePath = '/language';

  @override
  State<LanguageSettingsPageWidget> createState() =>
      _LanguageSettingsPageWidgetState();
}

class _LanguageSettingsPageWidgetState
    extends State<LanguageSettingsPageWidget> {

  bool loading = true;

  late Locale _currentLocale;

  final List<Map<String, dynamic>> languages = [

    {
      'name': 'English',
      'native': 'English',
      'locale': Locale('en'),
    },

    {
      'name': 'Swahili',
      'native': 'Kiswahili',
      'locale': Locale('sw'),
    },

    {
      'name': 'French',
      'native': 'Français',
      'locale': Locale('fr'),
    },

    {
      'name': 'Spanish',
      'native': 'Español',
      'locale': Locale('es'),
    },

    {
      'name': 'Arabic',
      'native': 'العربية',
      'locale': Locale('ar'),
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentLocale = context.locale;
    loadLanguage();
  }

  // =====================================
  // LOAD CURRENT LANGUAGE
  // =====================================
  Future<void> loadLanguage() async {
    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  // =====================================
  // SAVE TO BACKEND (OPTIONAL)
  // =====================================
  Future<void> saveLanguageBackend(
      String languageCode) async {

    try {

      await ApiService.request(
        method: 'PUT',
        path: '/settings/language',
        body: {'language': languageCode},
      );

    } catch (e) {

      debugPrint(
        'LANGUAGE BACKEND ERROR: $e',
      );
      // Don't block UI if backend sync fails
    }
  }

  // =====================================
  // CHANGE LANGUAGE
  // =====================================
  Future<void> changeLanguage(
    Map<String, dynamic> lang,
  ) async {

    final Locale locale = lang['locale'];

    try {
      // Change app language immediately
      await LocalizationService.changeLocale(context, locale);

      // Sync with backend asynchronously (don't wait)
      Future.microtask(() => saveLanguageBackend(locale.languageCode));

      if (!mounted) return;

      setState(() {
        _currentLocale = locale;
      });

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            'language.change_success'.tr(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error changing language: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change language: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          FlutterFlowTheme.of(context)
              .primaryBackground,

      appBar: AppBar(

        title: Text(
          'language.label'.tr(),
        ),

        elevation: 0,

        backgroundColor:
            FlutterFlowTheme.of(context)
                .primaryBackground,
        
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: FlutterFlowTheme.of(context).primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: loading

          ? Center(
              child:
                  CircularProgressIndicator(),
            )

          : ListView.builder(

              padding:
                  const EdgeInsets.all(16),

              itemCount:
                  languages.length,

              itemBuilder:
                  (context, index) {

                final lang =
                    languages[index];

                final isSelected =
                    _currentLocale.languageCode ==
                        lang['locale'].languageCode;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () async {
                      await changeLanguage(lang);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? FlutterFlowTheme.of(context).primary.withOpacity(0.1)
                            : FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(
                          color: isSelected
                              ? FlutterFlowTheme.of(context).primary
                              : FlutterFlowTheme.of(context).alternate,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(

                                  lang['native'],

                                  style: GoogleFonts.inter(

                                    fontSize: 16,

                                    fontWeight:
                                        FontWeight.w600,
                                    
                                    color: FlutterFlowTheme.of(context).primaryText,
                                  ),
                                ),
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Currently selected',
                                      style: FlutterFlowTheme.of(context).bodySmall.override(
                                        color: FlutterFlowTheme.of(context).primary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 24.0,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}