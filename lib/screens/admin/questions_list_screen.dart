import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/storage/local_storage.dart';

class AdminQuestionsScreen extends StatefulWidget {
  const AdminQuestionsScreen({super.key});

  @override
  State<AdminQuestionsScreen> createState() => _AdminQuestionsScreenState();
}

class _AdminQuestionsScreenState extends State<AdminQuestionsScreen> {
  final String baseUrl = "http://192.168.29.79:5000/api";

  List<dynamic> questions = [];
  bool loading = true;

  String? userSubject;
  String filterSubject = "";
  String filterLevel = "";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    await fetchQuestions();

    try {
      final user = await LocalStorage.getUser();

      if (!mounted) return;
      setState(() {
        userSubject = user != null && user["subject"] != null
            ? user["subject"].toString()
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        userSubject = null;
      });
    }
  }

  Future<void> fetchQuestions() async {
    try {
      final token = await LocalStorage.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/admin/questions"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      debugPrint("QUESTIONS STATUS => ${response.statusCode}");
      debugPrint("QUESTIONS BODY => ${response.body}");

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          questions = data["questions"] ?? [];
        });
      } else {
        showMessage(
          "Error",
          data["message"]?.toString() ?? "Failed to load questions",
        );
      }
    } catch (e) {
      debugPrint("FETCH QUESTIONS ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Failed to load questions");
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  bool get isAdmin => userSubject == null;

  List<String> get uniqueSubjects {
    return questions
        .map((q) => q["subject"])
        .where((s) => s != null && s.toString().trim().isNotEmpty)
        .map((s) => s.toString())
        .toSet()
        .toList();
  }

  List<dynamic> get filteredQuestions {
    return questions.where((q) {
      if (!isAdmin && q["subject"] != userSubject) return false;

      if (isAdmin &&
          filterSubject.isNotEmpty &&
          q["subject"] != filterSubject) {
        return false;
      }

      if (filterLevel.isNotEmpty &&
          q["level_number"] != int.tryParse(filterLevel)) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> handleDelete(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        title: const Text(
          "Confirm",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Delete this question?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = await LocalStorage.getToken();

      final response = await http.delete(
        Uri.parse("$baseUrl/admin/questions/$id"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      debugPrint("DELETE QUESTION STATUS => ${response.statusCode}");
      debugPrint("DELETE QUESTION BODY => ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          questions.removeWhere((q) => q["id"] == id);
        });
      } else {
        showMessage("Error", "Failed to delete question");
      }
    } catch (e) {
      debugPrint("DELETE QUESTION ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Failed to delete question");
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

  Widget buildQuestionCard(Map<String, dynamic> q, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#${index + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff8b5cf6).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  "Level ${q["level_number"] ?? "-"}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "Subject",
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            q["subject"]?.toString() ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Question",
            style: TextStyle(
              color: Colors.white.withOpacity(0.60),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            q["text"]?.toString() ?? "",
            style: const TextStyle(
              color: Color(0xffe5e7eb),
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      "/questions-edit",
                      arguments: {"id": q["id"]},
                    ).then((_) => loadData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff16a34a),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Edit",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => handleDelete(q["id"]),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffdc2626),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Delete",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: Container(
                padding: const EdgeInsets.all(16),
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
                      "Manage Questions",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Add, filter and manage exam questions",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/questions-add")
                            .then((_) => loadData());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563eb),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "+ Add Question",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.20),
                        ),
                      ),
                      child: Column(
                        children: [
                          if (isAdmin) ...[
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: filterSubject.isEmpty
                                      ? null
                                      : filterSubject,
                                  dropdownColor: const Color(0xff1e293b),
                                  isExpanded: true,
                                  hint: const Text(
                                    "All Subjects",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  iconEnabledColor: Colors.white,
                                  style: const TextStyle(color: Colors.white),
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: "",
                                      child: Text(
                                        "All Subjects",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    ...uniqueSubjects.map(
                                      (sub) => DropdownMenuItem<String>(
                                        value: sub,
                                        child: Text(
                                          sub,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      filterSubject = value ?? "";
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.16),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: filterLevel.isEmpty ? null : filterLevel,
                                dropdownColor: const Color(0xff1e293b),
                                isExpanded: true,
                                hint: const Text(
                                  "All Levels",
                                  style: TextStyle(color: Colors.white),
                                ),
                                iconEnabledColor: Colors.white,
                                style: const TextStyle(color: Colors.white),
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: "",
                                    child: Text(
                                      "All Levels",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  ...[1, 2, 3, 4, 5].map(
                                    (lvl) => DropdownMenuItem<String>(
                                      value: "$lvl",
                                      child: Text(
                                        "Level $lvl",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    filterLevel = value ?? "";
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (filteredQuestions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Text(
                            "No questions found for selected filters.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.60),
                              fontSize: 15,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children:
                            List.generate(filteredQuestions.length, (index) {
                          final q = Map<String, dynamic>.from(
                            filteredQuestions[index],
                          );
                          return buildQuestionCard(q, index);
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xffef4444).withOpacity(0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                "Admin Panel",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}