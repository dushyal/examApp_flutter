



// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// import '../../core/api/api_client.dart';
// import 'subject_screen.dart';
// import 'dashboard_screen.dart';

// class ExamAttemptScreen extends StatefulWidget {
//   final String? subject;
//   final dynamic level;
//   final dynamic attemptKey;

//   const ExamAttemptScreen({
//     super.key,
//     this.subject,
//     this.level,
//     this.attemptKey,
//   });

//   @override
//   State<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
// }

// class _ExamAttemptScreenState extends State<ExamAttemptScreen>
//     with WidgetsBindingObserver {
//   List<dynamic> questions = [];
//   List<dynamic> questionIds = [];
//   Map<String, dynamic> answers = {};

//   int? timeLeft;
//   bool loading = true;
//   bool submitting = false;
//   int currentIndex = 0;
//   int switchCount = 0;

//   bool submitted = false;
//   Timer? intervalTimer;
//   DateTime? endTime;

//   String? subject;
//   dynamic level;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     subject = widget.subject;
//     level = widget.level;

//     if (subject == null || level == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showToast('Missing subject or level');
//         goToDashboard();
//       });
//       return;
//     }

//     fetchExam();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     intervalTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (submitted) return;

//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached) {
//       setState(() {
//         switchCount += 1;
//       });

//       if (switchCount < 3) {
//         showToast('App switching is not allowed ($switchCount/3 warning)');
//       }

//       if (switchCount >= 3) {
//         showToast('Exam auto-submitted. App switched 3 times');
//         handleSubmit(true);
//       }
//     }
//   }

//   void showToast(String message) {
//     Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//     );
//   }

//   String formatTime(int sec) {
//     final safe = sec < 0 ? 0 : sec;
//     final m = safe ~/ 60;
//     final s = safe % 60;
//     return '$m:${s.toString().padLeft(2, '0')}';
//   }

//   dynamic getQuestionId(dynamic q, int fallbackIndex) {
//     return q?['id'] ??
//         q?['question_id'] ??
//         q?['_id'] ??
//         'q_$fallbackIndex';
//   }

//   String getQuestionText(dynamic q) {
//     return q?['text']?.toString() ??
//         q?['question']?.toString() ??
//         q?['question_text']?.toString() ??
//         'Question';
//   }

//   dynamic getOptionId(dynamic opt, int fallbackIndex) {
//     return opt?['id'] ??
//         opt?['option_id'] ??
//         opt?['_id'] ??
//         'o_$fallbackIndex';
//   }

//   String getOptionText(dynamic opt) {
//     return opt?['text']?.toString() ??
//         opt?['option']?.toString() ??
//         opt?['option_text']?.toString() ??
//         'Option';
//   }

//   List<Map<String, dynamic>> get normalizedQuestions {
//     return questions.asMap().entries.map((entry) {
//       final qIndex = entry.key;
//       final q = entry.value;

//       return {
//         ...Map<String, dynamic>.from(q),
//         'normalizedId': getQuestionId(q, qIndex).toString(),
//         'normalizedText': getQuestionText(q),
//         'normalizedOptions': (q?['options'] is List ? q['options'] as List : [])
//             .asMap()
//             .entries
//             .map((optEntry) {
//           final oIndex = optEntry.key;
//           final opt = optEntry.value;
//           return {
//             ...Map<String, dynamic>.from(opt),
//             'normalizedId': getOptionId(opt, oIndex).toString(),
//             'normalizedText': getOptionText(opt),
//           };
//         }).toList(),
//       };
//     }).toList();
//   }

//   int get answeredCount => answers.keys.length;

//   List<List<Map<String, dynamic>>> get questionRows {
//     final items = normalizedQuestions;
//     final total = items.length;

//     if (total <= 10) return [items];

//     final perRow = total ~/ 2 + (total % 2 == 0 ? 0 : 1);
//     final limitedPerRow = perRow > 10 ? 10 : perRow;

//     final rows = <List<Map<String, dynamic>>>[];
//     for (int i = 0; i < total; i += limitedPerRow) {
//       rows.add(items.sublist(
//         i,
//         i + limitedPerRow > total ? total : i + limitedPerRow,
//       ));
//     }
//     return rows;
//   }

//   void goToDashboard() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
//       (route) => false,
//     );
//   }

//   void goToSubjects() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SubjectScreen(initialSubject: subject),
//       ),
//       (route) => false,
//     );
//   }

//   void resetExamState() {
//     questions = [];
//     questionIds = [];
//     answers = {};
//     timeLeft = null;
//     loading = true;
//     submitting = false;
//     currentIndex = 0;
//     switchCount = 0;
//     submitted = false;
//     endTime = null;
//     intervalTimer?.cancel();
//     intervalTimer = null;
//   }

//   Future<void> fetchExam() async {
//     resetExamState();
//     if (mounted) setState(() {});

//     try {
//       final res = await ApiClient.dio.get(
//         '/start-exam/${Uri.encodeComponent(subject.toString())}/$level',
//       );

//       final apiQuestions =
//           res.data?['questions'] is List ? List.from(res.data['questions']) : [];
//       final apiQuestionIds = res.data?['question_ids'] is List
//           ? List.from(res.data['question_ids'])
//           : [];

//       if (apiQuestions.isEmpty) {
//         showToast('No questions available for this exam');
//         goToDashboard();
//         return;
//       }

//       final normalizedIds = apiQuestionIds.isNotEmpty
//           ? apiQuestionIds
//           : apiQuestions
//               .asMap()
//               .entries
//               .map((e) => getQuestionId(e.value, e.key))
//               .toList();

//       final durationMin = num.tryParse('${res.data?['duration'] ?? 0}') ?? 0;
//       final durationSec = durationMin > 0 ? durationMin.toInt() * 60 : 0;

//       if (durationSec <= 0) {
//         showToast('Invalid exam duration');
//         goToDashboard();
//         return;
//       }

//       questions = apiQuestions;
//       questionIds = normalizedIds;
//       timeLeft = durationSec;
//       endTime = DateTime.now().add(Duration(seconds: durationSec));
//       startCountdown();
//     } catch (err) {
//       String msg = 'Exam access denied. Please check your exam schedule.';
//       if (err is DioException) {
//         msg = err.response?.data?['message']?.toString() ?? msg;
//       }
//       showToast(msg);
//       goToDashboard();
//       return;
//     } finally {
//       if (mounted) {
//         setState(() {
//           loading = false;
//         });
//       }
//     }
//   }

//   void startCountdown() {
//     intervalTimer?.cancel();

//     intervalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (endTime == null || !mounted) return;

//       final remaining = endTime!.difference(DateTime.now()).inSeconds;
//       final safeRemaining = remaining < 0 ? 0 : remaining;

//       setState(() {
//         timeLeft = safeRemaining;
//       });

//       if (safeRemaining <= 0) {
//         intervalTimer?.cancel();
//         if (!submitted) {
//           handleSubmit(true);
//         }
//       }
//     });
//   }

//   void handleAnswerChange(String qid, String oid) {
//     if (submitted || submitting) return;

//     setState(() {
//       answers[qid] = oid;
//     });
//   }

//   Future<void> handleSubmit(bool auto) async {
//     if (submitting || submitted) return;

//     if (!auto && answers.isEmpty) {
//       showToast('Answer at least one question');
//       return;
//     }

//     submitted = true;
//     setState(() {
//       submitting = true;
//     });

//     intervalTimer?.cancel();

//     try {
//       final res = await ApiClient.dio.post(
//         '/start-exam/${Uri.encodeComponent(subject.toString())}/$level/submit',
//         data: {
//           'answers': answers,
//           'question_ids': questionIds.isNotEmpty
//               ? questionIds
//               : normalizedQuestions.map((q) => q['normalizedId']).toList(),
//           'auto': auto,
//         },
//       );

//       final score = num.tryParse('${res.data?['score'] ?? 0}') ?? 0;
//       final totalMarks = num.tryParse('${res.data?['totalMarks'] ?? 0}') ?? 0;
//       final studentPercentage =
//           num.tryParse('${res.data?['studentPercentage'] ?? 0}') ?? 0;
//       final passingPercentage =
//           num.tryParse('${res.data?['passingPercentage'] ?? 0}') ?? 0;
//       final passStatus = '${res.data?['pass_status'] ?? ''}'.toLowerCase();

//       final passed = passStatus == 'pass';

//       if (passed) {
//         showToast(
//           'Congratulations! You passed with ${studentPercentage.toStringAsFixed(0)}%',
//         );
//         await Future.delayed(const Duration(milliseconds: 800));
//         if (!mounted) return;
//         goToSubjects();
//       } else {
//         final passingMarks = ((passingPercentage / 100) * totalMarks).ceil();
//         showToast(
//           'Exam Failed. Score ${score.toStringAsFixed(0)} / $passingMarks | ${studentPercentage.toStringAsFixed(0)}%',
//         );
//         await Future.delayed(const Duration(milliseconds: 800));
//         if (!mounted) return;
//         goToDashboard();
//       }
//     } catch (err) {
//       submitted = false;
//       if (mounted) {
//         setState(() {
//           submitting = false;
//         });
//       }

//       String msg = 'Submission failed. Please try again.';
//       if (err is DioException) {
//         msg = err.response?.data?['message']?.toString() ?? msg;
//       }
//       showToast(msg);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isVerySmall = width < 340 || height < 680;
//     final isSmall = width < 380 || height < 760;

//     final gap = isVerySmall ? 6.0 : (isSmall ? 8.0 : 10.0);
//     final pad = isVerySmall ? 12.0 : (isSmall ? 14.0 : 16.0);
//     final optionPadV = isVerySmall ? 10.0 : (isSmall ? 12.0 : 16.0);
//     final titleSize = isVerySmall ? 16.0 : (isSmall ? 17.0 : 18.0);
//     final subTitleSize = isVerySmall ? 12.0 : 14.0;
//     final questionSize = isVerySmall ? 15.0 : (isSmall ? 16.0 : 17.0);
//     final optionTextSize = isVerySmall ? 13.0 : (isSmall ? 14.0 : 15.0);
//     final btnHeight = isVerySmall ? 46.0 : (isSmall ? 52.0 : 56.0);

//     final maxInRow = questionRows.isEmpty
//         ? 1
//         : questionRows.map((r) => r.length).reduce((a, b) => a > b ? a : b);

//     final horizontalPadding = pad * 2;
//     final totalGap = (maxInRow - 1) * 8;
//     final availableWidth = width - horizontalPadding - totalGap;
//     final rawSize = (availableWidth / maxInRow).floorToDouble();
//     final minSize = isVerySmall ? 26.0 : 30.0;
//     final maxSize = isVerySmall ? 34.0 : 40.0;
//     final circleSize = rawSize.clamp(minSize, maxSize);

//     if (loading || timeLeft == null) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF4338CA),
//         body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 CircularProgressIndicator(color: Colors.white),
//                 SizedBox(height: 10),
//                 Text(
//                   'Loading exam...',
//                   style: TextStyle(
//                     color: Color(0xD9FFFFFF),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     final currentQuestion =
//         normalizedQuestions.isNotEmpty ? normalizedQuestions[currentIndex] : null;

//     if (currentQuestion == null) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF4338CA),
//         body: SafeArea(
//           child: Center(
//             child: Text(
//               'No questions available',
//               style: TextStyle(
//                 color: Color(0xD9FFFFFF),
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final progressPercent = normalizedQuestions.isEmpty
//         ? 0
//         : (((currentIndex + 1) / normalizedQuestions.length) * 100).round();

//     return Scaffold(
//       backgroundColor: const Color(0xFF4338CA),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.fromLTRB(pad, pad * 0.75, pad, pad),
//           child: Column(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(isVerySmall ? 10 : 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.14),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '$subject — Level $level',
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                         fontSize: titleSize,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Question ${currentIndex + 1} of ${normalizedQuestions.length}',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: const Color(0xD1FFFFFF),
//                         fontSize: subTitleSize,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Container(
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.20),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: FractionallySizedBox(
//                         alignment: Alignment.centerLeft,
//                         widthFactor: progressPercent / 100,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(999),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       '$progressPercent% complete',
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Color(0xC7FFFFFF),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isVerySmall ? 10 : 12,
//                         vertical: isVerySmall ? 6 : 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: Text(
//                         '⏱ ${formatTime(timeLeft!)}',
//                         style: TextStyle(
//                           color: const Color(0xFF3730A3),
//                           fontWeight: FontWeight.w900,
//                           fontSize: isVerySmall ? 14 : 16,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'App switch: $switchCount/3',
//                       style: TextStyle(
//                         color: const Color(0xC7FFFFFF),
//                         fontSize: isVerySmall ? 11 : 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Column(
//                       children: questionRows.asMap().entries.map((rowEntry) {
//                         final rowIndex = rowEntry.key;
//                         final row = rowEntry.value;
//                         final offset = questionRows
//                             .take(rowIndex)
//                             .fold<int>(0, (acc, r) => acc + r.length);

//                         return Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: row.asMap().entries.map((entry) {
//                             final indexInRow = entry.key;
//                             final q = entry.value;
//                             final actualIndex = offset + indexInRow;
//                             final isActive = actualIndex == currentIndex;
//                             final isAnswered =
//                                 answers[q['normalizedId']] != null;

//                             return GestureDetector(
//                               onTap: () {
//                                 setState(() {
//                                   currentIndex = actualIndex;
//                                 });
//                               },
//                               child: AnimatedContainer(
//                                 duration: const Duration(milliseconds: 180),
//                                 width: circleSize,
//                                 height: circleSize,
//                                 margin: const EdgeInsets.symmetric(
//                                   horizontal: 4,
//                                   vertical: 4,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: isActive
//                                       ? Colors.white
//                                       : isAnswered
//                                           ? const Color(0xFF34D399)
//                                           : Colors.white.withOpacity(0.22),
//                                 ),
//                                 alignment: Alignment.center,
//                                 child: Text(
//                                   '${actualIndex + 1}',
//                                   style: TextStyle(
//                                     color: isActive
//                                         ? const Color(0xFF3730A3)
//                                         : Colors.white,
//                                     fontWeight: FontWeight.w900,
//                                     fontSize: circleSize * 0.38,
//                                   ),
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: gap),
//               Expanded(
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(pad),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(22),
//                     color: Colors.white.withOpacity(0.14),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.22),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${currentIndex + 1}. ${currentQuestion['normalizedText']}',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w900,
//                           fontSize: questionSize,
//                           height: 1.4,
//                         ),
//                       ),
//                       SizedBox(height: gap + 2),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Column(
//                             children:
//                                 (currentQuestion['normalizedOptions'] as List)
//                                     .map<Widget>((opt) {
//                               final selected =
//                                   answers[currentQuestion['normalizedId']] ==
//                                       opt['normalizedId'];

//                               return GestureDetector(
//                                 onTap: submitting
//                                     ? null
//                                     : () => handleAnswerChange(
//                                           currentQuestion['normalizedId'],
//                                           opt['normalizedId'],
//                                         ),
//                                 child: Container(
//                                   width: double.infinity,
//                                   margin: EdgeInsets.only(bottom: gap),
//                                   padding: EdgeInsets.symmetric(
//                                     vertical: optionPadV,
//                                     horizontal: pad,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(16),
//                                     color: selected
//                                         ? Colors.white
//                                         : Colors.white.withOpacity(0.10),
//                                     border: Border.all(
//                                       color: Colors.white.withOpacity(0.16),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           '${opt['normalizedText']}',
//                                           style: TextStyle(
//                                             color: selected
//                                                 ? const Color(0xFF3730A3)
//                                                 : Colors.white,
//                                             fontWeight: selected
//                                                 ? FontWeight.w900
//                                                 : FontWeight.w800,
//                                             fontSize: optionTextSize,
//                                           ),
//                                         ),
//                                       ),
//                                       if (selected)
//                                         Container(
//                                           width: isVerySmall ? 24 : 28,
//                                           height: isVerySmall ? 24 : 28,
//                                           decoration: BoxDecoration(
//                                             shape: BoxShape.circle,
//                                             color: const Color(0xFF4338CA)
//                                                 .withOpacity(0.12),
//                                           ),
//                                           child: Icon(
//                                             Icons.check,
//                                             size: isVerySmall ? 14 : 16,
//                                             color: const Color(0xFF3730A3),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: gap + 2),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Answered: $answeredCount/${normalizedQuestions.length}',
//                     style: TextStyle(
//                       color: const Color(0xD1FFFFFF),
//                       fontSize: isVerySmall ? 11 : 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   Text(
//                     'Remaining: ${normalizedQuestions.length - answeredCount}',
//                     style: TextStyle(
//                       color: const Color(0xD1FFFFFF),
//                       fontSize: isVerySmall ? 11 : 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: gap),
//               Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: btnHeight,
//                       child: ElevatedButton(
//                         onPressed: (currentIndex == 0 || submitting)
//                             ? null
//                             : () {
//                                 setState(() {
//                                   currentIndex =
//                                       currentIndex > 0 ? currentIndex - 1 : 0;
//                                 });
//                               },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white.withOpacity(0.18),
//                           foregroundColor: const Color(0xFFE9E7FF),
//                           disabledBackgroundColor:
//                               Colors.white.withOpacity(0.18),
//                           disabledForegroundColor:
//                               const Color(0xFFE9E7FF).withOpacity(0.45),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                         ),
//                         child: Text(
//                           '‹ Previous',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: isVerySmall ? 13 : 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: gap),
//                   Expanded(
//                     child: SizedBox(
//                       height: btnHeight,
//                       child: ElevatedButton(
//                         onPressed: submitting
//                             ? null
//                             : () {
//                                 if (currentIndex ==
//                                     normalizedQuestions.length - 1) {
//                                   handleSubmit(false);
//                                 } else {
//                                   setState(() {
//                                     currentIndex = currentIndex + 1;
//                                   });
//                                 }
//                               },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           foregroundColor: const Color(0xFF3730A3),
//                           disabledBackgroundColor:
//                               Colors.white.withOpacity(0.45),
//                           disabledForegroundColor:
//                               const Color(0xFF3730A3).withOpacity(0.7),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                         ),
//                         child: Text(
//                           currentIndex == normalizedQuestions.length - 1
//                               ? (submitting ? 'Submitting...' : 'Submit Exam')
//                               : 'Next ›',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: isVerySmall ? 13 : 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }





// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// import '../../core/api/api_client.dart';
// import 'subject_screen.dart';
// import 'dashboard_screen.dart';

// class ExamAttemptScreen extends StatefulWidget {
//   final String? subject;
//   final dynamic level;
//   final dynamic attemptKey;

//   const ExamAttemptScreen({
//     super.key,
//     this.subject,
//     this.level,
//     this.attemptKey,
//   });

//   @override
//   State<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
// }

// class _ExamAttemptScreenState extends State<ExamAttemptScreen>
//     with WidgetsBindingObserver {
//   List<dynamic> questions = [];
//   List<dynamic> questionIds = [];
//   Map<String, dynamic> answers = {};

//   int? timeLeft;
//   bool loading = true;
//   bool submitting = false;
//   int currentIndex = 0;
//   int switchCount = 0;

//   bool submitted = false;
//   Timer? intervalTimer;
//   DateTime? endTime;

//   String? subject;
//   dynamic level;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     subject = widget.subject;
//     level = widget.level;

//     if (subject == null || level == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showToast('Missing subject or level');
//         goToDashboard();
//       });
//       return;
//     }

//     fetchExam();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     intervalTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (submitted) return;

//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached) {
//       setState(() {
//         switchCount += 1;
//       });

//       if (switchCount < 3) {
//         showToast('App switching is not allowed ($switchCount/3 warning)');
//       }

//       if (switchCount >= 3) {
//         showToast('Exam auto-submitted. App switched 3 times');
//         handleSubmit(true);
//       }
//     }
//   }

//   void showToast(String message) {
//     Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//     );
//   }

//   String formatTime(int sec) {
//     final safe = sec < 0 ? 0 : sec;
//     final m = safe ~/ 60;
//     final s = safe % 60;
//     return '$m:${s.toString().padLeft(2, '0')}';
//   }

//   dynamic getQuestionId(dynamic q, int fallbackIndex) {
//     return q?['id'] ??
//         q?['question_id'] ??
//         q?['_id'] ??
//         'q_$fallbackIndex';
//   }

//   String getQuestionText(dynamic q) {
//     return q?['text']?.toString() ??
//         q?['question']?.toString() ??
//         q?['question_text']?.toString() ??
//         'Question';
//   }

//   dynamic getOptionId(dynamic opt, int fallbackIndex) {
//     return opt?['id'] ??
//         opt?['option_id'] ??
//         opt?['_id'] ??
//         'o_$fallbackIndex';
//   }

//   String getOptionText(dynamic opt) {
//     return opt?['text']?.toString() ??
//         opt?['option']?.toString() ??
//         opt?['option_text']?.toString() ??
//         'Option';
//   }

//   List<Map<String, dynamic>> get normalizedQuestions {
//     return questions.asMap().entries.map((entry) {
//       final qIndex = entry.key;
//       final q = entry.value;

//       return {
//         ...Map<String, dynamic>.from(q),
//         'normalizedId': getQuestionId(q, qIndex).toString(),
//         'normalizedText': getQuestionText(q),
//         'normalizedOptions': (q?['options'] is List ? q['options'] as List : [])
//             .asMap()
//             .entries
//             .map((optEntry) {
//           final oIndex = optEntry.key;
//           final opt = optEntry.value;
//           return {
//             ...Map<String, dynamic>.from(opt),
//             'normalizedId': getOptionId(opt, oIndex).toString(),
//             'normalizedText': getOptionText(opt),
//           };
//         }).toList(),
//       };
//     }).toList();
//   }

//   int get answeredCount => answers.keys.length;

//   void goToDashboard() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
//       (route) => false,
//     );
//   }

//   void goToSubjects() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(
//         builder: (_) => SubjectScreen(initialSubject: subject),
//       ),
//       (route) => false,
//     );
//   }

//   void resetExamState() {
//     questions = [];
//     questionIds = [];
//     answers = {};
//     timeLeft = null;
//     loading = true;
//     submitting = false;
//     currentIndex = 0;
//     switchCount = 0;
//     submitted = false;
//     endTime = null;
//     intervalTimer?.cancel();
//     intervalTimer = null;
//   }

//   Future<void> fetchExam() async {
//     resetExamState();
//     if (mounted) setState(() {});

//     try {
//       final res = await ApiClient.dio.get(
//         '/start-exam/${Uri.encodeComponent(subject.toString())}/$level',
//       );

//       final apiQuestions =
//           res.data?['questions'] is List ? List.from(res.data['questions']) : [];
//       final apiQuestionIds = res.data?['question_ids'] is List
//           ? List.from(res.data['question_ids'])
//           : [];

//       if (apiQuestions.isEmpty) {
//         showToast('No questions available for this exam');
//         goToDashboard();
//         return;
//       }

//       final normalizedIds = apiQuestionIds.isNotEmpty
//           ? apiQuestionIds
//           : apiQuestions
//               .asMap()
//               .entries
//               .map((e) => getQuestionId(e.value, e.key))
//               .toList();

//       final durationMin = num.tryParse('${res.data?['duration'] ?? 0}') ?? 0;
//       final durationSec = durationMin > 0 ? durationMin.toInt() * 60 : 0;

//       if (durationSec <= 0) {
//         showToast('Invalid exam duration');
//         goToDashboard();
//         return;
//       }

//       questions = apiQuestions;
//       questionIds = normalizedIds;
//       timeLeft = durationSec;
//       endTime = DateTime.now().add(Duration(seconds: durationSec));
//       startCountdown();
//     } catch (err) {
//       String msg = 'Exam access denied. Please check your exam schedule.';
//       if (err is DioException) {
//         msg = err.response?.data?['message']?.toString() ?? msg;
//       }
//       showToast(msg);
//       goToDashboard();
//       return;
//     } finally {
//       if (mounted) {
//         setState(() {
//           loading = false;
//         });
//       }
//     }
//   }

//   void startCountdown() {
//     intervalTimer?.cancel();

//     intervalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (endTime == null || !mounted) return;

//       final remaining = endTime!.difference(DateTime.now()).inSeconds;
//       final safeRemaining = remaining < 0 ? 0 : remaining;

//       setState(() {
//         timeLeft = safeRemaining;
//       });

//       if (safeRemaining <= 0) {
//         intervalTimer?.cancel();
//         if (!submitted) {
//           handleSubmit(true);
//         }
//       }
//     });
//   }

//   void handleAnswerChange(String qid, String oid) {
//     if (submitted || submitting) return;

//     setState(() {
//       answers[qid] = oid;
//     });
//   }

//   Future<void> handleSubmit(bool auto) async {
//     if (submitting || submitted) return;

//     if (!auto && answers.isEmpty) {
//       showToast('Answer at least one question');
//       return;
//     }

//     submitted = true;
//     setState(() {
//       submitting = true;
//     });

//     intervalTimer?.cancel();

//     try {
//       final res = await ApiClient.dio.post(
//         '/start-exam/${Uri.encodeComponent(subject.toString())}/$level/submit',
//         data: {
//           'answers': answers,
//           'question_ids': questionIds.isNotEmpty
//               ? questionIds
//               : normalizedQuestions.map((q) => q['normalizedId']).toList(),
//           'auto': auto,
//         },
//       );

//       final score = num.tryParse('${res.data?['score'] ?? 0}') ?? 0;
//       final totalMarks = num.tryParse('${res.data?['totalMarks'] ?? 0}') ?? 0;
//       final studentPercentage =
//           num.tryParse('${res.data?['studentPercentage'] ?? 0}') ?? 0;
//       final passingPercentage =
//           num.tryParse('${res.data?['passingPercentage'] ?? 0}') ?? 0;
//       final passStatus = '${res.data?['pass_status'] ?? ''}'.toLowerCase();

//       final passed = passStatus == 'pass';

//       if (passed) {
//         showToast(
//           'Congratulations! You passed with ${studentPercentage.toStringAsFixed(0)}%',
//         );
//         await Future.delayed(const Duration(milliseconds: 800));
//         if (!mounted) return;
//         goToSubjects();
//       } else {
//         final passingMarks = ((passingPercentage / 100) * totalMarks).ceil();
//         showToast(
//           'Exam Failed. Score ${score.toStringAsFixed(0)} / $passingMarks | ${studentPercentage.toStringAsFixed(0)}%',
//         );
//         await Future.delayed(const Duration(milliseconds: 800));
//         if (!mounted) return;
//         goToDashboard();
//       }
//     } catch (err) {
//       submitted = false;
//       if (mounted) {
//         setState(() {
//           submitting = false;
//         });
//       }

//       String msg = 'Submission failed. Please try again.';
//       if (err is DioException) {
//         msg = err.response?.data?['message']?.toString() ?? msg;
//       }
//       showToast(msg);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isVerySmall = width < 340 || height < 680;
//     final isSmall = width < 380 || height < 760;

//     final gap = isVerySmall ? 6.0 : (isSmall ? 8.0 : 10.0);
//     final pad = isVerySmall ? 12.0 : (isSmall ? 14.0 : 16.0);
//     final optionPadV = isVerySmall ? 10.0 : (isSmall ? 12.0 : 16.0);
//     final titleSize = isVerySmall ? 16.0 : (isSmall ? 17.0 : 18.0);
//     final subTitleSize = isVerySmall ? 12.0 : 14.0;
//     final questionSize = isVerySmall ? 15.0 : (isSmall ? 16.0 : 17.0);
//     final optionTextSize = isVerySmall ? 13.0 : (isSmall ? 14.0 : 15.0);
//     final btnHeight = isVerySmall ? 46.0 : (isSmall ? 52.0 : 56.0);

//     final maxInRow =
//         normalizedQuestions.isEmpty ? 1 : (normalizedQuestions.length > 8 ? 8 : normalizedQuestions.length);

//     final horizontalPadding = pad * 2;
//     final totalGap = (maxInRow - 1) * 8;
//     final availableWidth = width - horizontalPadding - totalGap;
//     final rawSize =
//         (availableWidth / (maxInRow == 0 ? 1 : maxInRow)).floorToDouble();
//     final minSize = isVerySmall ? 28.0 : 32.0;
//     final maxSize = isVerySmall ? 34.0 : 40.0;
//     final circleSize = rawSize.clamp(minSize, maxSize);

//     if (loading || timeLeft == null) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF4338CA),
//         body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 CircularProgressIndicator(color: Colors.white),
//                 SizedBox(height: 10),
//                 Text(
//                   'Loading exam...',
//                   style: TextStyle(
//                     color: Color(0xD9FFFFFF),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     final currentQuestion =
//         normalizedQuestions.isNotEmpty ? normalizedQuestions[currentIndex] : null;

//     if (currentQuestion == null) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF4338CA),
//         body: SafeArea(
//           child: Center(
//             child: Text(
//               'No questions available',
//               style: TextStyle(
//                 color: Color(0xD9FFFFFF),
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final progressPercent = normalizedQuestions.isEmpty
//         ? 0
//         : (((currentIndex + 1) / normalizedQuestions.length) * 100).round();

//     return Scaffold(
//       backgroundColor: const Color(0xFF4338CA),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.fromLTRB(pad, pad * 0.75, pad, pad),
//           child: Column(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(isVerySmall ? 10 : 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.14),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '$subject — Level $level',
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                         fontSize: titleSize,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Question ${currentIndex + 1} of ${normalizedQuestions.length}',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: const Color(0xD1FFFFFF),
//                         fontSize: subTitleSize,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Container(
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.20),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: FractionallySizedBox(
//                         alignment: Alignment.centerLeft,
//                         widthFactor: progressPercent / 100,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(999),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       '$progressPercent% complete',
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Color(0xC7FFFFFF),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isVerySmall ? 10 : 12,
//                         vertical: isVerySmall ? 6 : 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: Text(
//                         '⏱ ${formatTime(timeLeft!)}',
//                         style: TextStyle(
//                           color: const Color(0xFF3730A3),
//                           fontWeight: FontWeight.w900,
//                           fontSize: isVerySmall ? 14 : 16,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'App switch: $switchCount/3',
//                       style: TextStyle(
//                         color: const Color(0xC7FFFFFF),
//                         fontSize: isVerySmall ? 11 : 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Wrap(
//                       alignment: WrapAlignment.center,
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: normalizedQuestions.asMap().entries.map((entry) {
//                         final actualIndex = entry.key;
//                         final q = entry.value;
//                         final isActive = actualIndex == currentIndex;
//                         final isAnswered =
//                             answers[q['normalizedId']] != null;

//                         return GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               currentIndex = actualIndex;
//                             });
//                           },
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 180),
//                             width: circleSize,
//                             height: circleSize,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: isActive
//                                   ? Colors.white
//                                   : isAnswered
//                                       ? const Color(0xFF34D399)
//                                       : Colors.white.withOpacity(0.22),
//                             ),
//                             alignment: Alignment.center,
//                             child: Text(
//                               '${actualIndex + 1}',
//                               style: TextStyle(
//                                 color: isActive
//                                     ? const Color(0xFF3730A3)
//                                     : Colors.white,
//                                 fontWeight: FontWeight.w900,
//                                 fontSize: circleSize * 0.38,
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: gap),
//               Expanded(
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(pad),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(22),
//                     color: Colors.white.withOpacity(0.14),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.22),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${currentIndex + 1}. ${currentQuestion['normalizedText']}',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w900,
//                           fontSize: questionSize,
//                           height: 1.4,
//                         ),
//                       ),
//                       SizedBox(height: gap + 2),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Column(
//                             children:
//                                 (currentQuestion['normalizedOptions'] as List)
//                                     .map<Widget>((opt) {
//                               final selected =
//                                   answers[currentQuestion['normalizedId']] ==
//                                       opt['normalizedId'];

//                               return GestureDetector(
//                                 onTap: submitting
//                                     ? null
//                                     : () => handleAnswerChange(
//                                           currentQuestion['normalizedId'],
//                                           opt['normalizedId'],
//                                         ),
//                                 child: Container(
//                                   width: double.infinity,
//                                   margin: EdgeInsets.only(bottom: gap),
//                                   padding: EdgeInsets.symmetric(
//                                     vertical: optionPadV,
//                                     horizontal: pad,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(16),
//                                     color: selected
//                                         ? Colors.white
//                                         : Colors.white.withOpacity(0.10),
//                                     border: Border.all(
//                                       color: Colors.white.withOpacity(0.16),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           '${opt['normalizedText']}',
//                                           style: TextStyle(
//                                             color: selected
//                                                 ? const Color(0xFF3730A3)
//                                                 : Colors.white,
//                                             fontWeight: selected
//                                                 ? FontWeight.w900
//                                                 : FontWeight.w800,
//                                             fontSize: optionTextSize,
//                                           ),
//                                         ),
//                                       ),
//                                       if (selected)
//                                         Container(
//                                           width: isVerySmall ? 24 : 28,
//                                           height: isVerySmall ? 24 : 28,
//                                           decoration: BoxDecoration(
//                                             shape: BoxShape.circle,
//                                             color: const Color(0xFF4338CA)
//                                                 .withOpacity(0.12),
//                                           ),
//                                           child: Icon(
//                                             Icons.check,
//                                             size: isVerySmall ? 14 : 16,
//                                             color: const Color(0xFF3730A3),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: gap + 2),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Answered: $answeredCount/${normalizedQuestions.length}',
//                     style: TextStyle(
//                       color: const Color(0xD1FFFFFF),
//                       fontSize: isVerySmall ? 11 : 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   Text(
//                     'Remaining: ${normalizedQuestions.length - answeredCount}',
//                     style: TextStyle(
//                       color: const Color(0xD1FFFFFF),
//                       fontSize: isVerySmall ? 11 : 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: gap),
//               Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: btnHeight,
//                       child: ElevatedButton(
//                         onPressed: (currentIndex == 0 || submitting)
//                             ? null
//                             : () {
//                                 setState(() {
//                                   currentIndex =
//                                       currentIndex > 0 ? currentIndex - 1 : 0;
//                                 });
//                               },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white.withOpacity(0.18),
//                           foregroundColor: const Color(0xFFE9E7FF),
//                           disabledBackgroundColor:
//                               Colors.white.withOpacity(0.18),
//                           disabledForegroundColor:
//                               const Color(0xFFE9E7FF).withOpacity(0.45),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                         ),
//                         child: Text(
//                           '‹ Previous',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: isVerySmall ? 13 : 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: gap),
//                   Expanded(
//                     child: SizedBox(
//                       height: btnHeight,
//                       child: ElevatedButton(
//                         onPressed: submitting
//                             ? null
//                             : () {
//                                 if (currentIndex ==
//                                     normalizedQuestions.length - 1) {
//                                   handleSubmit(false);
//                                 } else {
//                                   setState(() {
//                                     currentIndex = currentIndex + 1;
//                                   });
//                                 }
//                               },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           foregroundColor: const Color(0xFF3730A3),
//                           disabledBackgroundColor:
//                               Colors.white.withOpacity(0.45),
//                           disabledForegroundColor:
//                               const Color(0xFF3730A3).withOpacity(0.7),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                         ),
//                         child: Text(
//                           currentIndex == normalizedQuestions.length - 1
//                               ? (submitting ? 'Submitting...' : 'Submit Exam')
//                               : 'Next ›',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: isVerySmall ? 13 : 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }






// import 'dart:async';

// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// import '../../core/api/api_client.dart';
// import 'subject_screen.dart';
// import 'dashboard_screen.dart';

// class ExamAttemptScreen extends StatefulWidget {
//   final String? subject;
//   final dynamic level;
//   final dynamic attemptKey;

//   const ExamAttemptScreen({
//     super.key,
//     this.subject,
//     this.level,
//     this.attemptKey,
//   });

//   @override
//   State<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
// }

// class _ExamAttemptScreenState extends State<ExamAttemptScreen>
//     with WidgetsBindingObserver {
//   List<dynamic> questions = [];
//   List<dynamic> questionIds = [];
//   Map<String, dynamic> answers = {};

//   int? timeLeft;
//   bool loading = true;
//   bool submitting = false;
//   int currentIndex = 0;
//   int switchCount = 0;

//   bool submitted = false;
//   Timer? intervalTimer;
//   DateTime? endTime;

//   String? subject;
//   dynamic level;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     subject = widget.subject;
//     level = widget.level;

//     if (subject == null || level == null) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         showToast('Missing subject or level');
//         goToDashboard();
//       });
//       return;
//     }

//     fetchExam();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     intervalTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (!mounted || submitted) return;

//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached) {
//       setState(() {
//         switchCount += 1;
//       });

//       if (switchCount < 3) {
//         showToast('App switching is not allowed ($switchCount/3 warning)');
//       }

//       if (switchCount >= 3) {
//         showToast('Exam auto-submitted. App switched 3 times');
//         handleSubmit(true);
//       }
//     }
//   }

//   void showToast(String message) {
//     Fluttertoast.showToast(
//       msg: message,
//       toastLength: Toast.LENGTH_SHORT,
//       gravity: ToastGravity.BOTTOM,
//     );
//   }

//   String formatTime(int sec) {
//     final safe = sec < 0 ? 0 : sec;
//     final m = safe ~/ 60;
//     final s = safe % 60;
//     return '$m:${s.toString().padLeft(2, '0')}';
//   }

//   dynamic getQuestionId(dynamic q, int fallbackIndex) {
//     return q?['id'] ?? q?['question_id'] ?? q?['_id'] ?? 'q_$fallbackIndex';
//   }

//   String getQuestionText(dynamic q) {
//     return q?['text']?.toString() ??
//         q?['question']?.toString() ??
//         q?['question_text']?.toString() ??
//         'Question';
//   }

//   dynamic getOptionId(dynamic opt, int fallbackIndex) {
//     return opt?['id'] ?? opt?['option_id'] ?? opt?['_id'] ?? 'o_$fallbackIndex';
//   }

//   String getOptionText(dynamic opt) {
//     return opt?['text']?.toString() ??
//         opt?['option']?.toString() ??
//         opt?['option_text']?.toString() ??
//         'Option';
//   }

//   List<Map<String, dynamic>> get normalizedQuestions {
//     return questions.asMap().entries.map((entry) {
//       final qIndex = entry.key;
//       final q = entry.value;

//       return {
//         ...Map<String, dynamic>.from(q),
//         'normalizedId': getQuestionId(q, qIndex).toString(),
//         'normalizedText': getQuestionText(q),
//         'normalizedOptions': (q?['options'] is List ? q['options'] as List : [])
//             .asMap()
//             .entries
//             .map((optEntry) {
//           final oIndex = optEntry.key;
//           final opt = optEntry.value;
//           return {
//             ...Map<String, dynamic>.from(opt),
//             'normalizedId': getOptionId(opt, oIndex).toString(),
//             'normalizedText': getOptionText(opt),
//           };
//         }).toList(),
//       };
//     }).toList();
//   }

//   int get answeredCount => answers.keys.length;

//   void goToDashboard() {
//     if (!mounted) return;
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(builder: (_) => const StudentDashboardScreen()),
//       (route) => false,
//     );
//   }

//   void goToSubjects() {
//     if (!mounted) return;
//     Navigator.of(context).pushAndRemoveUntil(
//       MaterialPageRoute(
//         builder: (_) => SubjectScreen(initialSubject: subject),
//       ),
//       (route) => false,
//     );
//   }

//   void resetExamState() {
//     questions = [];
//     questionIds = [];
//     answers = {};
//     timeLeft = null;
//     loading = true;
//     submitting = false;
//     currentIndex = 0;
//     switchCount = 0;
//     submitted = false;
//     endTime = null;
//     intervalTimer?.cancel();
//     intervalTimer = null;
//   }

//   Future<void> fetchExam() async {
//     resetExamState();
//     if (mounted) setState(() {});

//     try {
//       final res = await ApiClient.dio.get(
//         '/start-exam/${Uri.encodeComponent(subject.toString())}/$level',
//       );

//       final apiQuestions =
//           res.data?['questions'] is List ? List.from(res.data['questions']) : [];
//       final apiQuestionIds = res.data?['question_ids'] is List
//           ? List.from(res.data['question_ids'])
//           : [];

//       if (apiQuestions.isEmpty) {
//         showToast('No questions available for this exam');
//         goToDashboard();
//         return;
//       }

//       final normalizedIds = apiQuestionIds.isNotEmpty
//           ? apiQuestionIds
//           : apiQuestions
//               .asMap()
//               .entries
//               .map((e) => getQuestionId(e.value, e.key))
//               .toList();

//       final durationMin = num.tryParse('${res.data?['duration'] ?? 0}') ?? 0;
//       final durationSec = durationMin > 0 ? durationMin.toInt() * 60 : 0;

//       if (durationSec <= 0) {
//         showToast('Invalid exam duration');
//         goToDashboard();
//         return;
//       }

//       questions = apiQuestions;
//       questionIds = normalizedIds;
//       timeLeft = durationSec;
//       endTime = DateTime.now().add(Duration(seconds: durationSec));
//       startCountdown();
//     } catch (err) {
//       String msg = 'Exam access denied. Please check your exam schedule.';
//       if (err is DioException) {
//         msg = err.response?.data?['message']?.toString() ?? msg;
//       }
//       showToast(msg);
//       goToDashboard();
//       return;
//     } finally {
//       if (mounted) {
//         setState(() {
//           loading = false;
//         });
//       }
//     }
//   }

//   void startCountdown() {
//     intervalTimer?.cancel();

//     intervalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
//       if (!mounted || endTime == null || submitted) return;

//       final remaining = endTime!.difference(DateTime.now()).inSeconds;
//       final safeRemaining = remaining < 0 ? 0 : remaining;

//       setState(() {
//         timeLeft = safeRemaining;
//       });

//       if (safeRemaining <= 0) {
//         intervalTimer?.cancel();
//         if (!submitted) {
//           handleSubmit(true);
//         }
//       }
//     });
//   }

//   void handleAnswerChange(String qid, String oid) {
//     if (submitted || submitting) return;

//     setState(() {
//       answers[qid] = oid;
//     });
//   }

//   Future<void> handleSubmit(bool auto) async {
//     if (submitting || submitted) return;

//     if (!auto && answers.isEmpty) {
//       showToast('Answer at least one question');
//       return;
//     }

//     submitted = true;
//     if (mounted) {
//       setState(() {
//         submitting = true;
//       });
//     }

//     intervalTimer?.cancel();

//     try {
//       final res = await ApiClient.dio.post(
//         '/start-exam/${Uri.encodeComponent(subject.toString())}/$level/submit',
//         data: {
//           'answers': answers,
//           'question_ids': questionIds.isNotEmpty
//               ? questionIds
//               : normalizedQuestions.map((q) => q['normalizedId']).toList(),
//           'auto': auto,
//         },
//       );

//       final score = num.tryParse('${res.data?['score'] ?? 0}') ?? 0;
//       final totalMarks = num.tryParse('${res.data?['totalMarks'] ?? 0}') ?? 0;
//       final studentPercentage =
//           num.tryParse('${res.data?['studentPercentage'] ?? 0}') ?? 0;
//       final passingPercentage =
//           num.tryParse('${res.data?['passingPercentage'] ?? 0}') ?? 0;
//       final passStatus = '${res.data?['pass_status'] ?? ''}'.toLowerCase();

//       final passed = passStatus == 'pass';

//       if (passed) {
//         showToast(
//           'Congratulations! You passed with ${studentPercentage.toStringAsFixed(0)}%',
//         );
//         await Future.delayed(const Duration(milliseconds: 800));
//         goToSubjects();
//       } else {
//         final passingMarks = ((passingPercentage / 100) * totalMarks).ceil();
//         showToast(
//           'Exam Failed. Score ${score.toStringAsFixed(0)} / $passingMarks | ${studentPercentage.toStringAsFixed(0)}%',
//         );
//         await Future.delayed(const Duration(milliseconds: 800));
//         goToDashboard();
//       }
//     } catch (err) {
//       submitted = false;
//       if (mounted) {
//         setState(() {
//           submitting = false;
//         });
//       }

//       String msg = 'Submission failed. Please try again.';
//       if (err is DioException) {
//         msg = err.response?.data?['message']?.toString() ?? msg;
//       }
//       showToast(msg);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     final width = size.width;
//     final height = size.height;

//     final isVerySmall = width < 340 || height < 680;
//     final isSmall = width < 380 || height < 760;

//     final gap = isVerySmall ? 6.0 : (isSmall ? 8.0 : 10.0);
//     final pad = isVerySmall ? 12.0 : (isSmall ? 14.0 : 16.0);
//     final optionPadV = isVerySmall ? 10.0 : (isSmall ? 12.0 : 16.0);
//     final titleSize = isVerySmall ? 16.0 : (isSmall ? 17.0 : 18.0);
//     final subTitleSize = isVerySmall ? 12.0 : 14.0;
//     final questionSize = isVerySmall ? 15.0 : (isSmall ? 16.0 : 17.0);
//     final optionTextSize = isVerySmall ? 13.0 : (isSmall ? 14.0 : 15.0);
//     final btnHeight = isVerySmall ? 46.0 : (isSmall ? 52.0 : 56.0);

//     final maxInRow = normalizedQuestions.isEmpty
//         ? 1
//         : (normalizedQuestions.length > 8 ? 8 : normalizedQuestions.length);

//     final horizontalPadding = pad * 2;
//     final totalGap = (maxInRow - 1) * 8;
//     final availableWidth = width - horizontalPadding - totalGap;
//     final rawSize =
//         (availableWidth / (maxInRow == 0 ? 1 : maxInRow)).floorToDouble();
//     final minSize = isVerySmall ? 28.0 : 32.0;
//     final maxSize = isVerySmall ? 34.0 : 40.0;
//     final circleSize = rawSize.clamp(minSize, maxSize);

//     if (loading || timeLeft == null) {
//       return Scaffold(
//         backgroundColor: const Color(0xFF4338CA),
//         body: SafeArea(
//           child: Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: const [
//                 CircularProgressIndicator(color: Colors.white),
//                 SizedBox(height: 10),
//                 Text(
//                   'Loading exam...',
//                   style: TextStyle(
//                     color: Color(0xD9FFFFFF),
//                     fontSize: 14,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     final currentQuestion =
//         normalizedQuestions.isNotEmpty ? normalizedQuestions[currentIndex] : null;

//     if (currentQuestion == null) {
//       return const Scaffold(
//         backgroundColor: Color(0xFF4338CA),
//         body: SafeArea(
//           child: Center(
//             child: Text(
//               'No questions available',
//               style: TextStyle(
//                 color: Color(0xD9FFFFFF),
//                 fontSize: 14,
//               ),
//             ),
//           ),
//         ),
//       );
//     }

//     final progressPercent = normalizedQuestions.isEmpty
//         ? 0
//         : (((currentIndex + 1) / normalizedQuestions.length) * 100).round();

//     return Scaffold(
//       backgroundColor: const Color(0xFF4338CA),
//       body: SafeArea(
//         child: Padding(
//           padding: EdgeInsets.fromLTRB(pad, pad * 0.75, pad, pad),
//           child: Column(
//             children: [
//               Container(
//                 padding: EdgeInsets.all(isVerySmall ? 10 : 12),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.10),
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.14),
//                   ),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       '$subject — Level $level',
//                       textAlign: TextAlign.center,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w900,
//                         fontSize: titleSize,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Question ${currentIndex + 1} of ${normalizedQuestions.length}',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         color: const Color(0xD1FFFFFF),
//                         fontSize: subTitleSize,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Container(
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.20),
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: FractionallySizedBox(
//                         alignment: Alignment.centerLeft,
//                         widthFactor: progressPercent / 100,
//                         child: Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             borderRadius: BorderRadius.circular(999),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 6),
//                     Text(
//                       '$progressPercent% complete',
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Color(0xC7FFFFFF),
//                         fontSize: 12,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: isVerySmall ? 10 : 12,
//                         vertical: isVerySmall ? 6 : 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(999),
//                       ),
//                       child: Text(
//                         '⏱ ${formatTime(timeLeft!)}',
//                         style: TextStyle(
//                           color: const Color(0xFF3730A3),
//                           fontWeight: FontWeight.w900,
//                           fontSize: isVerySmall ? 14 : 16,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'App switch: $switchCount/3',
//                       style: TextStyle(
//                         color: const Color(0xC7FFFFFF),
//                         fontSize: isVerySmall ? 11 : 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                     SizedBox(height: gap),
//                     Wrap(
//                       alignment: WrapAlignment.center,
//                       spacing: 8,
//                       runSpacing: 8,
//                       children: normalizedQuestions.asMap().entries.map((entry) {
//                         final actualIndex = entry.key;
//                         final q = entry.value;
//                         final isActive = actualIndex == currentIndex;
//                         final isAnswered = answers[q['normalizedId']] != null;

//                         return GestureDetector(
//                           onTap: () {
//                             setState(() {
//                               currentIndex = actualIndex;
//                             });
//                           },
//                           child: AnimatedContainer(
//                             duration: const Duration(milliseconds: 180),
//                             width: circleSize,
//                             height: circleSize,
//                             decoration: BoxDecoration(
//                               shape: BoxShape.circle,
//                               color: isActive
//                                   ? Colors.white
//                                   : isAnswered
//                                       ? const Color(0xFF34D399)
//                                       : Colors.white.withOpacity(0.22),
//                             ),
//                             alignment: Alignment.center,
//                             child: Text(
//                               '${actualIndex + 1}',
//                               style: TextStyle(
//                                 color: isActive
//                                     ? const Color(0xFF3730A3)
//                                     : Colors.white,
//                                 fontWeight: FontWeight.w900,
//                                 fontSize: circleSize * 0.38,
//                               ),
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: gap),
//               Expanded(
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(pad),
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(22),
//                     color: Colors.white.withOpacity(0.14),
//                     border: Border.all(
//                       color: Colors.white.withOpacity(0.22),
//                     ),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${currentIndex + 1}. ${currentQuestion['normalizedText']}',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w900,
//                           fontSize: questionSize,
//                           height: 1.4,
//                         ),
//                       ),
//                       SizedBox(height: gap + 2),
//                       Expanded(
//                         child: SingleChildScrollView(
//                           child: Column(
//                             children: (currentQuestion['normalizedOptions']
//                                     as List)
//                                 .map<Widget>((opt) {
//                               final selected =
//                                   answers[currentQuestion['normalizedId']] ==
//                                       opt['normalizedId'];

//                               return GestureDetector(
//                                 onTap: submitting
//                                     ? null
//                                     : () => handleAnswerChange(
//                                           currentQuestion['normalizedId'],
//                                           opt['normalizedId'],
//                                         ),
//                                 child: Container(
//                                   width: double.infinity,
//                                   margin: EdgeInsets.only(bottom: gap),
//                                   padding: EdgeInsets.symmetric(
//                                     vertical: optionPadV,
//                                     horizontal: pad,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(16),
//                                     color: selected
//                                         ? Colors.white
//                                         : Colors.white.withOpacity(0.10),
//                                     border: Border.all(
//                                       color: Colors.white.withOpacity(0.16),
//                                     ),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       Expanded(
//                                         child: Text(
//                                           '${opt['normalizedText']}',
//                                           style: TextStyle(
//                                             color: selected
//                                                 ? const Color(0xFF3730A3)
//                                                 : Colors.white,
//                                             fontWeight: selected
//                                                 ? FontWeight.w900
//                                                 : FontWeight.w800,
//                                             fontSize: optionTextSize,
//                                           ),
//                                         ),
//                                       ),
//                                       if (selected)
//                                         Container(
//                                           width: isVerySmall ? 24 : 28,
//                                           height: isVerySmall ? 24 : 28,
//                                           decoration: BoxDecoration(
//                                             shape: BoxShape.circle,
//                                             color: const Color(0xFF4338CA)
//                                                 .withOpacity(0.12),
//                                           ),
//                                           child: Icon(
//                                             Icons.check,
//                                             size: isVerySmall ? 14 : 16,
//                                             color: const Color(0xFF3730A3),
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: gap + 2),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Answered: $answeredCount/${normalizedQuestions.length}',
//                     style: TextStyle(
//                       color: const Color(0xD1FFFFFF),
//                       fontSize: isVerySmall ? 11 : 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   Text(
//                     'Remaining: ${normalizedQuestions.length - answeredCount}',
//                     style: TextStyle(
//                       color: const Color(0xD1FFFFFF),
//                       fontSize: isVerySmall ? 11 : 12,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: gap),
//               Row(
//                 children: [
//                   Expanded(
//                     child: SizedBox(
//                       height: btnHeight,
//                       child: ElevatedButton(
//                         onPressed: (currentIndex == 0 || submitting)
//                             ? null
//                             : () {
//                                 setState(() {
//                                   currentIndex =
//                                       currentIndex > 0 ? currentIndex - 1 : 0;
//                                 });
//                               },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white.withOpacity(0.18),
//                           foregroundColor: const Color(0xFFE9E7FF),
//                           disabledBackgroundColor:
//                               Colors.white.withOpacity(0.18),
//                           disabledForegroundColor:
//                               const Color(0xFFE9E7FF).withOpacity(0.45),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                         ),
//                         child: Text(
//                           '‹ Previous',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: isVerySmall ? 13 : 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(width: gap),
//                   Expanded(
//                     child: SizedBox(
//                       height: btnHeight,
//                       child: ElevatedButton(
//                         onPressed: submitting
//                             ? null
//                             : () {
//                                 if (currentIndex ==
//                                     normalizedQuestions.length - 1) {
//                                   handleSubmit(false);
//                                 } else {
//                                   setState(() {
//                                     currentIndex = currentIndex + 1;
//                                   });
//                                 }
//                               },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.white,
//                           foregroundColor: const Color(0xFF3730A3),
//                           disabledBackgroundColor:
//                               Colors.white.withOpacity(0.45),
//                           disabledForegroundColor:
//                               const Color(0xFF3730A3).withOpacity(0.7),
//                           elevation: 0,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(18),
//                           ),
//                         ),
//                         child: Text(
//                           currentIndex == normalizedQuestions.length - 1
//                               ? (submitting ? 'Submitting...' : 'Submit Exam')
//                               : 'Next ›',
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             fontWeight: FontWeight.w900,
//                             fontSize: isVerySmall ? 13 : 15,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../../core/api/api_client.dart';
import '../../widgets/app_drawer.dart';
import 'subject_screen.dart';

class ExamAttemptScreen extends StatefulWidget {
  final String? subject;
  final dynamic level;
  final dynamic attemptKey;

  const ExamAttemptScreen({
    super.key,
    this.subject,
    this.level,
    this.attemptKey,
  });

  @override
  State<ExamAttemptScreen> createState() => _ExamAttemptScreenState();
}

class _ExamAttemptScreenState extends State<ExamAttemptScreen>
    with WidgetsBindingObserver {
  List<dynamic> questions = [];
  List<dynamic> questionIds = [];
  Map<String, dynamic> answers = {};

  int? timeLeft;
  bool loading = true;
  bool submitting = false;
  int currentIndex = 0;
  int switchCount = 0;

  bool submitted = false;
  Timer? intervalTimer;
  DateTime? endTime;

  String? subject;
  dynamic level;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    subject = widget.subject;
    level = widget.level;

    if (subject == null || level == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showToast('Missing subject or level');
        goToDashboard();
      });
      return;
    }

    fetchExam();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    intervalTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted || submitted) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      setState(() {
        switchCount += 1;
      });

      if (switchCount < 3) {
        showToast('App switching is not allowed ($switchCount/3 warning)');
      }

      if (switchCount >= 3) {
        showToast('Exam auto-submitted. App switched 3 times');
        handleSubmit(true);
      }
    }
  }

  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  String formatTime(int sec) {
    final safe = sec < 0 ? 0 : sec;
    final m = safe ~/ 60;
    final s = safe % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  dynamic getQuestionId(dynamic q, int fallbackIndex) {
    return q?['id'] ?? q?['question_id'] ?? q?['_id'] ?? 'q_$fallbackIndex';
  }

  String getQuestionText(dynamic q) {
    return q?['text']?.toString() ??
        q?['question']?.toString() ??
        q?['question_text']?.toString() ??
        'Question';
  }

  dynamic getOptionId(dynamic opt, int fallbackIndex) {
    return opt?['id'] ?? opt?['option_id'] ?? opt?['_id'] ?? 'o_$fallbackIndex';
  }

  String getOptionText(dynamic opt) {
    return opt?['text']?.toString() ??
        opt?['option']?.toString() ??
        opt?['option_text']?.toString() ??
        'Option';
  }

  List<Map<String, dynamic>> get normalizedQuestions {
    return questions.asMap().entries.map((entry) {
      final qIndex = entry.key;
      final q = entry.value;

      return {
        ...Map<String, dynamic>.from(q),
        'normalizedId': getQuestionId(q, qIndex).toString(),
        'normalizedText': getQuestionText(q),
        'normalizedOptions': (q?['options'] is List ? q['options'] as List : [])
            .asMap()
            .entries
            .map((optEntry) {
          final oIndex = optEntry.key;
          final opt = optEntry.value;
          return {
            ...Map<String, dynamic>.from(opt),
            'normalizedId': getOptionId(opt, oIndex).toString(),
            'normalizedText': getOptionText(opt),
          };
        }).toList(),
      };
    }).toList();
  }

  int get answeredCount => answers.keys.length;

  void goToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppDrawerScreen()),
      (route) => false,
    );
  }

  void goToSubjects() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SubjectScreen(initialSubject: subject),
      ),
      (route) => false,
    );
  }

  void resetExamState() {
    questions = [];
    questionIds = [];
    answers = {};
    timeLeft = null;
    loading = true;
    submitting = false;
    currentIndex = 0;
    switchCount = 0;
    submitted = false;
    endTime = null;
    intervalTimer?.cancel();
    intervalTimer = null;
  }

  Future<void> fetchExam() async {
    resetExamState();
    if (mounted) setState(() {});

    try {
      final res = await ApiClient.dio.get(
        '/start-exam/${Uri.encodeComponent(subject.toString())}/$level',
      );

      final apiQuestions =
          res.data?['questions'] is List ? List.from(res.data['questions']) : [];
      final apiQuestionIds = res.data?['question_ids'] is List
          ? List.from(res.data['question_ids'])
          : [];

      if (apiQuestions.isEmpty) {
        showToast('No questions available for this exam');
        goToDashboard();
        return;
      }

      final normalizedIds = apiQuestionIds.isNotEmpty
          ? apiQuestionIds
          : apiQuestions
              .asMap()
              .entries
              .map((e) => getQuestionId(e.value, e.key))
              .toList();

      final durationMin = num.tryParse('${res.data?['duration'] ?? 0}') ?? 0;
      final durationSec = durationMin > 0 ? durationMin.toInt() * 60 : 0;

      if (durationSec <= 0) {
        showToast('Invalid exam duration');
        goToDashboard();
        return;
      }

      questions = apiQuestions;
      questionIds = normalizedIds;
      timeLeft = durationSec;
      endTime = DateTime.now().add(Duration(seconds: durationSec));
      startCountdown();
    } catch (err) {
      String msg = 'Exam access denied. Please check your exam schedule.';
      if (err is DioException) {
        msg = err.response?.data?['message']?.toString() ?? msg;
      }
      showToast(msg);
      goToDashboard();
      return;
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void startCountdown() {
    intervalTimer?.cancel();

    intervalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || endTime == null || submitted) return;

      final remaining = endTime!.difference(DateTime.now()).inSeconds;
      final safeRemaining = remaining < 0 ? 0 : remaining;

      setState(() {
        timeLeft = safeRemaining;
      });

      if (safeRemaining <= 0) {
        intervalTimer?.cancel();
        if (!submitted) {
          handleSubmit(true);
        }
      }
    });
  }

  void handleAnswerChange(String qid, String oid) {
    if (submitted || submitting) return;

    setState(() {
      answers[qid] = oid;
    });
  }

  Future<void> handleSubmit(bool auto) async {
    if (submitting || submitted) return;

    if (!auto && answers.isEmpty) {
      showToast('Answer at least one question');
      return;
    }

    submitted = true;
    if (mounted) {
      setState(() {
        submitting = true;
      });
    }

    intervalTimer?.cancel();

    try {
      final res = await ApiClient.dio.post(
        '/start-exam/${Uri.encodeComponent(subject.toString())}/$level/submit',
        data: {
          'answers': answers,
          'question_ids': questionIds.isNotEmpty
              ? questionIds
              : normalizedQuestions.map((q) => q['normalizedId']).toList(),
          'auto': auto,
        },
      );

      final score = num.tryParse('${res.data?['score'] ?? 0}') ?? 0;
      final totalMarks = num.tryParse('${res.data?['totalMarks'] ?? 0}') ?? 0;
      final studentPercentage =
          num.tryParse('${res.data?['studentPercentage'] ?? 0}') ?? 0;
      final passingPercentage =
          num.tryParse('${res.data?['passingPercentage'] ?? 0}') ?? 0;
      final passStatus = '${res.data?['pass_status'] ?? ''}'.toLowerCase();

      final passed = passStatus == 'pass';

      if (passed) {
        showToast(
          'Congratulations! You passed with ${studentPercentage.toStringAsFixed(0)}%',
        );
        await Future.delayed(const Duration(milliseconds: 800));
        goToSubjects();
      } else {
        final passingMarks = ((passingPercentage / 100) * totalMarks).ceil();
        showToast(
          'Exam Failed. Score ${score.toStringAsFixed(0)} / $passingMarks | ${studentPercentage.toStringAsFixed(0)}%',
        );
        await Future.delayed(const Duration(milliseconds: 800));
        goToDashboard();
      }
    } catch (err) {
      submitted = false;
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }

      String msg = 'Submission failed. Please try again.';
      if (err is DioException) {
        msg = err.response?.data?['message']?.toString() ?? msg;
      }
      showToast(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isVerySmall = width < 340 || height < 680;
    final isSmall = width < 380 || height < 760;

    final gap = isVerySmall ? 6.0 : (isSmall ? 8.0 : 10.0);
    final pad = isVerySmall ? 12.0 : (isSmall ? 14.0 : 16.0);
    final optionPadV = isVerySmall ? 10.0 : (isSmall ? 12.0 : 16.0);
    final titleSize = isVerySmall ? 16.0 : (isSmall ? 17.0 : 18.0);
    final subTitleSize = isVerySmall ? 12.0 : 14.0;
    final questionSize = isVerySmall ? 15.0 : (isSmall ? 16.0 : 17.0);
    final optionTextSize = isVerySmall ? 13.0 : (isSmall ? 14.0 : 15.0);
    final btnHeight = isVerySmall ? 46.0 : (isSmall ? 52.0 : 56.0);

    final maxInRow = normalizedQuestions.isEmpty
        ? 1
        : (normalizedQuestions.length > 8 ? 8 : normalizedQuestions.length);

    final horizontalPadding = pad * 2;
    final totalGap = (maxInRow - 1) * 8;
    final availableWidth = width - horizontalPadding - totalGap;
    final rawSize =
        (availableWidth / (maxInRow == 0 ? 1 : maxInRow)).floorToDouble();
    final minSize = isVerySmall ? 28.0 : 32.0;
    final maxSize = isVerySmall ? 34.0 : 40.0;
    final circleSize = rawSize.clamp(minSize, maxSize);

    if (loading || timeLeft == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF4338CA),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Loading exam...',
                  style: TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQuestion =
        normalizedQuestions.isNotEmpty ? normalizedQuestions[currentIndex] : null;

    if (currentQuestion == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF4338CA),
        body: SafeArea(
          child: Center(
            child: Text(
              'No questions available',
              style: TextStyle(
                color: Color(0xD9FFFFFF),
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    final progressPercent = normalizedQuestions.isEmpty
        ? 0
        : (((currentIndex + 1) / normalizedQuestions.length) * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFF4338CA),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, pad * 0.75, pad, pad),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(isVerySmall ? 10 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.14),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$subject — Level $level',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: titleSize,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Question ${currentIndex + 1} of ${normalizedQuestions.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xD1FFFFFF),
                        fontSize: subTitleSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: gap),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progressPercent / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$progressPercent% complete',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xC7FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: gap),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isVerySmall ? 10 : 12,
                        vertical: isVerySmall ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '⏱ ${formatTime(timeLeft!)}',
                        style: TextStyle(
                          color: const Color(0xFF3730A3),
                          fontWeight: FontWeight.w900,
                          fontSize: isVerySmall ? 14 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'App switch: $switchCount/3',
                      style: TextStyle(
                        color: const Color(0xC7FFFFFF),
                        fontSize: isVerySmall ? 11 : 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: gap),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: normalizedQuestions.asMap().entries.map((entry) {
                        final actualIndex = entry.key;
                        final q = entry.value;
                        final isActive = actualIndex == currentIndex;
                        final isAnswered = answers[q['normalizedId']] != null;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              currentIndex = actualIndex;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: circleSize,
                            height: circleSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive
                                  ? Colors.white
                                  : isAnswered
                                      ? const Color(0xFF34D399)
                                      : Colors.white.withOpacity(0.22),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${actualIndex + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? const Color(0xFF3730A3)
                                    : Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: circleSize * 0.38,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gap),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(pad),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white.withOpacity(0.14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.22),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${currentIndex + 1}. ${currentQuestion['normalizedText']}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: questionSize,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: gap + 2),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: (currentQuestion['normalizedOptions']
                                    as List)
                                .map<Widget>((opt) {
                              final selected =
                                  answers[currentQuestion['normalizedId']] ==
                                      opt['normalizedId'];

                              return GestureDetector(
                                onTap: submitting
                                    ? null
                                    : () => handleAnswerChange(
                                          currentQuestion['normalizedId'],
                                          opt['normalizedId'],
                                        ),
                                child: Container(
                                  width: double.infinity,
                                  margin: EdgeInsets.only(bottom: gap),
                                  padding: EdgeInsets.symmetric(
                                    vertical: optionPadV,
                                    horizontal: pad,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: selected
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.16),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${opt['normalizedText']}',
                                          style: TextStyle(
                                            color: selected
                                                ? const Color(0xFF3730A3)
                                                : Colors.white,
                                            fontWeight: selected
                                                ? FontWeight.w900
                                                : FontWeight.w800,
                                            fontSize: optionTextSize,
                                          ),
                                        ),
                                      ),
                                      if (selected)
                                        Container(
                                          width: isVerySmall ? 24 : 28,
                                          height: isVerySmall ? 24 : 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF4338CA)
                                                .withOpacity(0.12),
                                          ),
                                          child: Icon(
                                            Icons.check,
                                            size: isVerySmall ? 14 : 16,
                                            color: const Color(0xFF3730A3),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: gap + 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Answered: $answeredCount/${normalizedQuestions.length}',
                    style: TextStyle(
                      color: const Color(0xD1FFFFFF),
                      fontSize: isVerySmall ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Remaining: ${normalizedQuestions.length - answeredCount}',
                    style: TextStyle(
                      color: const Color(0xD1FFFFFF),
                      fontSize: isVerySmall ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: btnHeight,
                      child: ElevatedButton(
                        onPressed: (currentIndex == 0 || submitting)
                            ? null
                            : () {
                                setState(() {
                                  currentIndex =
                                      currentIndex > 0 ? currentIndex - 1 : 0;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.18),
                          foregroundColor: const Color(0xFFE9E7FF),
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.18),
                          disabledForegroundColor:
                              const Color(0xFFE9E7FF).withOpacity(0.45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          '‹ Previous',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isVerySmall ? 13 : 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: SizedBox(
                      height: btnHeight,
                      child: ElevatedButton(
                        onPressed: submitting
                            ? null
                            : () {
                                if (currentIndex ==
                                    normalizedQuestions.length - 1) {
                                  handleSubmit(false);
                                } else {
                                  setState(() {
                                    currentIndex = currentIndex + 1;
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3730A3),
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.45),
                          disabledForegroundColor:
                              const Color(0xFF3730A3).withOpacity(0.7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: Text(
                          currentIndex == normalizedQuestions.length - 1
                              ? (submitting ? 'Submitting...' : 'Submit Exam')
                              : 'Next ›',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: isVerySmall ? 13 : 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}