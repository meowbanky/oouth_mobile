// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../models/profile.dart';
import '../models/approval_status.dart';
import '../services/api_service.dart';
import '../widgets/retirement_indicators.dart';
import '../widgets/retirement_calculator.dart';
import '../widgets/approval_status_banner.dart';
import 'edit_profile_screen.dart';
import 'dart:async'; // Add this import for Timer

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Profile? _profile;
  ApprovalStatus? _approvalStatus;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      apiService.setAuthToken(authProvider.token ?? '');

      final results = await Future.wait([
        apiService.getProfile(authProvider.user?.id ?? ''),
        apiService.getApprovalStatus(authProvider.user?.id ?? ''),
      ]);

      if (mounted) {
        final approvalData = results[1] as Map<String, dynamic>;
        final statusData = approvalData['status'] as Map<String, dynamic>;

        setState(() {
          _profile = results[0] as Profile;
          // Only set approval status if status is explicitly 'pending'
          _approvalStatus = statusData['status'] == 'pending'
              ? ApprovalStatus.fromJson(approvalData)
              : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _loadProfile: $e'); // Add debug print
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Timer? _refreshTimer;

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    if (_approvalStatus?.isPending ?? false) {
      _refreshTimer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _loadProfile(),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Profile not available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadProfile,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  bool _validateProfileData() {
    if (_profile == null) return false;

    if (_profile!.ppno == null || _profile!.ppno!.isEmpty) {
      _handleError('Invalid profile data: PP Number is missing');
      return false;
    }

    if (_profile!.name == null || _profile!.name!.isEmpty) {
      _handleError('Invalid profile data: Name is missing');
      return false;
    }

    return true;
  }

  int _retryCount = 0;
  Future<void> _retryLoadProfile() async {
    if (_retryCount >= 3) {
      _handleError('Failed to load profile after multiple attempts');
      return;
    }

    _retryCount++;
    await Future.delayed(Duration(seconds: _retryCount * 2));
    _loadProfile();
  }

  void _handleError(dynamic error) {
    String message = 'An error occurred';

    if (error.toString().contains('token')) {
      message = 'Your session has expired. Please login again.';
      // Handle token expiration
      Future.delayed(Duration.zero, () {
        context.read<AuthProvider>().logout().then((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      });
    } else if (error.toString().contains('Connection')) {
      message = 'Please check your internet connection';
    }

    setState(() {
      _error = message;
      _isLoading = false;
    });
  }

  Future<void> _cancelPendingChanges() async {
    try {
      setState(() {
        _isLoading = true; // Show loading state
      });

      final authProvider = context.read<AuthProvider>();
      final apiService = ApiService();
      apiService.setAuthToken(authProvider.token ?? '');

      // Cancel the changes
      await apiService.cancelPendingChanges(authProvider.user?.id ?? '');

      if (mounted) {
        // Explicitly clear both statuses
        setState(() {
          _approvalStatus = null;
          _profile = _profile?.copyWith(
            staffId: _profile?.staffId,
            pendingStatus: null,
          );
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pending changes cancelled'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );

        // Load fresh data
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Widget _buildProfileItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildBasicInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              _profile?.name?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildProfileItem('PP Number', _profile?.ppno),
          _buildProfileItem('Full Name', _profile?.name),
          _buildProfileItem('Email', _profile?.email),
          _buildProfileItem('Gender', _profile?.gender),
          _buildProfileItem('Employment Date', _formatDate(_profile?.empDate)),
          _buildProfileItem('Date of Birth', _formatDate(_profile?.dob)),
          _buildProfileItem(
              'Date of First Appointment', _formatDate(_profile?.dopa)),
          _buildProfileItem('Date of Confirmation', _formatDate(_profile?.doc)),
          _buildProfileItem('Local Government', _profile?.lgOrigin),
          _buildProfileItem('State of Origin', _profile?.sOrigin),
          _buildProfileItem('Department', _profile?.department),
          _buildProfileItem('Level/Appointment', _profile?.levelApt),
        ],
      ),
    );
  }

  Widget _buildQualificationsSection() {
    if (_profile?.qualifications.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Qualifications',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _profile!.qualifications.length,
            itemBuilder: (context, index) {
              final qualification = _profile!.qualifications[index];
              return Card(
                elevation: 0,
                color: Colors.grey[50],
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qualification.qualification,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (qualification.field != null)
                        Text(
                          qualification.field!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (qualification.institution != null)
                        Text(
                          qualification.institution!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      if (qualification.yearObtained != null)
                        Text(
                          'Year: ${qualification.yearObtained}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementInfo() {
    final retirement = _profile?.retirementInfo;
    final service = _profile?.serviceSummary;

    if (retirement == null || service == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Retirement Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const Divider(),
          RetirementProgress(
            retirementInfo: retirement,
            serviceSummary: service,
          ),
          const SizedBox(height: 24),
          Text(
            'Additional Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          _buildRetirementDetail('Expected Retirement Date',
              _formatDate(retirement.retirementDate)),
          _buildRetirementDetail(
              'Retirement Type', retirement.retirementType ?? 'N/A'),
          _buildRetirementDetail('Service Retirement Date',
              _formatDate(retirement.serviceRetirementDate)),
          _buildRetirementDetail(
              'Age Retirement Date', _formatDate(retirement.ageRetirementDate)),
          if (!retirement.isRetired!) ...[
            const SizedBox(height: 24),
            _buildSalaryInfo(),
            const SizedBox(height: 24),
            RetirementCalculator(
              currentSalary:
                  _profile?.annualSalary ?? (_profile?.monthlySalary ?? 0) * 12,
              yearsRemaining: retirement.yearsRemaining ?? 0,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSalaryInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Salary Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Salary:'),
              Text(
                NumberFormat.currency(
                  symbol: '₦',
                  decimalDigits: 2,
                ).format(_profile?.monthlySalary ?? 0),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Annual Salary:'),
              Text(
                NumberFormat.currency(
                  symbol: '₦',
                  decimalDigits: 2,
                ).format(_profile?.annualSalary ??
                    (_profile?.monthlySalary ?? 0) * 12),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetirementDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'My Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_profile != null &&
              (_approvalStatus == null || !_approvalStatus!.isPending))
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(profile: _profile!),
                  ),
                ).then((edited) {
                  if (edited == true) {
                    _loadProfile();
                  }
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppTheme.primaryColor,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_approvalStatus != null &&
                            _approvalStatus!.status == 'pending')
                          ApprovalStatusBanner(
                            status: _approvalStatus!,
                            onCancel: _approvalStatus!.isPending
                                ? _cancelPendingChanges
                                : null,
                          ),
                        _buildBasicInfo(),
                        const SizedBox(height: 16),
                        _buildRetirementInfo(),
                        const SizedBox(height: 16),
                        _buildQualificationsSection(),
                      ],
                    ),
                  ),
                ),
    );
  }
}
