import 'package:flutter/material.dart';
import '/backend/services/api_service.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/core/theme_extensions.dart';

class UserNotificationsPageWidget extends StatefulWidget {
  const UserNotificationsPageWidget({super.key});

  static String routeName = 'UserNotificationsPage';
  static String routePath = '/user-notifications';

  @override
  State<UserNotificationsPageWidget> createState() => _UserNotificationsPageWidgetState();
}

class _UserNotificationsPageWidgetState extends State<UserNotificationsPageWidget> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await ApiService.getNotifications();
      final rawNotifications = response['data'];
      final items = rawNotifications is List
          ? rawNotifications
              .map((item) => item is Map<String, dynamic>
                  ? item
                  : Map<String, dynamic>.from(item as Map))
              .toList()
          : <Map<String, dynamic>>[];
      setState(() {
        notifications = items.cast<Map<String, dynamic>>();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Unable to fetch notifications.';
        isLoading = false;
      });
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      // Mark notification as read (best effort)
      // TODO: Implement when API is ready
    } catch (_) {
      // ignore errors; this is best effort
    }
  }

  String _displayDate(Map<String, dynamic> item) {
    final createdAt = item['created_at'] ?? item['createdAt'] ?? item['createdAt'];
    if (createdAt is int) {
      return dateTimeFormat('MMM d, h:mm a', DateTime.fromMillisecondsSinceEpoch(createdAt));
    }
    if (createdAt is String) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null) {
        return dateTimeFormat('MMM d, h:mm a', parsed);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
      appBar: AppBar(
        title: Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                  )
                : notifications.isEmpty
                    ? Center(
                        child: Text(
                          'No notifications yet.',
                          style: FlutterFlowTheme.of(context).bodyMedium,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadNotifications,
                        child: ListView.separated(
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final item = notifications[index];
                            final title = item['title']?.toString() ?? 'Notification';
                            final body = item['body']?.toString() ?? item['message']?.toString() ?? '';
                            final source = item['type']?.toString() ?? item['source']?.toString() ?? 'Admin';
                            final isRead = item['read'] is bool
                                ? item['read'] as bool
                                : item['is_read'] is bool
                                    ? item['is_read'] as bool
                                    : item['isRead'] is bool
                                        ? item['isRead'] as bool
                                        : false;
                            final timestamp = _displayDate(item);
                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              color: FlutterFlowTheme.of(context).secondaryBackground,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  if (!isRead && item['id'] != null) {
                                    await markNotificationRead(item['id'].toString());
                                    loadNotifications();
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .override(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                          ),
                                          if (!isRead)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: FlutterFlowTheme.of(context).primary,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'New',
                                                style: FlutterFlowTheme.of(context)
                                                    .bodySmall
                                                    .override(
                                                      color: context.onSurface,
                                                    ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        body,
                                        style: FlutterFlowTheme.of(context).bodyMedium,
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            source,
                                            style: FlutterFlowTheme.of(context).bodySmall,
                                          ),
                                          if (timestamp.isNotEmpty)
                                            Text(
                                              timestamp,
                                              style: FlutterFlowTheme.of(context).bodySmall,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
