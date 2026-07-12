class NormalizedNotification {
  final String id;
  final String title;
  final String body;
  final String source;
  final bool isRead;
  final String timestamp;

  NormalizedNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.source,
    required this.isRead,
    required this.timestamp,
  });

  factory NormalizedNotification.fromMap(Map<String, dynamic> map) {
    return NormalizedNotification(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      source: map['source']?.toString() ?? map['type']?.toString() ?? 'Notification',
      isRead: map['is_read'] == true || map['isRead'] == true,
      timestamp: map['timestamp']?.toString() ?? map['created_at']?.toString() ?? '',
    );
  }
}

NormalizedNotification normalizeNotificationPayload(Map<String, dynamic> payload) {
  if (payload.containsKey('data') && payload['data'] is Map<String, dynamic>) {
    return NormalizedNotification.fromMap(payload['data'] as Map<String, dynamic>);
  }
  return NormalizedNotification.fromMap(payload);
}
