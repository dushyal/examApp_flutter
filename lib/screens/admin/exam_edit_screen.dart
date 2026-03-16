import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExamEditScreen extends StatefulWidget {
  const ExamEditScreen({super.key});

  @override
  State<ExamEditScreen> createState() => _ExamEditScreenState();
}

class _ExamEditScreenState extends State<ExamEditScreen> {
  final String baseUrl = "http://192.168.29.79:5000/api";

  bool loading = true;
  Map<String, dynamic>? exam;
  dynamic examId;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController levelController = TextEditingController();
  final TextEditingController totalMarksController = TextEditingController();
  final TextEditingController passingMarksController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController endTimeController = TextEditingController();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    examId = args?["id"];

    if (examId != null) {
      fetchExam();
    } else {
      setState(() {
        loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showMessage("Error", "Exam ID not found");
      });
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    subjectController.dispose();
    levelController.dispose();
    totalMarksController.dispose();
    passingMarksController.dispose();
    durationController.dispose();
    startTimeController.dispose();
    endTimeController.dispose();
    super.dispose();
  }

  Future<void> fetchExam() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/exams/$examId"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer your_token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["exam"] != null) {
        final e = Map<String, dynamic>.from(data["exam"]);

        final mappedExam = {
          ...e,
          "start_time": e["start_time"] != null
              ? formatDateTimeForInput(e["start_time"])
              : "",
          "end_time":
              e["end_time"] != null ? formatDateTimeForInput(e["end_time"]) : "",
        };

        setState(() {
          exam = mappedExam;
        });

        titleController.text = (mappedExam["title"] ?? "").toString();
        subjectController.text = (mappedExam["subject"] ?? "").toString();
        levelController.text = (mappedExam["level_number"] ?? "").toString();
        totalMarksController.text = (mappedExam["total_marks"] ?? "").toString();
        passingMarksController.text =
            (mappedExam["passing_marks"] ?? "").toString();
        durationController.text =
            (mappedExam["duration_minutes"] ?? "").toString();
        startTimeController.text = (mappedExam["start_time"] ?? "").toString();
        endTimeController.text = (mappedExam["end_time"] ?? "").toString();
      } else {
        if (!mounted) return;
        showMessage("Error", "Failed to load exam");
      }
    } catch (e) {
      debugPrint("Failed to load exam: $e");
      if (!mounted) return;
      showMessage("Error", "Failed to load exam");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  String formatDateTimeForInput(dynamic dateValue) {
    try {
      final date = DateTime.parse(dateValue.toString()).toLocal();

      final yyyy = date.year.toString().padLeft(4, '0');
      final mm = date.month.toString().padLeft(2, '0');
      final dd = date.day.toString().padLeft(2, '0');
      final hh = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');

      return "$yyyy-$mm-$dd $hh:$min";
    } catch (e) {
      return "";
    }
  }

  String? parseInputToISO(String value) {
    try {
      final normalized = value.trim().replaceFirst(" ", "T");
      final parsed = DateTime.parse(normalized);
      return parsed.toUtc().toIso8601String();
    } catch (e) {
      return null;
    }
  }

  Future<void> handleUpdate() async {
    if (exam == null) return;

    setState(() {
      loading = true;
    });

    try {
      final startISO = parseInputToISO(startTimeController.text);
      final endISO = parseInputToISO(endTimeController.text);

      if (startISO == null || endISO == null) {
        showMessage("Validation", "Start or End time is invalid");
        setState(() {
          loading = false;
        });
        return;
      }

      if (DateTime.parse(endISO).isBefore(DateTime.parse(startISO))) {
        showMessage("Validation", "End time cannot be before Start time");
        setState(() {
          loading = false;
        });
        return;
      }

      final payload = {
        "title": titleController.text.trim(),
        "level_number": int.tryParse(levelController.text.trim()) ?? 0,
        "total_marks": int.tryParse(totalMarksController.text.trim()) ?? 0,
        "passing_marks": int.tryParse(passingMarksController.text.trim()) ?? 0,
        "duration_minutes": int.tryParse(durationController.text.trim()) ?? 0,
        "start_time": startISO,
        "end_time": endISO,
      };

      final response = await http.put(
        Uri.parse("$baseUrl/admin/exams/$examId"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer your_token",
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showMessage("Success", "Exam updated successfully", onOk: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/exam",
            (route) => false,
          );
        });
      } else {
        showMessage("Error", "Failed to update exam");
      }
    } catch (e) {
      debugPrint("Failed to update exam: $e");
      if (!mounted) return;
      showMessage("Error", "Failed to update exam");
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

  Widget buildField({
    required String label,
    required TextEditingController controller,
    String hint = "",
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
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
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 15,
              color: enabled ? const Color(0xff111827) : const Color(0xff6b7280),
            ),
            decoration: InputDecoration(
              hintText: hint.isEmpty ? null : hint,
              hintStyle: const TextStyle(color: Color(0xff9ca3af)),
              filled: true,
              fillColor:
                  enabled ? const Color(0xfff9fafb) : const Color(0xffe5e7eb),
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xffc7d2fe)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading && exam == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xff4f46e5)),
                SizedBox(height: 10),
                Text(
                  "Loading...",
                  style: TextStyle(
                    color: Color(0xff6b7280),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (exam == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const SafeArea(
          child: Center(
            child: Text(
              "Exam not found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xffdc2626),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xffeef2ff),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Exam: ${titleController.text}",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff1f2937),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                  children: [
                    buildField(
                      label: "Exam Name",
                      controller: titleController,
                    ),
                    buildField(
                      label: "Subject",
                      controller: subjectController,
                      enabled: false,
                    ),
                    buildField(
                      label: "Level",
                      controller: levelController,
                      keyboardType: TextInputType.number,
                      hint: "1 to 5",
                    ),
                    buildField(
                      label: "Total Marks",
                      controller: totalMarksController,
                      keyboardType: TextInputType.number,
                    ),
                    buildField(
                      label: "Passing Marks",
                      controller: passingMarksController,
                      keyboardType: TextInputType.number,
                    ),
                    buildField(
                      label: "Duration (minutes)",
                      controller: durationController,
                      keyboardType: TextInputType.number,
                    ),
                    buildField(
                      label: "Start Time",
                      controller: startTimeController,
                      hint: "YYYY-MM-DD HH:mm",
                    ),
                    buildField(
                      label: "End Time",
                      controller: endTimeController,
                      hint: "YYYY-MM-DD HH:mm",
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : handleUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff16a34a),
                          disabledBackgroundColor:
                              const Color(0xff16a34a).withOpacity(0.7),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          loading ? "Saving..." : "Update Exam",
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
            ],
          ),
        ),
      ),
    );
  }
}