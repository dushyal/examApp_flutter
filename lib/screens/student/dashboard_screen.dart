// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/api/api_client.dart';
// import '../../providers/auth_provider.dart';
// import 'subject_screen.dart';

// class StudentDashboardScreen extends StatefulWidget {
//   const StudentDashboardScreen({super.key});

//   @override
//   State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
// }

// class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
//   Map<String, dynamic>? data;
//   bool loading = true;
//   String? error;
//   int page = 0;

//   static const int cardsPerRow = 2;
//   static const int rowsPerPage = 2;
//   static const int itemsPerPage = cardsPerRow * rowsPerPage;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(fetchDashboard);
//   }

//   Future<void> fetchDashboard() async {
//     if (!mounted) return;

//     setState(() {
//       loading = true;
//       error = null;
//     });

//     try {
//       final res = await ApiClient.dio.get('/student/dashboard');
//       final responseData = (res.data is Map<String, dynamic>)
//           ? res.data as Map<String, dynamic>
//           : <String, dynamic>{};

//       final subjects = List<String>.from(responseData['subjects'] ?? []);
//       final subjectScores =
//           Map<String, dynamic>.from(responseData['subjectScores'] ?? {});
//       final pendingLevels =
//           Map<String, dynamic>.from(responseData['pendingLevels'] ?? {});
//       final user = Map<String, dynamic>.from(responseData['user'] ?? {});

//       if (!mounted) return;

//       setState(() {
//         data = {
//           'user': user,
//           'subjects': subjects,
//           'subjectScores': subjectScores,
//           'pendingLevels': pendingLevels,
//         };
//         page = 0;
//       });
//     } on DioException catch (err) {
//       int? statusCode;
//       String message = 'Something went wrong';

//       statusCode = err.response?.statusCode;
//       final responseData = err.response?.data;

//       if (responseData is Map && responseData['message'] != null) {
//         message = responseData['message'].toString();
//       } else if (err.message != null && err.message!.isNotEmpty) {
//         message = err.message!;
//       } else {
//         message = err.toString();
//       }

//       if (statusCode == 401) {
//         if (!mounted) return;
//         await context.read<AuthProvider>().logout();
//         return;
//       }

//       if (!mounted) return;
//       setState(() {
//         error = message;
//       });
//     } catch (err) {
//       if (!mounted) return;
//       setState(() {
//         error = err.toString();
//       });
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         loading = false;
//       });
//     }
//   }

//   Map<String, dynamic> getSubjectStatus(String sub) {
//     final latest = num.tryParse('${data?['subjectScores']?[sub] ?? 0}') ?? 0;

//     final rawPending = data?['pendingLevels']?[sub];
//     final pendingText = rawPending == null ? '-' : rawPending.toString().trim();
//     final normalizedPending = pendingText.toLowerCase();

//     final isCompleted = pendingText == '-' ||
//         pendingText == '0' ||
//         normalizedPending == 'completed' ||
//         normalizedPending == 'complete';

//     final badgeLabel = isCompleted ? 'Completed' : 'Active';
//     final badgeType = isCompleted ? 'green' : 'blue';
//     final displayPending = isCompleted ? '-' : pendingText;

//     return {
//       'latest': latest,
//       'isCompleted': isCompleted,
//       'badgeLabel': badgeLabel,
//       'badgeType': badgeType,
//       'displayPending': displayPending,
//     };
//   }

//   Map<String, dynamic> get summary {
//     if (data == null) {
//       return {
//         'totalSubjects': 0,
//         'avgScore': '0',
//         'activeCount': 0,
//       };
//     }

//     final subjects = List<String>.from(data?['subjects'] ?? []);

//     final scores = subjects
//         .map((sub) => num.tryParse('${data?['subjectScores']?[sub] ?? 0}') ?? 0)
//         .toList();

//     final avgScore = scores.isNotEmpty
//         ? (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1)
//         : '0';

//     final activeCount = subjects
//         .where((sub) => !(getSubjectStatus(sub)['isCompleted'] as bool))
//         .length;

//     return {
//       'totalSubjects': subjects.length,
//       'avgScore': avgScore,
//       'activeCount': activeCount,
//     };
//   }

//   void openSubject(String subject) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SubjectScreen(initialSubject: subject),
//       ),
//     ).then((_) => fetchDashboard());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     if (loading) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Container(
//               width: double.infinity,
//               margin: const EdgeInsets.all(18),
//               padding: const EdgeInsets.all(28),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF111827),
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(
//                   color: Colors.white.withValues(alpha: 0.08),
//                 ),
//               ),
//               child: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 14),
//                   Text(
//                     'Loading Dashboard',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Please wait while your subjects are being prepared...',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color(0xFF94A3B8),
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     if (error != null) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Container(
//               width: double.infinity,
//               margin: const EdgeInsets.all(18),
//               padding: const EdgeInsets.all(22),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF111827),
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(
//                   color: const Color(0x4DEF4444),
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Dashboard Error',
//                     style: TextStyle(
//                       color: Color(0xFFFCA5A5),
//                       fontSize: 18,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Error: $error',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Color(0xFFFECACA),
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: fetchDashboard,
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     if (data == null) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Text(
//               'No dashboard data available.',
//               style: TextStyle(
//                 color: Color(0xFFCBD5E1),
//                 fontWeight: FontWeight.w600,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final user = Map<String, dynamic>.from(data?['user'] ?? {});
//     final subjects = List<String>.from(data?['subjects'] ?? []);

//     final totalPages = subjects.isEmpty ? 1 : (subjects.length / itemsPerPage).ceil();

//     final paginatedSubjects =
//         subjects.skip(page * itemsPerPage).take(itemsPerPage).toList();

//     const horizontalPadding = 16.0;
//     const cardGap = 12.0;

//     final cardWidth =
//         ((width - horizontalPadding * 2 - cardGap) / 2).floorToDouble();

//     final headerHeight = height < 700 ? 145.0 : 160.0;
//     const sectionHeight = 42.0;
//     final paginationHeight = totalPages > 1 ? 52.0 : 0.0;

//     final availableCardArea =
//         height - headerHeight - sectionHeight - paginationHeight - 165;

//     final cardHeight = availableCardArea > 0
//         ? ((availableCardArea - 10) / 2).floorToDouble().clamp(95.0, 220.0)
//         : 95.0;

//     final dashboardSummary = summary;

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Positioned(
//               top: -40,
//               right: -10,
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 40,
//               left: -50,
//               child: Container(
//                 width: 220,
//                 height: 220,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 10),
//               child: Column(
//                 children: [
//                   Container(
//                     constraints: BoxConstraints(minHeight: headerHeight),
//                     width: double.infinity,
//                     margin: const EdgeInsets.only(top: 6, bottom: 14),
//                     padding: const EdgeInsets.all(14),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF111827),
//                       borderRadius: BorderRadius.circular(22),
//                       border: Border.all(
//                         color: Colors.white.withValues(alpha: 0.08),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Student Panel',
//                           style: TextStyle(
//                             color: Color(0xFFA78BFA),
//                             fontSize: 13,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           'Welcome, ${user['name'] ?? 'Student'}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 21,
//                             fontWeight: FontWeight.w900,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         const Text(
//                           'Track your subjects, latest scores, and pending levels from one place.',
//                           style: TextStyle(
//                             color: Color(0xFF94A3B8),
//                             fontSize: 12,
//                             height: 1.5,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Subjects',
//                                 value: '${dashboardSummary['totalSubjects']}',
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Average',
//                                 value: '${dashboardSummary['avgScore']}%',
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Active',
//                                 value: '${dashboardSummary['activeCount']}',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const Align(
//                     alignment: Alignment.centerLeft,
//                     child: Padding(
//                       padding: EdgeInsets.only(left: 2, bottom: 8),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Your Subjects',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 16,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                           SizedBox(height: 2),
//                           Text(
//                             'Tap any subject to continue',
//                             style: TextStyle(
//                               color: Color(0xFF94A3B8),
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: paginatedSubjects.isEmpty
//                         ? Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(24),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF111827),
//                               borderRadius: BorderRadius.circular(22),
//                               border: Border.all(
//                                 color: Colors.white.withValues(alpha: 0.08),
//                               ),
//                             ),
//                             child: const Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   'No Subjects Found',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.w900,
//                                   ),
//                                 ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   'Subjects will appear here once available.',
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     color: Color(0xFF94A3B8),
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : Wrap(
//                             spacing: 12,
//                             runSpacing: 10,
//                             children: paginatedSubjects.map((sub) {
//                               final status = getSubjectStatus(sub);
//                               final latest = status['latest'];
//                               final isCompleted = status['isCompleted'] as bool;
//                               final badgeLabel = status['badgeLabel'].toString();
//                               final badgeType = status['badgeType'].toString();
//                               final displayPending =
//                                   status['displayPending'].toString();

//                               return InkWell(
//                                 onTap: () => openSubject(sub),
//                                 borderRadius: BorderRadius.circular(16),
//                                 child: Container(
//                                   width: cardWidth,
//                                   height: cardHeight,
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF111827),
//                                     borderRadius: BorderRadius.circular(16),
//                                     border: Border.all(
//                                       color: Colors.white.withValues(alpha: 0.08),
//                                     ),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment: CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: Text(
//                                               sub,
//                                               maxLines: 1,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: const TextStyle(
//                                                 color: Colors.white,
//                                                 fontSize: 14,
//                                                 fontWeight: FontWeight.w900,
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(width: 8),
//                                           Container(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 8,
//                                               vertical: 4,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               borderRadius: BorderRadius.circular(999),
//                                               color: badgeType == 'green'
//                                                   ? const Color(0xFF22C55E)
//                                                       .withValues(alpha: 0.15)
//                                                   : const Color(0xFF3B82F6)
//                                                       .withValues(alpha: 0.15),
//                                             ),
//                                             child: Text(
//                                               badgeLabel,
//                                               maxLines: 1,
//                                               overflow: TextOverflow.ellipsis,
//                                               style: TextStyle(
//                                                 fontWeight: FontWeight.w900,
//                                                 fontSize: 11,
//                                                 color: badgeType == 'green'
//                                                     ? const Color(0xFF4ADE80)
//                                                     : const Color(0xFF60A5FA),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const Spacer(),
//                                       Text(
//                                         'Pending Level: $displayPending',
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: const TextStyle(
//                                           color: Color(0xFF94A3B8),
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w600,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 3),
//                                       Text(
//                                         'Latest Score: $latest%',
//                                         maxLines: 1,
//                                         overflow: TextOverflow.ellipsis,
//                                         style: const TextStyle(
//                                           color: Color(0xFFCBD5E1),
//                                           fontSize: 11,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 10),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         child: ElevatedButton(
//                                           onPressed: () => openSubject(sub),
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: isCompleted
//                                                 ? const Color(0xFF16A34A)
//                                                 : const Color(0xFF8B5CF6),
//                                             foregroundColor: Colors.white,
//                                             elevation: 0,
//                                             padding: const EdgeInsets.symmetric(
//                                               vertical: 8,
//                                             ),
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius: BorderRadius.circular(10),
//                                             ),
//                                           ),
//                                           child: Text(
//                                             isCompleted
//                                                 ? 'View Subject'
//                                                 : 'Open Subject',
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.w900,
//                                               fontSize: 11,
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                   ),
//                   if (totalPages > 1)
//                     Container(
//                       height: 42,
//                       margin: const EdgeInsets.only(top: 6, bottom: 4),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           ElevatedButton(
//                             onPressed: page == 0
//                                 ? null
//                                 : () {
//                                     setState(() {
//                                       page -= 1;
//                                     });
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF8B5CF6),
//                               foregroundColor: Colors.white,
//                               disabledBackgroundColor:
//                                   const Color(0xFF8B5CF6).withValues(alpha: 0.4),
//                               elevation: 0,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 14,
//                                 vertical: 8,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: const Text(
//                               'Previous',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             '${page + 1} / $totalPages',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w800,
//                               fontSize: 13,
//                             ),
//                           ),
//                           ElevatedButton(
//                             onPressed: page == totalPages - 1
//                                 ? null
//                                 : () {
//                                     setState(() {
//                                       page += 1;
//                                     });
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF8B5CF6),
//                               foregroundColor: Colors.white,
//                               disabledBackgroundColor:
//                                   const Color(0xFF8B5CF6).withValues(alpha: 0.4),
//                               elevation: 0,
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 14,
//                                 vertical: 8,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: const Text(
//                               'Next',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _StatBox extends StatelessWidget {
//   final String label;
//   final String value;

//   const _StatBox({
//     required this.label,
//     required this.value,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0B1220),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: Colors.white.withValues(alpha: 0.06),
//         ),
//       ),
//       child: Column(
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//               color: Color(0xFF94A3B8),
//               fontSize: 12,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }







// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/api/api_client.dart';
// import '../../providers/auth_provider.dart';
// import 'subject_screen.dart';

// class StudentDashboardScreen extends StatefulWidget {
//   const StudentDashboardScreen({super.key});

//   @override
//   State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
// }

// class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
//   Map<String, dynamic>? data;
//   bool loading = true;
//   String? error;
//   int page = 0;

//   static const int cardsPerRow = 2;
//   static const int rowsPerPage = 2;
//   static const int itemsPerPage = cardsPerRow * rowsPerPage;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(fetchDashboard);
//   }

//   Future<void> fetchDashboard() async {
//     if (!mounted) return;

//     setState(() {
//       loading = true;
//       error = null;
//     });

//     try {
//       final res = await ApiClient.dio.get('/student/dashboard');
//       final responseData = (res.data is Map<String, dynamic>)
//           ? res.data as Map<String, dynamic>
//           : <String, dynamic>{};

//       final subjects = List<String>.from(responseData['subjects'] ?? []);
//       final subjectScores =
//           Map<String, dynamic>.from(responseData['subjectScores'] ?? {});
//       final pendingLevels =
//           Map<String, dynamic>.from(responseData['pendingLevels'] ?? {});
//       final user = Map<String, dynamic>.from(responseData['user'] ?? {});

//       if (!mounted) return;

//       setState(() {
//         data = {
//           'user': user,
//           'subjects': subjects,
//           'subjectScores': subjectScores,
//           'pendingLevels': pendingLevels,
//         };
//         page = 0;
//       });
//     } on DioException catch (err) {
//       final statusCode = err.response?.statusCode;
//       String message = 'Something went wrong';

//       final responseData = err.response?.data;

//       if (responseData is Map && responseData['message'] != null) {
//         message = responseData['message'].toString();
//       } else if (err.message != null && err.message!.isNotEmpty) {
//         message = err.message!;
//       } else {
//         message = err.toString();
//       }

//       if (statusCode == 401) {
//         if (!mounted) return;
//         await context.read<AuthProvider>().logout();
//         return;
//       }

//       if (!mounted) return;
//       setState(() {
//         error = message;
//       });
//     } catch (err) {
//       if (!mounted) return;
//       setState(() {
//         error = err.toString();
//       });
//     } finally {
//       if (!mounted) return;
//       setState(() {
//         loading = false;
//       });
//     }
//   }

//   Map<String, dynamic> getSubjectStatus(String sub) {
//     final latest = num.tryParse('${data?['subjectScores']?[sub] ?? 0}') ?? 0;

//     final rawPending = data?['pendingLevels']?[sub];
//     final pendingText = rawPending == null ? '-' : rawPending.toString().trim();
//     final normalizedPending = pendingText.toLowerCase();

//     final isCompleted = pendingText == '-' ||
//         pendingText == '0' ||
//         normalizedPending == 'completed' ||
//         normalizedPending == 'complete';

//     final badgeLabel = isCompleted ? 'Completed' : 'Active';
//     final badgeType = isCompleted ? 'green' : 'blue';
//     final displayPending = isCompleted ? '-' : pendingText;

//     return {
//       'latest': latest,
//       'isCompleted': isCompleted,
//       'badgeLabel': badgeLabel,
//       'badgeType': badgeType,
//       'displayPending': displayPending,
//     };
//   }

//   Map<String, dynamic> get summary {
//     if (data == null) {
//       return {
//         'totalSubjects': 0,
//         'avgScore': '0',
//         'activeCount': 0,
//       };
//     }

//     final subjects = List<String>.from(data?['subjects'] ?? []);

//     final scores = subjects
//         .map((sub) => num.tryParse('${data?['subjectScores']?[sub] ?? 0}') ?? 0)
//         .toList();

//     final avgScore = scores.isNotEmpty
//         ? (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1)
//         : '0';

//     final activeCount = subjects
//         .where((sub) => !(getSubjectStatus(sub)['isCompleted'] as bool))
//         .length;

//     return {
//       'totalSubjects': subjects.length,
//       'avgScore': avgScore,
//       'activeCount': activeCount,
//     };
//   }

//   void openSubject(String subject) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SubjectScreen(initialSubject: subject),
//       ),
//     ).then((_) => fetchDashboard());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isVerySmall = width < 340 || height < 680;

//     if (loading) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Container(
//               width: double.infinity,
//               margin: const EdgeInsets.all(18),
//               padding: const EdgeInsets.all(28),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF111827),
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(
//                   color: Colors.white.withOpacity(0.08),
//                 ),
//               ),
//               child: const Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   CircularProgressIndicator(color: Color(0xFF8B5CF6)),
//                   SizedBox(height: 14),
//                   Text(
//                     'Loading Dashboard',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 20,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Please wait while your subjects are being prepared...',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color(0xFF94A3B8),
//                       fontSize: 14,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     if (error != null) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Container(
//               width: double.infinity,
//               margin: const EdgeInsets.all(18),
//               padding: const EdgeInsets.all(22),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF111827),
//                 borderRadius: BorderRadius.circular(22),
//                 border: Border.all(
//                   color: const Color(0x4DEF4444),
//                 ),
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Dashboard Error',
//                     style: TextStyle(
//                       color: Color(0xFFFCA5A5),
//                       fontSize: 18,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Error: $error',
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Color(0xFFFECACA),
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: fetchDashboard,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF8B5CF6),
//                       foregroundColor: Colors.white,
//                     ),
//                     child: const Text('Retry'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     if (data == null) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Text(
//               'No dashboard data available.',
//               style: TextStyle(
//                 color: Color(0xFFCBD5E1),
//                 fontWeight: FontWeight.w600,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final user = Map<String, dynamic>.from(data?['user'] ?? {});
//     final subjects = List<String>.from(data?['subjects'] ?? []);

//     final totalPages =
//         subjects.isEmpty ? 1 : (subjects.length / itemsPerPage).ceil();

//     if (page >= totalPages) {
//       page = totalPages - 1;
//     }
//     if (page < 0) {
//       page = 0;
//     }

//     final paginatedSubjects =
//         subjects.skip(page * itemsPerPage).take(itemsPerPage).toList();

//     final dashboardSummary = summary;
//     final cardGap = isVerySmall ? 8.0 : 12.0;
//     final outerPadding = isVerySmall ? 12.0 : 16.0;
//     final sectionGap = isVerySmall ? 8.0 : 10.0;

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Positioned(
//               top: -40,
//               right: -10,
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF7C3AED).withOpacity(0.18),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 40,
//               left: -50,
//               child: Container(
//                 width: 220,
//                 height: 220,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF3B82F6).withOpacity(0.10),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.fromLTRB(
//                 outerPadding,
//                 10,
//                 outerPadding,
//                 isVerySmall ? 8 : 12,
//               ),
//               child: Column(
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     margin: EdgeInsets.only(bottom: sectionGap),
//                     padding: EdgeInsets.all(isVerySmall ? 12 : 14),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF111827),
//                       borderRadius: BorderRadius.circular(22),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.08),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Student Panel',
//                           style: TextStyle(
//                             color: Color(0xFFA78BFA),
//                             fontSize: 13,
//                             fontWeight: FontWeight.w800,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           'Welcome, ${user['name'] ?? 'Student'}',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: isVerySmall ? 18 : 21,
//                             fontWeight: FontWeight.w900,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Track your subjects, latest scores, and pending levels from one place.',
//                           maxLines: isVerySmall ? 2 : 3,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: const Color(0xFF94A3B8),
//                             fontSize: isVerySmall ? 11 : 12,
//                             height: 1.4,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Subjects',
//                                 value: '${dashboardSummary['totalSubjects']}',
//                                 small: isVerySmall,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Average',
//                                 value: '${dashboardSummary['avgScore']}%',
//                                 small: isVerySmall,
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Active',
//                                 value: '${dashboardSummary['activeCount']}',
//                                 small: isVerySmall,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: Padding(
//                       padding: EdgeInsets.only(left: 2, bottom: sectionGap),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Your Subjects',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: isVerySmall ? 15 : 16,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Text(
//                             'Tap any subject to continue',
//                             style: TextStyle(
//                               color: const Color(0xFF94A3B8),
//                               fontSize: isVerySmall ? 11 : 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: paginatedSubjects.isEmpty
//                         ? Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(24),
//                             decoration: BoxDecoration(
//                               color: const Color(0xFF111827),
//                               borderRadius: BorderRadius.circular(22),
//                               border: Border.all(
//                                 color: Colors.white.withOpacity(0.08),
//                               ),
//                             ),
//                             child: const Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   'No Subjects Found',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.w900,
//                                   ),
//                                 ),
//                                 SizedBox(height: 8),
//                                 Text(
//                                   'Subjects will appear here once available.',
//                                   textAlign: TextAlign.center,
//                                   style: TextStyle(
//                                     color: Color(0xFF94A3B8),
//                                     fontSize: 14,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : Column(
//                             children: [
//                               for (int rowIndex = 0;
//                                   rowIndex < rowsPerPage;
//                                   rowIndex++) ...[
//                                 Expanded(
//                                   child: Padding(
//                                     padding: EdgeInsets.only(
//                                       top: rowIndex == 0 ? 0 : cardGap,
//                                     ),
//                                     child: Row(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.stretch,
//                                       children: [
//                                         for (int colIndex = 0;
//                                             colIndex < cardsPerRow;
//                                             colIndex++) ...[
//                                           Expanded(
//                                             child: Builder(
//                                               builder: (context) {
//                                                 final itemIndex =
//                                                     rowIndex * cardsPerRow +
//                                                         colIndex;

//                                                 if (itemIndex >=
//                                                     paginatedSubjects.length) {
//                                                   return const SizedBox();
//                                                 }

//                                                 final sub =
//                                                     paginatedSubjects[itemIndex];
//                                                 final status =
//                                                     getSubjectStatus(sub);
//                                                 final latest = status['latest'];
//                                                 final isCompleted =
//                                                     status['isCompleted']
//                                                         as bool;
//                                                 final badgeLabel = status[
//                                                         'badgeLabel']
//                                                     .toString();
//                                                 final badgeType = status[
//                                                         'badgeType']
//                                                     .toString();
//                                                 final displayPending = status[
//                                                         'displayPending']
//                                                     .toString();

//                                                 return _SubjectCard(
//                                                   subject: sub,
//                                                   latest: latest.toString(),
//                                                   badgeLabel: badgeLabel,
//                                                   badgeType: badgeType,
//                                                   displayPending:
//                                                       displayPending,
//                                                   isCompleted: isCompleted,
//                                                   isVerySmall: isVerySmall,
//                                                   onTap: () => openSubject(sub),
//                                                 );
//                                               },
//                                             ),
//                                           ),
//                                           if (colIndex != cardsPerRow - 1)
//                                             SizedBox(width: cardGap),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ],
//                           ),
//                   ),
//                   if (totalPages > 1)
//                     Container(
//                       height: isVerySmall ? 40 : 42,
//                       margin: const EdgeInsets.only(top: 6, bottom: 4),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           ElevatedButton(
//                             onPressed: page == 0
//                                 ? null
//                                 : () {
//                                     setState(() {
//                                       page -= 1;
//                                     });
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF8B5CF6),
//                               foregroundColor: Colors.white,
//                               disabledBackgroundColor:
//                                   const Color(0xFF8B5CF6).withOpacity(0.4),
//                               elevation: 0,
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: isVerySmall ? 12 : 14,
//                                 vertical: 8,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: Text(
//                               'Previous',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: isVerySmall ? 11 : 12,
//                               ),
//                             ),
//                           ),
//                           Text(
//                             '${page + 1} / $totalPages',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w800,
//                               fontSize: isVerySmall ? 12 : 13,
//                             ),
//                           ),
//                           ElevatedButton(
//                             onPressed: page == totalPages - 1
//                                 ? null
//                                 : () {
//                                     setState(() {
//                                       page += 1;
//                                     });
//                                   },
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: const Color(0xFF8B5CF6),
//                               foregroundColor: Colors.white,
//                               disabledBackgroundColor:
//                                   const Color(0xFF8B5CF6).withOpacity(0.4),
//                               elevation: 0,
//                               padding: EdgeInsets.symmetric(
//                                 horizontal: isVerySmall ? 12 : 14,
//                                 vertical: 8,
//                               ),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                             ),
//                             child: Text(
//                               'Next',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: isVerySmall ? 11 : 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _SubjectCard extends StatelessWidget {
//   final String subject;
//   final String latest;
//   final String badgeLabel;
//   final String badgeType;
//   final String displayPending;
//   final bool isCompleted;
//   final bool isVerySmall;
//   final VoidCallback onTap;

//   const _SubjectCard({
//     required this.subject,
//     required this.latest,
//     required this.badgeLabel,
//     required this.badgeType,
//     required this.displayPending,
//     required this.isCompleted,
//     required this.isVerySmall,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final compactText = isVerySmall ? 10.0 : 11.0;
//     final titleSize = isVerySmall ? 13.0 : 14.0;
//     final buttonSize = isVerySmall ? 10.0 : 11.0;

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final superCompact = constraints.maxHeight < 125;

//         return InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Container(
//             padding: EdgeInsets.all(superCompact ? 10 : 12),
//             decoration: BoxDecoration(
//               color: const Color(0xFF111827),
//               borderRadius: BorderRadius.circular(16),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.08),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         subject,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: titleSize,
//                           fontWeight: FontWeight.w900,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Flexible(
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: superCompact ? 6 : 8,
//                           vertical: superCompact ? 3 : 4,
//                         ),
//                         decoration: BoxDecoration(
//                           borderRadius: BorderRadius.circular(999),
//                           color: badgeType == 'green'
//                               ? const Color(0xFF22C55E).withOpacity(0.15)
//                               : const Color(0xFF3B82F6).withOpacity(0.15),
//                         ),
//                         child: Text(
//                           badgeLabel,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: isVerySmall ? 10 : 11,
//                             color: badgeType == 'green'
//                                 ? const Color(0xFF4ADE80)
//                                 : const Color(0xFF60A5FA),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: superCompact ? 6 : 8),
//                 Text(
//                   'Pending Level: $displayPending',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: const Color(0xFF94A3B8),
//                     fontSize: compactText,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: 3),
//                 Text(
//                   'Latest Score: $latest%',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: const Color(0xFFCBD5E1),
//                     fontSize: compactText,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const Spacer(),
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: onTap,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: isCompleted
//                           ? const Color(0xFF16A34A)
//                           : const Color(0xFF8B5CF6),
//                       foregroundColor: Colors.white,
//                       elevation: 0,
//                       minimumSize: Size.fromHeight(superCompact ? 32 : 36),
//                       padding: EdgeInsets.symmetric(
//                         vertical: superCompact ? 6 : 8,
//                       ),
//                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                     child: Text(
//                       isCompleted ? 'View Subject' : 'Open Subject',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontWeight: FontWeight.w900,
//                         fontSize: buttonSize,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }

// class _StatBox extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool small;

//   const _StatBox({
//     required this.label,
//     required this.value,
//     required this.small,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(vertical: small ? 8 : 10, horizontal: 4),
//       decoration: BoxDecoration(
//         color: const Color(0xFF0B1220),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(
//           color: Colors.white.withOpacity(0.06),
//         ),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             label,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: const Color(0xFF94A3B8),
//               fontSize: small ? 11 : 12,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             value,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: small ? 16 : 18,
//               fontWeight: FontWeight.w900,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import 'subject_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;
  int page = 0;

  static const int cardsPerRow = 2;
  static const int rowsPerPage = 2;
  static const int itemsPerPage = cardsPerRow * rowsPerPage;

  @override
  void initState() {
    super.initState();
    Future.microtask(fetchDashboard);
  }

  Future<void> fetchDashboard() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiClient.dio.get('/student/dashboard');
      final responseData = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      final subjects = List<String>.from(responseData['subjects'] ?? []);
      final subjectScores =
          Map<String, dynamic>.from(responseData['subjectScores'] ?? {});
      final pendingLevels =
          Map<String, dynamic>.from(responseData['pendingLevels'] ?? {});
      final user = Map<String, dynamic>.from(responseData['user'] ?? {});

      if (!mounted) return;

      setState(() {
        data = {
          'user': user,
          'subjects': subjects,
          'subjectScores': subjectScores,
          'pendingLevels': pendingLevels,
        };
        page = 0;
      });
    } on DioException catch (err) {
      final statusCode = err.response?.statusCode;
      String message = 'Something went wrong';

      final responseData = err.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (err.message != null && err.message!.isNotEmpty) {
        message = err.message!;
      } else {
        message = err.toString();
      }

      if (statusCode == 401) {
        if (!mounted) return;
        await context.read<AuthProvider>().logout();
        return;
      }

      if (!mounted) return;
      setState(() {
        error = message;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        error = err.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Map<String, dynamic> getSubjectStatus(String sub) {
    final latest = num.tryParse('${data?['subjectScores']?[sub] ?? 0}') ?? 0;

    final rawPending = data?['pendingLevels']?[sub];
    final pendingText = rawPending == null ? '-' : rawPending.toString().trim();
    final normalizedPending = pendingText.toLowerCase();

    final isCompleted = pendingText == '-' ||
        pendingText == '0' ||
        normalizedPending == 'completed' ||
        normalizedPending == 'complete';

    final badgeLabel = isCompleted ? 'Completed' : 'Active';
    final badgeType = isCompleted ? 'green' : 'blue';
    final displayPending = isCompleted ? '-' : pendingText;

    return {
      'latest': latest,
      'isCompleted': isCompleted,
      'badgeLabel': badgeLabel,
      'badgeType': badgeType,
      'displayPending': displayPending,
    };
  }

  Map<String, dynamic> get summary {
    if (data == null) {
      return {
        'totalSubjects': 0,
        'avgScore': '0',
        'activeCount': 0,
      };
    }

    final subjects = List<String>.from(data?['subjects'] ?? []);

    final scores = subjects
        .map((sub) => num.tryParse('${data?['subjectScores']?[sub] ?? 0}') ?? 0)
        .toList();

    final avgScore = scores.isNotEmpty
        ? (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1)
        : '0';

    final activeCount = subjects
        .where((sub) => !(getSubjectStatus(sub)['isCompleted'] as bool))
        .length;

    return {
      'totalSubjects': subjects.length,
      'avgScore': avgScore,
      'activeCount': activeCount,
    };
  }

  void openSubject(String subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubjectScreen(initialSubject: subject),
      ),
    ).then((_) => fetchDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isVerySmall = width < 340 || height < 680;

    final user = Map<String, dynamic>.from(data?['user'] ?? {});
    final subjects = List<String>.from(data?['subjects'] ?? []);

    final totalPages =
        subjects.isEmpty ? 1 : (subjects.length / itemsPerPage).ceil();

    final safePage = totalPages <= 0 ? 0 : page.clamp(0, totalPages - 1);
    final paginatedSubjects =
        subjects.skip(safePage * itemsPerPage).take(itemsPerPage).toList();

    final dashboardSummary = summary;
    final cardGap = isVerySmall ? 8.0 : 12.0;
    final outerPadding = isVerySmall ? 12.0 : 16.0;
    final sectionGap = isVerySmall ? 8.0 : 10.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -10,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.18),
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: -50,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.10),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                outerPadding,
                10,
                outerPadding,
                isVerySmall ? 8 : 12,
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: sectionGap),
                    padding: EdgeInsets.all(isVerySmall ? 12 : 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Student Panel',
                          style: TextStyle(
                            color: Color(0xFFA78BFA),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Welcome, ${user['name'] ?? 'Student'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isVerySmall ? 18 : 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Track your subjects, latest scores, and pending levels from one place.',
                          maxLines: isVerySmall ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: isVerySmall ? 11 : 12,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: 'Subjects',
                                value: '${dashboardSummary['totalSubjects']}',
                                small: isVerySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                label: 'Average',
                                value: '${dashboardSummary['avgScore']}%',
                                small: isVerySmall,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                label: 'Active',
                                value: '${dashboardSummary['activeCount']}',
                                small: isVerySmall,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 2, bottom: sectionGap),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Subjects',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isVerySmall ? 15 : 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tap any subject to continue',
                            style: TextStyle(
                              color: const Color(0xFF94A3B8),
                              fontSize: isVerySmall ? 11 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: loading
                        ? Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111827),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Color(0xFF8B5CF6),
                                ),
                                SizedBox(height: 14),
                                Text(
                                  'Loading Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Please wait while your subjects are being prepared...',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : error != null
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111827),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(0x4DEF4444),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Dashboard Error',
                                      style: TextStyle(
                                        color: Color(0xFFFCA5A5),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Error: $error',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFFFECACA),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: fetchDashboard,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF8B5CF6),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              )
                            : data == null || paginatedSubjects.isEmpty
                                ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF111827),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.08),
                                      ),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'No Subjects Found',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Subjects will appear here once available.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    children: [
                                      for (int rowIndex = 0;
                                          rowIndex < rowsPerPage;
                                          rowIndex++) ...[
                                        Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.only(
                                              top: rowIndex == 0 ? 0 : cardGap,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                for (int colIndex = 0;
                                                    colIndex < cardsPerRow;
                                                    colIndex++) ...[
                                                  Expanded(
                                                    child: Builder(
                                                      builder: (context) {
                                                        final itemIndex =
                                                            rowIndex *
                                                                    cardsPerRow +
                                                                colIndex;

                                                        if (itemIndex >=
                                                            paginatedSubjects
                                                                .length) {
                                                          return const SizedBox();
                                                        }

                                                        final sub =
                                                            paginatedSubjects[
                                                                itemIndex];
                                                        final status =
                                                            getSubjectStatus(sub);
                                                        final latest =
                                                            status['latest'];
                                                        final isCompleted =
                                                            status['isCompleted']
                                                                as bool;
                                                        final badgeLabel = status[
                                                                'badgeLabel']
                                                            .toString();
                                                        final badgeType = status[
                                                                'badgeType']
                                                            .toString();
                                                        final displayPending =
                                                            status[
                                                                    'displayPending']
                                                                .toString();

                                                        return _SubjectCard(
                                                          subject: sub,
                                                          latest:
                                                              latest.toString(),
                                                          badgeLabel:
                                                              badgeLabel,
                                                          badgeType: badgeType,
                                                          displayPending:
                                                              displayPending,
                                                          isCompleted:
                                                              isCompleted,
                                                          isVerySmall:
                                                              isVerySmall,
                                                          onTap: () =>
                                                              openSubject(sub),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  if (colIndex !=
                                                      cardsPerRow - 1)
                                                    SizedBox(width: cardGap),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                  ),
                  if (!loading && error == null && totalPages > 1)
                    Container(
                      height: isVerySmall ? 40 : 42,
                      margin: const EdgeInsets.only(top: 6, bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: safePage == 0
                                ? null
                                : () {
                                    setState(() {
                                      page = safePage - 1;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF8B5CF6).withOpacity(0.4),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmall ? 12 : 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isVerySmall ? 11 : 12,
                              ),
                            ),
                          ),
                          Text(
                            '${safePage + 1} / $totalPages',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: isVerySmall ? 12 : 13,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: safePage == totalPages - 1
                                ? null
                                : () {
                                    setState(() {
                                      page = safePage + 1;
                                    });
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8B5CF6),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF8B5CF6).withOpacity(0.4),
                              elevation: 0,
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmall ? 12 : 14,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Next',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isVerySmall ? 11 : 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  final String subject;
  final String latest;
  final String badgeLabel;
  final String badgeType;
  final String displayPending;
  final bool isCompleted;
  final bool isVerySmall;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.latest,
    required this.badgeLabel,
    required this.badgeType,
    required this.displayPending,
    required this.isCompleted,
    required this.isVerySmall,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final compactText = isVerySmall ? 10.0 : 11.0;
    final titleSize = isVerySmall ? 13.0 : 14.0;
    final buttonSize = isVerySmall ? 10.0 : 11.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final superCompact = constraints.maxHeight < 125;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(superCompact ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: superCompact ? 6 : 8,
                          vertical: superCompact ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: badgeType == 'green'
                              ? const Color(0xFF22C55E).withOpacity(0.15)
                              : const Color(0xFF3B82F6).withOpacity(0.15),
                        ),
                        child: Text(
                          badgeLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isVerySmall ? 10 : 11,
                            color: badgeType == 'green'
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: superCompact ? 6 : 8),
                Text(
                  'Pending Level: $displayPending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: compactText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Latest Score: $latest%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFCBD5E1),
                    fontSize: compactText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: Size.fromHeight(superCompact ? 32 : 36),
                      padding: EdgeInsets.symmetric(
                        vertical: superCompact ? 6 : 8,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isCompleted ? 'View Subject' : 'Open Subject',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: buttonSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool small;

  const _StatBox({
    required this.label,
    required this.value,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: small ? 8 : 10, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF94A3B8),
              fontSize: small ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: small ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}





