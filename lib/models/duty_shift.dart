class DutyShift {
  final int id;
  final String title;
  final String startTime;
  final String endTime;

  DutyShift({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
  });

  factory DutyShift.fromJson(Map<String, dynamic> json) {
    return DutyShift(
      id: json['id'],
      title: json['title'],
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }
}
