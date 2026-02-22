import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../models/content_model.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../course_enrollment_page.dart';
import 'content_viewer_page.dart';

class CourseDetailPage extends StatefulWidget {
  final CourseModel course;

  const CourseDetailPage({super.key, required this.course});

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ContentService _contentService = ContentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isEnrolled(AuthService auth) {
    return auth.userModel?.enrolledCourses.contains(widget.course.id) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final enrolled = _isEnrolled(auth);
    final course = widget.course;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF0B1120),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (enrolled)
                Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '✓ Enrolled',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail or gradient
                  if (course.thumbnailUrl != null &&
                      course.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      course.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _gradientPlaceholder(course),
                    )
                  else
                    _gradientPlaceholder(course),
                  // Dark overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Category badge + title overlay at bottom
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CategoryBadge(category: course.category),
                        const SizedBox(height: 8),
                        Text(
                          course.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats Row ───────────────────────────────────────────
                  _buildStatsRow(course),
                  const SizedBox(height: 16),

                  // ── Instructor ──────────────────────────────────────────
                  _buildInstructorRow(course),
                  const SizedBox(height: 20),

                  // ── Tab Bar ─────────────────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111C2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF3B82F6),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Modules'),
                        Tab(text: 'Materials'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Tab Content ─────────────────────────────────────────
                  SizedBox(
                    height: 480,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _OverviewTab(course: course),
                        _ModulesTab(course: course),
                        _MaterialsTab(
                          course: course,
                          enrolled: enrolled,
                          contentService: _contentService,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // bottom padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Enroll / Continue FAB ─────────────────────────────────────────────
      bottomNavigationBar: _buildBottomBar(context, auth, enrolled, course),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _gradientPlaceholder(CourseModel course) {
    final gradients = [
      [const Color(0xFF1A2744), const Color(0xFF3B82F6)],
      [const Color(0xFF1A1A2E), const Color(0xFF7C3AED)],
      [const Color(0xFF0F2C1D), const Color(0xFF10B981)],
      [const Color(0xFF2D1B00), const Color(0xFFF59E0B)],
    ];
    final idx = course.title.length % gradients.length;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients[idx],
        ),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(course.category),
          size: 72,
          color: Colors.white.withOpacity(0.25),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'technology':
      case 'blockchain':
        return Icons.memory;
      case 'finance':
        return Icons.attach_money;
      case 'business':
        return Icons.business_center;
      case 'diploma':
        return Icons.school;
      default:
        return Icons.menu_book;
    }
  }

  Widget _buildStatsRow(CourseModel course) {
    return Row(
      children: [
        _StatChip(
          icon: Icons.access_time,
          label: '${course.duration}h',
          color: const Color(0xFF3B82F6),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: Icons.people_outline,
          label: '${course.studentsEnrolled} students',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        _StatChip(
          icon: course.priceEmc == 0 ? Icons.lock_open : Icons.token,
          label: course.priceEmc == 0 ? 'Free' : '${course.priceEmc} EMC',
          color: course.priceEmc == 0
              ? const Color(0xFF10B981)
              : const Color(0xFFF59E0B),
        ),
        if (course.modules.isNotEmpty) ...[
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.list_alt,
            label: '${course.modules.length} modules',
            color: const Color(0xFF8B5CF6),
          ),
        ],
      ],
    );
  }

  Widget _buildInstructorRow(CourseModel course) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2A3F5F).withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF3B82F6),
            child: Text(
              course.instructor.isNotEmpty
                  ? course.instructor[0].toUpperCase()
                  : 'L',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.instructor,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const Text(
                  'Course Instructor',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: const Color(0xFF3B82F6).withOpacity(0.3)),
            ),
            child: const Text(
              'Lecturer',
              style: TextStyle(
                color: Color(0xFF3B82F6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
      BuildContext context, AuthService auth, bool enrolled, CourseModel course) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120),
        border: Border(
            top: BorderSide(color: Color(0xFF1E3A5F), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (!auth.isAuthenticated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please login to enroll in courses.')),
                  );
                  return;
                }
                if (enrolled) {
                  // Jump to Materials tab
                  _tabController.animateTo(2);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CourseEnrollmentPage(course: course),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: enrolled
                    ? const Color(0xFF10B981)
                    : const Color(0xFF3B82F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    enrolled ? Icons.play_circle_fill : Icons.school,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    enrolled
                        ? 'Continue Learning'
                        : (course.priceEmc == 0
                            ? 'Enroll for Free'
                            : 'Enroll for ${course.priceEmc} EMC'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Overview
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final CourseModel course;
  const _OverviewTab({required this.course});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Course',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            course.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14.5,
              height: 1.65,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'What You\'ll Learn',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            course.modules.take(4).length,
            (i) => _LearnItem(text: course.modules[i]),
          ),
          if (course.modules.isEmpty)
            const Text(
              'Course content will be updated soon.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          const SizedBox(height: 24),
          // Course info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF111C2F),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: const Color(0xFF2A3F5F).withOpacity(0.5)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: course.category,
                ),
                const Divider(color: Color(0xFF1E3A5F), height: 20),
                _InfoRow(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: '${course.duration} hours',
                ),
                const Divider(color: Color(0xFF1E3A5F), height: 20),
                _InfoRow(
                  icon: Icons.list_alt,
                  label: 'Modules',
                  value: '${course.modules.length}',
                ),
                const Divider(color: Color(0xFF1E3A5F), height: 20),
                _InfoRow(
                  icon: Icons.people_outline,
                  label: 'Enrolled',
                  value: '${course.studentsEnrolled} students',
                ),
                const Divider(color: Color(0xFF1E3A5F), height: 20),
                _InfoRow(
                  icon: Icons.token,
                  label: 'Price',
                  value: course.priceEmc == 0
                      ? 'Free'
                      : '${course.priceEmc} EMC',
                  valueColor: course.priceEmc == 0
                      ? Colors.greenAccent
                      : const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Modules
// ─────────────────────────────────────────────────────────────────────────────

class _ModulesTab extends StatelessWidget {
  final CourseModel course;
  const _ModulesTab({required this.course});

  @override
  Widget build(BuildContext context) {
    if (course.modules.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: Colors.white24, size: 48),
            SizedBox(height: 12),
            Text(
              'No modules listed yet.',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 12),
      itemCount: course.modules.length,
      itemBuilder: (context, index) {
        final module = course.modules[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF2A3F5F).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.4)),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  module,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
              const Icon(Icons.play_circle_outline,
                  color: Colors.white24, size: 20),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab: Materials (live Firestore stream)
// ─────────────────────────────────────────────────────────────────────────────

class _MaterialsTab extends StatelessWidget {
  final CourseModel course;
  final bool enrolled;
  final ContentService contentService;

  const _MaterialsTab({
    required this.course,
    required this.enrolled,
    required this.contentService,
  });

  @override
  Widget build(BuildContext context) {
    if (!enrolled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111C2F),
                shape: BoxShape.circle,
                border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.3)),
              ),
              child: const Icon(Icons.lock_outlined,
                  color: Color(0xFF3B82F6), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enroll to access materials',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Course materials are available after enrollment.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<ContentModel>>(
      stream: contentService.getContentByCourse(course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading materials: ${snapshot.error}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }
        final materials = snapshot.data ?? [];
        if (materials.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, color: Colors.white24, size: 48),
                SizedBox(height: 12),
                Text(
                  'No materials uploaded yet.',
                  style: TextStyle(color: Colors.white38),
                ),
                SizedBox(height: 4),
                Text(
                  'Check back soon!',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 12),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final item = materials[index];
            return _ContentTile(content: item);
          },
        );
      },
    );
  }
}

class _ContentTile extends StatelessWidget {
  final ContentModel content;
  const _ContentTile({required this.content});

  IconData get _icon {
    switch (content.type) {
      case ContentType.video:
        return Icons.play_circle_fill;
      case ContentType.document:
        return Icons.picture_as_pdf;
      case ContentType.presentation:
        return Icons.slideshow;
      case ContentType.link:
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get _iconColor {
    switch (content.type) {
      case ContentType.video:
        return const Color(0xFFEF4444);
      case ContentType.document:
        return const Color(0xFFF59E0B);
      case ContentType.presentation:
        return const Color(0xFF8B5CF6);
      case ContentType.link:
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String get _typeLabel {
    switch (content.type) {
      case ContentType.video:
        return 'Video';
      case ContentType.document:
        return 'Document';
      case ContentType.presentation:
        return 'Slides';
      case ContentType.link:
        return 'Link';
      default:
        return 'File';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContentViewerPage(content: content),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF111C2F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF2A3F5F).withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(_icon, color: _iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _iconColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _typeLabel,
                          style: TextStyle(
                            color: _iconColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${content.viewCount} views',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String category;
  const _CategoryBadge({required this.category});

  Color get _color {
    switch (category.toLowerCase()) {
      case 'premium':
        return const Color(0xFFF59E0B);
      case 'freemium':
        return const Color(0xFF10B981);
      case 'diploma':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnItem extends StatelessWidget {
  final String text;
  const _LearnItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
