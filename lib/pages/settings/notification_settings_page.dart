
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '/core/app_config.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class NotificationSettingsPageWidget extends StatefulWidget {

  const NotificationSettingsPageWidget({
    super.key,
  });

  static String routeName =
      'NotificationSettingsPage';

  static String routePath =
      '/notifications';

  @override
  State<NotificationSettingsPageWidget>
      createState() =>
      _NotificationSettingsPageWidgetState();
}

class _NotificationSettingsPageWidgetState
    extends State<NotificationSettingsPageWidget> {

  bool pushNotifications = true;
  bool emailNotifications = false;
  bool smsNotifications = false;
  bool soundEnabled = true;
  bool vibrationEnabled = true;

  bool loading = true;

  final String baseUrl = AppConfig.api;

  // REAL TOKEN
  String get token =>
      FFAppState().accessToken;

  @override
  void initState() {
    super.initState();

    loadSettings();
  }

  // ==========================================
  // LOAD SETTINGS
  // ==========================================
  Future<void> loadSettings() async {

    try {

      final response = await http.get(

        Uri.parse(
          '$baseUrl/notifications/settings',
        ),

        headers: {
          'Authorization':
              'Bearer $token',
        },
      );

      print(
        'NOTIFICATIONS STATUS: ${response.statusCode}',
      );

      print(
        'NOTIFICATIONS BODY: ${response.body}',
      );

      if (response.statusCode == 200) {

        final data =
            jsonDecode(response.body);

        if (data['data'] != null) {

          final settings =
              data['data'];

          setState(() {

            pushNotifications =
                settings['push_notifications']
                    ?? true;

            emailNotifications =
                settings['email_notifications']
                    ?? false;

            smsNotifications =
                settings['sms_notifications']
                    ?? false;

            soundEnabled =
                settings['sound_enabled']
                    ?? true;

            vibrationEnabled =
                settings['vibration_enabled']
                    ?? true;

            loading = false;
          });
        }

      } else {

        setState(() {
          loading = false;
        });
      }

    } catch (e) {

      debugPrint(
        'LOAD SETTINGS ERROR: $e',
      );

      setState(() {
        loading = false;
      });
    }
  }

  // ==========================================
  // SAVE SETTINGS
  // ==========================================
  Future<void> saveSettings() async {

    try {

      final response =
          await http.put(

        Uri.parse(
          '$baseUrl/notifications/settings',
        ),

        headers: {

          'Content-Type':
              'application/json',

          'Authorization':
              'Bearer $token',
        },

        body: jsonEncode({

          'push_notifications':
              pushNotifications,

          'email_notifications':
              emailNotifications,

          'sms_notifications':
              smsNotifications,

          'sound_enabled':
              soundEnabled,

          'vibration_enabled':
              vibrationEnabled,
        }),
      );

      print(
        'SAVE SETTINGS STATUS: ${response.statusCode}',
      );

      print(
        'SAVE SETTINGS BODY: ${response.body}',
      );

    } catch (e) {

      debugPrint(
        'SAVE SETTINGS ERROR: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    if (loading) {

      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(

      backgroundColor:
          FlutterFlowTheme.of(context)
              .primaryBackground,

      appBar: AppBar(
        title:
            const Text('Notifications'),
      ),

      body: ListView(

        children: [

          SwitchListTile(

            value: pushNotifications,

            title: const Text(
              'Push Notifications',
            ),

            onChanged: (val) async {

              setState(() {
                pushNotifications = val;
              });

              await saveSettings();
            },
          ),

          SwitchListTile(

            value: emailNotifications,

            title: const Text(
              'Email Notifications',
            ),

            onChanged: (val) async {

              setState(() {
                emailNotifications = val;
              });

              await saveSettings();
            },
          ),

          SwitchListTile(

            value: smsNotifications,

            title: const Text(
              'SMS Notifications',
            ),

            onChanged: (val) async {

              setState(() {
                smsNotifications = val;
              });

              await saveSettings();
            },
          ),

          SwitchListTile(

            value: soundEnabled,

            title: const Text(
              'Sound',
            ),

            onChanged: (val) async {

              setState(() {
                soundEnabled = val;
              });

              await saveSettings();
            },
          ),

          SwitchListTile(

            value: vibrationEnabled,

            title: const Text(
              'Vibration',
            ),

            onChanged: (val) async {

              setState(() {
                vibrationEnabled = val;
              });

              await saveSettings();
            },
          ),
        ],
      ),
    );
  }
}