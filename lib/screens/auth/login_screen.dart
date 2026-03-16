// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:provider/provider.dart';

// import '../../providers/auth_provider.dart';
// import '../admin/admin_home_screen.dart';
// import '../../widgets/app_drawer.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();

//   bool btnLoading = false;
//   bool showPassword = false;

//   @override
//   void dispose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> handleSubmit() async {
//     final email = emailController.text.trim().toLowerCase();
//     final password = passwordController.text.trim();

//     if (email.isEmpty || password.isEmpty) {
//       _showErrorDialog('Error', 'Email and password required');
//       return;
//     }

//     setState(() {
//       btnLoading = true;
//     });

//     try {
//       final authProvider = context.read<AuthProvider>();

//       await authProvider.loginUser(
//         email: email,
//         password: password,
//       );

//       if (!mounted) return;

//       final user = authProvider.user;
//       const adminRoles = ['ADMIN', 'EXAMINER', 'SUBJECT'];
//       final isAdmin = adminRoles.contains(user?['role']);

//       Fluttertoast.showToast(
//         msg: 'Login successful',
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               isAdmin ? const AdminHomeScreen() : const AppDrawerScreen(),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       _showErrorDialog('Login failed', e.toString());
//     } finally {
//       if (mounted) {
//         setState(() {
//           btnLoading = false;
//         });
//       }
//     }
//   }

//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void goToForgotPassword() {
//     Navigator.pushNamed(context, '/forgot-password');
//   }

//   void goToRegister() {
//     Navigator.pushNamed(context, '/register');
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();

//     if (authProvider.loading) {
//       return const Scaffold(
//         body: SizedBox.shrink(),
//       );
//     }

//     return Scaffold(
//       backgroundColor: const Color(0xFF4F46E5),
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(22),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.12),
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.20),
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Center(
//                     child: Text(
//                       'Welcome Back 👋',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.w800,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   Center(
//                     child: Text(
//                       'Login to continue to your dashboard',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.white70,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   /// EMAIL
//                   const Text(
//                     'Email',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 8),

//                   Container(
//                     height: 48,
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.16),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.mail_outline,
//                           size: 18,
//                           color: Colors.white,
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: TextField(
//                             controller: emailController,
//                             keyboardType: TextInputType.emailAddress,
//                             style: const TextStyle(color: Colors.white),
//                             decoration: const InputDecoration(
//                               hintText: 'you@example.com',
//                               hintStyle: TextStyle(color: Colors.white70),
//                               border: InputBorder.none,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 14),

//                   /// PASSWORD
//                   const Text(
//                     'Password',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white,
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   Container(
//                     height: 48,
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.16),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.lock_outline,
//                           size: 18,
//                           color: Colors.white,
//                         ),
//                         const SizedBox(width: 10),
//                         Expanded(
//                           child: TextField(
//                             controller: passwordController,
//                             obscureText: !showPassword,
//                             style: const TextStyle(color: Colors.white),
//                             decoration: const InputDecoration(
//                               hintText: '••••••••',
//                               hintStyle: TextStyle(color: Colors.white70),
//                               border: InputBorder.none,
//                             ),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               showPassword = !showPassword;
//                             });
//                           },
//                           child: Icon(
//                             showPassword
//                                 ? Icons.visibility_off
//                                 : Icons.visibility,
//                             color: Colors.white,
//                           ),
//                         )
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   Align(
//                     alignment: Alignment.centerRight,
//                     child: GestureDetector(
//                       onTap: goToForgotPassword,
//                       child: const Text(
//                         'Forgot Password?',
//                         style: TextStyle(
//                           color: Colors.white,
//                           decoration: TextDecoration.underline,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   SizedBox(
//                     width: double.infinity,
//                     height: 50,
//                     child: ElevatedButton(
//                       onPressed: btnLoading ? null : handleSubmit,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         foregroundColor: const Color(0xFF4338CA),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(14),
//                         ),
//                       ),
//                       child: Text(
//                         btnLoading ? 'Logging in...' : 'Login',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 18),

//                   Center(
//                     child: GestureDetector(
//                       onTap: goToRegister,
//                       child: const Text(
//                         "Don't have an account? Create Account",
//                         style: TextStyle(
//                           color: Colors.white,
//                           decoration: TextDecoration.underline,
//                         ),
//                       ),
//                     ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }






import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../admin/admin_home_screen.dart';
import '../../widgets/app_drawer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool btnLoading = false;
  bool showPassword = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    final email = emailController.text.trim().toLowerCase();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Error', 'Email and password required');
      return;
    }

    setState(() {
      btnLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      await authProvider.loginUser(
        email: email,
        password: password,
      );

      if (!mounted) return;

      final user = authProvider.user;
      const adminRoles = ['ADMIN', 'EXAMINER', 'SUBJECT'];
      final isAdmin = adminRoles.contains(user?['role']);

      Fluttertoast.showToast(
        msg: 'Login successful',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isAdmin ? const AdminHomeScreen() : const AppDrawerScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Login failed', e.toString());
    } finally {
      if (mounted) {
        setState(() {
          btnLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
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

  void goToForgotPassword() {
    Navigator.pushNamed(context, '/forgot-password');
  }

  void goToRegister() {
    Navigator.pushNamed(context, '/register');
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
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Welcome Back 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Login to continue to your dashboard',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mail_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            obscureText: !showPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                          child: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: goToForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: Colors.white,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: btnLoading ? null : handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF4338CA),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        btnLoading ? 'Logging in...' : 'Login',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Center(
                    child: GestureDetector(
                      onTap: goToRegister,
                      child: const Text(
                        "Don't have an account? Create Account",
                        style: TextStyle(
                          color: Colors.white,
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
    );
  }
}