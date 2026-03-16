import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/local_storage.dart';

class FacultyScreen extends StatefulWidget {
  const FacultyScreen({super.key});

  @override
  State<FacultyScreen> createState() => _FacultyScreenState();
}

class _FacultyScreenState extends State<FacultyScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();

  String role = '';
  bool loading = false;
  String token = '';
  Map<String, dynamic>? credentials;

  @override
  void initState() {
    super.initState();
    getToken();
  }

  Future<void> getToken() async {
    final savedToken = await LocalStorage.getToken();
    if (!mounted) return;
    setState(() {
      token = savedToken ?? '';
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    subjectController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final subject = subjectController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        role.isEmpty ||
        (role == 'SUBJECT' && subject.isEmpty)) {
      await _showDialog('Error', 'Please fill all required fields');
      return;
    }

    setState(() {
      loading = true;
      credentials = null;
    });

    try {
      final res = await ApiClient.dio.post(
        '/admin/faculty',
        data: {
          'name': name,
          'email': email,
          'role': role,
          'subject': role == 'SUBJECT' ? subject : null,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        credentials = res.data['credentials'] is Map
            ? Map<String, dynamic>.from(res.data['credentials'])
            : null;

        nameController.clear();
        emailController.clear();
        subjectController.clear();
        role = '';
      });

      await _showDialog('Success', 'Faculty created successfully');
    } catch (err) {
      String message = 'Failed to create faculty';
      try {
        final data = (err as dynamic).response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      } catch (_) {}
      if (!mounted) return;
      await _showDialog('Error', message);
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _showDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool autoCapitalizeNone = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              autocorrect: !autoCapitalizeNone,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFCBD5E1),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                contentPadding: const EdgeInsets.fromLTRB(40, 12, 14, 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.40),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(
                icon,
                size: 18,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const roles = ['ADMIN', 'EXAMINER', 'SUBJECT', 'CANDIDATE'];

    return Scaffold(
      backgroundColor: const Color(0xFF4F46E5),
      appBar: AppBar(
        title: const Text('Faculty'),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Add Faculty',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Create new faculty account',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                buildInputField(
                  label: 'Name',
                  icon: Icons.person_outline,
                  controller: nameController,
                  hint: 'Faculty Name',
                ),
                const SizedBox(height: 16),

                buildInputField(
                  label: 'Email',
                  icon: Icons.mail_outline,
                  controller: emailController,
                  hint: 'faculty@email.com',
                  keyboardType: TextInputType.emailAddress,
                  autoCapitalizeNone: true,
                ),
                const SizedBox(height: 16),

                Text(
                  'Role',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.only(left: 12, right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: role.isEmpty ? null : role,
                            dropdownColor: const Color(0xFF4F46E5),
                            isExpanded: true,
                            hint: const Text(
                              'Select Role',
                              style: TextStyle(color: Colors.white),
                            ),
                            iconEnabledColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            items: roles.map((item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: loading
                                ? null
                                : (value) {
                                    setState(() {
                                      role = value ?? '';
                                    });
                                  },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (role == 'SUBJECT') ...[
                  const SizedBox(height: 16),
                  buildInputField(
                    label: 'Subject Name',
                    icon: Icons.menu_book_outlined,
                    controller: subjectController,
                    hint: 'e.g. Mathematics',
                  ),
                ],

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: loading ? null : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF4338CA),
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.7),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4F46E5),
                            ),
                          )
                        : const Text(
                            'Create Faculty',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                if (credentials != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login Credentials',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Name: ${credentials?['name'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Email: ${credentials?['email'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Password: ${credentials?['password'] ?? ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}