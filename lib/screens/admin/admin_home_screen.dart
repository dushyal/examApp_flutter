// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../providers/auth_provider.dart';
// import 'exam_list_screen.dart';
// import 'faculty_screen.dart';
// import 'questions_list_screen.dart';
// import 'results_screen.dart';
// import 'students_screen.dart';

// class AdminHomeScreen extends StatelessWidget {
//   const AdminHomeScreen({super.key});

//   void open(BuildContext context, Widget page) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => page),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.user;
//     final loading = authProvider.loading;

//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isSmallDevice = width < 380;
//     final isTablet = width >= 768;

//     if (loading) {
//       return const Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Text(
//             'Loading...',
//             style: TextStyle(
//               fontSize: 20,
//               color: Color(0xFF6B7280),
//             ),
//           ),
//         ),
//       );
//     }

//     if (user == null) {
//       return const Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Text(
//             'Unauthorized',
//             style: TextStyle(
//               fontSize: 20,
//               color: Color(0xFFEF4444),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       );
//     }

//     final List<_AdminCardItem> cards = [];

//     if (user['role'] == 'SUBJECT' || user['role'] == 'ADMIN') {
//       cards.add(
//         _AdminCardItem(
//           keyName: 'Questions',
//           title: 'Manage Questions',
//           color: const Color(0xFF6366F1),
//           icon: Icons.description_outlined,
//           onTap: () => open(context, const AdminQuestionsScreen()),
//         ),
//       );
//     }

//     if (user['role'] == 'EXAMINER' || user['role'] == 'ADMIN') {
//       cards.add(
//         _AdminCardItem(
//           keyName: 'Exam',
//           title: 'Manage Exams',
//           color: const Color(0xFF22C55E),
//           icon: Icons.assignment_outlined,
//           onTap: () => open(context, const ExamListScreen()),
//         ),
//       );
//     }

//     if (user['role'] == 'ADMIN') {
//       cards.addAll([
//         _AdminCardItem(
//           keyName: 'Results',
//           title: 'View Results',
//           color: const Color(0xFFEC4899),
//           icon: Icons.school_outlined,
//           onTap: () => open(context, const AdminResultsScreen()),
//         ),
//         _AdminCardItem(
//           keyName: 'Students',
//           title: 'Manage Students',
//           color: const Color(0xFFF59E0B),
//           icon: Icons.groups_outlined,
//           onTap: () => open(context, const AdminStudentsScreen()),
//         ),
//         _AdminCardItem(
//           keyName: 'Faculty',
//           title: 'Manage Faculty',
//           color: const Color(0xFF0D9488),
//           icon: Icons.co_present_outlined,
//           onTap: () => open(context, const FacultyScreen()),
//         ),
//       ]);
//     }

//     final cardCount = cards.length;
//     final gap = isTablet ? 18.0 : 14.0;
//     final horizontalPadding = isTablet ? 28.0 : 20.0;
//     final availableHeight = height - 140;
//     final cardHeight = ((availableHeight - gap * (cardCount - 1)) / cardCount)
//         .floorToDouble()
//         .clamp(isSmallDevice ? 90.0 : 105.0, 220.0);

//     final iconSize = isTablet ? 38.0 : (isSmallDevice ? 26.0 : 32.0);
//     final textSize = isTablet ? 20.0 : (isSmallDevice ? 16.0 : 18.0);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text('Admin Panel'),
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(horizontalPadding),
//         child: Column(
//           children: [
//             Expanded(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: cards.map((item) {
//                   return Container(
//                     width: double.infinity,
//                     height: cardHeight,
//                     margin: EdgeInsets.only(
//                       bottom: item == cards.last ? 0 : gap,
//                     ),
//                     child: Material(
//                       color: item.color,
//                       borderRadius: BorderRadius.circular(20),
//                       elevation: 4,
//                       child: InkWell(
//                         borderRadius: BorderRadius.circular(20),
//                         onTap: item.onTap,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 20),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 item.icon,
//                                 size: iconSize,
//                                 color: Colors.white,
//                               ),
//                               const SizedBox(height: 10),
//                               Text(
//                                 item.title,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w700,
//                                   fontSize: textSize,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _AdminCardItem {
//   final String keyName;
//   final String title;
//   final Color color;
//   final IconData icon;
//   final VoidCallback onTap;

//   _AdminCardItem({
//     required this.keyName,
//     required this.title,
//     required this.color,
//     required this.icon,
//     required this.onTap,
//   });
// }




// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../providers/auth_provider.dart';
// import 'exam_list_screen.dart';
// import 'faculty_screen.dart';
// import 'questions_list_screen.dart';
// import 'results_screen.dart';
// import 'students_screen.dart';

// class AdminHomeScreen extends StatelessWidget {
//   const AdminHomeScreen({super.key});

//   void open(BuildContext context, Widget page) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => page),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.user;
//     final loading = authProvider.loading;

//     final size = MediaQuery.of(context).size;
//     final width = size.width;

//     final isSmallDevice = width < 380;
//     final isTablet = width >= 768;

//     if (loading) {
//       return const Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Text(
//             'Loading...',
//             style: TextStyle(
//               fontSize: 20,
//               color: Color(0xFF6B7280),
//             ),
//           ),
//         ),
//       );
//     }

//     if (user == null) {
//       return const Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Text(
//             'Unauthorized',
//             style: TextStyle(
//               fontSize: 20,
//               color: Color(0xFFEF4444),
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ),
//       );
//     }

//     final List<_AdminCardItem> cards = [];

//     if (user['role'] == 'SUBJECT' || user['role'] == 'ADMIN') {
//       cards.add(
//         _AdminCardItem(
//           keyName: 'Questions',
//           title: 'Manage Questions',
//           color: const Color(0xFF6366F1),
//           icon: Icons.description_outlined,
//           onTap: () => open(context, const AdminQuestionsScreen()),
//         ),
//       );
//     }

//     if (user['role'] == 'EXAMINER' || user['role'] == 'ADMIN') {
//       cards.add(
//         _AdminCardItem(
//           keyName: 'Exam',
//           title: 'Manage Exams',
//           color: const Color(0xFF22C55E),
//           icon: Icons.assignment_outlined,
//           onTap: () => open(context, const ExamListScreen()),
//         ),
//       );
//     }

//     if (user['role'] == 'ADMIN') {
//       cards.addAll([
//         _AdminCardItem(
//           keyName: 'Results',
//           title: 'View Results',
//           color: const Color(0xFFEC4899),
//           icon: Icons.school_outlined,
//           onTap: () => open(context, const AdminResultsScreen()),
//         ),
//         _AdminCardItem(
//           keyName: 'Students',
//           title: 'Manage Students',
//           color: const Color(0xFFF59E0B),
//           icon: Icons.groups_outlined,
//           onTap: () => open(context, const AdminStudentsScreen()),
//         ),
//         _AdminCardItem(
//           keyName: 'Faculty',
//           title: 'Manage Faculty',
//           color: const Color(0xFF0D9488),
//           icon: Icons.co_present_outlined,
//           onTap: () => open(context, const FacultyScreen()),
//         ),
//       ]);
//     }

//     final gap = isTablet ? 18.0 : 14.0;
//     final horizontalPadding = isTablet ? 28.0 : 20.0;
//     final cardHeight = isTablet ? 160.0 : (isSmallDevice ? 110.0 : 130.0);

//     final iconSize = isTablet ? 38.0 : (isSmallDevice ? 26.0 : 32.0);
//     final textSize = isTablet ? 20.0 : (isSmallDevice ? 16.0 : 18.0);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.indigo,
//         foregroundColor: Colors.white,
//         elevation: 2,
//         centerTitle: true,
//         title: const Text('Admin Panel'),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.all(horizontalPadding),
//           child: ListView.separated(
//             itemCount: cards.length,
//             separatorBuilder: (_, __) => SizedBox(height: gap),
//             itemBuilder: (context, index) {
//               final item = cards[index];

//               return SizedBox(
//                 width: double.infinity,
//                 height: cardHeight,
//                 child: Material(
//                   color: item.color,
//                   borderRadius: BorderRadius.circular(20),
//                   elevation: 4,
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(20),
//                     onTap: item.onTap,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(
//                             item.icon,
//                             size: iconSize,
//                             color: Colors.white,
//                           ),
//                           const SizedBox(height: 10),
//                           Text(
//                             item.title,
//                             textAlign: TextAlign.center,
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w700,
//                               fontSize: textSize,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _AdminCardItem {
//   final String keyName;
//   final String title;
//   final Color color;
//   final IconData icon;
//   final VoidCallback onTap;

//   _AdminCardItem({
//     required this.keyName,
//     required this.title,
//     required this.color,
//     required this.icon,
//     required this.onTap,
//   });
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'exam_list_screen.dart';
import 'faculty_screen.dart';
import 'questions_list_screen.dart';
import 'results_screen.dart';
import 'students_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  void open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final loading = authProvider.loading;

    final size = MediaQuery.of(context).size;
    final width = size.width;

    final isSmallDevice = width < 380;
    final isTablet = width >= 768;

    final List<_AdminCardItem> cards = [];

    if (user != null) {
      if (user['role'] == 'SUBJECT' || user['role'] == 'ADMIN') {
        cards.add(
          _AdminCardItem(
            title: 'Manage Questions',
            color: const Color(0xFF6366F1),
            icon: Icons.description_outlined,
            onTap: () => open(context, const AdminQuestionsScreen()),
          ),
        );
      }

      if (user['role'] == 'EXAMINER' || user['role'] == 'ADMIN') {
        cards.add(
          _AdminCardItem(
            title: 'Manage Exams',
            color: const Color(0xFF22C55E),
            icon: Icons.assignment_outlined,
            onTap: () => open(context, const ExamListScreen()),
          ),
        );
      }

      if (user['role'] == 'ADMIN') {
        cards.addAll([
          _AdminCardItem(
            title: 'View Results',
            color: const Color(0xFFEC4899),
            icon: Icons.school_outlined,
            onTap: () => open(context, const AdminResultsScreen()),
          ),
          _AdminCardItem(
            title: 'Manage Students',
            color: const Color(0xFFF59E0B),
            icon: Icons.groups_outlined,
            onTap: () => open(context, const AdminStudentsScreen()),
          ),
          _AdminCardItem(
            title: 'Manage Faculty',
            color: const Color(0xFF0D9488),
            icon: Icons.co_present_outlined,
            onTap: () => open(context, const FacultyScreen()),
          ),
        ]);
      }
    }

    final gap = isTablet ? 18.0 : 14.0;
    final horizontalPadding = isTablet ? 28.0 : 20.0;
    final cardHeight = isTablet ? 160.0 : (isSmallDevice ? 110.0 : 130.0);
    final iconSize = isTablet ? 38.0 : (isSmallDevice ? 26.0 : 32.0);
    final textSize = isTablet ? 20.0 : (isSmallDevice ? 16.0 : 18.0);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : user == null
              ? const Center(
                  child: Text(
                    'Unauthorized',
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.all(horizontalPadding),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => SizedBox(height: gap),
                  itemBuilder: (context, index) {
                    final item = cards[index];

                    return SizedBox(
                      width: double.infinity,
                      height: cardHeight,
                      child: Material(
                        color: item.color,
                        borderRadius: BorderRadius.circular(20),
                        elevation: 4,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: item.onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: textSize,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _AdminCardItem {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  _AdminCardItem({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });
}