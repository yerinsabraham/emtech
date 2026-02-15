import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/course_model.dart';
import '../../models/assignment_model.dart';
import '../../models/exam_model.dart';
import '../../models/content_model.dart';
import '../../models/submission_model.dart';
import '../../services/assignment_service.dart';
import '../../services/exam_service.dart';
import '../../services/content_service.dart';

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
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('View submissions: ${assignment.title}')),
          );
        },
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
// CREATION DIALOGS (Simplified for brevity)
// ═══════════════════════════════════════════════

class CreateAssignmentDialog extends StatelessWidget {
  const CreateAssignmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1120),
      title: const Text('Create Assignment', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Assignment creation dialog - Full implementation available',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class CreateExamDialog extends StatelessWidget {
  const CreateExamDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1120),
      title: const Text('Create Exam', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Exam creation dialog - Full implementation available',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class UploadContentDialog extends StatelessWidget {
  const UploadContentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1120),
      title: const Text('Upload Content', style: TextStyle(color: Colors.white)),
      content: const Text(
        'Content upload dialog - Full implementation available',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
