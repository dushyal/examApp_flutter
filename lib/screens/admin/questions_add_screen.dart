import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final String baseUrl = "http://192.168.29.79:5000/api";

  List<String> subjects = [];
  final List<int> levels = [1, 2, 3, 4, 5];
  List<dynamic> exams = [];

  bool loading = true;
  bool saving = false;

  Map<String, dynamic> form = {
    "subject": "",
    "level_number": "",
    "question": "",
    "optionA": "",
    "optionB": "",
    "optionC": "",
    "optionD": "",
    "correctAnswer": "",
    "explanation": "",
  };

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();
  final TextEditingController explanationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  @override
  void dispose() {
    subjectController.dispose();
    questionController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    explanationController.dispose();
    super.dispose();
  }

  Future<void> fetchInitialData() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/students"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);
      final students = data["students"] ?? [];

      final subjectsFromApi = students
          .where((u) => u["subject"] != null)
          .map((u) => u["subject"].toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final uniqueSubjects = subjectsFromApi.toSet().toList();

      setState(() {
        subjects = uniqueSubjects;
      });

      if (uniqueSubjects.length == 1) {
        setState(() {
          form["subject"] = uniqueSubjects[0];
          subjectController.text = uniqueSubjects[0];
        });
      }
    } catch (err) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedUser = prefs.getString("authUser");
        final user = savedUser != null ? jsonDecode(savedUser) : null;

        if (user != null && user["subject"] != null) {
          setState(() {
            subjects = [user["subject"].toString()];
            form["subject"] = user["subject"].toString();
            subjectController.text = user["subject"].toString();
          });
        }
      } catch (_) {}
    }

    try {
      final res = await http.get(
        Uri.parse("$baseUrl/admin/exams"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(res.body);

      setState(() {
        exams = data["exams"] ?? [];
      });
    } catch (_) {}

    setState(() {
      loading = false;
    });
  }

  void handleChange(String name, dynamic value) {
    setState(() {
      form[name] = value;
    });
  }

  Future<void> handleSubmit() async {
    for (final key in form.keys) {
      if (key != "explanation" &&
          form[key].toString().trim().isEmpty) {
        showMessage("Error", "All required fields are required!");
        return;
      }
    }

    try {
      setState(() {
        saving = true;
      });

      final payload = {
        "subject": form["subject"],
        "level_number": form["level_number"],
        "question": form["question"],
        "optionA": form["optionA"],
        "optionB": form["optionB"],
        "optionC": form["optionC"],
        "optionD": form["optionD"],
        "correctAnswer": form["correctAnswer"],
        "explanation": form["explanation"],
      };

      final response = await http.post(
        Uri.parse("$baseUrl/admin/questions/add"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        showMessage("Success", "Question added successfully!");

        setState(() {
          form = {
            "subject": subjects.length == 1 ? subjects[0] : "",
            "level_number": "",
            "question": "",
            "optionA": "",
            "optionB": "",
            "optionC": "",
            "optionD": "",
            "correctAnswer": "",
            "explanation": "",
          };

          subjectController.text = subjects.length == 1 ? subjects[0] : "";
          questionController.clear();
          optionAController.clear();
          optionBController.clear();
          optionCController.clear();
          optionDController.clear();
          explanationController.clear();
        });
      } else {
        String message = "Error saving question";
        try {
          final errorData = jsonDecode(response.body);
          message = errorData["message"]?.toString() ?? message;
        } catch (_) {}
        showMessage("Error", message);
      }
    } catch (err) {
      showMessage("Error", "Error saving question");
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget buildInput({
    required TextEditingController controller,
    required String hint,
    required String fieldName,
    bool enabled = true,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      onChanged: (text) => handleChange(fieldName, text),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.25),
          ),
        ),
      ),
    );
  }

  Widget buildAnswerButton(String opt) {
    final selected = form["correctAnswer"] == opt;

    return Expanded(
      child: GestureDetector(
        onTap: () => handleChange("correctAnswer", opt),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xff7c3aed)
                : Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xffa78bfa)
                  : Colors.white.withOpacity(0.20),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            opt,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: const Color(0xff0f172a),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 10),
              Text(
                "Loading...",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add New Question",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                if (subjects.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: form["subject"].toString().isEmpty
                            ? null
                            : form["subject"].toString(),
                        dropdownColor: const Color(0xff1e293b),
                        isExpanded: true,
                        hint: Text(
                          "Select Subject",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        iconEnabledColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        items: subjects.map((sub) {
                          return DropdownMenuItem<String>(
                            value: sub,
                            child: Text(
                              sub,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          handleChange("subject", value ?? "");
                        },
                      ),
                    ),
                  )
                else
                  Opacity(
                    opacity: 0.7,
                    child: buildInput(
                      controller: subjectController,
                      hint: "Subject",
                      fieldName: "subject",
                      enabled: false,
                    ),
                  ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<dynamic>(
                      value: form["level_number"].toString().isEmpty
                          ? null
                          : form["level_number"],
                      dropdownColor: const Color(0xff1e293b),
                      isExpanded: true,
                      hint: Text(
                        "Select Level",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      iconEnabledColor: Colors.white,
                      style: const TextStyle(color: Colors.white),
                      items: levels.map((lvl) {
                        return DropdownMenuItem<dynamic>(
                          value: lvl,
                          child: Text(
                            "Level $lvl",
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        handleChange("level_number", value ?? "");
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                buildInput(
                  controller: questionController,
                  hint: "Enter Question",
                  fieldName: "question",
                  maxLines: 4,
                ),

                const SizedBox(height: 14),

                buildInput(
                  controller: optionAController,
                  hint: "Option A",
                  fieldName: "optionA",
                ),
                const SizedBox(height: 14),

                buildInput(
                  controller: optionBController,
                  hint: "Option B",
                  fieldName: "optionB",
                ),
                const SizedBox(height: 14),

                buildInput(
                  controller: optionCController,
                  hint: "Option C",
                  fieldName: "optionC",
                ),
                const SizedBox(height: 14),

                buildInput(
                  controller: optionDController,
                  hint: "Option D",
                  fieldName: "optionD",
                ),

                const SizedBox(height: 14),

                const Text(
                  "Correct Answer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    buildAnswerButton("A"),
                    const SizedBox(width: 10),
                    buildAnswerButton("B"),
                    const SizedBox(width: 10),
                    buildAnswerButton("C"),
                    const SizedBox(width: 10),
                    buildAnswerButton("D"),
                  ],
                ),

                const SizedBox(height: 14),

                buildInput(
                  controller: explanationController,
                  hint: "Explanation (optional)",
                  fieldName: "explanation",
                  maxLines: 4,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      disabledBackgroundColor: Colors.white.withOpacity(0.7),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            "Save Question",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}