// lib/models/approval_status.dart

class ApprovalStatus {
  final String status;
  final String? submittedAt;
  final int? submittedBy;
  final int? approvedBy;
  final String? approvedAt;
  final String? rejectionReason;
  final List<PendingChange> changes;

  ApprovalStatus({
    required this.status,
    this.submittedAt,
    this.submittedBy,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.changes,
  });

  factory ApprovalStatus.fromJson(Map<String, dynamic> json) {
    final statusData = json['status'] ?? {};
    final changesData = json['changes'] as List<dynamic>? ?? [];

    return ApprovalStatus(
      status: statusData['status'] as String? ?? 'pending',
      submittedAt: statusData['submitted_at'] as String?,
      submittedBy: statusData['submitted_by'] as int?,
      approvedBy: statusData['approved_by'] as int?,
      approvedAt: statusData['approved_at'] as String?,
      rejectionReason: statusData['rejection_reason'] as String?,
      changes: changesData
          .map((change) =>
              PendingChange.fromJson(change as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

class PendingChange {
  final String fieldName;
  final String? oldValue;
  final String? newValue;
  final String status;

  PendingChange({
    required this.fieldName,
    this.oldValue,
    this.newValue,
    required this.status,
  });

  factory PendingChange.fromJson(Map<String, dynamic> json) {
    return PendingChange(
      fieldName: json['field_name'] as String,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      status: json['status'] as String,
    );
  }
}
