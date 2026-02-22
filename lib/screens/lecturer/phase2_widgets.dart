import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/assignment_model.dart';
import '../../models/content_model.dart';
import '../../models/exam_model.dart';
import '../../models/submission_model.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import '../../services/content_service.dart';
import '../../services/exam_service.dart';
import '../../services/notification_service.dart';

// ═══════════════════════════════════════════════
// PHASE 2: ACADEMIC & CONTENT MANAGEMENT WIDGETS
// ═══════════════════════════════════════════════

// ─────────────────────────────────────────────
// ASSIGNMENTS TAB
// ─────────────────────────────────────────────
class AssignmentsTab extends StatelessWidget {
  const AssignmentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please login to view assignments',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return StreamBuilder<List<AssignmentModel>>(
      stream: AssignmentService().getAssignmentsByLecturer(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No assignments yet',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  'Create your first assignment using the + button',
                  style: TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ],
            ),
          );
        }

        final assignments = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assignments.length,
          itemBuilder: (context, index) {
            final assignment = assignments[index];
            return AssignmentCard(assignment: assignment);
          },
        );
      },
    );
  }
}

class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;

  const AssignmentCard({super.key, required this.assignment});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0B1120),
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSubmissionsSheet(context, assignment),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          assignment.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          assignment.courseName,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: assignment.isOverdue ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      assignment.isOverdue ? 'Overdue' : 'Active',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                assignment.description,
                style: const TextStyle(color: Colors.white60),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  InfoChip(
                    icon: Icons.calendar_today,
                    label: 'Due: ${DateFormat('MMM d').format(assignment.dueDate)}',
                  ),
                  const SizedBox(width: 8),
                  InfoChip(
                    icon: Icons.assignment_turned_in,
                    label: '${assignment.submissionCount} submissions',
                  ),
                  const SizedBox(width: 8),
                  InfoChip(
                    icon: Icons.star,
                    label: '${assignment.totalPoints} pts',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EXAMS TAB
// ─────────────────────────────────────────────
class ExamsTab extends StatelessWidget {
  const ExamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<List<ExamModel>>(
      stream: ExamService().getExamsByLecturer(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No exams yet',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final exams = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: exams.length,
          itemBuilder: (context, index) => ExamCard(exam: exams[index]),
        );
      },
    );
  }
}

class ExamCard extends StatelessWidget {
  final ExamModel exam;

  const ExamCard({super.key, required this.exam});

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
                _buildStatusChip(exam.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(exam.courseName, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              children: [
                InfoChip(
                  icon: Icons.calendar_today,
                  label: DateFormat('MMM d').format(exam.scheduledDate),
                ),
                const SizedBox(width: 8),
                InfoChip(
                  icon: Icons.question_answer,
                  label: '${exam.questions.length} Q',
                ),
              ],
            ),
            if (exam.status == ExamStatus.draft || exam.status == ExamStatus.rejected)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ElevatedButton.icon(
                  onPressed: () => _submitForApproval(context),
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Submit for Approval'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ExamStatus status) {
    Color color;
    String label;

    switch (status) {
      case ExamStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case ExamStatus.pendingApproval:
        color = Colors.orange;
        label = 'Pending';
        break;
      case ExamStatus.approved:
        color = Colors.green;
        label = 'Approved';
        break;
      case ExamStatus.rejected:
        color = Colors.red;
        label = 'Rejected';
        break;
      case ExamStatus.published:
        color = Colors.blue;
        label = 'Published';
        break;
      case ExamStatus.closed:
        color = Colors.grey;
        label = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _submitForApproval(BuildContext context) async {
    try {
      await ExamService().submitForApproval(exam.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted for approval')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────
// CONTENT TAB
// ─────────────────────────────────────────────
class ContentTab extends StatelessWidget {
  const ContentTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text('Please login', style: TextStyle(color: Colors.white54)),
      );
    }

    return StreamBuilder<List<ContentModel>>(
      stream: ContentService().getContentByUploader(currentUser.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No content uploaded',
                  style: TextStyle(color: Colors.white54, fontSize: 18),
                ),
              ],
            ),
          );
        }

        final contents = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contents.length,
          itemBuilder: (context, index) => ContentCard(content: contents[index]),
        );
      },
    );
  }
}

class ContentCard extends StatelessWidget {
  final ContentModel content;

  const ContentCard({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0B1120),
      margin: const EdgeInsets.only(bottom: 12),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: content.isFreemium ? Colors.green : Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                content.isFreemium ? 'Free' : 'Premium',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
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
// SHARED INFO CHIP WIDGET
// ─────────────────────────────────────────────
class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const InfoChip({super.key, required this.icon, required this.label});

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

// ═══════════════════════════════════════════════
// SUBMISSION VIEWER & GRADING
// ═══════════════════════════════════════════════

void _showSubmissionsSheet(BuildContext context, AssignmentModel assignment) {
  final auth = context.read<AuthService>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF0B1120),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SubmissionsSheet(assignment: assignment, auth: auth),
  );
}

class _SubmissionsSheet extends StatelessWidget {
  final AssignmentModel assignment;
  final AuthService auth;

  const _SubmissionsSheet({required this.assignment, required this.auth});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, controller) {
        return Column(children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Icon(Icons.assignment_turned_in, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(assignment.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('${assignment.totalPoints} pts total',
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ]),
              ),
            ]),
          ),
          const Divider(color: Color(0xFF1A2940), height: 20),
          Expanded(
            child: StreamBuilder<List<SubmissionModel>>(
              stream: AssignmentService().getSubmissionsByAssignment(assignment.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final submissions = snap.data ?? [];
                if (submissions.isEmpty) {
                  return const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox, size: 48, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('No submissions yet', style: TextStyle(color: Colors.white54)),
                    ]),
                  );
                }
                return ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: submissions.length,
                  itemBuilder: (context, i) {
                    final sub = submissions[i];
                    final isGraded = sub.status == SubmissionStatus.graded;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111C2F),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF1A2940)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              isGraded ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                          child: Icon(
                            isGraded ? Icons.check_circle : Icons.pending,
                            color: isGraded ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        title: Text(sub.studentName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            'Submitted ${DateFormat('MMM d, h:mm a').format(sub.submittedAt)}',
                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                          ),
                          if (isGraded)
                            Text(
                              'Grade: ${sub.grade}  ·  ${sub.score?.toStringAsFixed(0)}/${assignment.totalPoints} pts',
                              style: const TextStyle(color: Colors.green, fontSize: 12),
                            ),
                        ]),
                        trailing: TextButton(
                          onPressed: () => _showGradeDialog(context, sub, assignment, auth),
                          child: Text(
                            isGraded ? 'Re-grade' : 'Grade',
                            style: TextStyle(color: isGraded ? Colors.blue : Colors.orange),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]);
      },
    );
  }
}

void _showGradeDialog(
    BuildContext context, SubmissionModel sub, AssignmentModel assignment, AuthService auth) {
  showDialog(
    context: context,
    builder: (_) => _GradeDialog(submission: sub, assignment: assignment, auth: auth),
  );
}

class _GradeDialog extends StatefulWidget {
  final SubmissionModel submission;
  final AssignmentModel assignment;
  final AuthService auth;

  const _GradeDialog(
      {required this.submission, required this.assignment, required this.auth});

  @override
  State<_GradeDialog> createState() => _GradeDialogState();
}

class _GradeDialogState extends State<_GradeDialog> {
  late final TextEditingController _scoreCtrl;
  final _feedbackCtrl = TextEditingController();
  bool _loading = false;
  String _letterGrade = 'A';

  @override
  void initState() {
    super.initState();
    _scoreCtrl =
        TextEditingController(text: widget.submission.score?.toStringAsFixed(0) ?? '');
    _feedbackCtrl.text = widget.submission.feedback ?? '';
    _updateGrade(_scoreCtrl.text);
    _scoreCtrl.addListener(() => _updateGrade(_scoreCtrl.text));
  }

  void _updateGrade(String v) {
    final score = double.tryParse(v);
    if (score == null) return;
    final pct = score / widget.assignment.totalPoints * 100;
    setState(() {
      if (pct >= 90) _letterGrade = 'A';
      else if (pct >= 80) _letterGrade = 'B';
      else if (pct >= 70) _letterGrade = 'C';
      else if (pct >= 60) _letterGrade = 'D';
      else _letterGrade = 'E';
    });
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final score = double.tryParse(_scoreCtrl.text);
    if (score == null || score < 0 || score > widget.assignment.totalPoints) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Enter a score between 0 and ${widget.assignment.totalPoints}'),
          backgroundColor: Colors.red));
      return;
    }
    final user = widget.auth.userModel!;
    setState(() => _loading = true);
    try {
      await AssignmentService().gradeSubmission(
        submissionId: widget.submission.id,
        score: score,
        totalPoints: widget.assignment.totalPoints.toDouble(),
        grade: _letterGrade,
        lecturerId: user.uid,
        lecturerName: user.name,
        feedback:
            _feedbackCtrl.text.trim().isEmpty ? null : _feedbackCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Graded successfully'), backgroundColor: Colors.green),
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
    final gradeColor = switch (_letterGrade) {
      'A' => Colors.green,
      'B' => Colors.lightGreen,
      'C' => Colors.yellow,
      'D' => Colors.orange,
      _ => Colors.red,
    };
    return AlertDialog(
      backgroundColor: const Color(0xFF111C2F),
      title: Text('Grade: ${widget.submission.studentName}',
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.submission.textSubmission != null) ...[  
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1A2940)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Submission', style: TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Text(widget.submission.textSubmission!,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
            const SizedBox(height: 12),
          ],
          Row(children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _scoreCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Score / ${widget.assignment.totalPoints}', Icons.grade),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: gradeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: gradeColor),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_letterGrade,
                    style: TextStyle(
                        color: gradeColor, fontSize: 22, fontWeight: FontWeight.bold)),
                const Text('grade', style: TextStyle(color: Colors.white38, fontSize: 9)),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: _feedbackCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Feedback (optional)', Icons.comment),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Grade'),
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
            borderSide: const BorderSide(color: Colors.orange, width: 2)),
      );
}

// ═══════════════════════════════════════════════
// CREATION DIALOGS — Full Implementation
// ═══════════════════════════════════════════════

// ─────────────────────────────────────────────
// CREATE ASSIGNMENT DIALOG
// ─────────────────────────────────────────────
class CreateAssignmentDialog extends StatefulWidget {
  const CreateAssignmentDialog({super.key});

  @override
  State<CreateAssignmentDialog> createState() => _CreateAssignmentDialogState();
}

class _CreateAssignmentDialogState extends State<CreateAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController(text: '100');
  String? _courseId;
  String? _courseName;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _publish = true;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
                primary: Colors.orange, surface: Color(0xFF111C2F))),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _dueDate = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a course'), backgroundColor: Colors.red));
      return;
    }
    final user = context.read<AuthService>().userModel!;
    setState(() => _loading = true);
    try {
      await AssignmentService().createAssignment(
        courseId: _courseId!,
        courseName: _courseName!,
        lecturerId: user.uid,
        lecturerName: user.name,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        dueDate: _dueDate,
        totalPoints: int.tryParse(_pointsCtrl.text) ?? 100,
        publishImmediately: _publish,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Assignment created!'), backgroundColor: Colors.green),
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
    final uid = context.watch<AuthService>().userModel?.uid ?? '';
    return AlertDialog(
      backgroundColor: const Color(0xFF111C2F),
      title: const Text('Create Assignment', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _coursePicker(uid),
              const SizedBox(height: 12),
              _field(_titleCtrl, 'Title', Icons.title,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _field(_descCtrl, 'Instructions', Icons.description,
                  maxLines: 3,
                  validator: (v) => v!.trim().isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              _field(_pointsCtrl, 'Total Points', Icons.star_border,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'Enter a number' : null),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1120),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1A2940)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.event, color: Colors.white54),
                    const SizedBox(width: 12),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Due Date',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text(DateFormat('EEE, MMM d yyyy').format(_dueDate),
                          style: const TextStyle(color: Colors.white)),
                    ]),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.white38),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF1A2940)),
                ),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Publish immediately',
                          style: TextStyle(color: Colors.white70)),
                      Switch(
                          value: _publish,
                          onChanged: (v) => setState(() => _publish = v),
                          activeColor: Colors.orange),
                    ]),
              ),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _coursePicker(String uid) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('instructorId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          return DropdownButtonFormField<String>(
            value: _courseId,
            decoration: _dec('Course', Icons.school),
            dropdownColor: const Color(0xFF0B1120),
            style: const TextStyle(color: Colors.white),
            hint: const Text('Select course',
                style: TextStyle(color: Colors.white54)),
            items: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                  value: d.id, child: Text(data['title'] ?? ''));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                final doc = docs.firstWhere((d) => d.id == v);
                setState(() {
                  _courseId = v;
                  _courseName =
                      (doc.data() as Map<String, dynamic>)['title'];
                });
              }
            },
            validator: (v) => v == null ? 'Select a course' : null,
          );
        },
      );

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
            borderSide: const BorderSide(color: Colors.orange, width: 2)),
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

// ─────────────────────────────────────────────
// CREATE EXAM DIALOG
// ─────────────────────────────────────────────

class _QuestionDraft {
  final questionCtrl = TextEditingController();
  final optionCtrls = List.generate(4, (_) => TextEditingController());
  int correctIndex = 0;
  int points = 10;

  void dispose() {
    questionCtrl.dispose();
    for (final c in optionCtrls) {
      c.dispose();
    }
  }
}

class CreateExamDialog extends StatefulWidget {
  const CreateExamDialog({super.key});

  @override
  State<CreateExamDialog> createState() => _CreateExamDialogState();
}

class _CreateExamDialogState extends State<CreateExamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '60');
  String? _courseId;
  String? _courseName;
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 3));
  final List<_QuestionDraft> _questions = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _addQuestion();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionDraft()));

  void _removeQuestion(int index) {
    _questions[index].dispose();
    setState(() => _questions.removeAt(index));
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
                primary: Colors.purple, surface: Color(0xFF111C2F))),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _scheduledDate = d);
  }

  bool _validateQuestions() {
    if (_questions.isEmpty) {
      _snack('Add at least one question', Colors.red);
      return false;
    }
    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionCtrl.text.trim().isEmpty) {
        _snack('Question ${i + 1}: enter question text', Colors.red);
        return false;
      }
      for (int j = 0; j < 4; j++) {
        if (q.optionCtrls[j].text.trim().isEmpty) {
          _snack('Question ${i + 1}: fill all 4 options', Colors.red);
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null) {
      _snack('Select a course', Colors.red);
      return;
    }
    if (!_validateQuestions()) return;
    final user = context.read<AuthService>().userModel!;
    setState(() => _loading = true);
    try {
      final questions = _questions
          .map((q) => ExamQuestion(
                question: q.questionCtrl.text.trim(),
                options: q.optionCtrls.map((c) => c.text.trim()).toList(),
                correctAnswerIndex: q.correctIndex,
                points: q.points,
              ))
          .toList();
      await ExamService().createExam(
        courseId: _courseId!,
        courseName: _courseName!,
        lecturerId: user.uid,
        lecturerName: user.name,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        questions: questions,
        durationMinutes: int.tryParse(_durationCtrl.text) ?? 60,
        scheduledDate: _scheduledDate,
      );
      if (mounted) {
        Navigator.pop(context);
        _snack('Exam created! Submit for approval to publish.', Colors.green);
      }
    } catch (e) {
      if (mounted) _snack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().userModel?.uid ?? '';
    return Dialog(
      backgroundColor: const Color(0xFF111C2F),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(children: [
              const Icon(Icons.quiz, color: Colors.purple),
              const SizedBox(width: 10),
              const Text('Create Exam',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context)),
            ]),
          ),
          const Divider(color: Color(0xFF1A2940)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _coursePicker(uid),
                        const SizedBox(height: 12),
                        _field(_titleCtrl, 'Exam Title', Icons.title,
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Required' : null),
                        const SizedBox(height: 12),
                        _field(_descCtrl, 'Instructions', Icons.description,
                            maxLines: 2),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(
                            child: _field(
                                _durationCtrl, 'Duration (min)', Icons.timer,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    int.tryParse(v ?? '') == null
                                        ? 'Enter minutes'
                                        : null),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B1120),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF1A2940)),
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Scheduled',
                                          style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11)),
                                      Text(
                                          DateFormat('MMM d, yyyy')
                                              .format(_scheduledDate),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13)),
                                    ]),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 20),
                        Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  'Questions (${_questions.length})',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              TextButton.icon(
                                onPressed: _addQuestion,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Question'),
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.purple),
                              ),
                            ]),
                        const SizedBox(height: 8),
                        ...List.generate(
                            _questions.length, (i) => _questionCard(i)),
                      ])),
            ),
          ),
          const Divider(color: Color(0xFF1A2940)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: _loading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Create Exam'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _questionCard(int index) {
    final q = _questions[index];
    return Card(
      color: const Color(0xFF0B1120),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 13,
              backgroundColor: Colors.purple.withOpacity(0.25),
              child: Text('${index + 1}',
                  style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Text('Question',
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: 72,
              child: TextFormField(
                initialValue: q.points.toString(),
                keyboardType: TextInputType.number,
                style:
                    const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'pts',
                  labelStyle: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF111C2F),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide:
                          const BorderSide(color: Color(0xFF1A2940))),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                ),
                onChanged: (v) => q.points = int.tryParse(v) ?? 10,
              ),
            ),
            if (_questions.length > 1) ...[  
              const SizedBox(width: 4),
              IconButton(
                  icon: const Icon(Icons.delete,
                      color: Colors.red, size: 20),
                  onPressed: () => _removeQuestion(index)),
            ],
          ]),
          const SizedBox(height: 10),
          TextFormField(
            controller: q.questionCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Question text', Icons.help_outline),
          ),
          const SizedBox(height: 10),
          ...List.generate(
              4,
              (opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Radio<int>(
                        value: opt,
                        groupValue: q.correctIndex,
                        onChanged: (v) =>
                            setState(() => q.correctIndex = v!),
                        activeColor: Colors.green,
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: q.optionCtrls[opt],
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Option ${opt + 1}',
                            hintStyle: const TextStyle(
                                color: Colors.white38, fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFF111C2F),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: Color(0xFF1A2940))),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                    color: q.correctIndex == opt
                                        ? Colors.green
                                            .withOpacity(0.5)
                                        : const Color(0xFF1A2940))),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: Colors.purple, width: 2)),
                          ),
                        ),
                      ),
                    ]),
                  )),
          Row(children: [
            const Icon(Icons.brightness_1,
                color: Colors.green, size: 10),
            const SizedBox(width: 4),
            const Text('= correct answer',
                style:
                    TextStyle(color: Colors.white38, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }

  Widget _coursePicker(String uid) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('instructorId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          return DropdownButtonFormField<String>(
            value: _courseId,
            decoration: _dec('Course', Icons.school),
            dropdownColor: const Color(0xFF0B1120),
            style: const TextStyle(color: Colors.white),
            hint: const Text('Select course',
                style: TextStyle(color: Colors.white54)),
            items: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                  value: d.id, child: Text(data['title'] ?? ''));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                final doc = docs.firstWhere((d) => d.id == v);
                setState(() {
                  _courseId = v;
                  _courseName =
                      (doc.data() as Map<String, dynamic>)['title'];
                });
              }
            },
            validator: (v) => v == null ? 'Select a course' : null,
          );
        },
      );

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
            borderSide: const BorderSide(color: Colors.purple, width: 2)),
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

// ─────────────────────────────────────────────
// UPLOAD CONTENT DIALOG
// ─────────────────────────────────────────────
class UploadContentDialog extends StatefulWidget {
  const UploadContentDialog({super.key});

  @override
  State<UploadContentDialog> createState() => _UploadContentDialogState();
}

class _UploadContentDialogState extends State<UploadContentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _courseId;
  String? _courseName;
  ContentType _type = ContentType.link;
  bool _freemium = false;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Select a course'),
              backgroundColor: Colors.red));
      return;
    }
    final user = context.read<AuthService>().userModel!;
    setState(() => _loading = true);
    try {
      final fs = FirebaseFirestore.instance;
      final docRef = await fs.collection('content').add({
        'courseId': _courseId,
        'courseName': _courseName,
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'type': _type.name,
        'fileUrl': _urlCtrl.text.trim(),
        'thumbnailUrl': null,
        'accessLevel': _freemium ? 'freemium' : 'premium',
        'uploadedById': user.uid,
        'uploadedByName': user.name,
        'uploadedByRole': user.role,
        'createdAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'downloadCount': 0,
        'fileSizeBytes': 0,
      });
      await NotificationService().notifyCourseStudents(
        courseId: _courseId!,
        title: 'New Content Available',
        message:
            '${user.name} uploaded "${_titleCtrl.text.trim()}" in $_courseName',
        type: 'content',
        actionUrl: '/content/${docRef.id}',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Content added!'), backgroundColor: Colors.green),
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

  String get _urlLabel {
    switch (_type) {
      case ContentType.video:
        return 'YouTube or Video URL';
      case ContentType.document:
        return 'Google Drive / Doc URL';
      case ContentType.presentation:
        return 'Google Slides URL';
      default:
        return 'URL or External Link';
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthService>().userModel?.uid ?? '';
    return AlertDialog(
      backgroundColor: const Color(0xFF111C2F),
      title: const Text('Add Content', style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
              key: _formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _coursePicker(uid),
                const SizedBox(height: 12),
                _field(_titleCtrl, 'Title', Icons.title,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 12),
                _field(_descCtrl, 'Description', Icons.description,
                    maxLines: 2),
                const SizedBox(height: 12),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Content Type',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 13))),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  _typeChip(ContentType.video, Icons.play_circle,
                      'Video', Colors.red),
                  _typeChip(ContentType.document, Icons.description,
                      'Document', Colors.blue),
                  _typeChip(ContentType.presentation, Icons.slideshow,
                      'Slides', Colors.orange),
                  _typeChip(
                      ContentType.link, Icons.link, 'Link', Colors.green),
                ]),
                const SizedBox(height: 12),
                _field(_urlCtrl, _urlLabel, Icons.link,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Required' : null),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1120),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: const Color(0xFF1A2940)),
                  ),
                  child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text('Free Access (Freemium)',
                                  style:
                                      TextStyle(color: Colors.white70)),
                              Text(
                                  _freemium
                                      ? 'Visible to all users'
                                      : 'Enrolled students only',
                                  style: const TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11)),
                            ]),
                        Switch(
                            value: _freemium,
                            onChanged: (v) =>
                                setState(() => _freemium = v),
                            activeColor: Colors.green),
                      ]),
                ),
              ])),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Add Content'),
        ),
      ],
    );
  }

  Widget _typeChip(
      ContentType type, IconData icon, String label, Color color) {
    final selected = _type == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: selected ? Colors.white : color),
      label: Text(label,
          style: TextStyle(
              color: selected ? Colors.white : color, fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _type = type),
      backgroundColor: const Color(0xFF0B1120),
      selectedColor: color,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color.withOpacity(0.5))),
    );
  }

  Widget _coursePicker(String uid) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('courses')
            .where('instructorId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          return DropdownButtonFormField<String>(
            value: _courseId,
            decoration: _dec('Course', Icons.school),
            dropdownColor: const Color(0xFF0B1120),
            style: const TextStyle(color: Colors.white),
            hint: const Text('Select course',
                style: TextStyle(color: Colors.white54)),
            items: docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              return DropdownMenuItem(
                  value: d.id, child: Text(data['title'] ?? ''));
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                final doc = docs.firstWhere((d) => d.id == v);
                setState(() {
                  _courseId = v;
                  _courseName =
                      (doc.data() as Map<String, dynamic>)['title'];
                });
              }
            },
            validator: (v) => v == null ? 'Select a course' : null,
          );
        },
      );

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
            borderSide: const BorderSide(color: Colors.green, width: 2)),
      );

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: _dec(label, icon),
        validator: validator,
      );
}
