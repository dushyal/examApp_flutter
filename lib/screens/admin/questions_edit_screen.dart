import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditQuestionScreen extends StatefulWidget {
  const EditQuestionScreen({super.key});

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final String baseUrl = "http://192.168.29.79:5000/api";

  bool loading = true;
  bool saving = false;
  dynamic id;

  Map<String, dynamic> form = {
    "subject": "",
    "level_number": "",
    "text": "",
    "explanation": "",
    "option_a": "",
    "option_b": "",
    "option_c": "",
    "option_d": "",
    "correct_answer": "",
  };

  final TextEditingController subjectController = TextEditingController();
  final TextEditingController questionController = TextEditingController();
  final TextEditingController explanationController = TextEditingController();
  final TextEditingController optionAController = TextEditingController();
  final TextEditingController optionBController = TextEditingController();
  final TextEditingController optionCController = TextEditingController();
  final TextEditingController optionDController = TextEditingController();

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;
    _initialized = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    id = args?["id"];

    if (id != null) {
      fetchQuestion();
    } else {
      setState(() {
        loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showMessage("Error", "Question ID not found");
      });
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    questionController.dispose();
    explanationController.dispose();
    optionAController.dispose();
    optionBController.dispose();
    optionCController.dispose();
    optionDController.dispose();
    super.dispose();
  }

  Future<void> fetchQuestion() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/questions/$id"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer your_token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["question"] != null) {
        final q = data["question"];
        final options = List<dynamic>.from(q["options"] ?? []);

        final optionsWithLetters = options.asMap().entries.map((entry) {
          final index = entry.key;
          final value = Map<String, dynamic>.from(entry.value);
          return {
            ...value,
            "letter": ["A", "B", "C", "D"][index],
          };
        }).toList();

        final correctOption = optionsWithLetters.cast<Map<String, dynamic>?>().firstWhere(
              (o) => o?["is_correct"] == true,
              orElse: () => null,
            );

        final updatedForm = {
          "subject": q["subject"]?.toString() ?? "",
          "level_number": q["level_number"] ?? "",
          "text": q["text"]?.toString() ?? "",
          "explanation": q["explanation"]?.toString() ?? "",
          "option_a": optionsWithLetters.isNotEmpty
              ? optionsWithLetters[0]["text"]?.toString() ?? ""
              : "",
          "option_b": optionsWithLetters.length > 1
              ? optionsWithLetters[1]["text"]?.toString() ?? ""
              : "",
          "option_c": optionsWithLetters.length > 2
              ? optionsWithLetters[2]["text"]?.toString() ?? ""
              : "",
          "option_d": optionsWithLetters.length > 3
              ? optionsWithLetters[3]["text"]?.toString() ?? ""
              : "",
          "correct_answer": correctOption?["letter"]?.toString() ?? "",
        };

        setState(() {
          form = updatedForm;
        });

        subjectController.text = updatedForm["subject"] ?? "";
        questionController.text = updatedForm["text"] ?? "";
        explanationController.text = updatedForm["explanation"] ?? "";
        optionAController.text = updatedForm["option_a"] ?? "";
        optionBController.text = updatedForm["option_b"] ?? "";
        optionCController.text = updatedForm["option_c"] ?? "";
        optionDController.text = updatedForm["option_d"] ?? "";
      } else {
        showMessage("Error", "Error loading question");
      }
    } catch (e) {
      showMessage("Error", "Error loading question");
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  void handleChange(String name, dynamic value) {
    setState(() {
      form[name] = value;
    });
  }

  Future<void> handleSubmit() async {
    final payload = {
      "subject": form["subject"],
      "level_number": form["level_number"],
      "question": form["text"],
      "explanation": form["explanation"].toString().trim().isEmpty
          ? null
          : form["explanation"],
      "optionA": form["option_a"],
      "optionB": form["option_b"],
      "optionC": form["option_c"],
      "optionD": form["option_d"],
      "correctAnswer": form["correct_answer"],
    };

    try {
      setState(() {
        saving = true;
      });

      final response = await http.put(
        Uri.parse("$baseUrl/admin/questions/$id"),
        headers: {
          "Content-Type": "application/json",
          // "Authorization": "Bearer your_token",
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showMessage("Success", "Question updated successfully!", onOk: () {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/questions",
            (route) => false,
          );
        });
      } else {
        showMessage("Error", "Failed to update question");
      }
    } catch (e) {
      showMessage("Error", "Failed to update question");
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void showMessage(String title, String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
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

  Widget buildInput({
    required TextEditingController controller,
    required String hint,
    required String fieldName,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
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
        fillColor: Colors.white.withOpacity(0.18),
        contentPadding: const EdgeInsets.all(14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.20),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.35),
          ),
        ),
      ),
    );
  }

  Widget buildAnswerButton(String opt) {
    final selected = form["correct_answer"] == opt;

    return Expanded(
      child: GestureDetector(
        onTap: () => handleChange("correct_answer", opt),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xff9333ea)
                : Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? const Color(0xffc084fc)
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
                const Center(
                  child: Text(
                    "Edit Question",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  "Subject",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                buildInput(
                  controller: subjectController,
                  hint: "Subject",
                  fieldName: "subject",
                ),
                const SizedBox(height: 16),

                const Text(
                  "Level",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.20),
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
                      items: [1, 2, 3, 4, 5].map((level) {
                        return DropdownMenuItem<dynamic>(
                          value: level,
                          child: Text(
                            "Level $level",
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

                const SizedBox(height: 16),

                const Text(
                  "Question",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                buildInput(
                  controller: questionController,
                  hint: "Question",
                  fieldName: "text",
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                const Text(
                  "Explanation (optional)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                buildInput(
                  controller: explanationController,
                  hint: "Explanation",
                  fieldName: "explanation",
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                ...[
                  {"label": "Option A", "field": "option_a", "controller": optionAController},
                  {"label": "Option B", "field": "option_b", "controller": optionBController},
                  {"label": "Option C", "field": "option_c", "controller": optionCController},
                  {"label": "Option D", "field": "option_d", "controller": optionDController},
                ].map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["label"] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        buildInput(
                          controller: item["controller"] as TextEditingController,
                          hint: item["label"] as String,
                          fieldName: item["field"] as String,
                        ),
                      ],
                    ),
                  );
                }),

                const Text(
                  "Correct Answer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),

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

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff7c3aed),
                      disabledBackgroundColor:
                          const Color(0xff7c3aed).withOpacity(0.7),
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
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Update Question",
                            style: TextStyle(
                              color: Colors.white,
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