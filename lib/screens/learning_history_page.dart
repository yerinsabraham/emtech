import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/course_model.dart';
import '../services/auth_service.dart';
import 'student/course_detail_page.dart';

class LearningHistoryPage extends StatefulWidget {
  const LearningHistoryPage({super.key});

  @override
  State<LearningHistoryPage> createState() => _LearningHistoryPageState();
}

class _LearningHistoryPageState extends State<LearningHistoryPage> {
  Map<String, CourseModel> _courseData = {};

  Future<void> _fetchCourseData(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final Map<String, CourseModel> fetched = {};
      const chunkSize = 30;
      for (var i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.skip(i).take(chunkSize).toList();
        final snap = await FirebaseFirestore.instance
            .collection('courses')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          fetched[doc.id] = CourseModel.fromFirestore(doc);
        }
      }
      if (mounted) setState(() => _courseData = fetched);
    } catch (e) {
      debugPrint('LearningHistoryPage: course fetch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthService>().currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF080C14),
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text('Please log in to view learning history',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: _buildAppBar(context),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('enrollments')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('enrolledAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: Colors.red)),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text('No courses enrolled yet',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Enroll in a course to start learning',
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          final enrollments = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'id': d.id,
              'courseId': data['courseId'] ?? '',
              'courseName': data['courseName'] ?? 'Unknown Course',
              'progress': (data['progress'] as num?)?.toInt() ?? 0,
              'completedModules':
                  (data['completedModules'] as num?)?.toInt() ?? 0,
              'totalModules': (data['totalModules'] as num?)?.toInt() ?? 0,
              'enrolledAt': data['enrolledAt'] is Timestamp
                  ? (data['enrolledAt'] as Timestamp).toDate()
                  : DateTime.now(),
              'lastAccessedAt': data['lastAccessedAt'] is Timestamp
                  ? (data['lastAccessedAt'] as Timestamp).toDate()
                  : null,
            };
          }).toList();

          // Trigger secondary course fetch for tap navigation + thumbnail
          final newIds = enrollments
              .map((e) => e['courseId'] as String)
              .where((id) => id.isNotEmpty && !_courseData.containsKey(id))
              .toList();
          if (newIds.isNotEmpty) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _fetchCourseData(newIds));
          }

          final completedCount =
              enrollments.where((e) => (e['progress'] as int) >= 100).length;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // Stats Overview
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111C2F),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                        '${enrollments.length}', 'Enrolled', Icons.school),
                    _buildStat('$completedCount', 'Completed',
                        Icons.check_circle),
                    _buildStat('—', 'Total Time', Icons.access_time),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Recent Activity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // History cards
              ...enrollments
                  .map((item) => _buildHistoryCard(context, item)),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0B1120),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Learning History',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF3B82F6), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item) {
    final progress = item['progress'] as int;
    final isCompleted = progress >= 100;
    final completedModules = item['completedModules'] as int;
    final totalModules = item['totalModules'] as int;
    final lastAccessed = item['lastAccessedAt'] as DateTime?;
    final enrolledAt = item['enrolledAt'] as DateTime;
    final courseId = item['courseId'] as String;
    final courseName = item['courseName'] as String;
    final cachedCourse = _courseData[courseId];

    String lastAccessedLabel;
    if (lastAccessed != null) {
      final diff = DateTime.now().difference(lastAccessed);
      if (diff.inMinutes < 60) {
        lastAccessedLabel = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        lastAccessedLabel = '${diff.inHours}h ago';
      } else {
        lastAccessedLabel = DateFormat('MMM d').format(lastAccessed);
      }
    } else {
      lastAccessedLabel = 'Enrolled ${DateFormat('MMM d').format(enrolledAt)}';
    }

    return GestureDetector(
      onTap: () async {
        CourseModel? course = cachedCourse;
        if (course == null && courseId.isNotEmpty) {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('courses')
                .doc(courseId)
                .get();
            if (doc.exists) {
              course = CourseModel.fromFirestore(doc);
              if (mounted) setState(() => _courseData[courseId] = course!);
            }
          } catch (_) {}
        }
        if (course != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => CourseDetailPage(course: course!)),
          );
        }
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  courseName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF22C55E).withOpacity(0.2)
                      : const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    color: isCompleted
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF3B82F6),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: const Color(0xFF1E2D4A),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF3B82F6),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$progress%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalModules > 0
                    ? '$completedModules/$totalModules lessons'
                    : 'Enrolled',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
              Text(
                'Last: $lastAccessedLabel',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}
