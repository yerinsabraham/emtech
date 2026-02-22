import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/course_model.dart';
import '../../services/auth_service.dart';
import 'lecturer_certificates_tab.dart';
import 'phase2_widgets.dart';

class LecturerDashboardPage extends StatefulWidget {
  const LecturerDashboardPage({super.key});

  @override
  State<LecturerDashboardPage> createState() => _LecturerDashboardPageState();
}

class _LecturerDashboardPageState extends State<LecturerDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Lecturer Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: 'My Courses'),
            Tab(text: 'Live Classes'),
            Tab(text: 'Assignments'),
            Tab(text: 'Exams'),
            Tab(text: 'Content'),
            Tab(text: 'Students'),
            Tab(text: 'Certificates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _MyCoursesTab(),
          _LiveClassTab(),
          AssignmentsTab(),
          ExamsTab(),
          ContentTab(),
          _StudentsTab(),
          LecturerCertificatesTab(),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget? _buildFAB() {
    switch (_tabController.index) {
      case 0: // My Courses
        return FloatingActionButton.extended(
          onPressed: () => _showCreateCourseDialog(context),
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.add),
          label: const Text('Create Course'),
        );
      case 1: // Live Classes
        return FloatingActionButton.extended(
          onPressed: () => _showCreateLiveClassDialog(context),
          backgroundColor: Colors.red,
          icon: const Icon(Icons.video_call),
          label: const Text('Schedule Live'),
        );
      case 2: // Assignments
        return FloatingActionButton.extended(
          onPressed: () => _showCreateAssignmentDialog(context),
          backgroundColor: Colors.orange,
          icon: const Icon(Icons.assignment),
          label: const Text('New Assignment'),
        );
      case 3: // Exams
        return FloatingActionButton.extended(
          onPressed: () => _showCreateExamDialog(context),
          backgroundColor: Colors.purple,
          icon: const Icon(Icons.quiz),
          label: const Text('New Exam'),
        );
      case 4: // Content
        return FloatingActionButton.extended(
          onPressed: () => _showUploadContentDialog(context),
          backgroundColor: Colors.green,
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload Content'),
        );
      default:
        return null;
    }
  }

  void _showCreateCourseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateCourseDialog(),
    );
  }

  void _showCreateLiveClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateLiveClassDialog(),
    );
  }

  void _showCreateAssignmentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateAssignmentDialog(),
    );
  }

  void _showCreateExamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateExamDialog(),
    );
  }

  void _showUploadContentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UploadContentDialog(),
    );
  }
}

// ─────────────────────────────────────────────
// MY COURSES TAB
// ─────────────────────────────────────────────
class _MyCoursesTab extends StatelessWidget {
  const _MyCoursesTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please login to view your courses',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('courses')
          .where('instructorId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final courses = snapshot.data?.docs ?? [];

        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 64,
                  color: Colors.white30,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No courses yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first course using the + button below',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final courseData = courses[index].data() as Map<String, dynamic>;
            final course = CourseModel.fromMap(courseData, courses[index].id);

            return _CourseCard(course: course);
          },
        );
      },
    );
  }
}

class _CourseCard extends StatelessWidget {
  final CourseModel course;

  const _CourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2940), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              course.thumbnailUrl ?? 'https://via.placeholder.com/400x300?text=Course',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 160,
                color: const Color(0xFF1A2940),
                child: const Icon(
                  Icons.school,
                  size: 48,
                  color: Colors.white30,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  course.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          '${course.duration}h duration',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: Text(
                        '${course.priceEmc.toStringAsFixed(0)} EMC',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showEditCourseDialog(context, course),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF1A2940)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showCourseStudents(context, course),
                        icon: const Icon(Icons.people, size: 16),
                        label: const Text('Students'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF1A2940)),
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
    );
  }
}

// ─────────────────────────────────────────────
// COURSE EDIT & STUDENTS HELPERS
// ─────────────────────────────────────────────

void _showEditCourseDialog(BuildContext context, CourseModel course) {
  showDialog(
    context: context,
    builder: (_) => _EditCourseDialog(course: course),
  );
}

class _EditCourseDialog extends StatefulWidget {
  final CourseModel course;
  const _EditCourseDialog({required this.course});

  @override
  State<_EditCourseDialog> createState() => _EditCourseDialogState();
}

class _EditCourseDialogState extends State<_EditCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  late String _selectedCategory;
  bool _loading = false;

  final List<String> _categories = [
    'Design', 'Development', 'Business', 'Marketing',
    'Data Science', 'Engineering', 'Health', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.course.title);
    _descCtrl = TextEditingController(text: widget.course.description);
    _priceCtrl =
        TextEditingController(text: widget.course.priceEmc.toString());
    _imageCtrl =
        TextEditingController(text: widget.course.thumbnailUrl ?? '');
    _selectedCategory = _categories.contains(widget.course.category)
        ? widget.course.category
        : _categories.first;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .update({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'priceEmc': int.tryParse(_priceCtrl.text) ?? widget.course.priceEmc,
        'thumbnailUrl': _imageCtrl.text.trim().isEmpty
            ? null
            : _imageCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Course updated!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111C2F),
      title: const Text('Edit Course', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _field(_titleCtrl, 'Title', Icons.title,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _field(_descCtrl, 'Description', Icons.description,
                  maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: _dec('Category', Icons.category),
                dropdownColor: const Color(0xFF0B1120),
                style: const TextStyle(color: Colors.white),
                items: _categories
                    .map((c) =>
                        DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 12),
              _field(_priceCtrl, 'Price (EMC)', Icons.monetization_on,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'Enter a number' : null),
              const SizedBox(height: 12),
              _field(_imageCtrl, 'Thumbnail URL (optional)', Icons.image),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save'),
        ),
      ],
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0B1120),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1A2940))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF1A2940))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: _dec(label, icon),
        validator: validator,
      );
}

void _showCourseStudents(BuildContext context, CourseModel course) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1120),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.3,
      expand: false,
      builder: (ctx, controller) {
        return Column(children: [
          Container(
            margin:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.people, color: Colors.blue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const Text('Enrolled Students',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    ]),
              ),
            ]),
          ),
          const Divider(color: Color(0xFF1A2940), height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('enrollments')
                  .where('courseId', isEqualTo: course.id)
                  .orderBy('enrolledAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off,
                              size: 48, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('No students enrolled yet',
                              style: TextStyle(color: Colors.white54)),
                        ]),
                  );
                }
                return ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data =
                        docs[i].data() as Map<String, dynamic>;
                    final userId =
                        data['userId'] as String? ?? '';
                    final progress =
                        (data['progress'] as num?)?.toInt() ?? 0;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnap) {
                        final ud = userSnap.data?.data()
                            as Map<String, dynamic>?;
                        final name = ud?['name'] ?? 'Student';
                        final email = ud?['email'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF111C2F),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF1A2940)),
                          ),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor:
                                  const Color(0xFF1A2940),
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.w600)),
                                    Text(email,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ]),
                            ),
                            Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  const Text('Progress',
                                      style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10)),
                                  Text('$progress%',
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.bold)),
                                ]),
                          ]),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ]);
      },
    ),
  );
}

// ─────────────────────────────────────────────
// LIVE CLASS TAB
// ─────────────────────────────────────────────
class _LiveClassTab extends StatelessWidget {
  const _LiveClassTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.userModel;

    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please login to manage live classes',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('liveClasses')
          .where('instructorId', isEqualTo: currentUser.uid)
          .orderBy('scheduledAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final liveClasses = snapshot.data?.docs ?? [];

        if (liveClasses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111C2F),
                    borderRadius: BorderRadius.circular(60),
                    border: Border.all(color: const Color(0xFF1A2940), width: 2),
                  ),
                  child: const Icon(
                    Icons.video_call,
                    size: 64,
                    color: Colors.white30,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Live Classes Yet',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your first live class using the + button',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: liveClasses.length,
          itemBuilder: (context, index) {
            final liveClassData = liveClasses[index].data() as Map<String, dynamic>;
            final liveClassId = liveClasses[index].id;
            
            return _LiveClassCard(
              liveClassData: liveClassData,
              liveClassId: liveClassId,
            );
          },
        );
      },
    );
  }
}

class _LiveClassCard extends StatelessWidget {
  final Map<String, dynamic> liveClassData;
  final String liveClassId;

  const _LiveClassCard({
    required this.liveClassData,
    required this.liveClassId,
  });

  @override
  Widget build(BuildContext context) {
    final status = liveClassData['status'] ?? 'scheduled';
    final scheduledAt = DateTime.parse(liveClassData['scheduledAt']);
    final title = liveClassData['title'] ?? '';
    final courseName = liveClassData['courseName'] ?? '';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'live':
        statusColor = Colors.red;
        statusIcon = Icons.circle;
        statusText = 'LIVE NOW';
        break;
      case 'ended':
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        statusText = 'ENDED';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'SCHEDULED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2940), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            courseName,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                _formatDateTime(scheduledAt),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (status == 'scheduled') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goLive(context, liveClassId),
                    icon: const Icon(Icons.play_circle, size: 18),
                    label: const Text('Go Live'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteLiveClass(context, liveClassId),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $hour:$minute $period';
  }

  Future<void> _goLive(BuildContext context, String liveClassId) async {
    try {
      await FirebaseFirestore.instance
          .collection('liveClasses')
          .doc(liveClassId)
          .update({
        'status': 'live',
        'startedAt': DateTime.now().toIso8601String(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live class is now broadcasting!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteLiveClass(BuildContext context, String liveClassId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111C2F),
        title: const Text(
          'Delete Live Class',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this live class?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('liveClasses')
            .doc(liveClassId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Live class deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// ─────────────────────────────────────────────
// STUDENTS TAB
// ─────────────────────────────────────────────
class _StudentsTab extends StatefulWidget {
  const _StudentsTab();

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  String? _selectedCourseId;
  String? _selectedCourseName;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().userModel?.uid ?? '';
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .where('instructorId', isEqualTo: uid)
              .snapshots(),
          builder: (context, snap) {
            final courses = snap.data?.docs ?? [];
            if (courses.isEmpty && snap.connectionState != ConnectionState.waiting) {
              return const Text('No courses yet',
                  style: TextStyle(color: Colors.white54));
            }
            return DropdownButtonFormField<String>(
              value: _selectedCourseId,
              decoration: InputDecoration(
                labelText: 'Select Course',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon:
                    const Icon(Icons.school, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0B1120),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF1A2940))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: Color(0xFF1A2940))),
              ),
              dropdownColor: const Color(0xFF111C2F),
              style: const TextStyle(color: Colors.white),
              hint: const Text('Choose a course to view students',
                  style: TextStyle(color: Colors.white54)),
              items: courses.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                    value: doc.id, child: Text(d['title'] ?? ''));
              }).toList(),
              onChanged: (v) {
                if (v != null) {
                  final doc =
                      courses.firstWhere((d) => d.id == v);
                  setState(() {
                    _selectedCourseId = v;
                    _selectedCourseName =
                        (doc.data() as Map<String, dynamic>)['title'];
                  });
                }
              },
            );
          },
        ),
      ),
      if (_selectedCourseId != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            const Icon(Icons.people, size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Text('Students in $_selectedCourseName',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
          ]),
        ),
      Expanded(
        child: _selectedCourseId == null
            ? Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.people_outline,
                          size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('Select a course above to view students',
                          style: TextStyle(
                              color: Colors.white54, fontSize: 14)),
                    ]),
              )
            : StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enrollments')
                    .where('courseId', isEqualTo: _selectedCourseId)
                    .orderBy('enrolledAt', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final docs = snap.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off,
                                size: 48, color: Colors.white24),
                            SizedBox(height: 12),
                            Text('No students enrolled yet',
                                style:
                                    TextStyle(color: Colors.white54)),
                          ]),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, i) =>
                        _StudentEnrollmentTile(enrollment: docs[i]),
                  );
                },
              ),
      ),
    ]);
  }
}

class _StudentEnrollmentTile extends StatelessWidget {
  final QueryDocumentSnapshot enrollment;
  const _StudentEnrollmentTile({required this.enrollment});

  @override
  Widget build(BuildContext context) {
    final data = enrollment.data() as Map<String, dynamic>;
    final userId = data['userId'] as String? ?? '';
    final progress = (data['progress'] as num?)?.toInt() ?? 0;
    final enrolledAt = data['enrolledAt'] is Timestamp
        ? (data['enrolledAt'] as Timestamp).toDate()
        : DateTime.now();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),
      builder: (context, snap) {
        final ud = snap.data?.data() as Map<String, dynamic>?;
        final name = ud?['name'] ?? 'Student';
        final email = ud?['email'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111C2F),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF1A2940)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF1A2940),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    Text(email,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: const Color(0xFF1A2940),
                            valueColor: const AlwaysStoppedAnimation(
                                Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$progress%',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                    ]),
                  ]),
            ),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(DateFormat('MMM d').format(enrolledAt),
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.4)),
                ),
                child: const Text('Active',
                    style:
                        TextStyle(color: Colors.green, fontSize: 10)),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// CREATE COURSE DIALOG
// ─────────────────────────────────────────────
class _CreateCourseDialog extends StatefulWidget {
  const _CreateCourseDialog();

  @override
  State<_CreateCourseDialog> createState() => _CreateCourseDialogState();
}

class _CreateCourseDialogState extends State<_CreateCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = 'Design';
  bool _isLoading = false;

  final List<String> _categories = [
    'Design',
    'Development',
    'Business',
    'Marketing',
    'Data Science',
    'Engineering',
    'Health',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _createCourse() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    final userModel = authService.userModel;

    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to create a course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final courseData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'priceEmc': double.parse(_priceController.text).toInt(),
        'thumbnailUrl': _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        'instructor': userModel.name,
        'instructorId': userModel.uid,
        'modules': <String>[],
        'duration': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('courses').add(courseData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Course created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF111C2F),
      title: const Text(
        'Create New Course',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Course Title',
                icon: Icons.book,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter course title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.category, color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF0B1120),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF1A2940)),
                  ),
                ),
                dropdownColor: const Color(0xFF0B1120),
                style: const TextStyle(color: Colors.white),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _priceController,
                label: 'Price (EMC)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _imageUrlController,
                label: 'Image URL (optional)',
                icon: Icons.image,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCourse,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0B1120),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A2940)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A2940)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

// ─────────────────────────────────────────────
// CREATE LIVE CLASS DIALOG
// ─────────────────────────────────────────────
class _CreateLiveClassDialog extends StatefulWidget {
  const _CreateLiveClassDialog();

  @override
  State<_CreateLiveClassDialog> createState() => _CreateLiveClassDialogState();
}

class _CreateLiveClassDialogState extends State<_CreateLiveClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _youtubeUrlController = TextEditingController();
  String? _selectedCourseId;
  String? _selectedCourseName;
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<void> _createLiveClass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a course'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final userModel = authService.userModel;

    if (userModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to create a live class'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Extract YouTube video ID
      final youtubeUrl = _youtubeUrlController.text.trim();
      final videoId = _extractYouTubeVideoId(youtubeUrl);

      final liveClassData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'instructorId': userModel.uid,
        'instructorName': userModel.name,
        'courseId': _selectedCourseId!,
        'courseName': _selectedCourseName!,
        'youtubeUrl': youtubeUrl,
        'youtubeVideoId': videoId,
        'scheduledAt': _selectedDateTime.toIso8601String(),
        'status': 'scheduled',
        'viewerCount': 0,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance.collection('liveClasses').add(liveClassData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live class scheduled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue,
              surface: Color(0xFF111C2F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Colors.blue,
                surface: Color(0xFF111C2F),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;

    return AlertDialog(
      backgroundColor: const Color(0xFF111C2F),
      title: const Text(
        'Schedule Live Class',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Class Title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter class title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('courses')
                    .where('instructorId', isEqualTo: userModel?.uid ?? '')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final courses = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: InputDecoration(
                      labelText: 'Select Course',
                      labelStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.school, color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF0B1120),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1A2940)),
                      ),
                    ),
                    dropdownColor: const Color(0xFF0B1120),
                    style: const TextStyle(color: Colors.white),
                    items: courses.map((course) {
                      final courseData = course.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: course.id,
                        child: Text(courseData['title'] ?? 'Untitled'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final course = courses.firstWhere((c) => c.id == value);
                        final courseData = course.data() as Map<String, dynamic>;
                        setState(() {
                          _selectedCourseId = value;
                          _selectedCourseName = courseData['title'];
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a course';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _youtubeUrlController,
                label: 'YouTube Live URL',
                icon: Icons.videocam,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter YouTube URL';
                  }
                  if (!value.contains('youtube.com') && !value.contains('youtu.be')) {
                    return 'Please enter a valid YouTube URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _selectDateTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1120),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A2940)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.white54),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scheduled Date & Time',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateTime(_selectedDateTime),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createLiveClass,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Schedule'),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, ${dateTime.year} at $hour:$minute $period';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF0B1120),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A2940)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A2940)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
