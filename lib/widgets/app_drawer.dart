// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';
// import '../screens/student/certificate_screen.dart';
// import '../screens/student/dashboard_screen.dart';
// import '../screens/student/exam_attempt_screen.dart';
// import '../screens/student/subject_screen.dart';

// class AppDrawerScreen extends StatefulWidget {
//   const AppDrawerScreen({super.key});

//   @override
//   State<AppDrawerScreen> createState() => _AppDrawerScreenState();
// }

// class _AppDrawerScreenState extends State<AppDrawerScreen> {
//   int selectedIndex = 0;

//   final List<String> titles = [
//     'Online Exam Portal D',
//     'Online Exam Portal R',
//     'Exam Mode',
//     'Online Exam Portal A',
//   ];

//   final List<Widget> screens = const [
//     StudentDashboardScreen(),
//     SubjectScreen(),
//     ExamAttemptScreen(),
//     CertificateScreen(),
//   ];

//   final List<_DrawerItem> visibleItems = const [
//     _DrawerItem(
//       title: 'Dashboard',
//       icon: Icons.home_outlined,
//       index: 0,
//     ),
//     _DrawerItem(
//       title: 'Subjects',
//       icon: Icons.menu_book_outlined,
//       index: 1,
//     ),
//     _DrawerItem(
//       title: 'Certificate',
//       icon: Icons.workspace_premium_outlined,
//       index: 3,
//     ),
//   ];

//   void openScreen(int index) {
//     Navigator.pop(context);
//     setState(() {
//       selectedIndex = index;
//     });
//   }

//   void openExamAttempt() {
//     setState(() {
//       selectedIndex = 2;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.user;

//     if (authProvider.loading) {
//       return const Scaffold(
//         body: SizedBox.shrink(),
//       );
//     }

//     return Scaffold(
//       drawer: Drawer(
//         child: SafeArea(
//           child: Column(
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 color: const Color(0xFF4F46E5),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const CircleAvatar(
//                       radius: 28,
//                       backgroundColor: Colors.white,
//                       child: Icon(
//                         Icons.person,
//                         color: Color(0xFF4F46E5),
//                         size: 30,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       user?['name']?.toString() ?? 'Student',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       user?['email']?.toString() ?? '',
//                       style: TextStyle(
//                         color: Colors.white.withValues(alpha: 0.85),
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: ListView(
//                   padding: EdgeInsets.zero,
//                   children: visibleItems.map((item) {
//                     final isSelected = selectedIndex == item.index;
//                     return ListTile(
//                       leading: Icon(
//                         item.icon,
//                         color: isSelected
//                             ? const Color(0xFF4F46E5)
//                             : Colors.black54,
//                       ),
//                       title: Text(
//                         item.title,
//                         style: TextStyle(
//                           color: isSelected
//                               ? const Color(0xFF4F46E5)
//                               : Colors.black87,
//                           fontWeight:
//                               isSelected ? FontWeight.w700 : FontWeight.w500,
//                         ),
//                       ),
//                       selected: isSelected,
//                       onTap: () => openScreen(item.index),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF4F46E5),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         title: Text(
//           titles[selectedIndex],
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             fontWeight: FontWeight.w900,
//             fontSize: 16,
//           ),
//         ),
//         actions: user != null
//             ? [
//                 IconButton(
//                   onPressed: () {
//                     setState(() {
//                       selectedIndex = 0;
//                     });
//                   },
//                   icon: const Icon(Icons.person_outline),
//                 ),
//                 IconButton(
//                   onPressed: () async {
//                     await context.read<AuthProvider>().logout();
//                   },
//                   icon: const Icon(Icons.logout),
//                 ),
//               ]
//             : [
//                 IconButton(
//                   onPressed: () {
//                     setState(() {
//                       selectedIndex = 0;
//                     });
//                   },
//                   icon: const Icon(Icons.login),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     setState(() {
//                       selectedIndex = 0;
//                     });
//                   },
//                   icon: const Icon(Icons.person_add_alt_1_outlined),
//                 ),
//               ],
//       ),
//       body: screens[selectedIndex],
//     );
//   }
// }

// class _DrawerItem {
//   final String title;
//   final IconData icon;
//   final int index;

//   const _DrawerItem({
//     required this.title,
//     required this.icon,
//     required this.index,
//   });
// }






// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../providers/auth_provider.dart';
// import '../screens/student/certificate_screen.dart';
// import '../screens/student/dashboard_screen.dart';
// import '../screens/student/exam_attempt_screen.dart';
// import '../screens/student/subject_screen.dart';

// class AppDrawerScreen extends StatefulWidget {
//   const AppDrawerScreen({super.key});

//   @override
//   State<AppDrawerScreen> createState() => _AppDrawerScreenState();
// }

// class _AppDrawerScreenState extends State<AppDrawerScreen> {
//   int selectedIndex = 0;

//   final List<String> titles = [
//     'Online Exam Portal',
//     'Online Exam Portal',
//     'Exam Mode',
//     'Online Exam Portal',
//   ];

//   final List<Widget> screens = const [
//     StudentDashboardScreen(),
//     SubjectScreen(),
//     ExamAttemptScreen(),
//     CertificateScreen(),
//   ];

//   final List<_DrawerItem> visibleItems = const [
//     _DrawerItem(
//       title: 'Dashboard',
//       icon: Icons.home_outlined,
//       index: 0,
//     ),
//     // _DrawerItem(
//     //   title: 'Subjects',
//     //   icon: Icons.menu_book_outlined,
//     //   index: 1,
//     // ),
//     _DrawerItem(
//       title: 'Certificate',
//       icon: Icons.workspace_premium_outlined,
//       index: 3,
//     ),
//   ];

//   void openScreen(int index) {
//     Navigator.pop(context);
//     setState(() {
//       selectedIndex = index;
//     });
//   }

//   Future<void> handleLogout() async {
//     await context.read<AuthProvider>().logout();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final authUser = authProvider.user;

//     Map<String, dynamic> dashboardUser = {};
//     if (screens[selectedIndex] is StudentDashboardScreen) {
//       dashboardUser = {};
//     }

//     final currentUser = authUser;

//     if (authProvider.loading) {
//       return const Scaffold(
//         body: SizedBox.shrink(),
//       );
//     }

//     return Scaffold(
//       drawer: Drawer(
//         child: SafeArea(
//           child: Column(
//             children: [
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(20),
//                 color: const Color(0xFF4F46E5),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const CircleAvatar(
//                       radius: 28,
//                       backgroundColor: Colors.white,
//                       child: Icon(
//                         Icons.person,
//                         color: Color(0xFF4F46E5),
//                         size: 30,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       currentUser?['name']?.toString() ?? 'Student',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.w800,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       currentUser?['email']?.toString() ?? '',
//                       style: TextStyle(
//                         color: Colors.white.withOpacity(0.85),
//                         fontSize: 13,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: ListView(
//                   padding: EdgeInsets.zero,
//                   children: visibleItems.map((item) {
//                     final isSelected = selectedIndex == item.index;
//                     return ListTile(
//                       leading: Icon(
//                         item.icon,
//                         color: isSelected
//                             ? const Color(0xFF4F46E5)
//                             : Colors.black54,
//                       ),
//                       title: Text(
//                         item.title,
//                         style: TextStyle(
//                           color: isSelected
//                               ? const Color(0xFF4F46E5)
//                               : Colors.black87,
//                           fontWeight:
//                               isSelected ? FontWeight.w700 : FontWeight.w500,
//                         ),
//                       ),
//                       selected: isSelected,
//                       onTap: () => openScreen(item.index),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF4F46E5),
//         foregroundColor: Colors.white,
//         centerTitle: true,
//         title: Text(
//           titles[selectedIndex],
//           maxLines: 1,
//           overflow: TextOverflow.ellipsis,
//           style: const TextStyle(
//             fontWeight: FontWeight.w900,
//             fontSize: 16,
//           ),
//         ),
//         actions: currentUser != null
//             ? [
//                 // IconButton(
//                 //   onPressed: () {
//                 //     setState(() {
//                 //       selectedIndex = 0;
//                 //     });
//                 //   },
//                 //   icon: const Icon(Icons.person_outline),
//                 // ),
//                 IconButton(
//                   onPressed: handleLogout,
//                   icon: const Icon(Icons.logout),
//                 ),
//               ]
//             : [
//                 IconButton(
//                   onPressed: () {
//                     setState(() {
//                       selectedIndex = 0;
//                     });
//                   },
//                   icon: const Icon(Icons.login),
//                 ),
//                 IconButton(
//                   onPressed: () {
//                     setState(() {
//                       selectedIndex = 0;
//                     });
//                   },
//                   icon: const Icon(Icons.person_add_alt_1_outlined),
//                 ),
//               ],
//       ),
//       body: screens[selectedIndex],
//     );
//   }
// }

// class _DrawerItem {
//   final String title;
//   final IconData icon;
//   final int index;

//   const _DrawerItem({
//     required this.title,
//     required this.icon,
//     required this.index,
//   });
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/student/certificates_list_screen.dart';
import '../screens/student/dashboard_screen.dart';
import '../screens/student/exam_attempt_screen.dart';
import '../screens/student/subject_screen.dart';

class AppDrawerScreen extends StatefulWidget {
  const AppDrawerScreen({super.key});

  @override
  State<AppDrawerScreen> createState() => _AppDrawerScreenState();
}

class _AppDrawerScreenState extends State<AppDrawerScreen> {
  int selectedIndex = 0;

  final List<String> titles = [
    'Online Exam Portal',
    'Online Exam Portal',
    'Exam Mode',
    'Online Exam Portal',
  ];

  final List<Widget> screens = const [
    StudentDashboardScreen(),
    SubjectScreen(),
    ExamAttemptScreen(),
    CertificatesListScreen(),
  ];

  final List<_DrawerItem> visibleItems = const [
    _DrawerItem(
      title: 'Dashboard',
      icon: Icons.home_outlined,
      index: 0,
    ),
    _DrawerItem(
      title: 'Certificate',
      icon: Icons.workspace_premium_outlined,
      index: 3,
    ),
  ];

  void openScreen(int index) {
    Navigator.pop(context);
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> handleLogout() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.user;

    if (authProvider.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: const Color(0xFF4F46E5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.person,
                        color: Color(0xFF4F46E5),
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentUser?['name']?.toString() ?? 'Student',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentUser?['email']?.toString() ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: visibleItems.map((item) {
                    final isSelected = selectedIndex == item.index;
                    return ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : Colors.black54,
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected
                              ? const Color(0xFF4F46E5)
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () => openScreen(item.index),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          titles[selectedIndex],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        actions: currentUser != null
            ? [
                IconButton(
                  onPressed: handleLogout,
                  icon: const Icon(Icons.logout),
                ),
              ]
            : [],
      ),
      body: screens[selectedIndex],
    );
  }
}

class _DrawerItem {
  final String title;
  final IconData icon;
  final int index;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.index,
  });
}