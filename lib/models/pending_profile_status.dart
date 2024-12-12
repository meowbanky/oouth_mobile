// lib/models/pending_profile_status.dart

class PendingProfileStatus {
  final bool hasPendingChanges;
  final String? submittedAt;
  final Map<String, dynamic>? pendingProfileChanges;
  final List<PendingQualificationChange>? pendingQualificationChanges;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;

  PendingProfileStatus({
    required this.hasPendingChanges,
    this.submittedAt,
    this.pendingProfileChanges,
    this.pendingQualificationChanges,
    required this.status,
    this.rejectionReason,
  });

  factory PendingProfileStatus.fromJson(Map<String, dynamic> json) {
    return PendingProfileStatus(
      hasPendingChanges: json['has_pending_changes'] as bool,
      submittedAt: json['submitted_at'] as String?,
      pendingProfileChanges:
          json['pending_profile_changes'] as Map<String, dynamic>?,
      pendingQualificationChanges:
          (json['pending_qualification_changes'] as List?)
              ?.map((q) => PendingQualificationChange.fromJson(q))
              .toList(),
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  bool get isApprovalPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

class PendingQualificationChange {
  final int? originalId;
  final String changeType;
  final Map<String, dynamic> data;

  PendingQualificationChange({
    this.originalId,
    required this.changeType,
    required this.data,
  });

  factory PendingQualificationChange.fromJson(Map<String, dynamic> json) {
    return PendingQualificationChange(
      originalId: json['original_id'] as int?,
      changeType: json['change_type'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}
