import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import 'student/course_detail_page.dart';

class SavedCoursesPage extends StatefulWidget {
  const SavedCoursesPage({super.key});

  @override
  State<SavedCoursesPage> createState() => _SavedCoursesPageState();
}

class _SavedCoursesPageState extends State<SavedCoursesPage> {
  List<String> _savedCourseIds = [];
  Map<String, CourseModel> _courseData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCourses();
  }

  Future<void> _loadSavedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_courses') ?? [];
    setState(() => _savedCourseIds = saved);

    // Fetch actual course data for all saved IDs
    if (saved.isNotEmpty) {
      await _fetchCourseData(saved);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCourseData(List<String> ids) async {
    try {
      final Map<String, CourseModel> fetched = {};
      // Firestore whereIn supports up to 30 items per query
      const chunkSize = 30;
      for (var i = 0; i < ids.length; i += chunkSize) {
        final chunk = ids.skip(i).take(chunkSize).toList();
        final snapshot = await FirebaseFirestore.instance
            .collection('courses')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final doc in snapshot.docs) {
          fetched[doc.id] =
              CourseModel.fromFirestore(doc);
        }
      }
      if (mounted) setState(() => _courseData = fetched);
    } catch (e) {
      debugPrint('Error fetching saved course data: $e');
    }
  }

  Future<void> _removeCourse(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    _savedCourseIds.remove(courseId);
    await prefs.setStringList('saved_courses', _savedCourseIds);
    setState(() {});
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Course removed from saved'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Courses',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (_savedCourseIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _clearAllSaved,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _savedCourseIds.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _savedCourseIds.length,
                  itemBuilder: (context, index) {
                    return _buildSavedCourseCard(_savedCourseIds[index]);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Saved Courses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Courses you bookmark will appear here',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCourseCard(String courseId) {
    final course = _courseData[courseId];
    final isFree = course == null ? false : course.priceEmc == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E2D4A), width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (course != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CourseDetailPage(course: course),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Course thumbnail
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A2744),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: course?.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            course!.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.school,
                              color: Colors.white24,
                              size: 32,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.school,
                          color: Colors.white24,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                // Course info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course?.title ?? 'Loading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (course != null) ...
                        [
                          const SizedBox(height: 4),
                          Text(
                            course.instructor,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: (isFree
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFFBBF24))
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isFree
                                      ? 'FREE'
                                      : '${course.priceEmc} EMC',
                                  style: TextStyle(
                                    color: isFree
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFFBBF24),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Bookmarked',
                                  style: TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ]
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Course data unavailable',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Remove bookmark
                IconButton(
                  icon: const Icon(Icons.bookmark,
                      color: Color(0xFF3B82F6)),
                  onPressed: () => _removeCourse(courseId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _clearAllSaved() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text(
          'Clear All Saved Courses?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will remove all bookmarked courses. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_courses');
      setState(() => _savedCourseIds = []);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All saved courses cleared'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Helper class for managing bookmarks
class BookmarkService {
  static Future<bool> isBookmarked(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_courses') ?? [];
    return saved.contains(courseId);
  }

  static Future<void> toggleBookmark(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_courses') ?? [];
    
    if (saved.contains(courseId)) {
      saved.remove(courseId);
    } else {
      saved.add(courseId);
    }
    
    await prefs.setStringList('saved_courses', saved);
  }

  static Future<List<String>> getSavedCourses() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('saved_courses') ?? [];
  }
}
