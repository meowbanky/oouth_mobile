class Notification {
  final int id;
  final int staffId;
  final String title;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.staffId,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      staffId: json['staff_id'],
      title: json['title'],
      message: json['message'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
