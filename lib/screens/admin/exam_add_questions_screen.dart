import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExamAddQuestionsScreen extends StatefulWidget {
  const ExamAddQuestionsScreen({super.key});

  @override
  State<ExamAddQuestionsScreen> createState() => _ExamAddQuestionsScreenState();
}

class _ExamAddQuestionsScreenState extends State<ExamAddQuestionsScreen> {
  final String baseUrl = "http://192.168.29.79:5000/api";

  String name = "";
  String subject = "";
  int level = 1;
  int totalQuestions = 0;
  int totalMarks = 0;
  int passingMarks = 0;
  int duration = 20;
  String startDateTime = "";
  String endDateTime = "";

  String mode = "";
  List<dynamic> questions = [];
  List<dynamic> filteredQuestions = [];
  String selectedLevel = "";
  List<dynamic> selected = [];
  bool loading = false;

  Map<int, String> levelPick = {
    1: "0",
    2: "0",
    3: "0",
    4: "0",
    5: "0",
  };

  Map<int, int> autoLevelCount = {};

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    name = args?["name"]?.toString() ?? "";
    subject = args?["subject"]?.toString() ?? "";
    level = _toInt(args?["level"], 1);
    totalQuestions = _toInt(args?["totalQuestions"], 0);
    totalMarks = _toInt(args?["totalMarks"], 0);
    passingMarks = _toInt(args?["passingMarks"], 0);
    duration = _toInt(args?["duration"], 20);
    startDateTime = args?["startDateTime"]?.toString() ?? "";
    endDateTime = args?["endDateTime"]?.toString() ?? "";

    if (subject.isNotEmpty) {
      fetchQuestions();
    }
  }

  int _toInt(dynamic value, int fallback) {
    return int.tryParse(value?.toString() ?? "") ?? fallback;
  }

  Future<void> fetchQuestions() async {
    try {
      setState(() {
        loading = true;
      });

      final response = await http.get(
        Uri.parse("$baseUrl/admin/questions"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer your_token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final allQuestions = data["questions"] ?? [];
        final filtered = List<dynamic>.from(
          allQuestions.where((q) => q["subject"] == subject),
        );

        setState(() {
          questions = filtered;
          filteredQuestions = filtered;
        });
      } else {
        showMessage("Error", "Failed to load questions");
      }
    } catch (e) {
      debugPrint(e.toString());
      showMessage("Error", "Failed to load questions");
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Map<int, int> get availableByLevel {
    final map = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final q in questions) {
      final lvl = _toInt(q["level_number"], 0);
      if (map.containsKey(lvl)) {
        map[lvl] = map[lvl]! + 1;
      }
    }

    return map;
  }

  void toggleSelect(dynamic id) {
    if (!selected.contains(id) && selected.length >= totalQuestions) {
      showMessage(
        "Limit Reached",
        "You can select only $totalQuestions questions.",
      );
      return;
    }

    setState(() {
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
    });
  }

  void applyLevelFilter(String lvl) {
    setState(() {
      selectedLevel = lvl;

      if (lvl.isEmpty) {
        filteredQuestions = questions;
      } else {
        filteredQuestions = questions.where((q) {
          return _toInt(q["level_number"], 0) == _toInt(lvl, 0);
        }).toList();
      }
    });
  }

  void pickAutoQuestions() {
    final sumPick = levelPick.values.fold<int>(
      0,
      (sum, value) => sum + (int.tryParse(value) ?? 0),
    );

    if (sumPick > totalQuestions) {
      showMessage(
        "Too Many",
        "You can pick maximum $totalQuestions questions.",
      );
      return;
    }

    final List<dynamic> selectedIds = [];
    final Map<int, int> countByLevel = {};

    for (int lvl = 1; lvl <= 5; lvl++) {
      final numPick = int.tryParse(levelPick[lvl] ?? "0") ?? 0;
      if (numPick <= 0) continue;

      final lvlQuestions = questions.where((q) {
        return _toInt(q["level_number"], 0) == lvl;
      }).toList();

      if (lvlQuestions.isEmpty) continue;

      lvlQuestions.shuffle(Random());

      final picked = lvlQuestions.take(numPick).toList();

      for (final q in picked) {
        selectedIds.add(q["id"]);
      }

      countByLevel[lvl] = picked.length;
    }

    setState(() {
      selected = selectedIds;
      autoLevelCount = countByLevel;
    });
  }

  Future<void> handleCreateExam() async {
    if (mode.isEmpty) {
      showMessage("Validation", "Select manual or automatic mode.");
      return;
    }

    if (selected.isEmpty) {
      showMessage("Validation", "No questions selected.");
      return;
    }

    try {
      setState(() {
        loading = true;
      });

      final payload = {
        "name": name,
        "subject": subject,
        "level": level,
        "totalQuestions": selected.length,
        "totalMarks": totalMarks,
        "passingMarks": passingMarks,
        "duration": duration,
        "mode": mode,
        "selectedQuestions": selected,
        "startDateTime": startDateTime,
        "endDateTime": endDateTime,
      };

      final response = await http.post(
        Uri.parse("$baseUrl/admin/exams/create"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer your_token",
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMessage("Success", "Exam created successfully", onOk: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/exam",
            (route) => false,
          );
        });
      } else {
        showMessage("Error", "Failed to create exam");
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      showMessage("Error", "Failed to create exam");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void showMessage(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onOk != null) onOk();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xff374151),
          ),
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xff111827),
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget renderQuestionCard(Map<String, dynamic> q) {
    final isSelected = selected.contains(q["id"]);

    return GestureDetector(
      onTap: () => toggleSelect(q["id"]),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffe0e7ff) : const Color(0xfff9fafb),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xff22c55e) : const Color(0xffd1d5db),
          ),
        ),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xff111827),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: "${q["text"] ?? ""} "),
              TextSpan(
                text: "(Level ${q["level_number"] ?? "-"})",
                style: const TextStyle(
                  color: Color(0xff4b5563),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildModeButton(String value, String text) {
    final active = mode == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            mode = value;
            selected = [];
            autoLevelCount = {};
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xff4f46e5) : const Color(0xffe5e7eb),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xff374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLevelChip(String value, String text) {
    final active = selectedLevel == value;

    return GestureDetector(
      onTap: () => applyLevelFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xff4f46e5) : const Color(0xffe5e7eb),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xff374151),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget buildAutoRow(int lvl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              "Level $lvl",
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xff111827),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: TextField(
              controller: TextEditingController(text: levelPick[lvl] ?? "0")
                ..selection = TextSelection.fromPosition(
                  TextPosition(offset: (levelPick[lvl] ?? "0").length),
                ),
              keyboardType: TextInputType.number,
              onChanged: (text) {
                final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
                setState(() {
                  levelPick[lvl] = cleaned;
                });
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xfff9fafb),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xffc7d2fe)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xff4f46e5)),
                ),
              ),
              style: const TextStyle(color: Color(0xff111827)),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "/ ${availableByLevel[lvl] ?? 0} available",
            style: const TextStyle(
              color: Color(0xff6b7280),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeef2ff),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                "Select Questions",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff1f2937),
                ),
              ),
              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildInfoText("Exam Name:", name),
                    buildInfoText("Subject:", subject),
                    buildInfoText("Level:", level.toString()),
                    buildInfoText("Total Marks:", totalMarks.toString()),
                    buildInfoText("Passing Marks:", passingMarks.toString()),
                    buildInfoText("Duration:", "$duration min"),
                    buildInfoText(
                      "Total Questions Allowed:",
                      totalQuestions.toString(),
                    ),
                    buildInfoText(
                      "Start:",
                      startDateTime.isEmpty ? "-" : startDateTime,
                    ),
                    buildInfoText(
                      "End:",
                      endDateTime.isEmpty ? "-" : endDateTime,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  buildModeButton("manual", "Add Manually"),
                  const SizedBox(width: 10),
                  buildModeButton("auto", "Add Automatically"),
                ],
              ),

              if (loading) ...[
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xff4f46e5)),
                      SizedBox(height: 8),
                      Text(
                        "Loading questions...",
                        style: TextStyle(color: Color(0xff6b7280)),
                      ),
                    ],
                  ),
                ),
              ],

              if (mode == "manual" && !loading) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Filter by Level",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff374151),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          buildLevelChip("", "All"),
                          for (int lvl = 1; lvl <= 5; lvl++)
                            buildLevelChip("$lvl", "Level $lvl"),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "Selected Questions: ${selected.length} / $totalQuestions",
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (filteredQuestions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              "No questions found",
                              style: TextStyle(color: Color(0xff6b7280)),
                            ),
                          ),
                        )
                      else
                        ...filteredQuestions.map(
                          (q) => renderQuestionCard(
                            Map<String, dynamic>.from(q),
                          ),
                        ),
                    ],
                  ),
                ),
              ],

              if (mode == "auto" && !loading) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.08),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pick questions per level",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff111827),
                        ),
                      ),
                      const SizedBox(height: 12),

                      for (int lvl = 1; lvl <= 5; lvl++) buildAutoRow(lvl),

                      const SizedBox(height: 6),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: pickAutoQuestions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff16a34a),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Pick Questions",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),

                      if (selected.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffeef2ff),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Total Selected: ${selected.length} / $totalQuestions",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff111827),
                                ),
                              ),
                              const SizedBox(height: 8),

                              ...autoLevelCount.entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    "Level ${entry.key}: ${entry.value} question${entry.value > 1 ? "s" : ""}",
                                    style: const TextStyle(
                                      color: Color(0xff374151),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              ...selected.map((id) {
                                final q = questions.cast<dynamic>().firstWhere(
                                  (item) => item["id"] == id,
                                  orElse: () => null,
                                );

                                if (q == null) return const SizedBox.shrink();

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    "${q["text"] ?? ""} (Level ${q["level_number"] ?? "-"})",
                                    style: const TextStyle(
                                      color: Color(0xff111827),
                                      fontSize: 14,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : handleCreateExam,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff4f46e5),
                    disabledBackgroundColor:
                        const Color(0xff4f46e5).withOpacity(0.7),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    loading ? "Saving..." : "Create Exam",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}