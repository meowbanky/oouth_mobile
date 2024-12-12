// lib/services/api_service.dart

import 'package:dio/dio.dart';
import '../models/profile.dart';
import '../models/profile_changes.dart';
import '../models/pending_profile_status.dart';

class ApiService {
  late final Dio dio;
  static const String baseUrl = 'https://oouthsalary.com.ng/auth_api';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        return status! < 500;
      },
    ));
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      requestHeader: true,
      responseHeader: true,
    ));
  }

  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final response = await dio.get('/api/departments/get_departments.php');

      print('Departments API Response: ${response.data}'); // Debug print

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          final List<Map<String, dynamic>> departments =
              List<Map<String, dynamic>>.from(response.data['data']);
          print('Parsed departments: $departments'); // Debug print
          return departments;
        }
        throw Exception(
            response.data['message'] ?? 'Failed to load departments');
      } else {
        throw Exception(
            'Failed to load departments: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error getting departments: $e');
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to load departments');
      }
      throw Exception('Connection error while loading departments');
    }
  }

  Future<Map<String, dynamic>> fetchEmployeeById(String staffId) async {
    try {
      final response = await dio.get(
        '/api/auth/get_employee.php',
        queryParameters: {'staff_id': staffId},
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch employee details');
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Connection error. Please try again.';
    }
  }

  Future<Map<String, dynamic>> sendOTPEmail(String email, String otp) async {
    try {
      final response = await dio.post(
        '/api/auth/send_otp.php',
        data: {
          'email': email,
          'otp': otp,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Failed to send OTP email';
    }
  }

  Future<Map<String, dynamic>> resetPassword(
    String staffId,
    String otp,
    String newPassword,
  ) async {
    try {
      final response = await dio.post(
        '/api/auth/reset_password.php',
        data: {
          'staff_id': staffId,
          'otp': otp,
          'new_password': newPassword,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Failed to reset password';
    }
  }
  
// In your ApiService class
  Future<Map<String, dynamic>> getApprovalStatus(String staffId) async {
    try {
      final response = await dio.get(
        '/api/profile/get_approval_status.php',
        queryParameters: {'staff_id': staffId},
      );

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return response.data['data'];
        }
        throw Exception(
            response.data['message'] ?? 'Failed to get approval status');
      } else {
        throw Exception(
            'Failed to get approval status: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error getting approval status: $e');
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to get approval status');
      }
      throw Exception('Connection error while getting approval status');
    }
  }

  // Existing getProfile method - unchanged
  Future<Profile> getProfile(String staffId) async {
    try {
      final profileResponse =
          await dio.get('/api/profile/get_profile.php?staff_id=$staffId');
      final salaryResponse =
          await dio.get('/api/profile/get_salary_info.php?staff_id=$staffId');

      print('Profile API Response: ${profileResponse.data}');
      print('Salary API Response: ${salaryResponse.data}');

      if (profileResponse.statusCode == 200) {
        if (profileResponse.data['data'] != null) {
          var profileData = profileResponse.data['data'];

          if (salaryResponse.statusCode == 200 &&
              salaryResponse.data['data'] != null) {
            profileData['monthly_salary'] =
                salaryResponse.data['data']['monthly_salary'];
            profileData['annual_salary'] =
                salaryResponse.data['data']['annual_salary'];
          }

          final profile = Profile.fromJson(profileData);

          print('Retirement Info: ${profile.retirementInfo}');
          print('Service Summary: ${profile.serviceSummary}');
          print(
              'Salary Info - Monthly: ${profile.monthlySalary}, Annual: ${profile.annualSalary}');

          return profile;
        } else {
          throw Exception('Profile data is null');
        }
      } else {
        throw Exception(
            'Failed to load profile: ${profileResponse.statusMessage}');
      }
    } catch (e) {
      print('Error fetching profile or salary: $e');
      throw Exception('Failed to load profile: $e');
    }
  }

  // New method to submit profile changes
  Future<void> submitProfileChanges(ProfileChanges changes) async {
    try {
      final response = await dio.post(
        '/api/profile/submit_changes.php',
        data: changes.toJson(),
      );

      print('Submit changes response: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data['success'] != true) {
          throw Exception(
              response.data['message'] ?? 'Failed to submit changes');
        }
      } else {
        throw Exception('Failed to submit changes: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error submitting profile changes: $e');
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to submit changes');
      }
      throw Exception('Connection error while submitting changes');
    }
  }

  Future<List<Map<String, dynamic>>> getQualifications() async {
    try {
      final response =
          await dio.get('/api/qualifications/get_qualifications.php');

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          return List<Map<String, dynamic>>.from(response.data['data']);
        }
        throw Exception(
            response.data['message'] ?? 'Failed to load qualifications');
      } else {
        throw Exception(
            'Failed to load qualifications: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error getting qualifications: $e');
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to load qualifications');
      }
      throw Exception('Connection error while loading qualifications');
    }
  }

  // Get pending changes status
  Future<PendingProfileStatus?> getPendingChangesStatus(String staffId) async {
    try {
      final response = await dio.get(
        '/api/profile/pending_changes.php',
        queryParameters: {'staff_id': staffId},
      );

      print('Pending changes response: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data['success'] == true && response.data['data'] != null) {
          return PendingProfileStatus.fromJson(response.data['data']);
        }
        return null;
      } else {
        throw Exception(
            'Failed to get pending changes: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error getting pending changes: $e');
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to get pending changes');
      }
      throw Exception('Connection error while getting pending changes');
    }
  }

  // Cancel pending changes
  Future<void> cancelPendingChanges(String staffId) async {
    try {
      final response = await dio.post(
        '/api/profile/cancel_changes.php',
        data: {'staff_id': staffId},
      );

      print('Cancel changes response: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data['success'] != true) {
          throw Exception(
              response.data['message'] ?? 'Failed to cancel changes');
        }
      } else {
        throw Exception('Failed to cancel changes: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      print('Error canceling changes: $e');
      if (e.response != null) {
        throw Exception(
            e.response?.data['message'] ?? 'Failed to cancel changes');
      }
      throw Exception('Connection error while canceling changes');
    }
  }

  // Existing login method - unchanged
  Future<Map<String, dynamic>> login(String email, String password,
      {String? deviceId}) async {
    try {
      final response = await dio.post(
        '/api/auth/login.php',
        data: {
          'email': email,
          'password': password,
          if (deviceId != null) 'device_id': deviceId,
        },
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!.data;
      }
      throw 'Connection error. Please try again.';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }
}
