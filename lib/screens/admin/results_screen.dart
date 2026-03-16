import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/storage/local_storage.dart';

class AdminResultsScreen extends StatefulWidget {
  const AdminResultsScreen({super.key});

  @override
  State<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends State<AdminResultsScreen> {
  List<dynamic> results = [];
  bool loading = true;

  String filterExam = "";
  String filterStudent = "";
  String filterStatus = "";

  final TextEditingController studentSearchController = TextEditingController();

  final String baseUrl = "http://192.168.29.79:5000/api";

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  @override
  void dispose() {
    studentSearchController.dispose();
    super.dispose();
  }

  Future<void> fetchResults() async {
    try {
      final token = await LocalStorage.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/admin/results"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      debugPrint("RESULTS STATUS => ${response.statusCode}");
      debugPrint("RESULTS BODY => ${response.body}");

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          results = data["results"] ?? [];
        });
      } else {
        _showMessage(
          "Error",
          data["message"]?.toString() ?? "Failed to fetch results",
        );
      }
    } catch (e) {
      debugPrint("FETCH RESULTS ERROR => $e");
      if (!mounted) return;
      _showMessage("Error", "Failed to fetch results");
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  String normalizeStatus(dynamic status) {
    return (status ?? "").toString().toLowerCase();
  }

  List<dynamic> get filteredResults {
    return results.where((r) {
      final examTitle = (r["exam"]?["title"] ?? "").toString().toLowerCase();
      final studentName = (r["user"]?["name"] ?? "").toString().toLowerCase();
      final passStatus = normalizeStatus(r["pass_status"]);

      if (filterExam.isNotEmpty && examTitle != filterExam.toLowerCase()) {
        return false;
      }

      if (filterStudent.isNotEmpty &&
          !studentName.contains(filterStudent.toLowerCase())) {
        return false;
      }

      if (filterStatus.isNotEmpty &&
          passStatus != normalizeStatus(filterStatus)) {
        return false;
      }

      return true;
    }).toList();
  }

  int get totalAttempts => filteredResults.length;

  String get avgScore {
    if (totalAttempts == 0) return "0.00";

    final total = filteredResults.fold<double>(
      0,
      (sum, r) =>
          sum + (double.tryParse((r["score"] ?? 0).toString()) ?? 0),
    );

    return (total / totalAttempts).toStringAsFixed(2);
  }

  int get passCount {
    return filteredResults
        .where((r) => normalizeStatus(r["pass_status"]) == "pass")
        .length;
  }

  String get passPercentage {
    if (totalAttempts == 0) return "0.0";
    return ((passCount / totalAttempts) * 100).toStringAsFixed(1);
  }

  List<String> get uniqueExams {
    return results
        .map((r) => r["exam"]?["title"])
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .map((e) => e.toString())
        .toSet()
        .toList();
  }

  String formatDate(dynamic date) {
    if (date == null) return "-";

    try {
      final parsed = DateTime.parse(date.toString()).toLocal();
      return "${parsed.day.toString().padLeft(2, '0')}/"
          "${parsed.month.toString().padLeft(2, '0')}/"
          "${parsed.year} "
          "${_formatHour(parsed.hour)}:"
          "${parsed.minute.toString().padLeft(2, '0')} "
          "${parsed.hour >= 12 ? 'PM' : 'AM'}";
    } catch (_) {
      return date.toString();
    }
  }

  String _formatHour(int hour) {
    final h = hour % 12;
    return (h == 0 ? 12 : h).toString().padLeft(2, '0');
  }

  void _showMessage(String title, String message) {
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

  Widget _buildExamDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filterExam.isEmpty ? null : filterExam,
          dropdownColor: const Color(0xff1e293b),
          isExpanded: true,
          hint: const Text(
            "All Exams",
            style: TextStyle(color: Colors.white),
          ),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: [
            const DropdownMenuItem<String>(
              value: "",
              child: Text("All Exams", style: TextStyle(color: Colors.white)),
            ),
            ...uniqueExams.map(
              (exam) => DropdownMenuItem<String>(
                value: exam,
                child: Text(
                  exam,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              filterExam = value ?? "";
            });
          },
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filterStatus.isEmpty ? null : filterStatus,
          dropdownColor: const Color(0xff1e293b),
          isExpanded: true,
          hint: const Text(
            "All Status",
            style: TextStyle(color: Colors.white),
          ),
          iconEnabledColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          items: const [
            DropdownMenuItem<String>(
              value: "",
              child: Text("All Status", style: TextStyle(color: Colors.white)),
            ),
            DropdownMenuItem<String>(
              value: "pass",
              child: Text("PASS", style: TextStyle(color: Colors.white)),
            ),
            DropdownMenuItem<String>(
              value: "fail",
              child: Text("FAIL", style: TextStyle(color: Colors.white)),
            ),
          ],
          onChanged: (value) {
            setState(() {
              filterStatus = value ?? "";
            });
          },
        ),
      ),
    );
  }

  Widget _resultText({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xffe5e7eb),
            fontSize: 14,
          ),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            TextSpan(text: value),
          ],
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
              CircularProgressIndicator(color: Color(0xff6366f1)),
              SizedBox(height: 12),
              Text(
                "Loading results...",
                style: TextStyle(color: Colors.white, fontSize: 15),
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
            onRefresh: fetchResults,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeaderSection(),
                    const SizedBox(height: 24),

                    _AnalyticsCard(
                      label: "Total Attempts",
                      value: totalAttempts.toString(),
                    ),
                    const SizedBox(height: 12),
                    _AnalyticsCard(
                      label: "Average Score",
                      value: avgScore,
                    ),
                    const SizedBox(height: 12),
                    _AnalyticsCard(
                      label: "Pass Percentage",
                      value: "$passPercentage%",
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildExamDropdown(),
                          const SizedBox(height: 12),
                          _buildStatusDropdown(),
                          const SizedBox(height: 12),
                          TextField(
                            controller: studentSearchController,
                            onChanged: (value) {
                              setState(() {
                                filterStudent = value;
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Search student...",
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                              ),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.25),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.16),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.30),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    filteredResults.isEmpty
                        ? Center(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 36),
                              child: Text(
                                "No results found.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.60),
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: List.generate(filteredResults.length,
                                (index) {
                              final r = filteredResults[index];
                              final isPass =
                                  normalizeStatus(r["pass_status"]) == "pass";

                              return Container(
                                width: double.infinity,
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "#${index + 1}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPass
                                                ? const Color.fromRGBO(
                                                    22,
                                                    163,
                                                    74,
                                                    0.85,
                                                  )
                                                : const Color.fromRGBO(
                                                    220,
                                                    38,
                                                    38,
                                                    0.85,
                                                  ),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                          ),
                                          child: Text(
                                            isPass ? "PASS" : "FAIL",
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
                                    _resultText(
                                      label: "Student: ",
                                      value: r["user"]?["name"]?.toString() ?? "-",
                                    ),
                                    _resultText(
                                      label: "Exam: ",
                                      value: r["exam"]?["title"]?.toString() ?? "-",
                                    ),
                                    _resultText(
                                      label: "Attempt: ",
                                      value:
                                          r["attempt_number"]?.toString() ?? "-",
                                    ),
                                    _resultText(
                                      label: "Score: ",
                                      value: r["score"]?.toString() ?? "-",
                                    ),
                                    _resultText(
                                      label: "Submitted At: ",
                                      value: formatDate(r["submitted_at"]),
                                    ),
                                  ],
                                ),
                              );
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
                color: const Color(0xff4f46e5).withOpacity(0.92),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                "Admin • Results",
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Student Results",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          "Exam performance & analytics",
          style: TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.70),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String label;
  final String value;

  const _AnalyticsCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}