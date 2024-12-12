import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';
import '../models/user.dart' as app_user;
import 'dart:math';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final BiometricService _biometricService = BiometricService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  String? _verificationId;
  String? _resendToken;
  String? _generatedOtp;

  bool _isLoading = false;
  app_user.User? _user;
  bool _rememberMe = false;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  app_user.User? get user => _user;
  bool get rememberMe => _rememberMe;
  String? get token => _user?.token;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> init() async {
    try {
      _rememberMe = await _biometricService.isRememberMeEnabled();

      final isBiometricEnabled = await _biometricService.getBiometricStatus();
      if (isBiometricEnabled) {
        final savedUser = await _storageService.getUser();
        if (savedUser != null && savedUser.email.isNotEmpty) {
          final isEmailRegistered =
              await _biometricService.isEmailRegistered(savedUser.email);
          if (isEmailRegistered) {
            if (_rememberMe) {
              final savedPassword =
                  await _biometricService.getSavedPassword(savedUser.email);
              if (savedPassword != null) {
                final authenticated =
                    await _biometricService.authenticateWithBiometrics();
                if (authenticated) {
                  await login(savedUser.email, savedPassword);
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error in init: $e');
    }
  }

  Future<Map<String, dynamic>?> getEmployeeById(String staffId) async {
    try {
      setLoading(true);
      final response = await _apiService.fetchEmployeeById(staffId);
      if (response['success']) {
        return response['data'];
      }
      return null;
    } finally {
      setLoading(false);
    }
  }

  Future<void> sendSMSOTP(String phoneNumber, String generatedOtp) async {
    try {
      _generatedOtp = generatedOtp;
      final formattedPhone = '+234${phoneNumber.substring(1)}';
      print('Sending OTP to: $formattedPhone'); // Debug log

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          print('Auto verification completed'); // Debug log
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}'); // Debug log
          throw e;
        },
        codeSent: (String verificationId, int? resendToken) {
          print('SMS sent, verification ID: $verificationId'); // Debug log
          _verificationId = verificationId;
          _resendToken = resendToken?.toString();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout'); // Debug log
        },
        forceResendingToken:
            _resendToken != null ? int.parse(_resendToken!) : null,
      );
    } catch (e) {
      print('Error in sendSMSOTP: $e'); // Debug log
      rethrow;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    try {
      if (_verificationId == null) {
        throw Exception('Verification ID not found');
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _firebaseAuth.signInWithCredential(credential);
      return true;
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }

  Future<void> sendEmailOTP(String email, String otp) async {
    try {
      final response = await _apiService.sendOTPEmail(email, otp);
      if (!response['success']) throw Exception(response['message']);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> updatePassword(
      String staffId, String otp, String newPassword) async {
    try {
      setLoading(true);
      final response =
          await _apiService.resetPassword(staffId, otp, newPassword);
      return response['success'] ?? false;
    } finally {
      setLoading(false);
    }
  }

  Future<Map<String, dynamic>> login(String email, String password,
      {String? deviceId}) async {
    try {
      setLoading(true);
      final response =
          await _apiService.login(email, password, deviceId: deviceId);

      if (response['success'] == true) {
        final token = response['token'];
        _apiService.setAuthToken(token);

        final user = app_user.User.fromJson(response['user'], token);
        await _storageService.saveUser(user);
        _user = user;

        print('Login successful for email: $email');

        await NotificationService.initialize();
        await NotificationService.setExternalUserId(user.id);

        if (_rememberMe) {
          print('Saving credentials for remember me...');
          await _biometricService.saveUserCredentials(email, password);
          await _biometricService.setRememberMe(true);
        } else {
          print('Saving email only...');
          await _biometricService.saveUserId(email);
        }
      }
      return response;
    } catch (e) {
      print('Error in login: $e');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      _apiService.clearAuthToken();
      final currentUser = await _storageService.getUser();

      await NotificationService.setExternalUserId('');

      if (currentUser != null && currentUser.email.isNotEmpty) {
        final isRememberMeEnabled =
            await _biometricService.isRememberMeEnabled();
        print('Remember me at logout: $isRememberMeEnabled');

        if (isRememberMeEnabled) {
          print('Keeping credentials for remember me: ${currentUser.email}');
        } else {
          print('Clearing password but keeping email: ${currentUser.email}');
          await _biometricService.clearUserData(currentUser.email);
          await _biometricService.saveUserId(currentUser.email);
        }
      }
      await _firebaseAuth.signOut();
      clearOTPData();

      await _storageService.clearUser();
      _user = null;
      notifyListeners();
    } catch (e) {
      print('Error in logout: $e');
    }
  }

  void clearOTPData() {
    _verificationId = null;
    _resendToken = null;
    _generatedOtp = null;
  }

  Future<String?> getSavedEmail() async {
    try {
      final currentUser = await _storageService.getUser();
      if (currentUser != null && currentUser.email.isNotEmpty) {
        return currentUser.email;
      }

      final emails = await _biometricService.getAllRegisteredEmails();
      if (emails.isNotEmpty) {
        return emails.first;
      }

      return null;
    } catch (e) {
      print('Error getting saved email: $e');
      return null;
    }
  }

  Future<String> generateOTP() async {
    // Generate a random 6-digit OTP
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    return otp;
  }

  Future<void> setRememberMe(bool value) async {
    try {
      _rememberMe = value;
      await _biometricService.setRememberMe(value);

      final currentUser = await _storageService.getUser();
      if (currentUser != null && currentUser.email.isNotEmpty) {
        if (value) {
          await _biometricService.saveUserId(currentUser.email);
        } else {
          await _biometricService.clearUserData(currentUser.email);
          await _biometricService.saveUserId(currentUser.email);
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error setting remember me: $e');
    }
  }

  String? get generatedOtp => _generatedOtp;
}
