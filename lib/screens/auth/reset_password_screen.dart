import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool btnLoading = false;
  String? token;
  bool _didLoadArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadArgs) return;
    _didLoadArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['token'] != null) {
      token = args['token'].toString();
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (token == null || token!.isEmpty) {
      _showDialog('Error', 'Reset token missing.');
      return;
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showDialog('Error', 'Both fields are required');
      return;
    }

    if (password != confirmPassword) {
      _showDialog('Error', 'Passwords do not match');
      return;
    }

    setState(() {
      btnLoading = true;
    });

    try {
      await ApiClient.dio.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'password': password,
        },
      );

      if (!mounted) return;

      await _showDialog('Success', 'Password reset successfully');
      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/');
    } catch (err) {
      String message = 'Failed to reset password';
      try {
        final data = (err as dynamic).response?.data;
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {}
      if (!mounted) return;
      _showDialog('Failed', message);
    } finally {
      if (mounted) {
        setState(() {
          btnLoading = false;
        });
      }
    }
  }

  Future<void> _showDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void goToLogin() {
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Reset Password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Enter your new password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  Text(
                    'New Password',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.16),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  Text(
                    'Confirm Password',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.16),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: btnLoading ? null : handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4338CA),
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.65),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        btnLoading ? 'Resetting...' : 'Reset Password',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Center(
                    child: GestureDetector(
                      onTap: goToLogin,
                      child: Text(
                        'Back to Login',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          decoration: TextDecoration.underline,
                          decorationColor:
                              Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}