import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../providers/auth_provider.dart';
import 'certificate_screen.dart';

class CertificatesListScreen extends StatefulWidget {
  const CertificatesListScreen({super.key});

  @override
  State<CertificatesListScreen> createState() => _CertificatesListScreenState();
}

class _CertificatesListScreenState extends State<CertificatesListScreen> {
  List<String> subjects = [];
  Map<String, dynamic> subjectScores = {};
  Map<String, dynamic> pendingLevels = {};

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchCertificates();
  }

  Future<void> fetchCertificates() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiClient.dio.get('/student/dashboard');

      final responseData = (res.data is Map<String, dynamic>)
          ? res.data as Map<String, dynamic>
          : <String, dynamic>{};

      if (!mounted) return;

      setState(() {
        subjects = List<String>.from(responseData['subjects'] ?? []);
        subjectScores =
            Map<String, dynamic>.from(responseData['subjectScores'] ?? {});
        pendingLevels =
            Map<String, dynamic>.from(responseData['pendingLevels'] ?? {});
      });
    } on DioException catch (err) {
      final statusCode = err.response?.statusCode;
      String message = 'Failed to load certificates';

      final responseData = err.response?.data;

      if (responseData is Map && responseData['message'] != null) {
        message = responseData['message'].toString();
      } else if (err.message != null && err.message!.isNotEmpty) {
        message = err.message!;
      } else {
        message = err.toString();
      }

      if (statusCode == 401) {
        if (!mounted) return;
        await context.read<AuthProvider>().logout();
        return;
      }

      if (!mounted) return;
      setState(() {
        error = message;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        error = err.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  bool isCompleted(String sub) {
    final rawPending = pendingLevels[sub];
    final pendingText = rawPending == null ? '-' : rawPending.toString().trim();
    final normalizedPending = pendingText.toLowerCase();

    return pendingText == '-' ||
        pendingText == '0' ||
        normalizedPending == 'completed' ||
        normalizedPending == 'complete';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final completedSubjects = subjects.where(isCompleted).toList();

    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFF8B5CF6),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Certificate Error',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFECACA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: fetchCertificates,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (completedSubjects.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: SafeArea(
          child: Center(
            child: Text(
              'No certificates available',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedSubjects.length,
          itemBuilder: (context, index) {
            final sub = completedSubjects[index];
            final score = num.tryParse('${subjectScores[sub] ?? 0}') ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CertificateScreen(
                            name: authProvider.user?['name']?.toString() ??
                                'Student',
                            subject: sub,
                            aggregatePercent: score,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}