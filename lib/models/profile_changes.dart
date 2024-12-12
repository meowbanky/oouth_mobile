// lib/models/profile_changes.dart

class ProfileChanges {
  final int staffId;
  final Map<String, dynamic> profileChanges;
  final List<QualificationChange> qualificationChanges;
  final String? submittedAt;
  final String status;
  final int submittedBy;

  ProfileChanges({
    required this.staffId,
    required this.profileChanges,
    required this.qualificationChanges,
    this.submittedAt,
    this.status = 'pending',
    required this.submittedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'staff_id': staffId,
      'profile_changes': profileChanges,
      'qualification_changes':
          qualificationChanges.map((q) => q.toJson()).toList(),
      'submitted_at': submittedAt,
      'status': status,
      'submitted_by': submittedBy,
    };
  }

  factory ProfileChanges.fromJson(Map<String, dynamic> json) {
    return ProfileChanges(
      staffId: json['staff_id'] as int,
      profileChanges: json['profile_changes'] as Map<String, dynamic>,
      qualificationChanges: (json['qualification_changes'] as List)
          .map((q) => QualificationChange.fromJson(q))
          .toList(),
      submittedAt: json['submitted_at'] as String?,
      status: json['status'] as String,
      submittedBy: json['submitted_by'] as int,
    );
  }
}

class QualificationChange {
  final int? id; // Original qualification ID if editing/deleting
  final String changeType; // 'add', 'edit', or 'delete'
  final Map<String, dynamic>? data;

  QualificationChange({
    this.id,
    required this.changeType,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'change_type': changeType,
      'data': data,
    };
  }

  factory QualificationChange.fromJson(Map<String, dynamic> json) {
    return QualificationChange(
      id: json['id'] as int?,
      changeType: json['change_type'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
