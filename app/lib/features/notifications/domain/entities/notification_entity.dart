enum NotificationCategory { device, automation, security, system, alert }
enum NotificationSeverity { info, warning, critical }

class AppNotification {
  final String id;
  final String userId;
  final String? projectId;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationSeverity severity;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.projectId,
    required this.title,
    required this.body,
    this.category = NotificationCategory.system,
    this.severity = NotificationSeverity.info,
    this.isRead = false,
    this.data,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      projectId: json['project_id'] as String?,
      title: json['title'] as String,
      body: json['body'] as String,
      category: NotificationCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => NotificationCategory.system,
      ),
      severity: NotificationSeverity.values.firstWhere(
        (s) => s.name == json['severity'],
        orElse: () => NotificationSeverity.info,
      ),
      isRead: json['is_read'] as bool? ?? false,
      data: json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
