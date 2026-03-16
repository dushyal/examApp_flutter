// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';
// import '../screens/admin/admin_home_screen.dart';
// import '../widgets/app_drawer.dart';

// class AppHeader extends StatelessWidget implements PreferredSizeWidget {
//   final String title;

//   const AppHeader({
//     super.key,
//     this.title = "Online Exam Portal",
//   });

//   @override
//   Size get preferredSize => const Size.fromHeight(60);

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.user;

//     const adminRoles = ['ADMIN', 'EXAMINER', 'SUBJECT'];
//     final isAdminUser = user != null && adminRoles.contains(user['role']);

//     void goDashboard() {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) =>
//               isAdminUser ? const AdminHomeScreen() : const AppDrawerScreen(),
//         ),
//       );
//     }

//     Future<void> handleLogout() async {
//       await authProvider.logoutUser();

//       if (!context.mounted) return;

//       Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
//     }

//     return AppBar(
//       backgroundColor: const Color(0xFF4F46E5),
//       elevation: 0,
//       automaticallyImplyLeading: false,
//       titleSpacing: 0,
//       title: Row(
//         children: [
//           Builder(
//             builder: (context) => IconButton(
//               icon: const Icon(Icons.menu, color: Colors.white),
//               onPressed: () {
//                 Scaffold.of(context).openDrawer();
//               },
//             ),
//           ),
//           Expanded(
//             child: Text(
//               title,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w900,
//                 fontSize: 16,
//               ),
//             ),
//           ),
//         ],
//       ),
//       actions: user != null
//           ? [
//               IconButton(
//                 icon: const Icon(Icons.person_outline, color: Colors.white),
//                 onPressed: goDashboard,
//               ),
//               IconButton(
//                 icon: const Icon(Icons.logout, color: Colors.white),
//                 onPressed: handleLogout,
//               ),
//               const SizedBox(width: 6),
//             ]
//           : [],
//     );
//   }
// }






import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/admin/admin_home_screen.dart';
import '../widgets/app_drawer.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AppHeader({
    super.key,
    this.title = "Online Exam Portal Header",
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    const adminRoles = ['ADMIN', 'EXAMINER', 'SUBJECT'];
    final role = (user?['role'] ?? '').toString().toUpperCase();
    final isAdminUser = user != null && adminRoles.contains(role);

    void goDashboard() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              isAdminUser ? const AdminHomeScreen() : const AppDrawerScreen(),
        ),
      );
    }

    Future<void> handleLogout() async {
      await authProvider.logout();

      if (!context.mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    }

    return AppBar(
      backgroundColor: const Color(0xFF4F46E5),
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      actions: user != null
          ? [
              IconButton(
                icon: const Icon(Icons.person_outline, color: Colors.white),
                onPressed: goDashboard,
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: handleLogout,
              ),
              const SizedBox(width: 6),
            ]
          : [],
    );
  }
}