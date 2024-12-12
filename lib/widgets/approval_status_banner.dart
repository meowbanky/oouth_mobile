// lib/widgets/approval_status_banner.dart

import 'package:flutter/material.dart';
import '../models/approval_status.dart';

class ApprovalStatusBanner extends StatelessWidget {
  final ApprovalStatus status;
  final VoidCallback? onCancel;

  const ApprovalStatusBanner({
    super.key,
    required this.status,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String message;

    switch (status.status) {
      case 'pending':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade900;
        icon = Icons.pending_actions;
        title = 'Changes Pending Approval';
        message = 'Your profile changes are under review';
        break;
      case 'approved':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade900;
        icon = Icons.check_circle;
        title = 'Changes Approved';
        message = 'Your profile has been updated successfully';
        break;
      case 'rejected':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade900;
        icon = Icons.cancel;
        title = 'Changes Rejected';
        message = status.rejectionReason ?? 'Your changes were not approved';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (status.isPending && onCancel != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  color: textColor,
                  onPressed: onCancel,
                  tooltip: 'Cancel pending changes',
                ),
            ],
          ),
          if (status.changes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Changes:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            ...status.changes.map((change) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• ${_formatChange(change)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  String _formatChange(PendingChange change) {
    if (change.fieldName.toLowerCase() == 'qualification') {
      return change.newValue ?? 'Qualification update';
    }
    final fieldName = _formatFieldName(change.fieldName);
    if (change.oldValue == null || change.oldValue!.isEmpty) {
      return '$fieldName: ${change.newValue ?? 'Updated'}';
    }
    return '$fieldName: ${change.oldValue} → ${change.newValue}';
  }

  String _formatFieldName(String fieldName) {
    return fieldName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
