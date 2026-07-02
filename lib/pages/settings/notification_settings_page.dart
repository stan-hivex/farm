import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '/backend/services/api_service.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';

class NotificationSettingsPageWidget extends StatefulWidget {
  const NotificationSettingsPageWidget({super.key});

  static String routeName = 'NotificationSettingsPage';
  static String routePath = '/notifications';

  @override
  State<NotificationSettingsPageWidget> createState() =>
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
  bool notificationsLoading = true;
  List<Map<String, dynamic>> notifications = [];
  String? notificationsError;

  final String baseUrl = AppConfig.api;
  String get token => FFAppState().accessToken;

  @override
  void initState() {
    super.initState();
    loadSettings();
    loadNotifications();
  }

  Future<void> loadSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/settings'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = data['data'];

        if (settings is Map<String, dynamic>) {
          setState(() {
            pushNotifications = settings['push_notifications'] ?? true;
            emailNotifications = settings['email_notifications'] ?? false;
            smsNotifications = settings['sms_notifications'] ?? false;
            soundEnabled = settings['sound_enabled'] ?? true;
            vibrationEnabled = settings['vibration_enabled'] ?? true;
            loading = false;
          });
          return;
        }
      }

      setState(() {
        loading = false;
      });
    } catch (e) {
      debugPrint('LOAD SETTINGS ERROR: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> loadNotifications() async {
    if (!mounted) return;
    setState(() {
      notificationsLoading = true;
      notificationsError = null;
    });

    try {
      final response = await ApiService.getNotifications();
      final dynamic rawList = response['data'] ?? response['notifications'];
      final List<Map<String, dynamic>> parsed = [];

      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            parsed.add(Map<String, dynamic>.from(item));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        notifications = parsed;
        notificationsLoading = false;
      });
    } catch (e) {
      debugPrint('LOAD NOTIFICATIONS ERROR: $e');
      if (!mounted) return;
      setState(() {
        notificationsLoading = false;
        notificationsError = e.toString();
      });
    }
  }

  Future<void> saveSettings() async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/settings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'push_notifications': pushNotifications,
          'email_notifications': emailNotifications,
          'sms_notifications': smsNotifications,
          'sound_enabled': soundEnabled,
          'vibration_enabled': vibrationEnabled,
        }),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.statusCode >= 200 && response.statusCode < 300
                ? 'Notification preferences updated'
                : 'Unable to update preferences',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('SAVE SETTINGS ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update preferences right now'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return 'Just now';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final now = DateTime.now();
    final difference = now.difference(parsed);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded),
            onPressed: () async {
              await loadSettings();
              await loadNotifications();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadSettings();
          await loadNotifications();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Preferences',
              style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: pushNotifications,
                    title: Text('Push notifications'),
                    subtitle: Text('Receive alerts on your device'),
                    onChanged: (val) async {
                      setState(() => pushNotifications = val);
                      await saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: emailNotifications,
                    title: Text('Email notifications'),
                    subtitle: Text('Send updates to your inbox'),
                    onChanged: (val) async {
                      setState(() => emailNotifications = val);
                      await saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: smsNotifications,
                    title: Text('SMS notifications'),
                    subtitle: Text('Get important alerts by text'),
                    onChanged: (val) async {
                      setState(() => smsNotifications = val);
                      await saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: soundEnabled,
                    title: Text('Sound'),
                    subtitle: Text('Play sounds for notifications'),
                    onChanged: (val) async {
                      setState(() => soundEnabled = val);
                      await saveSettings();
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: vibrationEnabled,
                    title: Text('Vibration'),
                    subtitle: Text('Vibrate for incoming alerts'),
                    onChanged: (val) async {
                      setState(() => vibrationEnabled = val);
                      await saveSettings();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Recent activity',
                  style: theme.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await loadNotifications();
                  },
                  icon: Icon(Icons.sync_rounded, size: 18),
                  label: Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (notificationsLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (notificationsError != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Unable to load notifications right now.\n$notificationsError',
                    style: TextStyle(color: context.errorColorAccent),
                  ),
                ),
              )
            else if (notifications.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('No notifications yet', style: TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text('You will see account and transaction updates here.'),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: notifications
                    .map(
                      (notification) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: theme.secondaryBackground,
                              child: Icon(
                                Icons.notifications_none_rounded,
                                color: theme.primaryText,
                              ),
                            ),
                            title: Text(
                              notification['title']?.toString() ??
                                  notification['subject']?.toString() ??
                                  'Notification',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              notification['message']?.toString() ??
                                  notification['body']?.toString() ??
                                  notification['content']?.toString() ??
                                  'No details available',
                            ),
                            trailing: Text(
                              _formatTime(
                                notification['created_at'] ??
                                    notification['createdAt'] ??
                                    notification['timestamp'],
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.secondaryText,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
