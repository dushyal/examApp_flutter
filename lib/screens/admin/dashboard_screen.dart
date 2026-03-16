import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> stats = {
    'totalStudents': 0,
    'attempts': 0,
    'passRate': 0,
    'avgScore': 0,
  };

  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    try {
      final res = await ApiClient.dio.get('/admin/dashboard');

      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(res.data ?? {});
      });
    } catch (err) {
      debugPrint('ADMIN DASHBOARD ERROR: $err');
    } finally {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final isSmallDevice = width < 380;
    final isTablet = width >= 768;

    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Dashboard'),
        ),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF4F46E5),
              ),
              SizedBox(height: 10),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final cardHeight =
        isTablet ? height * 0.20 : (isSmallDevice ? height * 0.16 : height * 0.18);

    final titleSize = isTablet ? 34.0 : (isSmallDevice ? 24.0 : 28.0);
    final valueSize = isTablet ? 30.0 : (isSmallDevice ? 20.0 : 24.0);
    final labelSize = isTablet ? 18.0 : (isSmallDevice ? 14.0 : 16.0);
    final containerPadding = isTablet ? 28.0 : 20.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: EdgeInsets.all(containerPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: titleSize,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _DashboardCard(
                    height: cardHeight,
                    label: 'Total Students',
                    value: '${stats['totalStudents'] ?? 0}',
                    labelSize: labelSize,
                    valueSize: valueSize,
                  ),
                  _DashboardCard(
                    height: cardHeight,
                    label: 'Total Attempts',
                    value: '${stats['attempts'] ?? 0}',
                    labelSize: labelSize,
                    valueSize: valueSize,
                  ),
                  _DashboardCard(
                    height: cardHeight,
                    label: 'Pass Rate',
                    value: '${stats['passRate'] ?? 0}%',
                    labelSize: labelSize,
                    valueSize: valueSize,
                  ),
                  _DashboardCard(
                    height: cardHeight,
                    label: 'Average Score',
                    value: '${stats['avgScore'] ?? 0}',
                    labelSize: labelSize,
                    valueSize: valueSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final double height;
  final String label;
  final String value;
  final double labelSize;
  final double valueSize;

  const _DashboardCard({
    required this.height,
    required this.label,
    required this.value,
    required this.labelSize,
    required this.valueSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: const Color(0xFF555555),
              fontSize: labelSize,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111111),
              fontSize: valueSize,
            ),
          ),
        ],
      ),
    );
  }
}