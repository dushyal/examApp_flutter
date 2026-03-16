import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../core/storage/local_storage.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  List<dynamic> students = [];
  int? editingId;

  Map<String, dynamic> editData = {
    "name": "",
    "email": "",
    "role": "",
    "subject": "",
  };

  bool loading = false;
  String selectedRole = "";
  String searchText = "";

  final TextEditingController searchController = TextEditingController();
  final TextEditingController editNameController = TextEditingController();
  final TextEditingController editEmailController = TextEditingController();

  final String baseUrl = "http://192.168.29.79:5000/api";

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    searchController.dispose();
    editNameController.dispose();
    editEmailController.dispose();
    super.dispose();
  }

  Future<void> fetchStudents() async {
    setState(() {
      loading = true;
    });

    try {
      final token = await LocalStorage.getToken();

      final response = await http.get(
        Uri.parse("$baseUrl/admin/students"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      debugPrint("STUDENTS STATUS => ${response.statusCode}");
      debugPrint("STUDENTS BODY => ${response.body}");

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          students = data["students"] ?? [];
        });
      } else {
        showMessage(
          "Error",
          data["message"]?.toString() ?? "Failed to load students",
        );
      }
    } catch (e) {
      debugPrint("FETCH STUDENTS ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Failed to load students");
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  List<String> get uniqueRoles {
    return students
        .map((s) => s["role"])
        .where((r) => r != null && r.toString().trim().isNotEmpty)
        .map((r) => r.toString())
        .toSet()
        .toList();
  }

  List<dynamic> get filteredStudents {
    List<dynamic> data = [...students];

    if (selectedRole.isNotEmpty) {
      data = data.where((s) {
        return (s["role"] ?? "").toString().toLowerCase() ==
            selectedRole.toLowerCase();
      }).toList();
    }

    if (searchText.trim().isNotEmpty) {
      final value = searchText.toLowerCase();
      data = data.where((s) {
        final name = (s["name"] ?? "").toString().toLowerCase();
        final email = (s["email"] ?? "").toString().toLowerCase();
        return name.contains(value) || email.contains(value);
      }).toList();
    }

    return data;
  }

  void startEdit(Map<String, dynamic> student) {
    setState(() {
      editingId = student["id"];
      editData = {
        "name": student["name"] ?? "",
        "email": student["email"] ?? "",
        "role": student["role"] ?? "",
        "subject": student["subject"] ?? "",
      };

      editNameController.text = editData["name"] ?? "";
      editEmailController.text = editData["email"] ?? "";
    });
  }

  Future<void> saveEdit(int id) async {
    try {
      final token = await LocalStorage.getToken();

      final body = {
        "name": editNameController.text.trim(),
        "email": editEmailController.text.trim(),
        "role": editData["role"] ?? "",
        "subject": editData["subject"] ?? "",
      };

      final response = await http.put(
        Uri.parse("$baseUrl/admin/students/$id"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      debugPrint("UPDATE STUDENT STATUS => ${response.statusCode}");
      debugPrint("UPDATE STUDENT BODY => ${response.body}");

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          (data["success"] == true || data["student"] != null)) {
        final updated = data["student"] ?? body;

        setState(() {
          students = students.map((s) {
            return s["id"] == id ? updated : s;
          }).toList();
          editingId = null;
        });

        showMessage("Success", "Student updated");
      } else {
        showMessage(
          "Error",
          data["message"]?.toString() ?? "Update failed",
        );
      }
    } catch (e) {
      debugPrint("UPDATE STUDENT ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Update failed");
    }
  }

  Future<void> handleBlock(int id, bool block) async {
    final confirmed = await showConfirmDialog("Confirm", "Are you sure?");
    if (!confirmed) return;

    try {
      final token = await LocalStorage.getToken();

      final response = await http.put(
        Uri.parse("$baseUrl/admin/students/$id/block"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
        body: jsonEncode({"block": block}),
      );

      debugPrint("BLOCK STUDENT STATUS => ${response.statusCode}");
      debugPrint("BLOCK STUDENT BODY => ${response.body}");

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 &&
          (data["success"] == true || data["student"] != null)) {
        final updated = data["student"];

        if (updated != null) {
          setState(() {
            students = students.map((s) {
              return s["id"] == id ? updated : s;
            }).toList();
          });
        } else {
          await fetchStudents();
        }
      } else {
        showMessage(
          "Error",
          data["message"]?.toString() ?? "Failed to update block status",
        );
      }
    } catch (e) {
      debugPrint("BLOCK STUDENT ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Failed to update block status");
    }
  }

  Future<void> handleDelete(int id) async {
    final confirmed = await showConfirmDialog("Confirm", "Delete student?");
    if (!confirmed) return;

    try {
      final token = await LocalStorage.getToken();

      final response = await http.delete(
        Uri.parse("$baseUrl/admin/students/$id"),
        headers: {
          "Content-Type": "application/json",
          if (token != null && token.isNotEmpty)
            "Authorization": "Bearer $token",
        },
      );

      debugPrint("DELETE STUDENT STATUS => ${response.statusCode}");
      debugPrint("DELETE STUDENT BODY => ${response.body}");

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          students.removeWhere((s) => s["id"] == id);
        });
      } else {
        showMessage("Error", "Delete failed");
      }
    } catch (e) {
      debugPrint("DELETE STUDENT ERROR => $e");
      if (!mounted) return;
      showMessage("Error", "Delete failed");
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

  Future<bool> showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    return result ?? false;
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
              SizedBox(height: 12),
              Text(
                "Loading students...",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff0f172a),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchStudents,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Manage Students",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchText = value;
                    });
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search name or email...",
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.20),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ["ALL", ...uniqueRoles].map((role) {
                      final selected = role == "ALL"
                          ? selectedRole.isEmpty
                          : selectedRole == role;

                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedRole = role == "ALL" ? "" : role;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                color: selected ? Colors.black : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 22),

                filteredStudents.isEmpty
                    ? Text(
                        "No students found",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      )
                    : Column(
                        children:
                            List.generate(filteredStudents.length, (index) {
                          final s = filteredStudents[index];
                          final isBlocked =
                              s["is_blocked"] == true || s["is_blocked"] == 1;

                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
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
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "#${index + 1}",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isBlocked
                                            ? const Color.fromRGBO(
                                                239,
                                                68,
                                                68,
                                                0.30,
                                              )
                                            : const Color.fromRGBO(
                                                34,
                                                197,
                                                94,
                                                0.30,
                                              ),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        isBlocked ? "Blocked" : "Active",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                _buildLabel("Name"),
                                editingId == s["id"]
                                    ? _buildEditField(
                                        editNameController,
                                        "Name",
                                      )
                                    : _buildValue(s["name"] ?? ""),

                                _buildLabel("Email"),
                                editingId == s["id"]
                                    ? _buildEditField(
                                        editEmailController,
                                        "Email",
                                      )
                                    : _buildValue(s["email"] ?? ""),

                                _buildLabel("Role"),
                                _buildValue(
                                  s["subject"] != null &&
                                          s["subject"]
                                              .toString()
                                              .isNotEmpty
                                      ? "SUBJECT TEACHER"
                                      : (s["role"] ?? ""),
                                ),

                                if (s["subject"] != null &&
                                    s["subject"].toString().isNotEmpty) ...[
                                  _buildLabel("Subject"),
                                  _buildValue(s["subject"]),
                                ],

                                const SizedBox(height: 18),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _actionButton(
                                        text: isBlocked ? "Unblock" : "Block",
                                        color: isBlocked
                                            ? const Color(0xff16a34a)
                                            : const Color(0xffdc2626),
                                        onTap: () => handleBlock(
                                          s["id"],
                                          !isBlocked,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _actionButton(
                                        text: editingId == s["id"]
                                            ? "Save"
                                            : "Edit",
                                        color: editingId == s["id"]
                                            ? const Color(0xff059669)
                                            : const Color(0xff2563eb),
                                        onTap: () {
                                          if (editingId == s["id"]) {
                                            saveEdit(s["id"]);
                                          } else {
                                            startEdit(
                                              Map<String, dynamic>.from(s),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _actionButton(
                                        text: "Delete",
                                        color: const Color(0xff374151),
                                        onTap: () => handleDelete(s["id"]),
                                      ),
                                    ),
                                  ],
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
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.60),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildValue(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}