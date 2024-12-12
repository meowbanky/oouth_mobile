// lib/widgets/retirement_calculator.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class RetirementCalculator extends StatefulWidget {
  final double currentSalary;
  final int yearsRemaining;

  const RetirementCalculator({
    super.key,
    required this.currentSalary,
    required this.yearsRemaining,
  });

  @override
  State<RetirementCalculator> createState() => _RetirementCalculatorState();
}

class _RetirementCalculatorState extends State<RetirementCalculator> {
  final _formKey = GlobalKey<FormState>();
  double _annualSalaryIncrease = 3.0;
  double _savingsRate = 10.0;
  double _investmentReturn = 5.0;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '₦',
    decimalDigits: 0,
  );

  Widget _buildSlider({
    required String label,
    required double value,
    required void Function(double) onChanged,
    required String suffix,
    double min = 0,
    double max = 100,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$value$suffix',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: max.toInt(),
          label: '$value$suffix',
          onChanged: onChanged,
        ),
      ],
    );
  }

  Map<String, double> _calculateRetirement() {
    double currentSalary = widget.currentSalary;
    double totalSavings = 0;
    double finalSalary = currentSalary;
    double monthlyContributions = 0;

    for (int year = 0; year < widget.yearsRemaining; year++) {
      double yearlySavings = currentSalary * (_savingsRate / 100);
      totalSavings += yearlySavings;
      totalSavings *= (1 + _investmentReturn / 100);
      currentSalary *= (1 + _annualSalaryIncrease / 100);

      if (year == widget.yearsRemaining - 1) {
        finalSalary = currentSalary;
        monthlyContributions = yearlySavings / 12;
      }
    }

    // Calculate pension based on years of service
    // In _calculateRetirement() method of retirement_calculator.dart
// Change this line:
    double yearsOfService = widget.yearsRemaining.toDouble() +
        (DateTime.now().year -
            DateTime.now().year); // Add current years of service
    double pensionPercentage = yearsOfService >= 10
        ? 80
        : yearsOfService * 2; // 80% max or 2% per year
    double estimatedPension = finalSalary * (pensionPercentage / 100);

    return {
      'totalSavings': totalSavings,
      'finalSalary': finalSalary,
      'estimatedPension': estimatedPension,
      'monthlyContributions': monthlyContributions,
    };
  }

  Widget _buildInfoCard(String title, String value, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            _currencyFormat.format(value),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final calculations = _calculateRetirement();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Retirement Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Calculator Information'),
                        content: const SingleChildScrollView(
                          child: Text(
                            'This calculator provides an estimate based on:\n\n'
                            '• Current salary and expected increases\n'
                            '• Your monthly savings rate\n'
                            '• Expected return on investments\n'
                            '• Years until retirement\n\n'
                            'The pension calculation assumes a maximum of 80% '
                            'of your final salary for 35 years of service.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildInfoCard(
                  'Current Monthly Salary',
                  _currencyFormat.format(widget.currentSalary / 12),
                  'Base calculation amount',
                ),
                _buildInfoCard(
                  'Years Until Retirement',
                  '${widget.yearsRemaining} years',
                  'Time to plan and save',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Adjust Your Parameters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildSlider(
                    label: 'Annual Salary Increase',
                    value: _annualSalaryIncrease,
                    onChanged: (value) =>
                        setState(() => _annualSalaryIncrease = value),
                    suffix: '%',
                    max: 20,
                  ),
                  _buildSlider(
                    label: 'Monthly Savings Rate',
                    value: _savingsRate,
                    onChanged: (value) => setState(() => _savingsRate = value),
                    suffix: '%',
                    max: 50,
                  ),
                  _buildSlider(
                    label: 'Expected Investment Return',
                    value: _investmentReturn,
                    onChanged: (value) =>
                        setState(() => _investmentReturn = value),
                    suffix: '%',
                    max: 15,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Projected Results',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildResultRow(
                    'Final Monthly Salary',
                    calculations['finalSalary']! / 12,
                  ),
                  _buildResultRow(
                    'Total Savings',
                    calculations['totalSavings']!,
                  ),
                  _buildResultRow(
                    'Monthly Contributions',
                    calculations['monthlyContributions']!,
                  ),
                  const Divider(),
                  _buildResultRow(
                    'Estimated Monthly Pension',
                    calculations['estimatedPension']! / 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  // Add functionality to share or save results
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Save/Share functionality coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Share Results'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
