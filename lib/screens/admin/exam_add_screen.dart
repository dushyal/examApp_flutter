import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExamAddScreen extends StatefulWidget {
  const ExamAddScreen({super.key});

  @override
  State<ExamAddScreen> createState() => _ExamAddScreenState();
}

class _ExamAddScreenState extends State<ExamAddScreen> {
  final String baseUrl = "http://192.168.29.79:5000/api";

  final TextEditingController nameController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController levelController = TextEditingController();
  final TextEditingController totalQuestionsController =
      TextEditingController();
  final TextEditingController totalMarksController = TextEditingController();
  final TextEditingController passingMarksController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController startDateTimeController =
      TextEditingController();
  final TextEditingController endDateTimeController = TextEditingController();

  List<String> subjects = [];

  @override
  void initState() {
    super.initState();
    fetchSubjects();
  }

  @override
  void dispose() {
    nameController.dispose();
    subjectController.dispose();
    levelController.dispose();
    totalQuestionsController.dispose();
    totalMarksController.dispose();
    passingMarksController.dispose();
    durationController.dispose();
    startDateTimeController.dispose();
    endDateTimeController.dispose();
    super.dispose();
  }

  Future<void> fetchSubjects() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/questions"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer your_token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final questions = data["questions"] ?? [];

        final uniqueSubjects = questions
            .map((q) => q["subject"])
            .where((s) => s != null && s.toString().trim().isNotEmpty)
            .map((s) => s.toString())
            .toSet()
            .toList();

        setState(() {
          subjects = uniqueSubjects;
        });
      }
    } catch (error) {
      debugPrint("Error fetching questions: $error");
    }
  }

  void handleNext() {
    final name = nameController.text.trim();
    final subject = subjectController.text.trim();
    final level = levelController.text.trim();
    final totalQuestions = totalQuestionsController.text.trim();
    final totalMarks = totalMarksController.text.trim();
    final passingMarks = passingMarksController.text.trim();
    final duration = durationController.text.trim();
    final startDateTime = startDateTimeController.text.trim();
    final endDateTime = endDateTimeController.text.trim();

    if (name.isEmpty ||
        subject.isEmpty ||
        level.isEmpty ||
        totalQuestions.isEmpty ||
        totalMarks.isEmpty ||
        passingMarks.isEmpty ||
        duration.isEmpty ||
        startDateTime.isEmpty ||
        endDateTime.isEmpty) {
      showMessage("Validation", "Please fill all fields");
      return;
    }

    final payload = {
      "name": name,
      "subject": subject,
      "level": int.tryParse(level) ?? 0,
      "totalQuestions": int.tryParse(totalQuestions) ?? 0,
      "totalMarks": int.tryParse(totalMarks) ?? 0,
      "passingMarks": int.tryParse(passingMarks) ?? 0,
      "duration": int.tryParse(duration) ?? 0,
      "startDateTime": startDateTime,
      "endDateTime": endDateTime,
    };

    Navigator.pushNamed(
      context,
      "/exam-add-questions",
      arguments: payload,
    );
  }

  void showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xff374151),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xff111827),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xff9ca3af)),
              filled: true,
              fillColor: const Color(0xfff9fafb),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffc7d2fe)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xff4f46e5)),
              ),
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
                "Create New Exam",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff1e1b4b),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.08),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    buildField(
                      label: "Exam Name",
                      controller: nameController,
                      hint: "Enter exam name",
                    ),

                    buildField(
                      label: "Subject",
                      controller: subjectController,
                      hint: "Enter subject",
                    ),

                    if (subjects.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xffeef2ff),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Available Subjects:",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xff4338ca),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subjects.join(", "),
                              style: const TextStyle(
                                color: Color(0xff4b5563),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                    buildField(
                      label: "Level",
                      controller: levelController,
                      hint: "Enter level (1-5)",
                      keyboardType: TextInputType.number,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            label: "Total Questions",
                            controller: totalQuestionsController,
                            hint: "0",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildField(
                            label: "Total Marks",
                            controller: totalMarksController,
                            hint: "0",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: buildField(
                            label: "Passing Marks",
                            controller: passingMarksController,
                            hint: "0",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: buildField(
                            label: "Duration (minutes)",
                            controller: durationController,
                            hint: "0",
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),

                    buildField(
                      label: "Exam Start",
                      controller: startDateTimeController,
                      hint: "YYYY-MM-DD HH:mm",
                    ),

                    buildField(
                      label: "Exam End",
                      controller: endDateTimeController,
                      hint: "YYYY-MM-DD HH:mm",
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: handleNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff4f46e5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Next → Select Questions",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}