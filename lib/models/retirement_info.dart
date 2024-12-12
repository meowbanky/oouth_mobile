class RetirementInfo {
  final String? retirementDate;
  final String? retirementType;
  final int? yearsRemaining;
  final int? monthsRemaining;
  final int? totalMonthsRemaining;
  final bool? isRetired;
  final String? serviceRetirementDate;
  final String? ageRetirementDate;

  RetirementInfo({
    this.retirementDate,
    this.retirementType,
    this.yearsRemaining,
    this.monthsRemaining,
    this.totalMonthsRemaining,
    this.isRetired,
    this.serviceRetirementDate,
    this.ageRetirementDate,
  });

  factory RetirementInfo.fromJson(Map<String, dynamic> json) {
    return RetirementInfo(
      retirementDate: json['retirement_date']?.toString(),
      retirementType: json['retirement_type']?.toString(),
      yearsRemaining: json['years_remaining'],
      monthsRemaining: json['months_remaining'],
      totalMonthsRemaining: json['total_months_remaining'],
      isRetired: json['is_retired'],
      serviceRetirementDate: json['service_retirement_date']?.toString(),
      ageRetirementDate: json['age_retirement_date']?.toString(),
    );
  }

  @override
  String toString() {
    return 'RetirementInfo(retirementDate: $retirementDate, type: $retirementType, yearsRemaining: $yearsRemaining, monthsRemaining: $monthsRemaining)';
  }
}
