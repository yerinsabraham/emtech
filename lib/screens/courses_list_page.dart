import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';
import 'student/course_detail_page.dart';

class CoursesListPage extends StatefulWidget {
  final String? initialCategory; // 'Premium', 'Freemium', or null for all
  
  const CoursesListPage({super.key, this.initialCategory});

  @override
  State<CoursesListPage> createState() => _CoursesListPageState();
}

class _CoursesListPageState extends State<CoursesListPage> {
  late String _selectedCategory;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_courses') ?? [];
    if (mounted) setState(() => _bookmarkedIds = Set<String>.from(saved));
  }

  Future<void> _toggleBookmark(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('saved_courses') ?? [];
    final isNowBookmarked = !saved.contains(courseId);
    if (isNowBookmarked) {
      saved.add(courseId);
    } else {
      saved.remove(courseId);
    }
    await prefs.setStringList('saved_courses', saved);
    if (mounted) {
      setState(() => _bookmarkedIds = Set<String>.from(saved));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isNowBookmarked
            ? 'Course saved to bookmarks'
            : 'Course removed from bookmarks'),
        backgroundColor: isNowBookmarked
            ? const Color(0xFF3B82F6)
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search courses...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon:
                              const Icon(Icons.close, color: Colors.white54),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value.trim().toLowerCase());
                },
              )
            : Text(
                widget.initialCategory != null
                    ? '${widget.initialCategory} Courses'
                    : 'All Courses',
                style: const TextStyle(color: Colors.white),
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.search_off : Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 45,
            margin: const EdgeInsets.symmetric(vertical: 18),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: [
                _buildCategoryChip('All', 'All'),
                _buildCategoryChip('Premium', 'Premium'),
                _buildCategoryChip('Free', 'Freemium'),
                _buildCategoryChip('Diploma', 'Diploma'),
              ],
            ),
          ),

          // Courses List
          Expanded(
            child: StreamBuilder<List<CourseModel>>(
              stream: firestoreService.getCourses(
                category: _selectedCategory == 'All' ? null : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.school_outlined,
                          color: Colors.white24,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No courses available',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }
                
                // Apply search filter
                final allCourses = snapshot.data!;
                final courses = _searchQuery.isEmpty
                    ? allCourses
                    : allCourses.where((c) {
                        return c.title
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            c.description
                                .toLowerCase()
                                .contains(_searchQuery) ||
                            c.instructor
                                .toLowerCase()
                                .contains(_searchQuery);
                      }).toList();

                if (courses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          color: Colors.white24,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No results for "$_searchQuery"',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    return _buildCourseCard(courses[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = value;
          });
        },
        backgroundColor: const Color(0xFF111C2F),
        selectedColor: const Color(0xFF3B82F6),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFF1E2D4A),
        ),
      ),
    );
  }

  Widget _buildCourseCard(CourseModel course) {
    final isFree = course.priceEmc == 0;
    
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
          onTap: () => _showCourseDetails(course),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              if (course.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: const Color(0xFF1E2D4A),
                    child: Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.school,
                            color: Colors.white24,
                            size: 48,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Price
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isFree 
                                ? const Color(0xFF10B981).withOpacity(0.2)
                                : const Color(0xFFFBBF24).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFree ? 'FREE' : 'PREMIUM',
                            style: TextStyle(
                              color: isFree ? const Color(0xFF10B981) : const Color(0xFFFBBF24),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!isFree)
                          Row(
                            children: [
                              const Icon(
                                Icons.monetization_on,
                                color: Color(0xFFFBBF24),
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${course.priceEmc} EMC',
                                style: const TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    Text(
                      course.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      course.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),

                    // Instructor
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 12,
                          backgroundColor: Color(0xFF3B82F6),
                          child: Icon(Icons.person, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          course.instructor,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Meta Info
                    Row(
                      children: [
                        _buildMetaItem(
                          Icons.access_time,
                          '${course.duration}h',
                        ),
                        const SizedBox(width: 16),
                        _buildMetaItem(
                          Icons.people_outline,
                          '${course.studentsEnrolled}',
                        ),
                        const SizedBox(width: 16),
                        _buildMetaItem(
                          Icons.layers_outlined,
                          '${course.modules.length} modules',
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => _toggleBookmark(course.id),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              _bookmarkedIds.contains(course.id)
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: _bookmarkedIds.contains(course.id)
                                  ? const Color(0xFF3B82F6)
                                  : Colors.white24,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  void _showCourseDetails(CourseModel course) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailPage(course: course),
      ),
    );
  }
}
