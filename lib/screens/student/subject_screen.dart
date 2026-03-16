// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/api/api_client.dart';
// import '../../providers/auth_provider.dart';
// import 'certificate_screen.dart';
// import 'exam_attempt_screen.dart';

// class SubjectScreen extends StatefulWidget {
//   final String? initialSubject;

//   const SubjectScreen({super.key, this.initialSubject});

//   @override
//   State<SubjectScreen> createState() => _SubjectScreenState();
// }

// class _SubjectScreenState extends State<SubjectScreen> {
//   static const int passMark = 40;

//   Map<String, dynamic>? data;
//   bool loading = true;
//   String error = '';
//   DateTime now = DateTime.now();

//   Timer? _timer;
//   bool _loaded = false;
//   String? subjectParam;

//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) {
//         setState(() {
//           now = DateTime.now();
//         });
//       }
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_loaded) return;
//     _loaded = true;

//     final args = ModalRoute.of(context)?.settings.arguments;
//     if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
//       subjectParam = widget.initialSubject;
//     } else if (args is Map && args['subject'] != null) {
//       subjectParam = args['subject'].toString();
//     }

//     fetchData();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   String formatDateTime(DateTime? date) {
//     if (date == null) return '--';

//     try {
//       const months = [
//         'Jan',
//         'Feb',
//         'Mar',
//         'Apr',
//         'May',
//         'Jun',
//         'Jul',
//         'Aug',
//         'Sep',
//         'Oct',
//         'Nov',
//         'Dec',
//       ];

//       final day = date.day.toString().padLeft(2, '0');
//       final month = months[date.month - 1];

//       int hour = date.hour;
//       final minute = date.minute.toString().padLeft(2, '0');
//       final amPm = hour >= 12 ? 'PM' : 'AM';
//       hour = hour % 12;
//       if (hour == 0) hour = 12;

//       final hourText = hour.toString().padLeft(2, '0');
//       return '$day $month, $hourText:$minute $amPm';
//     } catch (_) {
//       return '--';
//     }
//   }

//   String formatDuration(int seconds) {
//     if (seconds <= 0) return '00:00:00';

//     final h = seconds ~/ 3600;
//     final m = (seconds % 3600) ~/ 60;
//     final s = seconds % 60;

//     return [h, m, s].map((n) => n.toString().padLeft(2, '0')).join(':');
//   }

//   List<List<dynamic>> chunkArray(List<dynamic> arr, int size) {
//     final output = <List<dynamic>>[];
//     for (int i = 0; i < arr.length; i += size) {
//       output.add(arr.sublist(i, i + size > arr.length ? arr.length : i + size));
//     }
//     return output;
//   }

//   Future<void> fetchData() async {
//     if (subjectParam == null || subjectParam!.isEmpty) {
//       setState(() {
//         loading = false;
//         error = 'Subject missing';
//       });
//       return;
//     }

//     setState(() {
//       loading = true;
//       error = '';
//     });

//     try {
//       final subUpper = subjectParam!.toUpperCase();
//       final res = await ApiClient.dio.get(
//         '/student/subject/${Uri.encodeComponent(subUpper)}',
//       );

//       final resData = res.data is Map<String, dynamic>
//           ? res.data as Map<String, dynamic>
//           : <String, dynamic>{};

//       final levelsRaw = resData['levels'] is List ? resData['levels'] as List : [];

//       final levels = <Map<String, dynamic>>[];

//       for (int i = 1; i <= 5; i++) {
//         Map<String, dynamic>? lvl;

//         for (final item in levelsRaw) {
//           if (item is Map && int.tryParse('${item['level']}') == i) {
//             lvl = Map<String, dynamic>.from(item);
//             break;
//           }
//         }

//         if (lvl != null) {
//           final scorePercent =
//               (num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0).clamp(0, 100);

//           final startTime =
//               lvl['start_time'] != null ? DateTime.tryParse('${lvl['start_time']}') : null;
//           final endTime =
//               lvl['end_time'] != null ? DateTime.tryParse('${lvl['end_time']}') : null;

//           levels.add({
//             'level': i,
//             'attempted': lvl['attempted'] == true,
//             'passed': scorePercent >= passMark,
//             'scorePercent': scorePercent,
//             'retryCount': int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0,
//             'maxRetry': int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1,
//             'start_time': startTime,
//             'end_time': endTime,
//           });
//         } else {
//           levels.add({
//             'level': i,
//             'attempted': false,
//             'passed': false,
//             'scorePercent': 0,
//             'retryCount': 0,
//             'maxRetry': 1,
//             'start_time': null,
//             'end_time': null,
//           });
//         }
//       }

//       final totalScore = levels.fold<num>(
//         0,
//         (acc, l) => acc + ((l['scorePercent'] as num?) ?? 0),
//       );

//       final aggregatePercent = (totalScore / levels.length).clamp(0, 100);

//       if (!mounted) return;

//       setState(() {
//         data = {
//           'subject': resData['subject'] ?? subjectParam,
//           'levels': levels,
//           'aggregatePercent': aggregatePercent,
//         };
//       });
//     } on DioException catch (err) {
//       int? statusCode;
//       String message = 'Failed to load exams';

//       statusCode = err.response?.statusCode;
//       final resData = err.response?.data;

//       if (resData is Map && resData['message'] != null) {
//         message = resData['message'].toString();
//       } else if (err.message != null && err.message!.isNotEmpty) {
//         message = err.message!;
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

//   bool isPreviousPassed(List levels, int idx) {
//     if (idx == 0) return true;
//     return levels[idx - 1]['passed'] == true;
//   }

//   bool get allPassed {
//     final levels = data?['levels'] as List?;
//     if (levels == null || levels.isEmpty) return false;
//     return levels.every((l) => l['passed'] == true);
//   }

//   int get passedCount {
//     final levels = data?['levels'] as List?;
//     if (levels == null) return 0;
//     return levels.where((l) => l['passed'] == true).length;
//   }

//   int get attemptedCount {
//     final levels = data?['levels'] as List?;
//     if (levels == null) return 0;
//     return levels.where((l) => l['attempted'] == true).length;
//   }

//   Map<String, String> getBadge({
//     required bool passed,
//     required bool prevPassed,
//     required bool isAfterEnd,
//     required bool isExamActive,
//     required bool isBeforeStart,
//   }) {
//     if (passed) return {'label': 'Passed', 'type': 'green'};
//     if (!prevPassed) return {'label': 'Locked', 'type': 'gray'};
//     if (isAfterEnd) return {'label': 'Ended', 'type': 'red'};
//     if (isExamActive) return {'label': 'Live', 'type': 'blue'};
//     if (isBeforeStart) return {'label': 'Soon', 'type': 'yellow'};
//     return {'label': 'Locked', 'type': 'gray'};
//   }

//   Color badgeBg(String type) {
//     switch (type) {
//       case 'green':
//         return const Color(0xFF22C55E).withValues(alpha: 0.15);
//       case 'blue':
//         return const Color(0xFF3B82F6).withValues(alpha: 0.15);
//       case 'yellow':
//         return const Color(0xFFF59E0B).withValues(alpha: 0.15);
//       case 'red':
//         return const Color(0xFFEF4444).withValues(alpha: 0.15);
//       default:
//         return const Color(0xFF94A3B8).withValues(alpha: 0.15);
//     }
//   }

//   Color badgeTextColor(String type) {
//     switch (type) {
//       case 'green':
//         return const Color(0xFF4ADE80);
//       case 'blue':
//         return const Color(0xFF60A5FA);
//       case 'yellow':
//         return const Color(0xFFFBBF24);
//       case 'red':
//         return const Color(0xFFF87171);
//       default:
//         return const Color(0xFFCBD5E1);
//     }
//   }

//   void onPressAttempt(Map<String, dynamic> lvl) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ExamAttemptScreen(
//           subject: subjectParam,
//           level: lvl['level'],
//           attemptKey: DateTime.now().millisecondsSinceEpoch,
//         ),
//       ),
//     ).then((_) => fetchData());
//   }

//   void onPressCertificate() {
//     final authProvider = context.read<AuthProvider>();
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CertificateScreen(
//           name: authProvider.user?['name']?.toString() ?? 'Student',
//           subject: (data?['subject'] ?? subjectParam).toString(),
//           aggregatePercent: num.tryParse('${data?['aggregatePercent'] ?? 0}') ?? 0,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.user;

//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isVerySmall = width < 340 || height < 650;
//     final isSmall = width < 380 || height < 760;
//     final cardsPerRow = isVerySmall ? 1 : 2;

//     final fontScale = isVerySmall ? 0.82 : (isSmall ? 0.9 : 1.0);
//     final spacing = isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0);

//     final ui = {
//       'containerPadding': spacing,
//       'heroPadding': isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0),
//       'cardPadding': isVerySmall ? 10.0 : (isSmall ? 10.0 : 12.0),
//       'titleSize': isVerySmall ? 18.0 : (isSmall ? 21.0 : 24.0),
//       'statLabel': 11 * fontScale,
//       'statValue': 16 * fontScale,
//       'cardTitle': isVerySmall ? 15.0 : (isSmall ? 15.0 : 16.0),
//       'cardMeta': isVerySmall ? 11.0 : 12.0,
//       'btnText': isVerySmall ? 11.0 : 12.0,
//       'badgeText': isVerySmall ? 10.0 : 11.0,
//     };

//     if (loading) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 12),
//                 Text(
//                   'Loading dashboard...',
//                   style: TextStyle(
//                     color: Color(0xFFCBD5E1),
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     if (error.isNotEmpty) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(18),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Something went wrong',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color(0xFFFCA5A5),
//                       fontSize: 18,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     error,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Color(0xFFFECACA),
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     if (data == null || (data!['levels'] as List?)?.isEmpty != false) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Text(
//               'No exams available',
//               style: TextStyle(
//                 color: Color(0xFFCBD5E1),
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final levels = List<Map<String, dynamic>>.from(data!['levels'] as List);
//     final cardsData = [
//       ...levels,
//       {
//         'level': 6,
//         'isCertificate': true,
//         'unlocked': allPassed,
//       }
//     ];

//     final levelRows = chunkArray(cardsData, cardsPerRow);

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Positioned(
//               top: -30,
//               right: -10,
//               child: Container(
//                 width: 160,
//                 height: 160,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF7C3AED).withValues(alpha: 0.18),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 30,
//               left: -30,
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(ui['containerPadding'] as double),
//               child: Column(
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     padding: EdgeInsets.all(ui['heroPadding'] as double),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF111827),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: Colors.white.withValues(alpha: 0.08),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Exam Dashboard',
//                           style: TextStyle(
//                             color: const Color(0xFFA78BFA),
//                             fontWeight: FontWeight.w800,
//                             fontSize: 12 * fontScale,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${data!['subject']}'.toUpperCase(),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w900,
//                             letterSpacing: 0.4,
//                             fontSize: ui['titleSize'] as double,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Welcome ${user?['name'] ?? 'Student'}',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: const Color(0xFF94A3B8),
//                             fontSize: isVerySmall ? 11 : 13,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Passed',
//                                 value: '$passedCount/5',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Attempt',
//                                 value: '$attemptedCount/5',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Avg',
//                                 value:
//                                     '${(num.tryParse('${data!['aggregatePercent']}') ?? 0).round()}%',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Progress',
//                               style: TextStyle(
//                                 color: const Color(0xFFCBD5E1),
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 11 * fontScale,
//                               ),
//                             ),
//                             Text(
//                               '${((passedCount / 5) * 100).round()}%',
//                               style: TextStyle(
//                                 color: const Color(0xFFCBD5E1),
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 11 * fontScale,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 6),
//                         Container(
//                           height: 8,
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF1E293B),
//                             borderRadius: BorderRadius.circular(999),
//                           ),
//                           child: FractionallySizedBox(
//                             alignment: Alignment.centerLeft,
//                             widthFactor: (passedCount / 5).clamp(0, 1),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF8B5CF6),
//                                 borderRadius: BorderRadius.circular(999),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Expanded(
//                     child: ListView.builder(
//                       padding: EdgeInsets.zero,
//                       itemCount: levelRows.length,
//                       itemBuilder: (context, rowIndex) {
//                         final row = levelRows[rowIndex];

//                         return Padding(
//                           padding: EdgeInsets.only(
//                             top: rowIndex == 0 ? 0 : (isVerySmall ? 8 : 10),
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               ...row.asMap().entries.map((entry) {
//                                 final indexInRow = entry.key;
//                                 final lvl = Map<String, dynamic>.from(entry.value);
//                                 final index = rowIndex * cardsPerRow + indexInRow;
//                                 final isCertificateCard = lvl['isCertificate'] == true;

//                                 if (isCertificateCard) {
//                                   return _buildCertificateCard(
//                                     context: context,
//                                     allPassed: allPassed,
//                                     aggregatePercent:
//                                         num.tryParse('${data!['aggregatePercent']}') ?? 0,
//                                     passedCount: passedCount,
//                                     cardsPerRow: cardsPerRow,
//                                     isVerySmall: isVerySmall,
//                                     isSmall: isSmall,
//                                     ui: ui,
//                                   );
//                                 }

//                                 final attempted = lvl['attempted'] == true;
//                                 final passed = lvl['passed'] == true;
//                                 final retryCount =
//                                     int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0;
//                                 final maxRetry =
//                                     int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1;
//                                 final scorePercent =
//                                     num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0;
//                                 final startTime = lvl['start_time'] as DateTime?;
//                                 final endTime = lvl['end_time'] as DateTime?;

//                                 final prevPassed = isPreviousPassed(levels, index);

//                                 final isBeforeStart =
//                                     startTime != null && now.isBefore(startTime);
//                                 final isAfterEnd =
//                                     endTime != null && now.isAfter(endTime);
//                                 final isExamActive = startTime != null &&
//                                     endTime != null &&
//                                     (now.isAtSameMomentAs(startTime) ||
//                                         now.isAfter(startTime)) &&
//                                     (now.isAtSameMomentAs(endTime) ||
//                                         now.isBefore(endTime));

//                                 final canAttempt = !passed &&
//                                     prevPassed &&
//                                     startTime != null &&
//                                     isExamActive &&
//                                     (!attempted || retryCount < maxRetry);

//                                 final secondsToStart = !passed && isBeforeStart && startTime != null
//                                     ? startTime.difference(now).inSeconds
//                                     : 0;

//                                 final badge = getBadge(
//                                   passed: passed,
//                                   prevPassed: prevPassed,
//                                   isAfterEnd: isAfterEnd,
//                                   isExamActive: isExamActive,
//                                   isBeforeStart: isBeforeStart,
//                                 );

//                                 String statusLine = 'Not attempted';
//                                 if (attempted) statusLine = 'Score $scorePercent%';
//                                 if (attempted && !passed) {
//                                   statusLine += ' • $retryCount/$maxRetry';
//                                 }

//                                 String timeLine = '';
//                                 if (!passed) {
//                                   if (isExamActive) {
//                                     timeLine = 'Live now';
//                                   } else if (isBeforeStart) {
//                                     timeLine = formatDuration(secondsToStart);
//                                   } else if (isAfterEnd) {
//                                     timeLine = 'Exam ended';
//                                   } else {
//                                     timeLine = 'Start ${formatDateTime(startTime)}';
//                                   }
//                                 }

//                                 String buttonLabel = 'Not Available';
//                                 if (passed) {
//                                   buttonLabel = 'Passed';
//                                 } else if (!prevPassed) {
//                                   buttonLabel = 'Complete L${lvl['level'] - 1}';
//                                 } else if (canAttempt) {
//                                   buttonLabel = attempted ? 'Retry Exam' : 'Start Exam';
//                                 }

//                                 return _buildLevelCard(
//                                   lvl: lvl,
//                                   passed: passed,
//                                   isExamActive: isExamActive,
//                                   canAttempt: canAttempt,
//                                   badge: badge,
//                                   statusLine: statusLine,
//                                   timeLine: timeLine,
//                                   buttonLabel: buttonLabel,
//                                   cardsPerRow: cardsPerRow,
//                                   isVerySmall: isVerySmall,
//                                   isSmall: isSmall,
//                                   ui: ui,
//                                 );
//                               }),
//                               if (cardsPerRow == 2 && row.length == 1)
//                                 const SizedBox(width: 0),
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCertificateCard({
//     required BuildContext context,
//     required bool allPassed,
//     required num aggregatePercent,
//     required int passedCount,
//     required int cardsPerRow,
//     required bool isVerySmall,
//     required bool isSmall,
//     required Map<String, dynamic> ui,
//   }) {
//     return Container(
//       width: cardsPerRow == 1
//           ? MediaQuery.of(context).size.width
//           : MediaQuery.of(context).size.width * 0.485 - 12,
//       constraints: BoxConstraints(
//         minHeight: cardsPerRow == 1
//             ? (isVerySmall ? 108 : 118)
//             : (isVerySmall ? 110 : (isSmall ? 126 : 138)),
//       ),
//       padding: EdgeInsets.all(ui['cardPadding'] as double),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111827),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: allPassed
//               ? const Color(0xFF22C55E).withValues(alpha: 0.40)
//               : Colors.white.withValues(alpha: 0.08),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Certification',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w900,
//                     fontSize: ui['cardTitle'] as double,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 6),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(999),
//                   color: allPassed
//                       ? const Color(0xFF22C55E).withValues(alpha: 0.15)
//                       : const Color(0xFF94A3B8).withValues(alpha: 0.15),
//                 ),
//                 child: Text(
//                   allPassed ? 'Unlocked' : 'Locked',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: allPassed
//                         ? const Color(0xFF4ADE80)
//                         : const Color(0xFFCBD5E1),
//                     fontWeight: FontWeight.w900,
//                     fontSize: ui['badgeText'] as double,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             allPassed
//                 ? 'Avg Score ${aggregatePercent.round()}%'
//                 : 'Complete all 5 levels',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: const Color(0xFF94A3B8),
//               fontWeight: FontWeight.w600,
//               fontSize: ui['cardMeta'] as double,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             allPassed ? 'Certificate ready' : '$passedCount/5 levels passed',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: const Color(0xFFCBD5E1),
//               fontWeight: FontWeight.w500,
//               fontSize: ui['cardMeta'] as double,
//             ),
//           ),
//           const Spacer(),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: allPassed ? onPressCertificate : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor:
//                     allPassed ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
//                 foregroundColor:
//                     allPassed ? Colors.white : const Color(0xFF94A3B8),
//                 disabledBackgroundColor: const Color(0xFF1E293B),
//                 disabledForegroundColor: const Color(0xFF94A3B8),
//                 elevation: 0,
//                 padding: EdgeInsets.symmetric(
//                   vertical: isVerySmall ? 8 : 10,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   side: allPassed
//                       ? BorderSide.none
//                       : BorderSide(
//                           color: Colors.white.withValues(alpha: 0.06),
//                         ),
//                 ),
//               ),
//               child: Text(
//                 allPassed ? 'Download' : 'Locked',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w900,
//                   fontSize: ui['btnText'] as double,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLevelCard({
//     required Map<String, dynamic> lvl,
//     required bool passed,
//     required bool isExamActive,
//     required bool canAttempt,
//     required Map<String, String> badge,
//     required String statusLine,
//     required String timeLine,
//     required String buttonLabel,
//     required int cardsPerRow,
//     required bool isVerySmall,
//     required bool isSmall,
//     required Map<String, dynamic> ui,
//   }) {
//     return Builder(
//       builder: (context) {
//         return Container(
//           width: cardsPerRow == 1
//               ? MediaQuery.of(context).size.width
//               : MediaQuery.of(context).size.width * 0.485 - 12,
//           constraints: BoxConstraints(
//             minHeight: cardsPerRow == 1
//                 ? (isVerySmall ? 108 : 118)
//                 : (isVerySmall ? 110 : (isSmall ? 126 : 138)),
//           ),
//           padding: EdgeInsets.all(ui['cardPadding'] as double),
//           decoration: BoxDecoration(
//             color: const Color(0xFF111827),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(
//               color: passed
//                   ? const Color(0xFF22C55E).withValues(alpha: 0.40)
//                   : isExamActive
//                       ? const Color(0xFF3B82F6).withValues(alpha: 0.40)
//                       : Colors.white.withValues(alpha: 0.08),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Level ${lvl['level']}',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                         fontSize: ui['cardTitle'] as double,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(999),
//                       color: badgeBg(badge['type']!),
//                     ),
//                     child: Text(
//                       badge['label']!,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: badgeTextColor(badge['type']!),
//                         fontWeight: FontWeight.w900,
//                         fontSize: ui['badgeText'] as double,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 6),
//               Text(
//                 statusLine,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   color: const Color(0xFF94A3B8),
//                   fontWeight: FontWeight.w600,
//                   fontSize: ui['cardMeta'] as double,
//                 ),
//               ),
//               if (timeLine.isNotEmpty) ...[
//                 const SizedBox(height: 4),
//                 Text(
//                   timeLine,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: const Color(0xFFCBD5E1),
//                     fontWeight: FontWeight.w500,
//                     fontSize: ui['cardMeta'] as double,
//                   ),
//                 ),
//               ],
//               const Spacer(),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (!passed && canAttempt) ? () => onPressAttempt(lvl) : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: passed
//                         ? const Color(0xFF16A34A)
//                         : canAttempt
//                             ? const Color(0xFF8B5CF6)
//                             : const Color(0xFF1E293B),
//                     foregroundColor:
//                         (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
//                     disabledBackgroundColor: passed
//                         ? const Color(0xFF16A34A)
//                         : const Color(0xFF1E293B),
//                     disabledForegroundColor:
//                         (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
//                     elevation: 0,
//                     padding: EdgeInsets.symmetric(
//                       vertical: isVerySmall ? 8 : 10,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: (!passed && !canAttempt)
//                           ? BorderSide(
//                               color: Colors.white.withValues(alpha: 0.06),
//                             )
//                           : BorderSide.none,
//                     ),
//                   ),
//                   child: Text(
//                     buttonLabel,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w900,
//                       fontSize: ui['btnText'] as double,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _StatBox extends StatelessWidget {
//   final String label;
//   final String value;
//   final double statLabelSize;
//   final double statValueSize;

//   const _StatBox({
//     required this.label,
//     required this.value,
//     required this.statLabelSize,
//     required this.statValueSize,
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
//             style: TextStyle(
//               color: const Color(0xFF94A3B8),
//               fontWeight: FontWeight.w700,
//               fontSize: statLabelSize,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//               fontSize: statValueSize,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/api/api_client.dart';
// import '../../providers/auth_provider.dart';
// import 'certificate_screen.dart';
// import 'exam_attempt_screen.dart';

// class SubjectScreen extends StatefulWidget {
//   final String? initialSubject;

//   const SubjectScreen({super.key, this.initialSubject});

//   @override
//   State<SubjectScreen> createState() => _SubjectScreenState();
// }

// class _SubjectScreenState extends State<SubjectScreen> {
//   static const int passMark = 40;

//   Map<String, dynamic>? data;
//   bool loading = true;
//   String error = '';
//   DateTime now = DateTime.now();

//   Timer? _timer;
//   bool _loaded = false;
//   String? subjectParam;

//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) {
//         setState(() {
//           now = DateTime.now();
//         });
//       }
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_loaded) return;
//     _loaded = true;

//     final args = ModalRoute.of(context)?.settings.arguments;

//     if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
//       subjectParam = widget.initialSubject;
//     } else if (args is Map && args['subject'] != null) {
//       subjectParam = args['subject'].toString();
//     }

//     fetchData();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   String formatDateTime(DateTime? date) {
//     if (date == null) return '--';

//     try {
//       const months = [
//         'Jan',
//         'Feb',
//         'Mar',
//         'Apr',
//         'May',
//         'Jun',
//         'Jul',
//         'Aug',
//         'Sep',
//         'Oct',
//         'Nov',
//         'Dec',
//       ];

//       final day = date.day.toString().padLeft(2, '0');
//       final month = months[date.month - 1];

//       int hour = date.hour;
//       final minute = date.minute.toString().padLeft(2, '0');
//       final amPm = hour >= 12 ? 'PM' : 'AM';
//       hour = hour % 12;
//       if (hour == 0) hour = 12;

//       final hourText = hour.toString().padLeft(2, '0');
//       return '$day $month, $hourText:$minute $amPm';
//     } catch (_) {
//       return '--';
//     }
//   }

//   String formatDuration(int seconds) {
//     if (seconds <= 0) return '00:00:00';

//     final h = seconds ~/ 3600;
//     final m = (seconds % 3600) ~/ 60;
//     final s = seconds % 60;

//     return [h, m, s].map((n) => n.toString().padLeft(2, '0')).join(':');
//   }

//   List<List<dynamic>> chunkArray(List<dynamic> arr, int size) {
//     final output = <List<dynamic>>[];
//     for (int i = 0; i < arr.length; i += size) {
//       output.add(arr.sublist(i, i + size > arr.length ? arr.length : i + size));
//     }
//     return output;
//   }

//   Future<void> fetchData() async {
//     if (subjectParam == null || subjectParam!.isEmpty) {
//       setState(() {
//         loading = false;
//         error = 'Subject missing';
//       });
//       return;
//     }

//     setState(() {
//       loading = true;
//       error = '';
//     });

//     try {
//       final subUpper = subjectParam!.toUpperCase();
//       final res = await ApiClient.dio.get(
//         '/student/subject/${Uri.encodeComponent(subUpper)}',
//       );

//       final resData = res.data is Map<String, dynamic>
//           ? res.data as Map<String, dynamic>
//           : <String, dynamic>{};

//       final levelsRaw = resData['levels'] is List ? resData['levels'] as List : [];

//       final levels = <Map<String, dynamic>>[];

//       for (int i = 1; i <= 5; i++) {
//         Map<String, dynamic>? lvl;

//         for (final item in levelsRaw) {
//           if (item is Map && int.tryParse('${item['level']}') == i) {
//             lvl = Map<String, dynamic>.from(item);
//             break;
//           }
//         }

//         if (lvl != null) {
//           final scorePercent =
//               (num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0).clamp(0, 100);

//           final startTime =
//               lvl['start_time'] != null ? DateTime.tryParse('${lvl['start_time']}') : null;
//           final endTime =
//               lvl['end_time'] != null ? DateTime.tryParse('${lvl['end_time']}') : null;

//           levels.add({
//             'level': i,
//             'attempted': lvl['attempted'] == true,
//             'passed': scorePercent >= passMark,
//             'scorePercent': scorePercent,
//             'retryCount': int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0,
//             'maxRetry': int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1,
//             'start_time': startTime,
//             'end_time': endTime,
//           });
//         } else {
//           levels.add({
//             'level': i,
//             'attempted': false,
//             'passed': false,
//             'scorePercent': 0,
//             'retryCount': 0,
//             'maxRetry': 1,
//             'start_time': null,
//             'end_time': null,
//           });
//         }
//       }

//       final totalScore = levels.fold<num>(
//         0,
//         (acc, l) => acc + ((l['scorePercent'] as num?) ?? 0),
//       );

//       final aggregatePercent = (totalScore / levels.length).clamp(0, 100);

//       if (!mounted) return;

//       setState(() {
//         data = {
//           'subject': resData['subject'] ?? subjectParam,
//           'levels': levels,
//           'aggregatePercent': aggregatePercent,
//         };
//       });
//     } on DioException catch (err) {
//       final statusCode = err.response?.statusCode;
//       String message = 'Failed to load exams';

//       final resData = err.response?.data;

//       if (resData is Map && resData['message'] != null) {
//         message = resData['message'].toString();
//       } else if (err.message != null && err.message!.isNotEmpty) {
//         message = err.message!;
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

//   bool isPreviousPassed(List levels, int idx) {
//     if (idx == 0) return true;
//     return levels[idx - 1]['passed'] == true;
//   }

//   bool get allPassed {
//     final levels = data?['levels'] as List?;
//     if (levels == null || levels.isEmpty) return false;
//     return levels.every((l) => l['passed'] == true);
//   }

//   int get passedCount {
//     final levels = data?['levels'] as List?;
//     if (levels == null) return 0;
//     return levels.where((l) => l['passed'] == true).length;
//   }

//   int get attemptedCount {
//     final levels = data?['levels'] as List?;
//     if (levels == null) return 0;
//     return levels.where((l) => l['attempted'] == true).length;
//   }

//   Map<String, String> getBadge({
//     required bool passed,
//     required bool prevPassed,
//     required bool isAfterEnd,
//     required bool isExamActive,
//     required bool isBeforeStart,
//   }) {
//     if (passed) return {'label': 'Passed', 'type': 'green'};
//     if (!prevPassed) return {'label': 'Locked', 'type': 'gray'};
//     if (isAfterEnd) return {'label': 'Ended', 'type': 'red'};
//     if (isExamActive) return {'label': 'Live', 'type': 'blue'};
//     if (isBeforeStart) return {'label': 'Soon', 'type': 'yellow'};
//     return {'label': 'Locked', 'type': 'gray'};
//   }

//   Color badgeBg(String type) {
//     switch (type) {
//       case 'green':
//         return const Color(0xFF22C55E).withOpacity(0.15);
//       case 'blue':
//         return const Color(0xFF3B82F6).withOpacity(0.15);
//       case 'yellow':
//         return const Color(0xFFF59E0B).withOpacity(0.15);
//       case 'red':
//         return const Color(0xFFEF4444).withOpacity(0.15);
//       default:
//         return const Color(0xFF94A3B8).withOpacity(0.15);
//     }
//   }

//   Color badgeTextColor(String type) {
//     switch (type) {
//       case 'green':
//         return const Color(0xFF4ADE80);
//       case 'blue':
//         return const Color(0xFF60A5FA);
//       case 'yellow':
//         return const Color(0xFFFBBF24);
//       case 'red':
//         return const Color(0xFFF87171);
//       default:
//         return const Color(0xFFCBD5E1);
//     }
//   }

//   void onPressAttempt(Map<String, dynamic> lvl) {
//     if (subjectParam == null || subjectParam!.isEmpty) return;

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ExamAttemptScreen(
//           subject: subjectParam!,
//           level: lvl['level'],
//           attemptKey: DateTime.now().millisecondsSinceEpoch,
//         ),
//       ),
//     ).then((_) => fetchData());
//   }

//   void onPressCertificate() {
//     final authProvider = context.read<AuthProvider>();
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CertificateScreen(
//           name: authProvider.user?['name']?.toString() ?? 'Student',
//           subject: (data?['subject'] ?? subjectParam ?? '').toString(),
//           aggregatePercent: num.tryParse('${data?['aggregatePercent'] ?? 0}') ?? 0,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.user;

//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isVerySmall = width < 340 || height < 650;
//     final isSmall = width < 380 || height < 760;
//     final cardsPerRow = isVerySmall ? 1 : 2;

//     final fontScale = isVerySmall ? 0.82 : (isSmall ? 0.9 : 1.0);
//     final spacing = isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0);

//     final ui = {
//       'containerPadding': spacing,
//       'heroPadding': isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0),
//       'cardPadding': isVerySmall ? 10.0 : (isSmall ? 10.0 : 12.0),
//       'titleSize': isVerySmall ? 18.0 : (isSmall ? 21.0 : 24.0),
//       'statLabel': 11 * fontScale,
//       'statValue': 16 * fontScale,
//       'cardTitle': isVerySmall ? 15.0 : (isSmall ? 15.0 : 16.0),
//       'cardMeta': isVerySmall ? 11.0 : 12.0,
//       'btnText': isVerySmall ? 11.0 : 12.0,
//       'badgeText': isVerySmall ? 10.0 : 11.0,
//     };

//     if (loading) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 CircularProgressIndicator(color: Color(0xFF8B5CF6)),
//                 SizedBox(height: 12),
//                 Text(
//                   'Loading dashboard...',
//                   style: TextStyle(
//                     color: Color(0xFFCBD5E1),
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     if (error.isNotEmpty) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(18),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Something went wrong',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color(0xFFFCA5A5),
//                       fontSize: 18,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     error,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Color(0xFFFECACA),
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     if (data == null || (data!['levels'] as List?)?.isEmpty != false) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF0F172A),
//         body: SafeArea(
//           child: Center(
//             child: Text(
//               'No exams available',
//               style: TextStyle(
//                 color: Color(0xFFCBD5E1),
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final levels = List<Map<String, dynamic>>.from(data!['levels'] as List);
//     final cardsData = [
//       ...levels,
//       {
//         'level': 6,
//         'isCertificate': true,
//         'unlocked': allPassed,
//       }
//     ];

//     final levelRows = chunkArray(cardsData, cardsPerRow);

//     final availableWidth = MediaQuery.of(context).size.width -
//         ((ui['containerPadding'] as double) * 2);
//     final gap = 10.0;
//     final cardWidth = cardsPerRow == 1
//         ? availableWidth
//         : (availableWidth - gap) / 2;

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Positioned(
//               top: -30,
//               right: -10,
//               child: Container(
//                 width: 160,
//                 height: 160,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF7C3AED).withOpacity(0.18),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 30,
//               left: -30,
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF3B82F6).withOpacity(0.10),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(ui['containerPadding'] as double),
//               child: Column(
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     padding: EdgeInsets.all(ui['heroPadding'] as double),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF111827),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.08),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Exam Dashboard',
//                           style: TextStyle(
//                             color: const Color(0xFFA78BFA),
//                             fontWeight: FontWeight.w800,
//                             fontSize: 12 * fontScale,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           '${data!['subject']}'.toUpperCase(),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.w900,
//                             letterSpacing: 0.4,
//                             fontSize: ui['titleSize'] as double,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Welcome ${user?['name'] ?? 'Student'}',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: const Color(0xFF94A3B8),
//                             fontSize: isVerySmall ? 11 : 13,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             SizedBox(
//                               width: (availableWidth - 12) / 3,
//                               child: _StatBox(
//                                 label: 'Passed',
//                                 value: '$passedCount/5',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             SizedBox(
//                               width: (availableWidth - 12) / 3,
//                               child: _StatBox(
//                                 label: 'Attempt',
//                                 value: '$attemptedCount/5',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             SizedBox(
//                               width: (availableWidth - 12) / 3,
//                               child: _StatBox(
//                                 label: 'Avg',
//                                 value:
//                                     '${(num.tryParse('${data!['aggregatePercent']}') ?? 0).round()}%',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Progress',
//                               style: TextStyle(
//                                 color: const Color(0xFFCBD5E1),
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 11 * fontScale,
//                               ),
//                             ),
//                             Text(
//                               '${((passedCount / 5) * 100).round()}%',
//                               style: TextStyle(
//                                 color: const Color(0xFFCBD5E1),
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 11 * fontScale,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 6),
//                         Container(
//                           height: 8,
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF1E293B),
//                             borderRadius: BorderRadius.circular(999),
//                           ),
//                           child: FractionallySizedBox(
//                             alignment: Alignment.centerLeft,
//                             widthFactor: (passedCount / 5).clamp(0, 1),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF8B5CF6),
//                                 borderRadius: BorderRadius.circular(999),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Expanded(
//                     child: ListView.builder(
//                       padding: EdgeInsets.zero,
//                       itemCount: levelRows.length,
//                       itemBuilder: (context, rowIndex) {
//                         final row = levelRows[rowIndex];

//                         return Padding(
//                           padding: EdgeInsets.only(
//                             top: rowIndex == 0 ? 0 : (isVerySmall ? 8 : 10),
//                           ),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               for (int i = 0; i < row.length; i++) ...[
//                                 SizedBox(
//                                   width: cardWidth,
//                                   child: Builder(
//                                     builder: (context) {
//                                       final lvl =
//                                           Map<String, dynamic>.from(row[i] as Map);
//                                       final index = rowIndex * cardsPerRow + i;
//                                       final isCertificateCard =
//                                           lvl['isCertificate'] == true;

//                                       if (isCertificateCard) {
//                                         return _buildCertificateCard(
//                                           allPassed: allPassed,
//                                           aggregatePercent:
//                                               num.tryParse('${data!['aggregatePercent']}') ?? 0,
//                                           passedCount: passedCount,
//                                           isVerySmall: isVerySmall,
//                                           isSmall: isSmall,
//                                           ui: ui,
//                                         );
//                                       }

//                                       final attempted = lvl['attempted'] == true;
//                                       final passed = lvl['passed'] == true;
//                                       final retryCount =
//                                           int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0;
//                                       final maxRetry =
//                                           int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1;
//                                       final scorePercent =
//                                           num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0;
//                                       final startTime = lvl['start_time'] as DateTime?;
//                                       final endTime = lvl['end_time'] as DateTime?;

//                                       final prevPassed = isPreviousPassed(levels, index);

//                                       final isBeforeStart =
//                                           startTime != null && now.isBefore(startTime);
//                                       final isAfterEnd =
//                                           endTime != null && now.isAfter(endTime);
//                                       final isExamActive = startTime != null &&
//                                           endTime != null &&
//                                           (now.isAtSameMomentAs(startTime) ||
//                                               now.isAfter(startTime)) &&
//                                           (now.isAtSameMomentAs(endTime) ||
//                                               now.isBefore(endTime));

//                                       final canAttempt = !passed &&
//                                           prevPassed &&
//                                           startTime != null &&
//                                           isExamActive &&
//                                           (!attempted || retryCount < maxRetry);

//                                       final secondsToStart =
//                                           !passed && isBeforeStart && startTime != null
//                                               ? startTime.difference(now).inSeconds
//                                               : 0;

//                                       final badge = getBadge(
//                                         passed: passed,
//                                         prevPassed: prevPassed,
//                                         isAfterEnd: isAfterEnd,
//                                         isExamActive: isExamActive,
//                                         isBeforeStart: isBeforeStart,
//                                       );

//                                       String statusLine = 'Not attempted';
//                                       if (attempted) statusLine = 'Score $scorePercent%';
//                                       if (attempted && !passed) {
//                                         statusLine += ' • $retryCount/$maxRetry';
//                                       }

//                                       String timeLine = '';
//                                       if (!passed) {
//                                         if (isExamActive) {
//                                           timeLine = 'Live now';
//                                         } else if (isBeforeStart) {
//                                           timeLine = formatDuration(secondsToStart);
//                                         } else if (isAfterEnd) {
//                                           timeLine = 'Exam ended';
//                                         } else {
//                                           timeLine = 'Start ${formatDateTime(startTime)}';
//                                         }
//                                       }

//                                       String buttonLabel = 'Not Available';
//                                       if (passed) {
//                                         buttonLabel = 'Passed';
//                                       } else if (!prevPassed) {
//                                         buttonLabel = 'Complete L${lvl['level'] - 1}';
//                                       } else if (canAttempt) {
//                                         buttonLabel =
//                                             attempted ? 'Retry Exam' : 'Start Exam';
//                                       }

//                                       return _buildLevelCard(
//                                         lvl: lvl,
//                                         passed: passed,
//                                         isExamActive: isExamActive,
//                                         canAttempt: canAttempt,
//                                         badge: badge,
//                                         statusLine: statusLine,
//                                         timeLine: timeLine,
//                                         buttonLabel: buttonLabel,
//                                         isVerySmall: isVerySmall,
//                                         isSmall: isSmall,
//                                         ui: ui,
//                                       );
//                                     },
//                                   ),
//                                 ),
//                                 if (i != row.length - 1) const SizedBox(width: 10),
//                               ],
//                               if (cardsPerRow == 2 && row.length == 1) ...[
//                                 const SizedBox(width: 10),
//                                 SizedBox(width: cardWidth),
//                               ],
//                             ],
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCertificateCard({
//     required bool allPassed,
//     required num aggregatePercent,
//     required int passedCount,
//     required bool isVerySmall,
//     required bool isSmall,
//     required Map<String, dynamic> ui,
//   }) {
//     return Container(
//       constraints: BoxConstraints(
//         minHeight: isVerySmall ? 110 : (isSmall ? 126 : 138),
//       ),
//       padding: EdgeInsets.all(ui['cardPadding'] as double),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111827),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: allPassed
//               ? const Color(0xFF22C55E).withOpacity(0.40)
//               : Colors.white.withOpacity(0.08),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Certification',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w900,
//                     fontSize: ui['cardTitle'] as double,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 6),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(999),
//                   color: allPassed
//                       ? const Color(0xFF22C55E).withOpacity(0.15)
//                       : const Color(0xFF94A3B8).withOpacity(0.15),
//                 ),
//                 child: Text(
//                   allPassed ? 'Unlocked' : 'Locked',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color:
//                         allPassed ? const Color(0xFF4ADE80) : const Color(0xFFCBD5E1),
//                     fontWeight: FontWeight.w900,
//                     fontSize: ui['badgeText'] as double,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             allPassed
//                 ? 'Avg Score ${aggregatePercent.round()}%'
//                 : 'Complete all 5 levels',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: const Color(0xFF94A3B8),
//               fontWeight: FontWeight.w600,
//               fontSize: ui['cardMeta'] as double,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             allPassed ? 'Certificate ready' : '$passedCount/5 levels passed',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: const Color(0xFFCBD5E1),
//               fontWeight: FontWeight.w500,
//               fontSize: ui['cardMeta'] as double,
//             ),
//           ),
//           SizedBox(height: isVerySmall ? 8 : 10),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: allPassed ? onPressCertificate : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor:
//                     allPassed ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
//                 foregroundColor:
//                     allPassed ? Colors.white : const Color(0xFF94A3B8),
//                 disabledBackgroundColor: const Color(0xFF1E293B),
//                 disabledForegroundColor: const Color(0xFF94A3B8),
//                 elevation: 0,
//                 padding: EdgeInsets.symmetric(
//                   vertical: isVerySmall ? 8 : 10,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   side: allPassed
//                       ? BorderSide.none
//                       : BorderSide(
//                           color: Colors.white.withOpacity(0.06),
//                         ),
//                 ),
//               ),
//               child: Text(
//                 allPassed ? 'Download' : 'Locked',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w900,
//                   fontSize: ui['btnText'] as double,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLevelCard({
//     required Map<String, dynamic> lvl,
//     required bool passed,
//     required bool isExamActive,
//     required bool canAttempt,
//     required Map<String, String> badge,
//     required String statusLine,
//     required String timeLine,
//     required String buttonLabel,
//     required bool isVerySmall,
//     required bool isSmall,
//     required Map<String, dynamic> ui,
//   }) {
//     final badgeType = badge['type']?.toString() ?? 'gray';
//     final badgeLabel = badge['label']?.toString() ?? 'Locked';

//     return Container(
//       constraints: BoxConstraints(
//         minHeight: isVerySmall ? 110 : (isSmall ? 126 : 138),
//       ),
//       padding: EdgeInsets.all(ui['cardPadding'] as double),
//       decoration: BoxDecoration(
//         color: const Color(0xFF111827),
//         borderRadius: BorderRadius.circular(18),
//         border: Border.all(
//           color: passed
//               ? const Color(0xFF22C55E).withOpacity(0.40)
//               : isExamActive
//                   ? const Color(0xFF3B82F6).withOpacity(0.40)
//                   : Colors.white.withOpacity(0.08),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: Text(
//                   'Level ${lvl['level']}',
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w900,
//                     fontSize: ui['cardTitle'] as double,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 6),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(999),
//                   color: badgeBg(badgeType),
//                 ),
//                 child: Text(
//                   badgeLabel,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: badgeTextColor(badgeType),
//                     fontWeight: FontWeight.w900,
//                     fontSize: ui['badgeText'] as double,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             statusLine,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: const Color(0xFF94A3B8),
//               fontWeight: FontWeight.w600,
//               fontSize: ui['cardMeta'] as double,
//             ),
//           ),
//           if (timeLine.isNotEmpty) ...[
//             const SizedBox(height: 4),
//             Text(
//               timeLine,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 color: const Color(0xFFCBD5E1),
//                 fontWeight: FontWeight.w500,
//                 fontSize: ui['cardMeta'] as double,
//               ),
//             ),
//           ],
//           SizedBox(height: isVerySmall ? 8 : 10),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: (!passed && canAttempt) ? () => onPressAttempt(lvl) : null,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: passed
//                     ? const Color(0xFF16A34A)
//                     : canAttempt
//                         ? const Color(0xFF8B5CF6)
//                         : const Color(0xFF1E293B),
//                 foregroundColor:
//                     (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
//                 disabledBackgroundColor:
//                     passed ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
//                 disabledForegroundColor:
//                     (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
//                 elevation: 0,
//                 padding: EdgeInsets.symmetric(
//                   vertical: isVerySmall ? 8 : 10,
//                 ),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   side: (!passed && !canAttempt)
//                       ? BorderSide(
//                           color: Colors.white.withOpacity(0.06),
//                         )
//                       : BorderSide.none,
//                 ),
//               ),
//               child: Text(
//                 buttonLabel,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   fontWeight: FontWeight.w900,
//                   fontSize: ui['btnText'] as double,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StatBox extends StatelessWidget {
//   final String label;
//   final String value;
//   final double statLabelSize;
//   final double statValueSize;

//   const _StatBox({
//     required this.label,
//     required this.value,
//     required this.statLabelSize,
//     required this.statValueSize,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10),
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
//             style: TextStyle(
//               color: const Color(0xFF94A3B8),
//               fontWeight: FontWeight.w700,
//               fontSize: statLabelSize,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//               fontSize: statValueSize,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// import '../../core/api/api_client.dart';
// import '../../providers/auth_provider.dart';
// import 'certificate_screen.dart';
// import 'exam_attempt_screen.dart';

// class SubjectScreen extends StatefulWidget {
//   final String? initialSubject;

//   const SubjectScreen({super.key, this.initialSubject});

//   @override
//   State<SubjectScreen> createState() => _SubjectScreenState();
// }

// class _SubjectScreenState extends State<SubjectScreen> {
//   static const int passMark = 40;

//   Map<String, dynamic>? data;
//   bool loading = true;
//   String error = '';
//   DateTime now = DateTime.now();

//   Timer? _timer;
//   bool _loaded = false;
//   String? subjectParam;

//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (mounted) {
//         setState(() {
//           now = DateTime.now();
//         });
//       }
//     });
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_loaded) return;
//     _loaded = true;

//     final args = ModalRoute.of(context)?.settings.arguments;

//     if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
//       subjectParam = widget.initialSubject;
//     } else if (args is Map && args['subject'] != null) {
//       subjectParam = args['subject'].toString();
//     }

//     fetchData();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   String formatDateTime(DateTime? date) {
//     if (date == null) return '--';

//     try {
//       const months = [
//         'Jan',
//         'Feb',
//         'Mar',
//         'Apr',
//         'May',
//         'Jun',
//         'Jul',
//         'Aug',
//         'Sep',
//         'Oct',
//         'Nov',
//         'Dec',
//       ];

//       final day = date.day.toString().padLeft(2, '0');
//       final month = months[date.month - 1];

//       int hour = date.hour;
//       final minute = date.minute.toString().padLeft(2, '0');
//       final amPm = hour >= 12 ? 'PM' : 'AM';
//       hour = hour % 12;
//       if (hour == 0) hour = 12;

//       final hourText = hour.toString().padLeft(2, '0');
//       return '$day $month, $hourText:$minute $amPm';
//     } catch (_) {
//       return '--';
//     }
//   }

// String formatDateOnly(DateTime? date) {
//   if (date == null) return '--';

//   try {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];

//     final day = date.day.toString().padLeft(2, '0');
//     final month = months[date.month - 1];

//     return '$day $month';
//   } catch (_) {
//     return '--';
//   }
// }

//   String formatDuration(int seconds) {
//     if (seconds <= 0) return '00:00:00';

//     final h = seconds ~/ 3600;
//     final m = (seconds % 3600) ~/ 60;
//     final s = seconds % 60;

//     return [h, m, s].map((n) => n.toString().padLeft(2, '0')).join(':');
//   }

//   List<List<dynamic>> chunkArray(List<dynamic> arr, int size) {
//     final output = <List<dynamic>>[];
//     for (int i = 0; i < arr.length; i += size) {
//       output.add(arr.sublist(i, i + size > arr.length ? arr.length : i + size));
//     }
//     return output;
//   }

//   Future<void> fetchData() async {
//     if (subjectParam == null || subjectParam!.isEmpty) {
//       setState(() {
//         loading = false;
//         error = 'Subject missing';
//       });
//       return;
//     }

//     setState(() {
//       loading = true;
//       error = '';
//     });

//     try {
//       final subUpper = subjectParam!.toUpperCase();
//       final res = await ApiClient.dio.get(
//         '/student/subject/${Uri.encodeComponent(subUpper)}',
//       );

//       final resData = res.data is Map<String, dynamic>
//           ? res.data as Map<String, dynamic>
//           : <String, dynamic>{};

//       final levelsRaw = resData['levels'] is List ? resData['levels'] as List : [];
//       final levels = <Map<String, dynamic>>[];

//       for (int i = 1; i <= 5; i++) {
//         Map<String, dynamic>? lvl;

//         for (final item in levelsRaw) {
//           if (item is Map && int.tryParse('${item['level']}') == i) {
//             lvl = Map<String, dynamic>.from(item);
//             break;
//           }
//         }

//         if (lvl != null) {
//           final scorePercent =
//               (num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0).clamp(0, 100);

//           final startTime =
//               lvl['start_time'] != null ? DateTime.tryParse('${lvl['start_time']}') : null;
//           final endTime =
//               lvl['end_time'] != null ? DateTime.tryParse('${lvl['end_time']}') : null;

//           levels.add({
//             'level': i,
//             'attempted': lvl['attempted'] == true,
//             'passed': scorePercent >= passMark,
//             'scorePercent': scorePercent,
//             'retryCount': int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0,
//             'maxRetry': int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1,
//             'start_time': startTime,
//             'end_time': endTime,
//           });
//         } else {
//           levels.add({
//             'level': i,
//             'attempted': false,
//             'passed': false,
//             'scorePercent': 0,
//             'retryCount': 0,
//             'maxRetry': 1,
//             'start_time': null,
//             'end_time': null,
//           });
//         }
//       }

//       final totalScore = levels.fold<num>(
//         0,
//         (acc, l) => acc + ((l['scorePercent'] as num?) ?? 0),
//       );

//       final aggregatePercent = (totalScore / levels.length).clamp(0, 100);

//       if (!mounted) return;

//       setState(() {
//         data = {
//           'subject': resData['subject'] ?? subjectParam,
//           'levels': levels,
//           'aggregatePercent': aggregatePercent,
//         };
//       });
//     } on DioException catch (err) {
//       final statusCode = err.response?.statusCode;
//       String message = 'Failed to load exams';

//       final resData = err.response?.data;

//       if (resData is Map && resData['message'] != null) {
//         message = resData['message'].toString();
//       } else if (err.message != null && err.message!.isNotEmpty) {
//         message = err.message!;
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

//   bool isPreviousPassed(List levels, int idx) {
//     if (idx == 0) return true;
//     return levels[idx - 1]['passed'] == true;
//   }

//   bool get allPassed {
//     final levels = data?['levels'] as List?;
//     if (levels == null || levels.isEmpty) return false;
//     return levels.every((l) => l['passed'] == true);
//   }

//   int get passedCount {
//     final levels = data?['levels'] as List?;
//     if (levels == null) return 0;
//     return levels.where((l) => l['passed'] == true).length;
//   }

//   int get attemptedCount {
//     final levels = data?['levels'] as List?;
//     if (levels == null) return 0;
//     return levels.where((l) => l['attempted'] == true).length;
//   }

//   Map<String, String> getBadge({
//     required bool passed,
//     required bool prevPassed,
//     required bool isAfterEnd,
//     required bool isExamActive,
//     required bool isBeforeStart,
//   }) {
//     if (passed) return {'label': 'Passed', 'type': 'green'};
//     if (!prevPassed) return {'label': 'Locked', 'type': 'gray'};
//     if (isAfterEnd) return {'label': 'Ended', 'type': 'red'};
//     if (isExamActive) return {'label': 'Live', 'type': 'blue'};
//     if (isBeforeStart) return {'label': 'Soon', 'type': 'yellow'};
//     return {'label': 'Locked', 'type': 'gray'};
//   }

//   Color badgeBg(String type) {
//     switch (type) {
//       case 'green':
//         return const Color(0xFF22C55E).withOpacity(0.15);
//       case 'blue':
//         return const Color(0xFF3B82F6).withOpacity(0.15);
//       case 'yellow':
//         return const Color(0xFFF59E0B).withOpacity(0.15);
//       case 'red':
//         return const Color(0xFFEF4444).withOpacity(0.15);
//       default:
//         return const Color(0xFF94A3B8).withOpacity(0.15);
//     }
//   }

//   Color badgeTextColor(String type) {
//     switch (type) {
//       case 'green':
//         return const Color(0xFF4ADE80);
//       case 'blue':
//         return const Color(0xFF60A5FA);
//       case 'yellow':
//         return const Color(0xFFFBBF24);
//       case 'red':
//         return const Color(0xFFF87171);
//       default:
//         return const Color(0xFFCBD5E1);
//     }
//   }

//   void onPressAttempt(Map<String, dynamic> lvl) {
//     if (subjectParam == null || subjectParam!.isEmpty) return;

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => ExamAttemptScreen(
//           subject: subjectParam!,
//           level: lvl['level'],
//           attemptKey: DateTime.now().millisecondsSinceEpoch,
//         ),
//       ),
//     ).then((_) => fetchData());
//   }

//   void onPressCertificate() {
//     final authProvider = context.read<AuthProvider>();
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => CertificateScreen(
//           name: authProvider.user?['name']?.toString() ?? 'Student',
//           subject: (data?['subject'] ?? subjectParam ?? '').toString(),
//           aggregatePercent: num.tryParse('${data?['aggregatePercent'] ?? 0}') ?? 0,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final authProvider = context.watch<AuthProvider>();
//     final user = authProvider.user;

//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isVerySmall = width < 340 || height < 650;
//     final isSmall = width < 380 || height < 760;

//     final cardsPerRow = width < 320 ? 1 : 2;
//     final fontScale = isVerySmall ? 0.80 : (isSmall ? 0.90 : 1.0);
//     final spacing = isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0);
//     final cardGap = isVerySmall ? 8.0 : 10.0;

//     final ui = {
//       'containerPadding': spacing,
//       'heroPadding': isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0),
//       'cardPadding': isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0),
//       'titleSize': isVerySmall ? 18.0 : (isSmall ? 21.0 : 24.0),
//       'statLabel': 10.5 * fontScale,
//       'statValue': 15 * fontScale,
//       'cardTitle': isVerySmall ? 14.0 : 16.0,
//       'cardMeta': isVerySmall ? 10.0 : 12.0,
//       'btnText': isVerySmall ? 10.5 : 12.0,
//       'badgeText': isVerySmall ? 9.0 : 11.0,
//     };

//     PreferredSizeWidget appBar = AppBar(
//       backgroundColor: const Color(0xFF0F172A),
//       elevation: 0,
//       centerTitle: true,
//       title: Text(
//         data == null ? 'Subject' : '${data!['subject']}',
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.w700,
//         ),
//       ),
//       iconTheme: const IconThemeData(color: Colors.white),
//     );

//     if (loading) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         appBar: appBar,
//         body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 CircularProgressIndicator(color: Color(0xFF8B5CF6)),
//                 SizedBox(height: 12),
//                 Text(
//                   'Loading dashboard...',
//                   style: TextStyle(
//                     color: Color(0xFFCBD5E1),
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     if (error.isNotEmpty) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         appBar: appBar,
//         body: SafeArea(
//           child: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(18),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Text(
//                     'Something went wrong',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Color(0xFFFCA5A5),
//                       fontSize: 18,
//                       fontWeight: FontWeight.w900,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     error,
//                     textAlign: TextAlign.center,
//                     style: const TextStyle(
//                       color: Color(0xFFFECACA),
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     if (data == null || (data!['levels'] as List?)?.isEmpty != false) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF0F172A),
//         appBar: appBar,
//         body: const SafeArea(
//           child: Center(
//             child: Text(
//               'No exams available',
//               style: TextStyle(
//                 color: Color(0xFFCBD5E1),
//                 fontSize: 15,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final levels = List<Map<String, dynamic>>.from(data!['levels'] as List);
//     final cardsData = [
//       ...levels,
//       {
//         'level': 6,
//         'isCertificate': true,
//         'unlocked': allPassed,
//       }
//     ];
//     final levelRows = chunkArray(cardsData, cardsPerRow);

//     return Scaffold(
//       backgroundColor: const Color(0xFF0F172A),
//       appBar: appBar,
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Positioned(
//               top: -30,
//               right: -10,
//               child: Container(
//                 width: 160,
//                 height: 160,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF7C3AED).withOpacity(0.18),
//                 ),
//               ),
//             ),
//             Positioned(
//               bottom: 30,
//               left: -30,
//               child: Container(
//                 width: 180,
//                 height: 180,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: const Color(0xFF3B82F6).withOpacity(0.10),
//                 ),
//               ),
//             ),
//             Padding(
//               padding: EdgeInsets.all(ui['containerPadding'] as double),
//               child: Column(
//                 children: [
//                   Container(
//                     width: double.infinity,
//                     padding: EdgeInsets.all(ui['heroPadding'] as double),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF111827),
//                       borderRadius: BorderRadius.circular(20),
//                       border: Border.all(
//                         color: Colors.white.withOpacity(0.08),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           'Exam Dashboard',
//                           style: TextStyle(
//                             color: const Color(0xFFA78BFA),
//                             fontWeight: FontWeight.w800,
//                             fontSize: 12 * fontScale,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         // Text(
//                         //   '${data!['subject']}'.toUpperCase(),
//                         //   maxLines: 1,
//                         //   overflow: TextOverflow.ellipsis,
//                         //   style: TextStyle(
//                         //     color: Colors.white,
//                         //     fontWeight: FontWeight.w900,
//                         //     letterSpacing: 0.4,
//                         //     fontSize: ui['titleSize'] as double,
//                         //   ),
//                         // ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Welcome ${user?['name'] ?? 'Student'}',
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: const Color(0xFF94A3B8),
//                             fontSize: isVerySmall ? 11 : 13,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           children: [
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Passed',
//                                 value: '$passedCount/5',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Attempt',
//                                 value: '$attemptedCount/5',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                             const SizedBox(width: 6),
//                             Expanded(
//                               child: _StatBox(
//                                 label: 'Avg',
//                                 value:
//                                     '${(num.tryParse('${data!['aggregatePercent']}') ?? 0).round()}%',
//                                 statLabelSize: ui['statLabel'] as double,
//                                 statValueSize: ui['statValue'] as double,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'Progress',
//                               style: TextStyle(
//                                 color: const Color(0xFFCBD5E1),
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 11 * fontScale,
//                               ),
//                             ),
//                             Text(
//                               '${((passedCount / 5) * 100).round()}%',
//                               style: TextStyle(
//                                 color: const Color(0xFFCBD5E1),
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 11 * fontScale,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 6),
//                         Container(
//                           height: 8,
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF1E293B),
//                             borderRadius: BorderRadius.circular(999),
//                           ),
//                           child: FractionallySizedBox(
//                             alignment: Alignment.centerLeft,
//                             widthFactor: (passedCount / 5).clamp(0, 1),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: const Color(0xFF8B5CF6),
//                                 borderRadius: BorderRadius.circular(999),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   SizedBox(height: cardGap),
//                   Expanded(
//                     child: Column(
//                       children: [
//                         for (int rowIndex = 0; rowIndex < levelRows.length; rowIndex++) ...[
//                           Expanded(
//                             child: Padding(
//                               padding: EdgeInsets.only(
//                                 top: rowIndex == 0 ? 0 : cardGap,
//                               ),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                                 children: [
//                                   for (int i = 0; i < levelRows[rowIndex].length; i++) ...[
//                                     Expanded(
//                                       child: Builder(
//                                         builder: (context) {
//                                           final lvl = Map<String, dynamic>.from(
//                                             levelRows[rowIndex][i] as Map,
//                                           );

//                                           final index = rowIndex * cardsPerRow + i;
//                                           final isCertificateCard =
//                                               lvl['isCertificate'] == true;

//                                           if (isCertificateCard) {
//                                             return _buildCertificateCard(
//                                               allPassed: allPassed,
//                                               aggregatePercent: num.tryParse(
//                                                     '${data!['aggregatePercent']}',
//                                                   ) ??
//                                                   0,
//                                               passedCount: passedCount,
//                                               isVerySmall: isVerySmall,
//                                               isSmall: isSmall,
//                                               ui: ui,
//                                             );
//                                           }

//                                           final attempted = lvl['attempted'] == true;
//                                           final passed = lvl['passed'] == true;
//                                           final retryCount =
//                                               int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0;
//                                           final maxRetry =
//                                               int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1;
//                                           final scorePercent =
//                                               num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0;
//                                           final startTime = lvl['start_time'] as DateTime?;
//                                           final endTime = lvl['end_time'] as DateTime?;

//                                           final prevPassed = isPreviousPassed(levels, index);

//                                           final isBeforeStart =
//                                               startTime != null && now.isBefore(startTime);
//                                           final isAfterEnd =
//                                               endTime != null && now.isAfter(endTime);
//                                           final isExamActive = startTime != null &&
//                                               endTime != null &&
//                                               (now.isAtSameMomentAs(startTime) ||
//                                                   now.isAfter(startTime)) &&
//                                               (now.isAtSameMomentAs(endTime) ||
//                                                   now.isBefore(endTime));

//                                           final canAttempt = !passed &&
//                                               prevPassed &&
//                                               startTime != null &&
//                                               isExamActive &&
//                                               (!attempted || retryCount < maxRetry);

//                                           final secondsToStart =
//                                               !passed && isBeforeStart && startTime != null
//                                                   ? startTime.difference(now).inSeconds
//                                                   : 0;

//                                           final badge = getBadge(
//                                             passed: passed,
//                                             prevPassed: prevPassed,
//                                             isAfterEnd: isAfterEnd,
//                                             isExamActive: isExamActive,
//                                             isBeforeStart: isBeforeStart,
//                                           );

//                                           String statusLine = 'Not attempted';
//                                           if (attempted) statusLine = 'Score $scorePercent%';
//                                           if (attempted && !passed) {
//                                             statusLine += ' • $retryCount/$maxRetry';
//                                           }

//                                           String timeLine = '';
//                                           if (!passed) {
//                                             if (isExamActive) {
//                                               timeLine = 'Live now';
//                                             } else if (isBeforeStart) {
//                                               timeLine = formatDuration(secondsToStart);
//                                             } else if (isAfterEnd) {
//                                               timeLine = 'Exam ended';
//                                             } else {
//                                               timeLine = 'Start ${formatDateTime(startTime)}';
//                                             }
//                                           }
//                                            else {
//                                               timeLine = 'Completed on ${formatDateOnly(endTime)}';
//                                               // print(timeLine);
//                                             }

//                                           String buttonLabel = 'Not Available';
//                                           if (passed) {
//                                             buttonLabel = 'Passed';
//                                           } else if (!prevPassed) {
//                                             buttonLabel = 'Complete L${lvl['level'] - 1}';
//                                           } else if (canAttempt) {
//                                             buttonLabel = attempted ? 'Retry Exam' : 'Start Exam';
//                                           }

//                                           return _buildLevelCard(
//                                             lvl: lvl,
//                                             passed: passed,
//                                             isExamActive: isExamActive,
//                                             canAttempt: canAttempt,
//                                             badge: badge,
//                                             statusLine: statusLine,
//                                             timeLine: timeLine,
//                                             buttonLabel: buttonLabel,
//                                             isVerySmall: isVerySmall,
//                                             isSmall: isSmall,
//                                             ui: ui,
//                                           );
//                                         },
//                                       ),
//                                     ),
//                                     if (i != levelRows[rowIndex].length - 1)
//                                       SizedBox(width: cardGap),
//                                   ],
//                                   if (cardsPerRow == 2 && levelRows[rowIndex].length == 1) ...[
//                                     SizedBox(width: cardGap),
//                                     const Expanded(child: SizedBox()),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildCertificateCard({
//     required bool allPassed,
//     required num aggregatePercent,
//     required int passedCount,
//     required bool isVerySmall,
//     required bool isSmall,
//     required Map<String, dynamic> ui,
//   }) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final compact = constraints.maxHeight < 145;
//         final superCompact = constraints.maxHeight < 125;

//         final vGap1 = superCompact ? 3.0 : 6.0;
//         final vGap2 = superCompact ? 2.0 : 4.0;
//         final innerPad = superCompact
//             ? ((ui['cardPadding'] as double) - 2).clamp(6.0, 20.0)
//             : (ui['cardPadding'] as double);
//         final titleSize = superCompact
//             ? ((ui['cardTitle'] as double) - 1)
//             : (ui['cardTitle'] as double);
//         final metaSize = compact
//             ? ((ui['cardMeta'] as double) - 1).clamp(9.0, 20.0)
//             : (ui['cardMeta'] as double);
//         final badgeSize = compact
//             ? ((ui['badgeText'] as double) - 1).clamp(8.0, 20.0)
//             : (ui['badgeText'] as double);
//         final btnSize = compact
//             ? ((ui['btnText'] as double) - 1).clamp(9.0, 20.0)
//             : (ui['btnText'] as double);
//         final btnVPad = superCompact ? 6.0 : (isVerySmall ? 8.0 : 10.0);

//         return Container(
//           height: double.infinity,
//           padding: EdgeInsets.all(innerPad),
//           decoration: BoxDecoration(
//             color: const Color(0xFF111827),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(
//               color: allPassed
//                   ? const Color(0xFF22C55E).withOpacity(0.40)
//                   : Colors.white.withOpacity(0.08),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Certification',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                         fontSize: titleSize,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Flexible(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: superCompact ? 6 : 8,
//                         vertical: superCompact ? 3 : 4,
//                       ),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(999),
//                         color: allPassed
//                             ? const Color(0xFF22C55E).withOpacity(0.15)
//                             : const Color(0xFF94A3B8).withOpacity(0.15),
//                       ),
//                       child: Text(
//                         allPassed ? 'Unlocked' : 'Locked',
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: allPassed
//                               ? const Color(0xFF4ADE80)
//                               : const Color(0xFFCBD5E1),
//                           fontWeight: FontWeight.w900,
//                           fontSize: badgeSize,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: vGap1),
//               Text(
//                 allPassed
//                     ? 'Avg Score ${aggregatePercent.round()}%'
//                     : 'Complete all 5 levels',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   color: const Color(0xFF94A3B8),
//                   fontWeight: FontWeight.w600,
//                   fontSize: metaSize,
//                 ),
//               ),
//               SizedBox(height: vGap2),
//               Text(
//                 allPassed ? 'Certificate ready' : '$passedCount/5 levels passed',
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   color: const Color(0xFFCBD5E1),
//                   fontWeight: FontWeight.w500,
//                   fontSize: metaSize,
//                 ),
//               ),
//               const SizedBox(height: 6),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: allPassed ? onPressCertificate : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor:
//                         allPassed ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
//                     foregroundColor:
//                         allPassed ? Colors.white : const Color(0xFF94A3B8),
//                     disabledBackgroundColor: const Color(0xFF1E293B),
//                     disabledForegroundColor: const Color(0xFF94A3B8),
//                     elevation: 0,
//                     minimumSize: Size.fromHeight(superCompact ? 30 : 36),
//                     padding: EdgeInsets.symmetric(vertical: btnVPad),
//                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: allPassed
//                           ? BorderSide.none
//                           : BorderSide(
//                               color: Colors.white.withOpacity(0.06),
//                             ),
//                     ),
//                   ),
//                   child: Text(
//                     allPassed ? 'Download' : 'Locked',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w900,
//                       fontSize: btnSize,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildLevelCard({
//     required Map<String, dynamic> lvl,
//     required bool passed,
//     required bool isExamActive,
//     required bool canAttempt,
//     required Map<String, String> badge,
//     required String statusLine,
//     required String timeLine,
//     required String buttonLabel,
//     required bool isVerySmall,
//     required bool isSmall,
//     required Map<String, dynamic> ui,
//   }) {
//     final badgeType = badge['type']?.toString() ?? 'gray';
//     final badgeLabel = badge['label']?.toString() ?? 'Locked';

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final compact = constraints.maxHeight < 145;
//         final superCompact = constraints.maxHeight < 125;

//         final vGap1 = superCompact ? 3.0 : 6.0;
//         final vGap2 = superCompact ? 2.0 : 4.0;
//         final innerPad = superCompact
//             ? ((ui['cardPadding'] as double) - 2).clamp(6.0, 20.0)
//             : (ui['cardPadding'] as double);
//         final titleSize = superCompact
//             ? ((ui['cardTitle'] as double) - 1)
//             : (ui['cardTitle'] as double);
//         final metaSize = compact
//             ? ((ui['cardMeta'] as double) - 1).clamp(9.0, 20.0)
//             : (ui['cardMeta'] as double);
//         final badgeSize = compact
//             ? ((ui['badgeText'] as double) - 1).clamp(8.0, 20.0)
//             : (ui['badgeText'] as double);
//         final btnSize = compact
//             ? ((ui['btnText'] as double) - 1).clamp(9.0, 20.0)
//             : (ui['btnText'] as double);
//         final btnVPad = superCompact ? 6.0 : (isVerySmall ? 8.0 : 10.0);

//         return Container(
//           height: double.infinity,
//           padding: EdgeInsets.all(innerPad),
//           decoration: BoxDecoration(
//             color: const Color(0xFF111827),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(
//               color: passed
//                   ? const Color(0xFF22C55E).withOpacity(0.40)
//                   : isExamActive
//                       ? const Color(0xFF3B82F6).withOpacity(0.40)
//                       : Colors.white.withOpacity(0.08),
//             ),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Level ${lvl['level']}',
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                         fontSize: titleSize,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Flexible(
//                     child: Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: superCompact ? 6 : 8,
//                         vertical: superCompact ? 3 : 4,
//                       ),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(999),
//                         color: badgeBg(badgeType),
//                       ),
//                       child: Text(
//                         badgeLabel,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           color: badgeTextColor(badgeType),
//                           fontWeight: FontWeight.w900,
//                           fontSize: badgeSize,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: vGap1),
//               Text(
//                 statusLine,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//                 style: TextStyle(
//                   color: const Color(0xFF94A3B8),
//                   fontWeight: FontWeight.w600,
//                   fontSize: metaSize,
//                 ),
//               ),
//               if (timeLine.isNotEmpty) ...[
//                 SizedBox(height: vGap2),
//                 Text(
//                   timeLine,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: const Color(0xFFCBD5E1),
//                     fontWeight: FontWeight.w500,
//                     fontSize: metaSize,
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 6),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: (!passed && canAttempt) ? () => onPressAttempt(lvl) : null,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: passed
//                         ? const Color(0xFF16A34A)
//                         : canAttempt
//                             ? const Color(0xFF8B5CF6)
//                             : const Color(0xFF1E293B),
//                     foregroundColor:
//                         (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
//                     disabledBackgroundColor:
//                         passed ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
//                     disabledForegroundColor:
//                         (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
//                     elevation: 0,
//                     minimumSize: Size.fromHeight(superCompact ? 30 : 36),
//                     padding: EdgeInsets.symmetric(vertical: btnVPad),
//                     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       side: (!passed && !canAttempt)
//                           ? BorderSide(
//                               color: Colors.white.withOpacity(0.06),
//                             )
//                           : BorderSide.none,
//                     ),
//                   ),
//                   child: Text(
//                     buttonLabel,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontWeight: FontWeight.w900,
//                       fontSize: btnSize,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _StatBox extends StatelessWidget {
//   final String label;
//   final String value;
//   final double statLabelSize;
//   final double statValueSize;

//   const _StatBox({
//     required this.label,
//     required this.value,
//     required this.statLabelSize,
//     required this.statValueSize,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
//               fontWeight: FontWeight.w700,
//               fontSize: statLabelSize,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             value,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//               fontSize: statValueSize,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }




import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import 'certificate_screen.dart';
import 'exam_attempt_screen.dart';

class SubjectScreen extends StatefulWidget {
  final String? initialSubject;

  const SubjectScreen({super.key, this.initialSubject});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  static const int passMark = 40;

  Map<String, dynamic>? data;
  bool loading = true;
  String error = '';
  DateTime now = DateTime.now();

  Timer? _timer;
  bool _loaded = false;
  String? subjectParam;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          now = DateTime.now();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    if (widget.initialSubject != null && widget.initialSubject!.isNotEmpty) {
      subjectParam = widget.initialSubject;
    } else if (args is Map && args['subject'] != null) {
      subjectParam = args['subject'].toString();
    }

    fetchData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return null;
    return DateTime.tryParse(text);
  }

  DateTime? _getSubmittedAt(Map<String, dynamic> lvl) {
    final possibleKeys = [
      'submitted_at',
      'completed_at',
      'attempted_at',
      'updatedAt',
      'updated_at',
      'createdAt',
      'created_at',
    ];

    for (final key in possibleKeys) {
      final parsed = _parseDate(lvl[key]);
      if (parsed != null) return parsed;
    }
    return null;
  }

  String formatDateTime(DateTime? date) {
    if (date == null) return '--';

    try {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];

      int hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;

      final hourText = hour.toString().padLeft(2, '0');
      return '$day $month, $hourText:$minute $amPm';
    } catch (_) {
      return '--';
    }
  }

  String formatDateOnly(DateTime? date) {
    if (date == null) return '--';

    try {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final day = date.day.toString().padLeft(2, '0');
      final month = months[date.month - 1];

      return '$day $month';
    } catch (_) {
      return '--';
    }
  }

  String formatDuration(int seconds) {
    if (seconds <= 0) return '00:00:00';

    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;

    return [h, m, s].map((n) => n.toString().padLeft(2, '0')).join(':');
  }

  List<List<dynamic>> chunkArray(List<dynamic> arr, int size) {
    final output = <List<dynamic>>[];
    for (int i = 0; i < arr.length; i += size) {
      output.add(arr.sublist(i, i + size > arr.length ? arr.length : i + size));
    }
    return output;
  }

  Future<void> fetchData() async {
    if (subjectParam == null || subjectParam!.isEmpty) {
      setState(() {
        loading = false;
        error = 'Subject missing';
      });
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final subUpper = subjectParam!.toUpperCase();
      final res = await ApiClient.dio.get(
        '/student/subject/${Uri.encodeComponent(subUpper)}',
      );

      final resData = res.data is Map<String, dynamic>
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      final levelsRaw = resData['levels'] is List ? resData['levels'] as List : [];
      final levels = <Map<String, dynamic>>[];

      for (int i = 1; i <= 5; i++) {
        Map<String, dynamic>? lvl;

        for (final item in levelsRaw) {
          if (item is Map && int.tryParse('${item['level']}') == i) {
            lvl = Map<String, dynamic>.from(item);
            break;
          }
        }

        if (lvl != null) {
          final scorePercent =
              (num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0).clamp(0, 100);

          final startTime = _parseDate(lvl['start_time']);
          final endTime = _parseDate(lvl['end_time']);
          final submittedAt = _getSubmittedAt(lvl);

          levels.add({
            'level': i,
            'attempted': lvl['attempted'] == true,
            'passed': scorePercent >= passMark,
            'scorePercent': scorePercent,
            'retryCount': int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0,
            'maxRetry': int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1,
            'start_time': startTime,
            'end_time': endTime,
            'submitted_at': submittedAt,
          });
        } else {
          levels.add({
            'level': i,
            'attempted': false,
            'passed': false,
            'scorePercent': 0,
            'retryCount': 0,
            'maxRetry': 1,
            'start_time': null,
            'end_time': null,
            'submitted_at': null,
          });
        }
      }

      final totalScore = levels.fold<num>(
        0,
        (acc, l) => acc + ((l['scorePercent'] as num?) ?? 0),
      );

      final aggregatePercent = (totalScore / levels.length).clamp(0, 100);

      if (!mounted) return;

      setState(() {
        data = {
          'subject': resData['subject'] ?? subjectParam,
          'levels': levels,
          'aggregatePercent': aggregatePercent,
        };
      });
    } on DioException catch (err) {
      final statusCode = err.response?.statusCode;
      String message = 'Failed to load exams';

      final resData = err.response?.data;

      if (resData is Map && resData['message'] != null) {
        message = resData['message'].toString();
      } else if (err.message != null && err.message!.isNotEmpty) {
        message = err.message!;
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

  bool isPreviousPassed(List levels, int idx) {
    if (idx == 0) return true;
    return levels[idx - 1]['passed'] == true;
  }

  bool get allPassed {
    final levels = data?['levels'] as List?;
    if (levels == null || levels.isEmpty) return false;
    return levels.every((l) => l['passed'] == true);
  }

  int get passedCount {
    final levels = data?['levels'] as List?;
    if (levels == null) return 0;
    return levels.where((l) => l['passed'] == true).length;
  }

  int get attemptedCount {
    final levels = data?['levels'] as List?;
    if (levels == null) return 0;
    return levels.where((l) => l['attempted'] == true).length;
  }

  Map<String, String> getBadge({
    required bool passed,
    required bool prevPassed,
    required bool isAfterEnd,
    required bool isExamActive,
    required bool isBeforeStart,
  }) {
    if (passed) return {'label': 'Passed', 'type': 'green'};
    if (!prevPassed) return {'label': 'Locked', 'type': 'gray'};
    if (isAfterEnd) return {'label': 'Ended', 'type': 'red'};
    if (isExamActive) return {'label': 'Live', 'type': 'blue'};
    if (isBeforeStart) return {'label': 'Soon', 'type': 'yellow'};
    return {'label': 'Locked', 'type': 'gray'};
  }

  Color badgeBg(String type) {
    switch (type) {
      case 'green':
        return const Color(0xFF22C55E).withOpacity(0.15);
      case 'blue':
        return const Color(0xFF3B82F6).withOpacity(0.15);
      case 'yellow':
        return const Color(0xFFF59E0B).withOpacity(0.15);
      case 'red':
        return const Color(0xFFEF4444).withOpacity(0.15);
      default:
        return const Color(0xFF94A3B8).withOpacity(0.15);
    }
  }

  Color badgeTextColor(String type) {
    switch (type) {
      case 'green':
        return const Color(0xFF4ADE80);
      case 'blue':
        return const Color(0xFF60A5FA);
      case 'yellow':
        return const Color(0xFFFBBF24);
      case 'red':
        return const Color(0xFFF87171);
      default:
        return const Color(0xFFCBD5E1);
    }
  }

  void onPressAttempt(Map<String, dynamic> lvl) {
    if (subjectParam == null || subjectParam!.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamAttemptScreen(
          subject: subjectParam!,
          level: lvl['level'],
          attemptKey: DateTime.now().millisecondsSinceEpoch,
        ),
      ),
    ).then((_) => fetchData());
  }

  void onPressCertificate() {
    final authProvider = context.read<AuthProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CertificateScreen(
          name: authProvider.user?['name']?.toString() ?? 'Student',
          subject: (data?['subject'] ?? subjectParam ?? '').toString(),
          aggregatePercent: num.tryParse('${data?['aggregatePercent'] ?? 0}') ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isVerySmall = width < 340 || height < 650;
    final isSmall = width < 380 || height < 760;

    final cardsPerRow = width < 320 ? 1 : 2;
    final fontScale = isVerySmall ? 0.80 : (isSmall ? 0.90 : 1.0);
    final spacing = isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0);
    final cardGap = isVerySmall ? 8.0 : 10.0;

    final ui = {
      'containerPadding': spacing,
      'heroPadding': isVerySmall ? 10.0 : (isSmall ? 12.0 : 14.0),
      'cardPadding': isVerySmall ? 8.0 : (isSmall ? 10.0 : 12.0),
      'titleSize': isVerySmall ? 18.0 : (isSmall ? 21.0 : 24.0),
      'statLabel': 10.5 * fontScale,
      'statValue': 15 * fontScale,
      'cardTitle': isVerySmall ? 14.0 : 16.0,
      'cardMeta': isVerySmall ? 10.0 : 12.0,
      'btnText': isVerySmall ? 10.5 : 12.0,
      'badgeText': isVerySmall ? 9.0 : 11.0,
    };

    PreferredSizeWidget appBar = AppBar(
      backgroundColor: const Color(0xFF0F172A),
      elevation: 0,
      centerTitle: true,
      title: Text(
        data == null ? 'Subject' : '${data!['subject']}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );

    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: appBar,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                SizedBox(height: 12),
                Text(
                  'Loading dashboard...',
                  style: TextStyle(
                    color: Color(0xFFCBD5E1),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (error.isNotEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: appBar,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFECACA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (data == null || (data!['levels'] as List?)?.isEmpty != false) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: appBar,
        body: const SafeArea(
          child: Center(
            child: Text(
              'No exams available',
              style: TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    final levels = List<Map<String, dynamic>>.from(data!['levels'] as List);
    final cardsData = [
      ...levels,
      {
        'level': 6,
        'isCertificate': true,
        'unlocked': allPassed,
      }
    ];
    final levelRows = chunkArray(cardsData, cardsPerRow);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: appBar,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -10,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.18),
                ),
              ),
            ),
            Positioned(
              bottom: 30,
              left: -30,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3B82F6).withOpacity(0.10),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(ui['containerPadding'] as double),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(ui['heroPadding'] as double),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Exam Dashboard',
                          style: TextStyle(
                            color: const Color(0xFFA78BFA),
                            fontWeight: FontWeight.w800,
                            fontSize: 12 * fontScale,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome ${user?['name'] ?? 'Student'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontSize: isVerySmall ? 11 : 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                label: 'Passed',
                                value: '$passedCount/5',
                                statLabelSize: ui['statLabel'] as double,
                                statValueSize: ui['statValue'] as double,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatBox(
                                label: 'Attempt',
                                value: '$attemptedCount/5',
                                statLabelSize: ui['statLabel'] as double,
                                statValueSize: ui['statValue'] as double,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _StatBox(
                                label: 'Avg',
                                value:
                                    '${(num.tryParse('${data!['aggregatePercent']}') ?? 0).round()}%',
                                statLabelSize: ui['statLabel'] as double,
                                statValueSize: ui['statValue'] as double,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(
                                color: const Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w700,
                                fontSize: 11 * fontScale,
                              ),
                            ),
                            Text(
                              '${((passedCount / 5) * 100).round()}%',
                              style: TextStyle(
                                color: const Color(0xFFCBD5E1),
                                fontWeight: FontWeight.w700,
                                fontSize: 11 * fontScale,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: (passedCount / 5).clamp(0, 1),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6),
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: cardGap),
                  Expanded(
                    child: Column(
                      children: [
                        for (int rowIndex = 0; rowIndex < levelRows.length; rowIndex++) ...[
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: rowIndex == 0 ? 0 : cardGap,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (int i = 0; i < levelRows[rowIndex].length; i++) ...[
                                    Expanded(
                                      child: Builder(
                                        builder: (context) {
                                          final lvl = Map<String, dynamic>.from(
                                            levelRows[rowIndex][i] as Map,
                                          );

                                          final index = rowIndex * cardsPerRow + i;
                                          final isCertificateCard =
                                              lvl['isCertificate'] == true;

                                          if (isCertificateCard) {
                                            return _buildCertificateCard(
                                              allPassed: allPassed,
                                              aggregatePercent: num.tryParse(
                                                    '${data!['aggregatePercent']}',
                                                  ) ??
                                                  0,
                                              passedCount: passedCount,
                                              isVerySmall: isVerySmall,
                                              isSmall: isSmall,
                                              ui: ui,
                                            );
                                          }

                                          final attempted = lvl['attempted'] == true;
                                          final passed = lvl['passed'] == true;
                                          final retryCount =
                                              int.tryParse('${lvl['retryCount'] ?? 0}') ?? 0;
                                          final maxRetry =
                                              int.tryParse('${lvl['maxRetry'] ?? 1}') ?? 1;
                                          final scorePercent =
                                              num.tryParse('${lvl['scorePercent'] ?? 0}') ?? 0;
                                          final startTime = lvl['start_time'] as DateTime?;
                                          final endTime = lvl['end_time'] as DateTime?;
                                          final submittedAt = lvl['submitted_at'] as DateTime?;

                                          final prevPassed = isPreviousPassed(levels, index);

                                          final isBeforeStart =
                                              startTime != null && now.isBefore(startTime);
                                          final isAfterEnd =
                                              endTime != null && now.isAfter(endTime);
                                          final isExamActive = startTime != null &&
                                              endTime != null &&
                                              (now.isAtSameMomentAs(startTime) ||
                                                  now.isAfter(startTime)) &&
                                              (now.isAtSameMomentAs(endTime) ||
                                                  now.isBefore(endTime));

                                          final canAttempt = !passed &&
                                              prevPassed &&
                                              startTime != null &&
                                              isExamActive &&
                                              (!attempted || retryCount < maxRetry);

                                          final secondsToStart =
                                              !passed && isBeforeStart && startTime != null
                                                  ? startTime.difference(now).inSeconds
                                                  : 0;

                                          final badge = getBadge(
                                            passed: passed,
                                            prevPassed: prevPassed,
                                            isAfterEnd: isAfterEnd,
                                            isExamActive: isExamActive,
                                            isBeforeStart: isBeforeStart,
                                          );

                                          String statusLine = 'Not attempted';
                                          if (attempted) statusLine = 'Score $scorePercent%';
                                          if (attempted && !passed) {
                                            statusLine += ' • $retryCount/$maxRetry';
                                          }

                                          String timeLine = '';
                                          if (!passed) {
                                            if (isExamActive) {
                                              timeLine = 'Live now';
                                            } else if (isBeforeStart) {
                                              timeLine = formatDuration(secondsToStart);
                                            } else if (isAfterEnd) {
                                              timeLine = 'Exam ended';
                                            } else {
                                              timeLine = 'Start ${formatDateTime(startTime)}';
                                            }
                                          } else {
                                            timeLine = submittedAt != null
                                                ? 'Completed on ${formatDateOnly(submittedAt)}'
                                                : 'Completed';
                                          }

                                          String buttonLabel = 'Not Available';
                                          if (passed) {
                                            buttonLabel = 'Passed';
                                          } else if (!prevPassed) {
                                            buttonLabel = 'Complete L${lvl['level'] - 1}';
                                          } else if (canAttempt) {
                                            buttonLabel = attempted ? 'Retry Exam' : 'Start Exam';
                                          }

                                          return _buildLevelCard(
                                            lvl: lvl,
                                            passed: passed,
                                            isExamActive: isExamActive,
                                            canAttempt: canAttempt,
                                            badge: badge,
                                            statusLine: statusLine,
                                            timeLine: timeLine,
                                            buttonLabel: buttonLabel,
                                            isVerySmall: isVerySmall,
                                            isSmall: isSmall,
                                            ui: ui,
                                          );
                                        },
                                      ),
                                    ),
                                    if (i != levelRows[rowIndex].length - 1)
                                      SizedBox(width: cardGap),
                                  ],
                                  if (cardsPerRow == 2 && levelRows[rowIndex].length == 1) ...[
                                    SizedBox(width: cardGap),
                                    const Expanded(child: SizedBox()),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildCertificateCard({
    required bool allPassed,
    required num aggregatePercent,
    required int passedCount,
    required bool isVerySmall,
    required bool isSmall,
    required Map<String, dynamic> ui,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 145;
        final superCompact = constraints.maxHeight < 125;

        final vGap1 = superCompact ? 3.0 : 6.0;
        final vGap2 = superCompact ? 2.0 : 4.0;
        final innerPad = superCompact
            ? ((ui['cardPadding'] as double) - 2).clamp(6.0, 20.0)
            : (ui['cardPadding'] as double);
        final titleSize = superCompact
            ? ((ui['cardTitle'] as double) - 1)
            : (ui['cardTitle'] as double);
        final metaSize = compact
            ? ((ui['cardMeta'] as double) - 1).clamp(9.0, 20.0)
            : (ui['cardMeta'] as double);
        final badgeSize = compact
            ? ((ui['badgeText'] as double) - 1).clamp(8.0, 20.0)
            : (ui['badgeText'] as double);
        final btnSize = compact
            ? ((ui['btnText'] as double) - 1).clamp(9.0, 20.0)
            : (ui['btnText'] as double);
        final btnVPad = superCompact ? 6.0 : (isVerySmall ? 8.0 : 10.0);

        return Container(
          height: double.infinity,
          padding: EdgeInsets.all(innerPad),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: allPassed
                  ? const Color(0xFF22C55E).withOpacity(0.40)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Certification',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: titleSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: superCompact ? 6 : 8,
                        vertical: superCompact ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: allPassed
                            ? const Color(0xFF22C55E).withOpacity(0.15)
                            : const Color(0xFF94A3B8).withOpacity(0.15),
                      ),
                      child: Text(
                        allPassed ? 'Unlocked' : 'Locked',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: allPassed
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFCBD5E1),
                          fontWeight: FontWeight.w900,
                          fontSize: badgeSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: vGap1),
              Text(
                allPassed
                    ? 'Avg Score ${aggregatePercent.round()}%'
                    : 'Complete all 5 levels',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                  fontSize: metaSize,
                ),
              ),
              SizedBox(height: vGap2),
              Text(
                allPassed ? 'Certificate ready' : '$passedCount/5 levels passed',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFFCBD5E1),
                  fontWeight: FontWeight.w500,
                  fontSize: metaSize,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: allPassed ? onPressCertificate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        allPassed ? const Color(0xFFF59E0B) : const Color(0xFF1E293B),
                    foregroundColor:
                        allPassed ? Colors.white : const Color(0xFF94A3B8),
                    disabledBackgroundColor: const Color(0xFF1E293B),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    minimumSize: Size.fromHeight(superCompact ? 30 : 36),
                    padding: EdgeInsets.symmetric(vertical: btnVPad),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: allPassed
                          ? BorderSide.none
                          : BorderSide(
                              color: Colors.white.withOpacity(0.06),
                            ),
                    ),
                  ),
                  child: Text(
                    allPassed ? 'Download' : 'Locked',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: btnSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelCard({
    required Map<String, dynamic> lvl,
    required bool passed,
    required bool isExamActive,
    required bool canAttempt,
    required Map<String, String> badge,
    required String statusLine,
    required String timeLine,
    required String buttonLabel,
    required bool isVerySmall,
    required bool isSmall,
    required Map<String, dynamic> ui,
  }) {
    final badgeType = badge['type']?.toString() ?? 'gray';
    final badgeLabel = badge['label']?.toString() ?? 'Locked';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 145;
        final superCompact = constraints.maxHeight < 125;

        final vGap1 = superCompact ? 3.0 : 6.0;
        final vGap2 = superCompact ? 2.0 : 4.0;
        final innerPad = superCompact
            ? ((ui['cardPadding'] as double) - 2).clamp(6.0, 20.0)
            : (ui['cardPadding'] as double);
        final titleSize = superCompact
            ? ((ui['cardTitle'] as double) - 1)
            : (ui['cardTitle'] as double);
        final metaSize = compact
            ? ((ui['cardMeta'] as double) - 1).clamp(9.0, 20.0)
            : (ui['cardMeta'] as double);
        final badgeSize = compact
            ? ((ui['badgeText'] as double) - 1).clamp(8.0, 20.0)
            : (ui['badgeText'] as double);
        final btnSize = compact
            ? ((ui['btnText'] as double) - 1).clamp(9.0, 20.0)
            : (ui['btnText'] as double);
        final btnVPad = superCompact ? 6.0 : (isVerySmall ? 8.0 : 10.0);

        return Container(
          height: double.infinity,
          padding: EdgeInsets.all(innerPad),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: passed
                  ? const Color(0xFF22C55E).withOpacity(0.40)
                  : isExamActive
                      ? const Color(0xFF3B82F6).withOpacity(0.40)
                      : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Level ${lvl['level']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: titleSize,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: superCompact ? 6 : 8,
                        vertical: superCompact ? 3 : 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: badgeBg(badgeType),
                      ),
                      child: Text(
                        badgeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: badgeTextColor(badgeType),
                          fontWeight: FontWeight.w900,
                          fontSize: badgeSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: vGap1),
              Text(
                statusLine,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                  fontSize: metaSize,
                ),
              ),
              if (timeLine.isNotEmpty) ...[
                SizedBox(height: vGap2),
                Text(
                  timeLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFCBD5E1),
                    fontWeight: FontWeight.w500,
                    fontSize: metaSize,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (!passed && canAttempt) ? () => onPressAttempt(lvl) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: passed
                        ? const Color(0xFF16A34A)
                        : canAttempt
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF1E293B),
                    foregroundColor:
                        (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
                    disabledBackgroundColor:
                        passed ? const Color(0xFF16A34A) : const Color(0xFF1E293B),
                    disabledForegroundColor:
                        (passed || canAttempt) ? Colors.white : const Color(0xFF94A3B8),
                    elevation: 0,
                    minimumSize: Size.fromHeight(superCompact ? 30 : 36),
                    padding: EdgeInsets.symmetric(vertical: btnVPad),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: (!passed && !canAttempt)
                          ? BorderSide(
                              color: Colors.white.withOpacity(0.06),
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Text(
                    buttonLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: btnSize,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final double statLabelSize;
  final double statValueSize;

  const _StatBox({
    required this.label,
    required this.value,
    required this.statLabelSize,
    required this.statValueSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
              fontWeight: FontWeight.w700,
              fontSize: statLabelSize,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: statValueSize,
            ),
          ),
        ],
      ),
    );
  }
}