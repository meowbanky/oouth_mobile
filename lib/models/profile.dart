// lib/models/profile.dart

import 'qualification.dart';
import 'retirement_info.dart';
import 'service_summary.dart';
import 'pending_profile_status.dart';

class Profile {
  final int? staffId;
  final String? ppno;
  final String? name;
  final String? email;
  final String? gender;
  final String? empDate;
  final String? dob;
  final String? dopa;
  final String? doc;
  final String? lgOrigin;
  final String? sOrigin;
  final String? department;
  final String? levelApt;
  final List<Qualification> qualifications;
  final RetirementInfo? retirementInfo;
  final ServiceSummary? serviceSummary;
  final double? monthlySalary;
  final double? annualSalary;
  final PendingProfileStatus? pendingStatus;

  Profile({
    required this.staffId,
    this.ppno,
    this.name,
    this.email,
    this.gender,
    this.empDate,
    this.dob,
    this.dopa,
    this.doc,
    this.lgOrigin,
    this.sOrigin,
    this.department,
    this.levelApt,
    this.qualifications = const [],
    this.retirementInfo,
    this.serviceSummary,
    this.monthlySalary,
    this.annualSalary,
    this.pendingStatus,
  });

  Profile copyWith({
    int? staffId, // Add this line
    String? ppno,
    String? name,
    String? email,
    String? gender,
    String? empDate,
    String? dob,
    String? dopa,
    String? doc,
    String? lgOrigin,
    String? sOrigin,
    String? department,
    String? levelApt,
    List<Qualification>? qualifications,
    RetirementInfo? retirementInfo,
    ServiceSummary? serviceSummary,
    double? monthlySalary,
    double? annualSalary,
    PendingProfileStatus? pendingStatus,
  }) {
    return Profile(
      staffId: staffId ?? this.staffId, // Add this line
      ppno: ppno ?? this.ppno,
      name: name ?? this.name,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      empDate: empDate ?? this.empDate,
      dob: dob ?? this.dob,
      dopa: dopa ?? this.dopa,
      doc: doc ?? this.doc,
      lgOrigin: lgOrigin ?? this.lgOrigin,
      sOrigin: sOrigin ?? this.sOrigin,
      department: department ?? this.department,
      levelApt: levelApt ?? this.levelApt,
      qualifications: qualifications ?? this.qualifications,
      retirementInfo: retirementInfo ?? this.retirementInfo,
      serviceSummary: serviceSummary ?? this.serviceSummary,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      annualSalary: annualSalary ?? this.annualSalary,
      pendingStatus: pendingStatus,
    );
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      staffId: json['staff_id'],
      ppno: json['PPNO']?.toString(),
      name: json['NAME']?.toString(),
      email: json['EMAIL']?.toString(),
      gender: json['GENDER']?.toString(),
      empDate: json['EMPDATE']?.toString(),
      dob: json['DOB']?.toString(),
      dopa: json['DOPA']?.toString(),
      doc: json['DOC']?.toString(),
      lgOrigin: json['LG_ORIGIN']?.toString(),
      sOrigin: json['S_ORIGIN']?.toString(),
      department: json['dept']?.toString(),
      levelApt: json['LEVE_APT']?.toString(),
      qualifications: (json['qualifications'] as List<dynamic>?)
              ?.map((q) => Qualification.fromJson(q))
              .toList() ??
          [],
      retirementInfo: json['retirement_info'] != null
          ? RetirementInfo.fromJson(json['retirement_info'])
          : null,
      serviceSummary: json['service_summary'] != null
          ? ServiceSummary.fromJson(json['service_summary'])
          : null,
      monthlySalary: json['monthly_salary'] != null
          ? double.tryParse(json['monthly_salary'].toString())
          : null,
      annualSalary: json['annual_salary'] != null
          ? double.tryParse(json['annual_salary'].toString())
          : null,
      pendingStatus: json['pending_status'] != null
          ? PendingProfileStatus.fromJson(json['pending_status'])
          : null,
    );
  }

  bool get hasPendingChanges => pendingStatus?.hasPendingChanges ?? false;
  bool get canEdit => !hasPendingChanges;
}
