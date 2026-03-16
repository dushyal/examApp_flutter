import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/local_storage.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  String email = '';
  String name = '';

  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool loading = false;
  int timer = 30;
  bool canResend = false;
  bool _didLoadArgs = false;

  @override
  void initState() {
    super.initState();
    loadStorageData();
    startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(otpFocusNodes[0]);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadArgs) return;
    _didLoadArgs = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['email'] != null) {
      email = args['email'].toString();
    }
  }

  Future<void> loadStorageData() async {
    final savedEmail = await LocalStorage.getRegisterEmail();
    final savedName = await LocalStorage.getRegisterName();

    if (email.isEmpty && savedEmail != null) {
      email = savedEmail;
    }
    if (savedName != null) {
      name = savedName;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void startTimer() {
    Future.doWhile(() async {
      if (!mounted || timer <= 0) {
        if (mounted) {
          setState(() {
            canResend = true;
          });
        }
        return false;
      }

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return false;

      setState(() {
        timer -= 1;
        if (timer <= 0) {
          canResend = true;
        }
      });

      return timer > 0;
    });
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
    );
  }

  void handleOtpChange(String value, int index) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.isEmpty) {
      otpControllers[index].text = '';
      return;
    }

    final digit = cleaned[cleaned.length - 1];
    otpControllers[index].text = digit;
    otpControllers[index].selection =
        TextSelection.collapsed(offset: otpControllers[index].text.length);

    if (index < 5) {
      FocusScope.of(context).requestFocus(otpFocusNodes[index + 1]);
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  void handleBackspace(String value, int index) {
    if (value.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(otpFocusNodes[index - 1]);
    }
  }

  String get otpValue => otpControllers.map((e) => e.text).join();

  Future<void> handleVerify() async {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty) {
      showToast('Email missing');
      return;
    }

    if (password != confirmPassword) {
      showToast('Passwords do not match');
      return;
    }

    if (otpValue.length < 6) {
      showToast('Enter complete OTP');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await ApiClient.dio.post(
        '/auth/register-complete',
        data: {
          'name': name,
          'email': email,
          'otp': otpValue,
          'password': password,
        },
      );

      showToast('Registration successful 🎉');

      await LocalStorage.clearRegisterData();

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/');
    } catch (err) {
      String message = 'Verification failed';
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
          loading = false;
        });
      }
    }
  }

  Future<void> handleResend() async {
    try {
      await ApiClient.dio.post(
        '/auth/register-init',
        data: {
          'name': name,
          'email': email,
        },
      );

      showToast('OTP resent successfully!');

      for (final controller in otpControllers) {
        controller.clear();
      }

      FocusScope.of(context).requestFocus(otpFocusNodes[0]);

      setState(() {
        timer = 30;
        canResend = false;
      });

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

  @override
  void dispose() {
    for (final controller in otpControllers) {
      controller.dispose();
    }
    for (final node in otpFocusNodes) {
      node.dispose();
    }
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF4F46E5),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Verify OTP 🔐',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Complete your registration',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '📩 ${email.isEmpty ? "--" : email}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Enter 6-Digit OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (i) {
                        return SizedBox(
                          width: 44,
                          height: 52,
                          child: TextField(
                            controller: otpControllers[i],
                            focusNode: otpFocusNodes[i],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(1),
                            ],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
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
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                handleBackspace(value, i);
                              } else {
                                handleOtpChange(value, i);
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 14),
                    canResend
                        ? GestureDetector(
                            onTap: handleResend,
                            child: const Text(
                              'Resend OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          )
                        : Text(
                            'Resend OTP in ${timer}s',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),

                    const SizedBox(height: 14),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Create Password',
                        hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
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
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Confirm Password',
                        hintStyle: const TextStyle(color: Color(0x80FFFFFF)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.18),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
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
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : handleVerify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4338CA),
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          loading ? 'Submitting...' : 'Verify & Register',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
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