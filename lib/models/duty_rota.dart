class DutyRota {
  final int id;
  final int staffId;
  final int shiftId;
  final int locationId;
  final String dutyDate;
  final String status;
  final String staffName;
  final String shiftTitle;
  final String startTime;
  final String endTime;
  final String locationName;

  DutyRota({
    required this.id,
    required this.staffId,
    required this.shiftId,
    required this.locationId,
    required this.dutyDate,
    required this.status,
    required this.staffName,
    required this.shiftTitle,
    required this.startTime,
    required this.endTime,
    required this.locationName,
  });

  factory DutyRota.fromJson(Map<String, dynamic> json) {
    return DutyRota(
      id: json['id'],
      staffId: json['staff_id'],
      shiftId: json['shift_id'],
      locationId: json['location_id'],
      dutyDate: json['duty_date'],
      status: json['status'],
      staffName: json['staff_name'],
      shiftTitle: json['shift_title'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      locationName: json['location_name'],
    );
  }
}
