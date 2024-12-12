import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../services/biometric_service.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _biometricService = BiometricService();

  bool _obscurePassword = true;
  bool _isFirstSubmit = false;
  bool _rememberMe = false;
  bool _biometricsAvailable = false;
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _loadSavedState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final isAvailable = await _biometricService.isBiometricsAvailable();
      final isEnabled = await _biometricService.getBiometricStatus();
      final email = _emailController.text.trim();

      if (mounted) {
        final isEmailRegistered =
            await _biometricService.isEmailRegistered(email);
        setState(() {
          _biometricsAvailable = isAvailable;
          _showBiometricButton = isAvailable && isEnabled && isEmailRegistered;
        });
      }
    } catch (e) {
      print('Error checking biometrics: $e');
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isRememberMe = await _biometricService.isRememberMeEnabled();
      final savedEmail = await authProvider.getSavedEmail();

      if (mounted) {
        setState(() {
          _rememberMe = isRememberMe;
          if (savedEmail != null) {
            _emailController.text = savedEmail;
          }
        });

        await _checkBiometrics();

        if (isRememberMe && savedEmail != null) {
          final savedPassword =
              await _biometricService.getSavedPassword(savedEmail);
          if (savedPassword != null && mounted) {
            setState(() {
              _passwordController.text = savedPassword;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading saved state: $e');
    }
  }

  Future<void> _showBiometricPrompt() async {
    try {
      final authenticated =
          await _biometricService.authenticateWithBiometrics();
      if (authenticated && mounted) {
        _handleLogin(useBiometric: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLogin({bool useBiometric = false}) async {
    setState(() => _isFirstSubmit = true);

    if (!useBiometric && !_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      final String email;
      final String password;
      if (useBiometric) {
        email = await authProvider.getSavedEmail() ?? '';
        password = await _biometricService.getPassword(email) ?? '';
      } else {
        email = _emailController.text.trim();
        password = _passwordController.text.trim();
      }

      // Get OneSignal Device ID
      String? deviceId;
      try {
        deviceId = OneSignal.User.pushSubscription.id;
        print('OneSignal Device ID: $deviceId');
      } catch (e) {
        print('Error getting OneSignal Device ID: $e');
      }

      final response =
          await authProvider.login(email, password, deviceId: deviceId);

      if (!mounted) return;

      if (response['success'] == true) {
        _showSuccessSnackBar('Login successful! Welcome back.');

        if (!useBiometric) {
          final biometricsAvailable =
              await _biometricService.isBiometricsAvailable();
          final isEmailRegistered =
              await _biometricService.isEmailRegistered(email);

          if (biometricsAvailable && !isEmailRegistered) {
            final shouldEnableBiometric = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Enable Fingerprint Login'),
                content: const Text(
                    'Would you like to enable fingerprint login for faster access next time?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );

            if (shouldEnableBiometric ?? false) {
              await _biometricService.setBiometricEnabled(true);
              await _biometricService.savePassword(email, password);
              await _biometricService.saveUserId(email);
              setState(() => _showBiometricButton = true);
            }
          }

          if (_rememberMe) {
            await authProvider.setRememberMe(true);
            await _biometricService.saveUserCredentials(email, password);
          } else {
            await authProvider.setRememberMe(false);
          }
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } else {
        _showErrorSnackBar(
            response['message'] ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      String errorMessage =
          'An unexpected error occurred. Please try again later.';
      if (e.toString().contains('Connection error')) {
        errorMessage =
            'Unable to connect to server. Please check your internet connection.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout. Please try again.';
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _isFirstSubmit
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      Hero(
                        tag: 'oouth_logo',
                        child: Image.asset(
                          'assets/images/oouth_logo.png',
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'OLABISI ONABANJO UNIVERSITY',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        'TEACHING HOSPITAL',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 40),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Login',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (_showBiometricButton) ...[
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.fingerprint,
                                        size: 35,
                                      ),
                                      onPressed: () {
                                        print(
                                            'Fingerprint button pressed'); // Debug print
                                        _showBiometricPrompt();
                                      },
                                      tooltip: 'Login with fingerprint',
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email_outlined),
                                hintText: 'Enter your email address',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                hintText: 'Enter your password',
                                filled: true,
                                fillColor: Colors.grey[50],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        print(
                                            'Remember me changed to: $value'); // Debug print
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                      activeColor: AppTheme.primaryColor,
                                    ),
                                    const Text('Remember me'),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                  ),
                                  child: const Text('Forgot Password?'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SpinKitThreeBounce(
                                        color: Colors.white,
                                        size: 24,
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              // Handle registration
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                            ),
                            child: const Text('Register'),
                          ),
                        ],
                      ),
                      if (_biometricsAvailable && !_showBiometricButton)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'Biometric login will be available after first successful login',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
