// lib/widgets/retirement_indicators.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/retirement_info.dart';
import '../models/service_summary.dart';
import 'package:intl/intl.dart';

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

  Widget _buildTimelineMilestone(String title, String date, bool isPast,
      {bool isLast = false}) {
    return Row(
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isPast ? AppTheme.primaryColor : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: isPast
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                color: isPast ? AppTheme.primaryColor : Colors.grey[300],
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPast ? Colors.black87 : Colors.grey[600],
                ),
              ),
              Text(
                date,
                style: TextStyle(
                  color: isPast ? Colors.black54 : Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
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
        child: Column(
          children: [
            const Icon(Icons.person_off, color: Colors.red, size: 48),
            const SizedBox(height: 8),
            const Text(
              'Retired',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Retirement Date: ${_formatDate(retirementInfo.retirementDate)}',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final empDate = DateTime.parse(retirementInfo.serviceRetirementDate!)
        .subtract(const Duration(days: 35 * 365));

    return Column(
      children: [
        // Stats Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Years in Service',
                '${serviceSummary.yearsInService}y',
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Current Age',
                '${serviceSummary.currentAge}y',
                AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Time to Retire',
                '${retirementInfo.yearsRemaining}y ${retirementInfo.monthsRemaining}m',
                _getStatusColor(retirementInfo.yearsRemaining),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Timeline
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Career Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildTimelineMilestone(
                'Employment Date',
                _formatDate(empDate.toString()),
                true,
              ),
              _buildTimelineMilestone(
                'Current Position',
                'Present',
                true,
              ),
              _buildTimelineMilestone(
                retirementInfo.retirementType ?? 'Retirement',
                _formatDate(retirementInfo.retirementDate),
                false,
                isLast: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Progress Bars
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Text(
                'Progress Tracking',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Service Progress',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${serviceSummary.yearsInService}/35 years',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: (serviceSummary.yearsInService ?? 0) / 35,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor),
                      minHeight: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Age Progress',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${serviceSummary.currentAge}/60 years',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: (serviceSummary.currentAge ?? 0) / 60,
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.secondaryColor),
                      minHeight: 24,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
