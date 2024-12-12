// lib/models/qualification.dart
class Qualification {
   final int? id;
  final String qualification;
  final String? field;
  final String? institution;
  final int? yearObtained;

  Qualification({
    this.id,
    required this.qualification,
    this.field,
    this.institution,
    this.yearObtained,
  });

  factory Qualification.fromJson(Map<String, dynamic> json) {
    return Qualification(
      id: json['id'] as int?, 
      qualification: json['quaification'], // keeping original spelling
      field: json['field'],
      institution: json['institution'],
      yearObtained: json['year_obtained'] != null
          ? int.tryParse(json['year_obtained'].toString())
          : null,
    );
  }
}
