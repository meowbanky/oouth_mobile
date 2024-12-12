class ServiceSummary {
  final int? yearsInService;
  final int? currentAge;
  final int? yearsToServiceRetirement;
  final int? yearsToAgeRetirement;

  ServiceSummary({
    this.yearsInService,
    this.currentAge,
    this.yearsToServiceRetirement,
    this.yearsToAgeRetirement,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> json) {
    return ServiceSummary(
      yearsInService: json['years_in_service'],
      currentAge: json['current_age'],
      yearsToServiceRetirement: json['years_to_service_retirement'],
      yearsToAgeRetirement: json['years_to_age_retirement'],
    );
  }

  @override
  String toString() {
    return 'ServiceSummary(yearsInService: $yearsInService, currentAge: $currentAge)';
  }
}
