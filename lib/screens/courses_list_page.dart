import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'course_enrollment_page.dart';

class CoursesListPage extends StatefulWidget {
  final String? initialCategory; // 'Premium', 'Freemium', or null for all
  
  const CoursesListPage({super.key, this.initialCategory});

  @override
  State<CoursesListPage> createState() => _CoursesListPageState();
}

class _CoursesListPageState extends State<CoursesListPage> {
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.watch<FirestoreService>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: Text(
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
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search feature coming soon!')),
              );
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
                
                final courses = snapshot.data!;
                
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111C2F),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Title
            Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Instructor
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF3B82F6),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.instructor,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Course Instructor',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'About this course',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              course.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // Modules
            if (course.modules.isNotEmpty) ...[
              const Text(
                'Course Modules',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...course.modules.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
            ],

            // Enroll Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final authService = context.read<AuthService>();
                  if (!authService.isAuthenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login to enroll in courses'),
                      ),
                    );
                  } else {
                    // Navigate to CourseEnrollmentPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseEnrollmentPage(course: course),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  course.priceEmc == 0 
                      ? 'Enroll for Free' 
                      : 'Enroll for ${course.priceEmc} EMC',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
