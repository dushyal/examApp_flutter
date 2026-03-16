import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool otpSent = false;
  bool showPassword = false;
  bool showConfirmPassword = false;
  int timer = 0;
  bool btnLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final node in otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void startTimer() {
    Future.doWhile(() async {
      if (!mounted || timer <= 0) return false;

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return false;

      setState(() {
        timer -= 1;
      });

      return timer > 0;
    });
  }

  void handleOtpChange(String value, int idx) {
    if (!RegExp(r'^\d*$').hasMatch(value)) return;

    if (value.isNotEmpty) {
      final digit = value[value.length - 1];
      otpControllers[idx].text = digit;
      otpControllers[idx].selection = TextSelection.collapsed(
        offset: otpControllers[idx].text.length,
      );

      if (idx < 5) {
        FocusScope.of(context).requestFocus(otpFocusNodes[idx + 1]);
      }
    } else {
      otpControllers[idx].clear();
    }
  }

  void handleOtpBackspace(String value, int idx) {
    if (value.isEmpty && idx > 0) {
      FocusScope.of(context).requestFocus(otpFocusNodes[idx - 1]);
    }
  }

  Future<void> handleSendOtp() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showToast('Email required');
      return;
    }

    setState(() {
      btnLoading = true;
    });

    try {
      final res = await ApiClient.dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      showToast(res.data?['message']?.toString() ?? 'OTP sent');

      if (!mounted) return;

      setState(() {
        otpSent = true;
        timer = 300;
      });

      startTimer();
    } catch (err) {
      String message = 'Failed to send OTP';
      try {
        final data = (err as dynamic).response?.data;
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {}
      showToast(message);
    } finally {
      if (mounted) {
        setState(() {
          btnLoading = false;
        });
      }
    }
  }

  Future<void> handleResendOtp() async {
    final email = emailController.text.trim();

    try {
      await ApiClient.dio.post(
        '/auth/resend',
        data: {'email': email},
      );

      showToast('OTP resent successfully');

      for (final controller in otpControllers) {
        controller.clear();
      }

      if (!mounted) return;

      setState(() {
        timer = 300;
      });

      FocusScope.of(context).requestFocus(otpFocusNodes[0]);
      startTimer();
    } catch (err) {
      String message = 'Failed to resend OTP';
      try {
        final data = (err as dynamic).response?.data;
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {}
      showToast(message);
    }
  }

  Future<void> handleResetPassword() async {
    final email = emailController.text.trim();
    final otpCode = otpControllers.map((e) => e.text).join();
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (otpCode.length != 6) {
      showToast('Please enter complete OTP');
      return;
    }

    if (newPassword != confirmPassword) {
      showToast('Passwords do not match');
      return;
    }

    if (newPassword.length < 6) {
      showToast('Password must be at least 6 characters');
      return;
    }

    setState(() {
      btnLoading = true;
    });

    try {
      final res = await ApiClient.dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'otp': otpCode,
          'newPassword': newPassword,
        },
      );

      showToast(res.data?['message']?.toString() ?? 'Password reset');

      final loginRes = await ApiClient.dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': newPassword,
        },
      );

      final authProvider = context.read<AuthProvider>();
      await authProvider.login(
        token: loginRes.data['token'],
        user: Map<String, dynamic>.from(loginRes.data['user']),
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (err) {
      String message = 'Failed to reset password';
      try {
        final data = (err as dynamic).response?.data;
        if (data is Map && data['error'] != null) {
          message = data['error'].toString();
        }
      } catch (_) {}
      showToast(message);
    } finally {
      if (mounted) {
        setState(() {
          btnLoading = false;
        });
      }
    }
  }

  Widget buildOtpBox(int idx) {
    return SizedBox(
      width: 44,
      height: 48,
      child: TextField(
        controller: otpControllers[idx],
        focusNode: otpFocusNodes[idx],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        decoration: InputDecoration(
          hintText: '•',
          hintStyle: const TextStyle(color: Color(0x59FFFFFF)),
          counterText: '',
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.18),
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.40),
            ),
          ),
        ),
        onChanged: (value) {
          if (value.isEmpty) {
            handleOtpBackspace(value, idx);
          } else {
            handleOtpChange(value, idx);
          }
        },
      ),
    );
  }

  Widget buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool showValue,
    required VoidCallback onToggle,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 6),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextField(
              controller: controller,
              obscureText: !showValue,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                contentPadding: const EdgeInsets.fromLTRB(12, 12, 70, 12),
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
            TextButton(
              onPressed: onToggle,
              child: Text(
                showValue ? 'Hide' : 'Show',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  32,
            ),
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: !otpSent
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Forgot Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Enter your email to receive an OTP',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Email',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'you@example.com',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.18),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
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
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: btnLoading ? null : handleSendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF3730A3),
                                disabledBackgroundColor:
                                    Colors.white.withValues(alpha: 0.65),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: btnLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Send OTP',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Reset Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                                children: [
                                  const TextSpan(text: 'OTP sent to '),
                                  TextSpan(
                                    text: emailController.text.trim(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'OTP',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, buildOtpBox),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: timer > 0 ? null : handleResendOtp,
                              child: Text(
                                timer > 0
                                    ? 'Resend OTP (${timer}s)'
                                    : 'Resend OTP',
                                style: TextStyle(
                                  color: timer > 0
                                      ? Colors.white.withValues(alpha: 0.45)
                                      : Colors.white.withValues(alpha: 0.85),
                                  decoration: timer > 0
                                      ? TextDecoration.none
                                      : TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          buildPasswordField(
                            label: 'New Password',
                            controller: newPasswordController,
                            showValue: showPassword,
                            onToggle: () {
                              setState(() {
                                showPassword = !showPassword;
                              });
                            },
                            hint: 'Enter New Password',
                          ),
                          const SizedBox(height: 12),
                          buildPasswordField(
                            label: 'Confirm Password',
                            controller: confirmPasswordController,
                            showValue: showConfirmPassword,
                            onToggle: () {
                              setState(() {
                                showConfirmPassword = !showConfirmPassword;
                              });
                            },
                            hint: 'Confirm New Password',
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: btnLoading ? null : handleResetPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF3730A3),
                                disabledBackgroundColor:
                                    Colors.white.withValues(alpha: 0.65),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: btnLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Reset Password & Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Back to Login',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  decoration: TextDecoration.underline,
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
      ),
    );
  }
}