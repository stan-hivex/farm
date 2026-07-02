
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/core/app_config.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

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

  String selectedLanguage = 'English';

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
    loadLanguage();
  }

  // =====================================
  // LOAD SAVED LANGUAGE
  // =====================================
  Future<void> loadLanguage() async {

    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getString('language') ?? 'English';

    if (!mounted) return;

    setState(() {

      selectedLanguage = saved;

      loading = false;
    });
  }

  // =====================================
  // SAVE TO LOCAL STORAGE
  // =====================================
  Future<void> saveLanguage(
      String language) async {

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'language',
      language,
    );
  }

  // =====================================
  // SAVE TO BACKEND
  // =====================================
  Future<void> saveLanguageBackend(
      String language) async {

    try {

      await http.put(

        Uri.parse(
          '${AppConfig.api}/settings/language',
        ),

        headers: {

          'Content-Type': 'application/json',

          'Authorization':
              'Bearer ${FFAppState().accessToken}',
        },

        body: jsonEncode({
          'language': language,
        }),
      );

    } catch (e) {

      debugPrint(
        'LANGUAGE BACKEND ERROR: $e',
      );
    }
  }

  // =====================================
  // CHANGE LANGUAGE
  // =====================================
  Future<void> changeLanguage(
    Map<String, dynamic> lang,
  ) async {

    final Locale locale =
        lang['locale'];

    final String languageName =
        lang['name'];

    // SAVE LOCAL
    await saveLanguage(languageName);

    // SAVE BACKEND
    await saveLanguageBackend(
      locale.languageCode,
    );

    // CHANGE APP LANGUAGE
    await context.setLocale(locale);

    if (!mounted) return;

    setState(() {

      selectedLanguage =
          languageName;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(

      SnackBar(
        content: Text(
          '$languageName selected',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          FlutterFlowTheme.of(context)
              .primaryBackground,

      appBar: AppBar(

        title: Text(
          'language'.tr(),
        ),

        elevation: 0,

        backgroundColor:
            FlutterFlowTheme.of(context)
                .primaryBackground,
      ),

      body: loading

          ? Center(
              child:
                  CircularProgressIndicator(),
            )

          : ListView.separated(

              padding:
                  const EdgeInsets.all(16),

              itemCount:
                  languages.length,

              separatorBuilder:
                  (_, __) =>
                      const Divider(),

              itemBuilder:
                  (context, index) {

                final lang =
                    languages[index];

                final isSelected =
                    selectedLanguage ==
                        lang['name'];

                return ListTile(

                  title: Text(

                    lang['native'],

                    style:
                        GoogleFonts.inter(

                      fontSize: 16,

                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  trailing: isSelected

                      ? Icon(
                          Icons.check_circle,

                          color:
                              FlutterFlowTheme.of(
                                      context)
                                  .primary,
                        )

                      : null,

                  onTap: () async {

                    await changeLanguage(
                      lang,
                    );
                  },
                );
              },
            ),
    );
  }
}