// lib/models/app_notification.dart
class AppNotification {
  final int id;
  final String staffId; // This will store the user's id
  final String title;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppNotification({
    required this.id,
    required this.staffId,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      staffId: json['staff_id']
          .toString(), // Convert to String since User.id is String
      title: json['title'],
      message: json['message'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
