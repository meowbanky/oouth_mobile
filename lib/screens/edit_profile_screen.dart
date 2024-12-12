// lib/screens/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../models/profile_changes.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  final Profile profile;

  const EditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _hasChanges = false;

  // Form Controllers
  late TextEditingController _ppnoController;
  late TextEditingController _empDateController;
  late TextEditingController _dobController;
  late TextEditingController _docController;
  late TextEditingController _levelAptController;
  late TextEditingController _lgOriginController;
  late TextEditingController _sOriginController;

  // Selected Values
  String? _selectedGender;
  DateTime? _selectedEmpDate;
  DateTime? _selectedDob;
  DateTime? _selectedDoc;

  // Qualifications
  List<Map<String, dynamic>> _qualifications = [];
  List<Map<String, dynamic>> _availableQualifications = [];
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadDepartments().then((_) {
      if (widget.profile.department != null && mounted) {
        setState(() {
          for (var dept in _departments) {
            if (dept['dept'].toString() == widget.profile.department) {
              _selectedDepartment = dept['dept_id'].toString();
              print(
                  'Found matching department: ${dept['dept_id']}'); // Debug print
              break;
            }
          }
        });
      }
    });
    _initializeQualifications();
    _loadQualifications();
  }

  Future<void> _loadDepartments() async {
    try {
      final apiService = ApiService();
      final authProvider = context.read<AuthProvider>();
      apiService.setAuthToken(authProvider.token ?? '');
      final departments = await apiService.getDepartments();

      print('Current department: $_selectedDepartment'); // Debug print
      print('Available departments: $departments'); // Debug print

      if (mounted) {
        setState(() {
          _departments = departments;
          // Check if current department exists in loaded departments
          if (_selectedDepartment != null) {
            final exists = departments.any((dept) =>
                dept['dept_id'].toString() == _selectedDepartment ||
                dept['dept'].toString() == _selectedDepartment);
            if (!exists) {
              _selectedDepartment = null;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  Future<void> _loadQualifications() async {
    try {
      final apiService = ApiService();
      final authProvider = context.read<AuthProvider>();
      apiService.setAuthToken(authProvider.token ?? '');
      final qualifications = await apiService.getQualifications();
      setState(() {
        _availableQualifications = qualifications;
      });
    } catch (e) {
      print('Error loading qualifications: $e');
    }
  }

  void _initializeControllers() {
    _selectedDepartment = null;

    _ppnoController = TextEditingController(text: widget.profile.ppno);
    _empDateController =
        TextEditingController(text: _formatDisplayDate(widget.profile.empDate));
    _dobController =
        TextEditingController(text: _formatDisplayDate(widget.profile.dob));
    _docController =
        TextEditingController(text: _formatDisplayDate(widget.profile.doc));
    _levelAptController = TextEditingController(text: widget.profile.levelApt);
    _lgOriginController = TextEditingController(text: widget.profile.lgOrigin);
    _sOriginController = TextEditingController(text: widget.profile.sOrigin);

    _selectedGender = widget.profile.gender;
    _selectedEmpDate = _parseDate(widget.profile.empDate);
    _selectedDob = _parseDate(widget.profile.dob);
    _selectedDoc = _parseDate(widget.profile.doc);

    // Add listeners
    _ppnoController.addListener(_onFieldChanged);
    _levelAptController.addListener(_onFieldChanged);
    _lgOriginController.addListener(_onFieldChanged);
    _sOriginController.addListener(_onFieldChanged);

    if (widget.profile.department != null) {
      // Extract department ID if it's in "id - name" format
      final deptParts = widget.profile.department!.split(' - ');
      _selectedDepartment = deptParts.first.trim();
      print('Initialized department: $_selectedDepartment'); // Debug print
    }
  }

  void _initializeQualifications() {
    _qualifications = widget.profile.qualifications.map((qual) {
      return {
        'id': qual.id,
        'qualification': qual.qualification,
        'field': qual.field,
        'institution': qual.institution,
        'yearObtained': qual.yearObtained,
        'isNew': false,
        'isDeleted': false,
        'isModified': false,
      };
    }).toList();
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  String _formatDisplayDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  String _formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _selectDate(BuildContext context, String field) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        switch (field) {
          case 'empDate':
            _selectedEmpDate = picked;
            _empDateController.text = DateFormat('dd-MM-yyyy').format(picked);
            break;
          case 'dob':
            _selectedDob = picked;
            _dobController.text = DateFormat('dd-MM-yyyy').format(picked);
            break;
          case 'doc':
            _selectedDoc = picked;
            _docController.text = DateFormat('dd-MM-yyyy').format(picked);
            break;
        }
        _hasChanges = true;
      });
    }
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSubmitting = true);

      final apiService = ApiService();
      final authProvider = context.read<AuthProvider>();

      // Get the user ID from the token
      final userId = int.parse(authProvider.user?.id ?? '0');
      if (userId == 0) {
        throw Exception('User ID not found');
      }

      apiService.setAuthToken(authProvider.token ?? '');

      // Prepare profile changes
      final Map<String, dynamic> profileChanges = {
        'PPNO': _ppnoController.text,
        'GENDER': _selectedGender,
        'EMPDATE':
            _selectedEmpDate != null ? _formatApiDate(_selectedEmpDate!) : null,
        'DOB': _selectedDob != null ? _formatApiDate(_selectedDob!) : null,
        'DOC': _selectedDoc != null ? _formatApiDate(_selectedDoc!) : null,
        'LEVE_APT': _levelAptController.text,
        'LG_ORIGIN': _lgOriginController.text,
        'DEPTCD': _selectedDepartment,
        'S_ORIGIN': _sOriginController.text,
      };

      final qualificationChanges = _qualifications
          .where((qual) =>
              qual['isNew'] || qual['isModified'] || qual['isDeleted'])
          .map((qual) {
        final changeType = qual['isNew']
            ? 'add'
            : qual['isDeleted']
                ? 'delete'
                : 'edit';

        return QualificationChange(
          id: qual['id'],
          changeType: changeType,
          data: {
            'qua_id': qual['selectedQualificationId'],
            'field': qual['field'],
            'institution': qual['institution'],
            'yearObtained': qual['yearObtained'],
          },
        );
      }).toList();

      // Debug prints
      print('User ID: $userId');
      print('Profile Changes: $profileChanges');
      print('Selected Department: $_selectedDepartment');

      // Create ProfileChanges object
      final changes = ProfileChanges(
        staffId: userId,
        profileChanges: profileChanges,
        qualificationChanges: qualificationChanges,
        submittedBy: userId,
        status: 'pending',
      );

      await apiService.submitProfileChanges(changes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your changes have been submitted for approval'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error details: $e'); // Detailed error logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: const Text(
            'Edit Profile',
            style: TextStyle(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_hasChanges) {
                _onWillPop().then((canPop) {
                  if (canPop) Navigator.pop(context);
                });
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoCard(),
                const SizedBox(height: 16),
                _buildQualificationsCard(),
                const SizedBox(height: 24),
                if (_hasChanges) _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Submit Changes for Approval',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            const SizedBox(height: 16),
            // PP Number
            TextFormField(
              controller: _ppnoController,
              decoration: const InputDecoration(
                labelText: 'PP Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'PP Number is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Gender Dropdown
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              items: ['Male', 'Female'].map((String gender) {
                return DropdownMenuItem<String>(
                  value: gender,
                  child: Text(gender),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGender = newValue;
                  _hasChanges = true;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Gender is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Employment Date
            TextFormField(
              controller: _empDateController,
              decoration: InputDecoration(
                labelText: 'Employment Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, 'empDate'),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Employment date is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Date of Birth
            TextFormField(
              controller: _dobController,
              decoration: InputDecoration(
                labelText: 'Date of Birth',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, 'dob'),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Date of birth is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Date of Confirmation
            TextFormField(
              controller: _docController,
              decoration: InputDecoration(
                labelText: 'Date of Confirmation',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, 'doc'),
                ),
              ),
              readOnly: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Date of confirmation is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Level/Appointment
            TextFormField(
              controller: _levelAptController,
              decoration: const InputDecoration(
                labelText: 'Level/Appointment',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Level/Appointment is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_departments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedDepartment,
                isExpanded: true,
                hint: const Text('Select Department'),
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                ),
                items: _departments.map((dept) {
                  final deptId = dept['dept_id'].toString();
                  final deptName = dept['dept'].toString();
                  return DropdownMenuItem<String>(
                    value: deptId,
                    child: Text(deptName),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  print('Selected department: $newValue'); // Debug print
                  setState(() {
                    _selectedDepartment = newValue;
                    _hasChanges = true;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Department is required';
                  }
                  return null;
                },
              ),
            // Local Government
            const SizedBox(height: 16),
            TextFormField(
              controller: _lgOriginController,
              decoration: const InputDecoration(
                labelText: 'Local Government of Origin',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Local Government is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // State
            TextFormField(
              controller: _sOriginController,
              decoration: const InputDecoration(
                labelText: 'State of Origin',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'State is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Qualifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    setState(() {
                      _qualifications.add({
                        'id': null,
                        'selectedQualificationId': null,
                        'field': '',
                        'institution': '',
                        'yearObtained': DateTime.now().year.toString(),
                        'isNew': true,
                        'isDeleted': false,
                        'isModified': false,
                      });
                      _hasChanges = true;
                    });
                  },
                ),
              ],
            ),
            const Divider(),
            if (_availableQualifications.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _qualifications.length,
                itemBuilder: (context, index) {
                  final qual = _qualifications[index];
                  if (qual['isDeleted']) return const SizedBox.shrink();

                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Qualification ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                onPressed: () {
                                  setState(() {
                                    if (qual['isNew']) {
                                      _qualifications.removeAt(index);
                                    } else {
                                      qual['isDeleted'] = true;
                                    }
                                    _hasChanges = true;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Qualification Dropdown
                          DropdownButtonFormField<int>(
                            value: qual['selectedQualificationId'],
                            decoration: const InputDecoration(
                              labelText: 'Qualification Type',
                              border: OutlineInputBorder(),
                            ),
                            items: _availableQualifications
                                .map((q) => DropdownMenuItem<int>(
                                      value: q['id'] as int,
                                      child: Text(q['quaification'] as String),
                                    ))
                                .toList(),
                            onChanged: (int? newValue) {
                              setState(() {
                                qual['selectedQualificationId'] = newValue;
                                if (!qual['isNew']) {
                                  qual['isModified'] = true;
                                }
                                _hasChanges = true;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a qualification';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          // Field of Study
                          TextFormField(
                            initialValue: qual['field'],
                            decoration: const InputDecoration(
                              labelText: 'Field of Study',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                qual['field'] = value;
                                if (!qual['isNew']) {
                                  qual['isModified'] = true;
                                }
                                _hasChanges = true;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // Institution
                          TextFormField(
                            initialValue: qual['institution'],
                            decoration: const InputDecoration(
                              labelText: 'Institution',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                qual['institution'] = value;
                                if (!qual['isNew']) {
                                  qual['isModified'] = true;
                                }
                                _hasChanges = true;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          // Year Obtained
                          TextFormField(
                            initialValue: qual['yearObtained'].toString(),
                            decoration: const InputDecoration(
                              labelText: 'Year Obtained',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                qual['yearObtained'] = value;
                                if (!qual['isNew']) {
                                  qual['isModified'] = true;
                                }
                                _hasChanges = true;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Year is required';
                              }
                              final year = int.tryParse(value);
                              if (year == null ||
                                  year < 1950 ||
                                  year > DateTime.now().year) {
                                return 'Enter a valid year';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
