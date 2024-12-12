import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _rememberMeKey = 'remember_me';
  static const String _credentialsPrefix = 'credentials_';
  static const String _emailPrefix = 'email_';

  Future<bool> isBiometricsAvailable() async {
    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;

      print('Device supported: $isDeviceSupported'); // Debug
      print('Can check biometrics: $canCheckBiometrics'); // Debug

      if (!isDeviceSupported || !canCheckBiometrics) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('Available biometrics: $availableBiometrics'); // Debug

      return availableBiometrics.isNotEmpty;
    } catch (e) {
      print('Error checking biometrics: $e'); // Debug
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      print('Authentication error: $e'); // Debug
      return false;
    }
  }

  Future<bool> isEmailRegistered(String? email) async {
    if (email == null || email.isEmpty) {
      print('Null or empty email checked'); // Debug
      return false;
    }

    try {
      // Get biometric status first
      final biometricStatus = await getBiometricStatus();
      final value = await _secureStorage.read(key: '$_emailPrefix$email');

      print('Checking email registration:'); // Debug
      print('Email: $email'); // Debug
      print('Biometrics enabled: $biometricStatus'); // Debug
      print('Email stored: ${value != null}'); // Debug

      return biometricStatus && value != null;
    } catch (e) {
      print('Error checking email registration: $e'); // Debug
      return false;
    }
  }

  Future<bool> getBiometricStatus() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      print('Error checking biometric status: $e'); // Debug
      return false;
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _biometricEnabledKey,
        value: enabled.toString(),
      );
      print('Biometric enabled set to: $enabled'); // Debug
    } catch (e) {
      print('Error setting biometric status: $e'); // Debug
      throw Exception('Failed to set biometric status: $e');
    }
  }

  Future<void> saveUserId(String? email) async {
    if (email == null || email.isEmpty) {
      print('Cannot save null or empty email'); // Debug
      return;
    }

    try {
      await _secureStorage.write(
        key: '$_emailPrefix$email',
        value: email,
      );
      print('Email saved for biometrics: $email'); // Debug
    } catch (e) {
      print('Error saving email: $e'); // Debug
      throw Exception('Failed to save email: $e');
    }
  }

  Future<void> savePassword(String email, String password) async {
    try {
      // Construct a unique key for the password using the email
      final passwordKey = 'password_$email';

      // Save the password securely
      await _secureStorage.write(key: passwordKey, value: password);

      print('Password saved for email: $email'); // Debug
    } catch (e) {
      print('Error saving password: $e'); // Debug
      throw Exception('Failed to save password: $e');
    }
  }

Future<String?> getPassword(String email) async {
    try {
      // Construct the key for the password using the email
      final passwordKey = 'password_$email';

      // Retrieve the password securely
      final password = await _secureStorage.read(key: passwordKey);

      if (password != null) {
        print('Password retrieved for email: $email'); // Debug
      } else {
        print('No password found for email: $email'); // Debug
      }

      return password;
    } catch (e) {
      print('Error retrieving password: $e'); // Debug
      throw Exception('Failed to retrieve password: $e');
    }
  }


  Future<String?> getSavedPassword(String? email) async {
    if (email == null || email.isEmpty) return null;

    try {
      return await _secureStorage.read(key: '$_credentialsPrefix$email');
    } catch (e) {
      print('Error getting password: $e'); // Debug
      return null;
    }
  }

  Future<void> saveUserCredentials(String email, String password) async {
    try {
      await saveUserId(email);
      await _secureStorage.write(
        key: '$_credentialsPrefix$email',
        value: password,
      );
      print('Credentials saved for: $email'); // Debug
    } catch (e) {
      print('Error saving credentials: $e'); // Debug
      throw Exception('Failed to save credentials: $e');
    }
  }

  Future<void> setRememberMe(bool enabled) async {
    try {
      await _secureStorage.write(
        key: _rememberMeKey,
        value: enabled.toString(),
      );
      print('Remember me set to: $enabled'); // Debug
    } catch (e) {
      print('Error setting remember me: $e'); // Debug
      throw Exception('Failed to set remember me: $e');
    }
  }

  Future<bool> isRememberMeEnabled() async {
    try {
      final value = await _secureStorage.read(key: _rememberMeKey);
      return value == 'true';
    } catch (e) {
      print('Error checking remember me status: $e'); // Debug
      return false;
    }
  }

  Future<List<String>> getAllRegisteredEmails() async {
    try {
      final allData = await _secureStorage.readAll();
      final emails = allData.entries
          .where((entry) => entry.key.startsWith(_emailPrefix))
          .map((entry) => entry.value)
          .where((email) => email.isNotEmpty)
          .toList();

      print('Found registered emails: $emails'); // Debug
      return emails;
    } catch (e) {
      print('Error getting registered emails: $e'); // Debug
      return [];
    }
  }

Future<String?> getSavedEmail() async {
    try {
      final savedEmail = await _secureStorage.read(key: 'savedEmail');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        print('Retrieved saved email: $savedEmail'); // Debug
        return savedEmail;
      } else {
        print('No email found in storage.'); // Debug
        return null;
      }
    } catch (e) {
      print('Error retrieving saved email: $e'); // Debug
      return null;
    }
  }

  Future<void> clearUserData(String email) async {
    try {
      await _secureStorage.delete(key: '$_credentialsPrefix$email');
      print('User data cleared for: $email'); // Debug
    } catch (e) {
      print('Error clearing user data: $e'); // Debug
      throw Exception('Failed to clear user data: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      print('All secure storage cleared'); // Debug
    } catch (e) {
      print('Error clearing all data: $e'); // Debug
      throw Exception('Failed to clear all data: $e');
    }
  }
}
