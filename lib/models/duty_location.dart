class DutyLocation {
  final int id;
  final String name;

  DutyLocation({required this.id, required this.name});

  factory DutyLocation.fromJson(Map<String, dynamic> json) {
    return DutyLocation(
      id: json['id'],
      name: json['duty_locations'],
    );
  }
}
