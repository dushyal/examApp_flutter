import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  List<dynamic> exams = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchExams();
  }

  Future<void> fetchExams() async {
    try {
      setState(() {
        loading = true;
      });

      final response = await ApiClient.dio.get('/admin/exams');

      debugPrint("EXAMS STATUS => ${response.statusCode}");
      debugPrint("EXAMS BODY => ${response.data}");

      if (!mounted) return;

      final data = response.data;
      final examList = data is Map ? (data['exams'] ?? []) : [];

      setState(() {
        exams = examList is List ? examList : [];
      });
    } on DioException catch (e) {
      debugPrint("FETCH EXAMS ERROR => ${e.response?.data ?? e.message}");

      if (!mounted) return;

      final data = e.response?.data;
      String message = "Failed to fetch exams";

      if (data is Map) {
        message =
            data["message"]?.toString() ??
            data["error"]?.toString() ??
            "Failed to fetch exams";
      }

      showMessage("Error", message);
    } catch (e) {
      debugPrint("FETCH EXAMS ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Failed to fetch exams");
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> handleDelete(dynamic id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm"),
        content: const Text("Delete this exam?"),
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
      final response = await ApiClient.dio.delete('/admin/exams/$id');

      debugPrint("DELETE EXAM STATUS => ${response.statusCode}");
      debugPrint("DELETE EXAM BODY => ${response.data}");

      if (!mounted) return;

      if ((response.statusCode ?? 0) >= 200 &&
          (response.statusCode ?? 0) < 300) {
        setState(() {
          exams.removeWhere((e) {
            final exam = Map<String, dynamic>.from(e);
            return exam["id"] == id || exam["_id"] == id;
          });
        });
      } else {
        showMessage("Error", "Failed to delete exam");
      }
    } on DioException catch (e) {
      debugPrint("DELETE EXAM ERROR => ${e.response?.data ?? e.message}");

      if (!mounted) return;

      final data = e.response?.data;
      String message = "Failed to delete exam";

      if (data is Map) {
        message =
            data["message"]?.toString() ??
            data["error"]?.toString() ??
            "Failed to delete exam";
      }

      showMessage("Error", message);
    } catch (e) {
      debugPrint("DELETE EXAM ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Failed to delete exam");
    }
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

  Widget buildInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget buildExamCard(Map<String, dynamic> exam, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "#${index + 1}  ${exam["title"] ?? exam["name"] ?? "Exam"}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            buildInfo("Subject", exam["subject"]?.toString() ?? "-"),
            buildInfo("Duration", exam["duration"]?.toString() ?? "-"),
            buildInfo("Total Marks", exam["totalMarks"]?.toString() ?? "-"),
            buildInfo("Status", exam["status"]?.toString() ?? "-"),
            if (exam["date"] != null)
              buildInfo("Date", exam["date"]?.toString() ?? "-"),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        "/exam-edit",
                        arguments: {"id": exam["id"] ?? exam["_id"]},
                      ).then((_) => fetchExams());
                    },
                    child: const Text("Edit"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => handleDelete(exam["id"] ?? exam["_id"]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text("Delete"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Exams"),
      ),
      body: RefreshIndicator(
        onRefresh: fetchExams,
        child: exams.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: Text("No exams found")),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: exams.length,
                itemBuilder: (context, index) {
                  final exam = Map<String, dynamic>.from(exams[index]);
                  return buildExamCard(exam, index);
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/exam-add").then((_) => fetchExams());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}