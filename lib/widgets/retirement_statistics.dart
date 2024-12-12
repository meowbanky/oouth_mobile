// lib/widgets/retirement_statistics.dart
import 'package:flutter/material.dart';
import '../models/retirement_info.dart';
import '../models/service_summary.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class RetirementStatistics extends StatelessWidget {
  final RetirementInfo retirementInfo;
  final ServiceSummary serviceSummary;

  const RetirementStatistics({
    super.key,
    required this.retirementInfo,
    required this.serviceSummary,
  });

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Widget _buildStatCard(
      String title, String value, String subtitle, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final retirementDate =
        DateTime.parse(retirementInfo.retirementDate ?? now.toString());
    final totalWorkingDays = retirementDate.difference(now).inDays;
    final workingYears = totalWorkingDays ~/ 365;
    final workingMonths = (totalWorkingDays % 365) ~/ 30;
    final workingDays = totalWorkingDays % 30;

    return Column(
      children: [
        const Text(
          'Detailed Statistics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Service Duration',
              '${serviceSummary.yearsInService} years',
              'Total time in service',
              Icons.work,
            ),
            _buildStatCard(
              'Retirement Age',
              '60 years',
              'Maximum service age',
              Icons.person,
            ),
            _buildStatCard(
              'Working Days Left',
              '$workingDays days',
              '$workingYears years, $workingMonths months',
              Icons.calendar_today,
            ),
            _buildStatCard(
              'Pension Eligibility',
              (serviceSummary.yearsInService ?? 0) >= 10 ? 'Eligible' : 'Not Eligible',
              'Minimum 10 years required',
              Icons.account_balance_wallet,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Important Dates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildDateRow(
                    'Service Retirement', retirementInfo.serviceRetirementDate),
                _buildDateRow(
                    'Age Retirement', retirementInfo.ageRetirementDate),
                _buildDateRow(
                    'Actual Retirement', retirementInfo.retirementDate),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateRow(String label, String? date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            _formatDate(date),
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
