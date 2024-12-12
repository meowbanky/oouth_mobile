// lib/widgets/retirement_progress.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/retirement_info.dart';
import '../models/service_summary.dart';

class RetirementProgress extends StatelessWidget {
  final RetirementInfo retirementInfo;
  final ServiceSummary serviceSummary;

  const RetirementProgress({
    super.key,
    required this.retirementInfo,
    required this.serviceSummary,
  });

  Color _getStatusColor(int? yearsRemaining) {
    if (yearsRemaining == null) return Colors.grey;
    if (yearsRemaining <= 2) return Colors.red;
    if (yearsRemaining <= 5) return Colors.orange;
    if (yearsRemaining <= 10) return Colors.yellow.shade700;
    return Colors.green;
  }

  String _getStatusMessage(int? yearsRemaining) {
    if (yearsRemaining == null) return 'Unknown';
    if (yearsRemaining <= 2) return 'Critical';
    if (yearsRemaining <= 5) return 'Approaching';
    if (yearsRemaining <= 10) return 'Intermediate';
    return 'Long Term';
  }

  Widget _buildTimelineIndicator() {
    const totalWidth = 35; // Maximum years to show
    final yearsInService = serviceSummary.yearsInService ?? 0;
    final progress = yearsInService / totalWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Service Timeline',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$yearsInService/35 years',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Container(
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgeIndicator() {
    const totalWidth = 60; // Maximum age
    final currentAge = serviceSummary.currentAge ?? 0;
    final progress = currentAge / totalWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Age Progress',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '$currentAge/60 years',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[200],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Container(
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.secondaryColor,
                          AppTheme.secondaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRetirementCountdown() {
    final years = retirementInfo.yearsRemaining ?? 0;
    final color = _getStatusColor(years);
    final message = _getStatusMessage(years);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${years}y ${retirementInfo.monthsRemaining}m',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'until retirement',
            style: TextStyle(
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (retirementInfo.isRetired == true) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: const Column(
          children: [
            Icon(Icons.person_off, color: Colors.red, size: 48),
            SizedBox(height: 8),
            Text(
              'Retired',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildRetirementCountdown(),
        const SizedBox(height: 24),
        _buildTimelineIndicator(),
        const SizedBox(height: 16),
        _buildAgeIndicator(),
      ],
    );
  }
}
