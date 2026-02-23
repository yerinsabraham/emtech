import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminAnalyticsTab extends StatefulWidget {
  const AdminAnalyticsTab({super.key});

  @override
  State<AdminAnalyticsTab> createState() => _AdminAnalyticsTabState();
}

class _AdminAnalyticsTabState extends State<AdminAnalyticsTab> {
  bool _loading = true;
  String? _error;

  // Snapshot data
  int _totalUsers = 0;
  int _totalStudents = 0;
  int _totalLecturers = 0;
  int _totalCourses = 0;
  int _totalEnrollments = 0;
  int _totalCertificates = 0;
  int _openTickets = 0;
  int _resolvedTickets = 0;
  double _totalRevenue = 0;
  int _activeLoans = 0;
  double _totalLoaned = 0;

  // Monthly breakdowns (last 6 months)
  List<Map<String, dynamic>> _monthlySignups = [];
  List<Map<String, dynamic>> _monthlyRevenue = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = FirebaseFirestore.instance;

      final results = await Future.wait([
        db.collection('users').get(),
        db.collection('courses').get(),
        db.collection('enrollments').get(),
        db.collection('certificates').get(),
        db.collection('supportTickets').get(),
        db.collection('payments').get(),
        db.collection('loans').get(),
      ]);

      final users = results[0];
      final courses = results[1];
      final enrollments = results[2];
      final certificates = results[3];
      final tickets = results[4];
      final payments = results[5];
      final loans = results[6];

      // Users
      int students = 0, lecturers = 0;
      for (final doc in users.docs) {
        final role = doc.data()['role'] ?? 'student';
        if (role == 'student') students++;
        if (role == 'lecturer') lecturers++;
      }

      // Tickets
      int openT = 0, resolvedT = 0;
      for (final doc in tickets.docs) {
        final status = doc.data()['status'] ?? 'open';
        if (status == 'open' || status == 'in_progress') openT++;
        if (status == 'resolved' || status == 'closed') resolvedT++;
      }

      // Revenue from payments
      double totalRev = 0;
      final Map<String, double> monthlyRev = {};
      for (final doc in payments.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final status = data['status'] ?? '';
        if (status == 'completed' || status == 'success') {
          totalRev += amount;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          if (createdAt != null) {
            final monthKey = DateFormat('MMM yyyy').format(createdAt);
            monthlyRev[monthKey] = (monthlyRev[monthKey] ?? 0) + amount;
          }
        }
      }

      // Loans
      int activeLoanCount = 0;
      double totalLoanedOut = 0;
      for (final doc in loans.docs) {
        final data = doc.data();
        final status = data['status'] ?? '';
        if (status == 'active' || status == 'disbursed') {
          activeLoanCount++;
          totalLoanedOut += (data['principalAmount'] ?? 0).toDouble();
        }
      }

      // Monthly signups (last 6 months)
      final Map<String, int> monthlySignupsMap = {};
      for (final doc in users.docs) {
        final created = (doc.data()['createdAt'] as Timestamp?)?.toDate();
        if (created != null) {
          final key = DateFormat('MMM yyyy').format(created);
          monthlySignupsMap[key] = (monthlySignupsMap[key] ?? 0) + 1;
        }
      }

      // Build sorted lists of last 6 months
      final now = DateTime.now();
      final signupList = <Map<String, dynamic>>[];
      final revList = <Map<String, dynamic>>[];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final key = DateFormat('MMM yyyy').format(month);
        signupList.add({'month': DateFormat('MMM').format(month), 'count': monthlySignupsMap[key] ?? 0});
        revList.add({'month': DateFormat('MMM').format(month), 'amount': monthlyRev[key] ?? 0.0});
      }

      if (mounted) {
        setState(() {
          _totalUsers = users.docs.length;
          _totalStudents = students;
          _totalLecturers = lecturers;
          _totalCourses = courses.docs.length;
          _totalEnrollments = enrollments.docs.length;
          _totalCertificates = certificates.docs.length;
          _openTickets = openT;
          _resolvedTickets = resolvedT;
          _totalRevenue = totalRev;
          _activeLoans = activeLoanCount;
          _totalLoaned = totalLoanedOut;
          _monthlySignups = signupList;
          _monthlyRevenue = revList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadAnalytics, child: const Text('Retry')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Platform Analytics', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _loadAnalytics,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Users row ─────────────────────────────
            _sectionHeader('Users'),
            _statGrid([
              _StatItem('Total Users', _totalUsers, Icons.people, Colors.blue),
              _StatItem('Students', _totalStudents, Icons.school, Colors.cyan),
              _StatItem('Lecturers', _totalLecturers, Icons.cast_for_education, Colors.purple),
            ]),
            const SizedBox(height: 20),

            // ── Courses & Learning ─────────────────────
            _sectionHeader('Courses & Learning'),
            _statGrid([
              _StatItem('Total Courses', _totalCourses, Icons.library_books, Colors.orange),
              _StatItem('Enrollments', _totalEnrollments, Icons.assignment_turned_in, Colors.green),
              _StatItem('Certificates', _totalCertificates, Icons.workspace_premium, const Color(0xFFD4AF37)),
            ]),
            const SizedBox(height: 20),

            // ── Finance ───────────────────────────────
            _sectionHeader('Finance'),
            _statGrid([
              _StatItem('Revenue', _totalRevenue.toStringAsFixed(0), Icons.attach_money, Colors.green, prefix: '₦'),
              _StatItem('Active Loans', _activeLoans, Icons.account_balance, Colors.amber),
              _StatItem('Total Loaned', _totalLoaned.toStringAsFixed(0), Icons.money_off, Colors.orange, prefix: '₦'),
            ]),
            const SizedBox(height: 20),

            // ── Support ───────────────────────────────
            _sectionHeader('Support'),
            _statGrid([
              _StatItem('Open Tickets', _openTickets, Icons.support_agent, Colors.red),
              _StatItem('Resolved', _resolvedTickets, Icons.check_circle, Colors.green),
            ]),
            const SizedBox(height: 20),

            // ── Monthly Signups Chart ──────────────────
            _sectionHeader('Monthly New Users'),
            _BarChart(
              data: _monthlySignups.map((e) => _BarData(e['month'] as String, (e['count'] as int).toDouble())).toList(),
              color: Colors.blue,
            ),
            const SizedBox(height: 20),

            // ── Monthly Revenue Chart ──────────────────
            _sectionHeader('Monthly Revenue (₦)'),
            _BarChart(
              data: _monthlyRevenue.map((e) => _BarData(e['month'] as String, (e['amount'] as double))).toList(),
              color: Colors.green,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _statGrid(List<_StatItem> items) {
    return Row(
      children: items
          .map((item) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C2F),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: item.color.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(item.icon, color: item.color, size: 22),
                      const SizedBox(height: 8),
                      Text(
                        '${item.prefix}${item.value}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _StatItem {
  final String label;
  final dynamic value;
  final IconData icon;
  final Color color;
  final String prefix;

  _StatItem(this.label, this.value, this.icon, this.color, {this.prefix = ''});
}

class _BarData {
  final String label;
  final double value;
  _BarData(this.label, this.value);
}

class _BarChart extends StatelessWidget {
  final List<_BarData> data;
  final Color color;

  const _BarChart({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.fold(0.0, (m, d) => d.value > m ? d.value : m);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: data.map((d) {
              final height = maxVal > 0 ? (d.value / maxVal) * 80 : 4.0;
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    d.value >= 1000
                        ? '${(d.value / 1000).toStringAsFixed(1)}k'
                        : d.value.toStringAsFixed(0),
                    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    width: 28,
                    height: height.clamp(4.0, 80.0),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(d.label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
