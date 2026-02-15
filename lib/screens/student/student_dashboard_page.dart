import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/course_model.dart';
import '../../models/assignment_model.dart';
import '../../models/exam_model.dart';
import '../../models/content_model.dart';
import '../../models/grade_model.dart';
import '../../models/submission_model.dart';
import '../../services/assignment_service.dart';
import '../../services/exam_service.dart';
import '../../services/content_service.dart';
import '../../services/grading_service.dart';
import 'loan_application_page.dart';
import 'my_certificates_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;
    
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Student Dashboard',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance),
            tooltip: 'Apply for Loan',
            onPressed: () {
              if (userModel != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoanApplicationPage(userModel: userModel),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: 'My Courses'),
            Tab(text: 'Assignments'),
            Tab(text: 'Exams'),
            Tab(text: 'Materials'),
            Tab(text: 'Grades'),
            Tab(text: 'Certificates'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _MyCoursesTab(),
          const _AssignmentsTab(),
          const _ExamsTab(),
          const _MaterialsTab(),
          const _GradesTab(),
          _buildCertificatesTab(),
        ],
      ),
    );
  }

  Widget _buildCertificatesTab() {
    final authService = context.watch<AuthService>();
    final userModel = authService.userModel;
    
    if (userModel == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }
    
    return MyCertificatesPage(userModel: userModel);
  }
}

// ─────────────────────────────────────────────
// MY COURSES TAB - Shows enrolled courses
// ─────────────────────────────────────────────
class _MyCoursesTab extends StatelessWidget {
  const _MyCoursesTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        if (enrollmentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!enrollmentSnapshot.hasData || enrollmentSnapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.school, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No enrolled courses yet',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final courseIds = enrollmentSnapshot.data!.docs
            .map((doc) => doc['courseId'] as String)
            .toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('courses')
              .where(FieldPath.documentId, whereIn: courseIds.isEmpty ? [''] : courseIds)
              .snapshots(),
          builder: (context, courseSnapshot) {
            if (!courseSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final courses = courseSnapshot.data!.docs
                .map((doc) => CourseModel.fromFirestore(doc))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return _CourseCard(course: course);
              },
            );
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
    return Card(
      color: const Color(0xFF0B1120),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              course.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              course.description,
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _InfoChip(icon: Icons.person, label: course.lecturerName),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.people,
                  label: '${course.studentsEnrolled} students',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// ASSIGNMENTS TAB - View and submit assignments
// ─────────────────────────────────────────────
class _AssignmentsTab extends StatelessWidget {
  const _AssignmentsTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }

    // Get enrolled courses first
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        if (!enrollmentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final courseIds = enrollmentSnapshot.data!.docs
            .map((doc) => doc['courseId'] as String)
            .toList();

        if (courseIds.isEmpty) {
          return const Center(
            child: Text(
              'Enroll in courses to view assignments',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        // Get assignments for enrolled courses
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('assignments')
              .where('courseId', whereIn: courseIds)
              .where('isPublished', isEqualTo: true)
              .orderBy('dueDate', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  'No assignments yet',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            final assignments = snapshot.data!.docs
                .map((doc) => AssignmentModel.fromFirestore(doc))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: assignments.length,
              itemBuilder: (context, index) {
                final assignment = assignments[index];
                return _StudentAssignmentCard(
                  assignment: assignment,
                  studentId: currentUser.uid,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StudentAssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final String studentId;

  const _StudentAssignmentCard({
    required this.assignment,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SubmissionModel?>(
      future: AssignmentService().getStudentSubmission(assignment.id, studentId),
      builder: (context, snapshot) {
        final hasSubmitted = snapshot.data != null;
        final submission = snapshot.data;

        return Card(
          color: const Color(0xFF0B1120),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasSubmitted
                            ? submission!.isGraded
                                ? Colors.green
                                : Colors.blue
                            : assignment.isOverdue
                                ? Colors.red
                                : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasSubmitted
                            ? submission!.isGraded
                                ? 'Graded'
                                : 'Submitted'
                            : assignment.isOverdue
                                ? 'Overdue'
                                : 'Pending',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(assignment.courseName, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),
                Text(
                  assignment.description,
                  style: const TextStyle(color: Colors.white60),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: 'Due: ${DateFormat('MMM d').format(assignment.dueDate)}',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.star,
                      label: '${assignment.totalPoints} pts',
                    ),
                    if (hasSubmitted && submission!.isGraded) ...[
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.grade,
                        label: 'Grade: ${submission.grade}',
                      ),
                    ],
                  ],
                ),
                if (!hasSubmitted && !assignment.isOverdue)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Submit assignment dialog')),
                          );
                        },
                        icon: const Icon(Icons.upload),
                        label: const Text('Submit Assignment'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// EXAMS TAB - View and take exams
// ─────────────────────────────────────────────
class _ExamsTab extends StatelessWidget {
  const _ExamsTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        if (!enrollmentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final courseIds = enrollmentSnapshot.data!.docs
            .map((doc) => doc['courseId'] as String)
            .toList();

        if (courseIds.isEmpty) {
          return const Center(
            child: Text(
              'Enroll in courses to view exams',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('exams')
              .where('courseId', whereIn: courseIds)
              .where('status', whereIn: ['approved', 'published'])
              .orderBy('scheduledDate', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No exams available', style: TextStyle(color: Colors.white54)),
              );
            }

            final exams = snapshot.data!.docs
                .map((doc) => ExamModel.fromFirestore(doc))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: exams.length,
              itemBuilder: (context, index) {
                final exam = exams[index];
                return _StudentExamCard(exam: exam, studentId: currentUser.uid);
              },
            );
          },
        );
      },
    );
  }
}

class _StudentExamCard extends StatelessWidget {
  final ExamModel exam;
  final String studentId;

  const _StudentExamCard({required this.exam, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SubmissionModel?>(
      future: ExamService().getStudentExamAttempt(exam.id, studentId),
      builder: (context, snapshot) {
        final hasAttempted = snapshot.data != null;
        final submission = snapshot.data;

        return Card(
          color: const Color(0xFF0B1120),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exam.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasAttempted ? Colors.green : Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        hasAttempted ? 'Completed' : 'Available',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(exam.courseName, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: DateFormat('MMM d').format(exam.scheduledDate),
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.timer,
                      label: '${exam.durationMinutes} min',
                    ),
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.question_answer,
                      label: '${exam.questions.length} questions',
                    ),
                  ],
                ),
                if (hasAttempted && submission!.score != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Score: ${submission.score!.toInt()}/${exam.totalPoints}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!hasAttempted)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Start exam')),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Exam'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// MATERIALS TAB - Course content/materials
// ─────────────────────────────────────────────
class _MaterialsTab extends StatelessWidget {
  const _MaterialsTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('enrollments')
          .where('studentId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, enrollmentSnapshot) {
        if (!enrollmentSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final courseIds = enrollmentSnapshot.data!.docs
            .map((doc) => doc['courseId'] as String)
            .toList();

        if (courseIds.isEmpty) {
          return const Center(
            child: Text(
              'Enroll in courses to view materials',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('content')
              .where('courseId', whereIn: courseIds)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No materials yet', style: TextStyle(color: Colors.white54)),
              );
            }

            final contents = snapshot.data!.docs
                .map((doc) => ContentModel.fromFirestore(doc))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: contents.length,
              itemBuilder: (context, index) {
                final content = contents[index];
                return _ContentMaterialCard(content: content);
              },
            );
          },
        );
      },
    );
  }
}

class _ContentMaterialCard extends StatelessWidget {
  final ContentModel content;

  const _ContentMaterialCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0B1120),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ContentService().incrementViewCount(content.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Open: ${content.title}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _getContentIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      content.courseName,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (content.type != ContentType.link)
                Text(
                  content.fileSizeFormatted,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getContentIcon() {
    IconData icon;
    Color color;

    switch (content.type) {
      case ContentType.video:
        icon = Icons.play_circle_filled;
        color = Colors.red;
        break;
      case ContentType.document:
        icon = Icons.description;
        color = Colors.blue;
        break;
      case ContentType.presentation:
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      case ContentType.link:
        icon = Icons.link;
        color = Colors.green;
        break;
      case ContentType.other:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

// ─────────────────────────────────────────────
// GRADES TAB - View all grades and GPA
// ─────────────────────────────────────────────
class _GradesTab extends StatelessWidget {
  const _GradesTab();

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }

    return FutureBuilder<double>(
      future: GradingService().calculateGPA(currentUser.uid),
      builder: (context, gpaSnapshot) {
        return StreamBuilder<List<GradeModel>>(
          stream: GradingService().getStudentGrades(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  'No grades yet',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            }

            final grades = snapshot.data!;
            final gpa = gpaSnapshot.data ?? 0.0;

            return Column(
              children: [
                // GPA Summary Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.purple],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'GPA',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gpa.toStringAsFixed(2),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'Courses',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${grades.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text(
                            'EMC Earned',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${grades.fold<double>(0, (sum, grade) => sum + grade.emcReward).toInt()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Grades List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: grades.length,
                    itemBuilder: (context, index) {
                      final grade = grades[index];
                      return _GradeCard(grade: grade);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GradeCard extends StatelessWidget {
  final GradeModel grade;

  const _GradeCard({required this.grade});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0B1120),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getGradeColor().withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _getGradeColor(), width: 2),
              ),
              child: Center(
                child: Text(
                  grade.grade.toString().split('.').last,
                  style: TextStyle(
                    color: _getGradeColor(),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    grade.courseName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Score: ${grade.numericScore.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'EMC Reward: ${grade.emcReward.toInt()} ${grade.isRedeemed ? "(Redeemed)" : "(Pending)"}',
                    style: TextStyle(
                      color: grade.isRedeemed ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('MMM d, y').format(grade.gradedAt),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  grade.semester,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor() {
    switch (grade.grade) {
      case LetterGrade.A:
        return Colors.green;
      case LetterGrade.B:
        return Colors.blue;
      case LetterGrade.C:
        return Colors.orange;
      case LetterGrade.D:
        return Colors.deepOrange;
      case LetterGrade.E:
        return Colors.red;
      case LetterGrade.F:
        return Colors.grey;
    }
  }
}

// ─────────────────────────────────────────────
// SHARED INFO CHIP WIDGET
// ─────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2940),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
