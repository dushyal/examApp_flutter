// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import 'providers/auth_provider.dart';
// import 'screens/auth/forgot_password_screen.dart';
// import 'screens/auth/login_screen.dart';
// import 'screens/auth/register_screen.dart';
// import 'screens/auth/reset_password_screen.dart';
// import 'screens/auth/verify_screen.dart';
// import 'screens/admin/admin_home_screen.dart';
// import 'widgets/app_drawer.dart';

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return ChangeNotifierProvider(
//       create: (_) => AuthProvider(),
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Exam App',
//         theme: ThemeData(primarySwatch: Colors.indigo),
//         home: const RootDecider(),
//         routes: {
//           '/login': (context) => const LoginScreen(),
//           '/register': (context) => const RegisterScreen(),
//           '/forgot-password': (context) => const ForgotPasswordScreen(),
//           '/reset-password': (context) => const ResetPasswordScreen(),
//           '/verify': (context) => const VerifyScreen(),
//         },
//       ),
//     );
//   }
// }

// class RootDecider extends StatelessWidget {
//   const RootDecider({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();

//     if (authProvider.loading) {
//       return const Scaffold(
//         body: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     final user = authProvider.user;
//     const adminRoles = ['ADMIN', 'EXAMINER', 'SUBJECT'];
//     final isAdmin = adminRoles.contains(user?['role']);

//     if (user == null) {
//       return const LoginScreen();
//     }

//     if (isAdmin) {
//       return const AdminHomeScreen();
//     }

//     return const AppDrawerScreen();
//   }
// }





import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/verify_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'widgets/app_drawer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Exam App',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            centerTitle: true,
            elevation: 2,
          ),
        ),
        home: const RootDecider(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          '/verify': (context) => const VerifyScreen(),
          '/admin-home': (context) => const AdminHomeScreen(),
        },
      ),
    );
  }
}

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authProvider.user;
    const adminRoles = ['ADMIN', 'EXAMINER', 'SUBJECT'];
    final isAdmin = adminRoles.contains(user?['role']);

    if (user == null) {
      return const LoginScreen();
    }

    if (isAdmin) {
      return const AdminHomeScreen();
    }

    return const AppDrawerScreen();
  }
}