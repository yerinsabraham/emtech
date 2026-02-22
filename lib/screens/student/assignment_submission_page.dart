import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/assignment_model.dart';
import '../../models/submission_model.dart';
import '../../services/assignment_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class AssignmentSubmissionPage extends StatefulWidget {
  final AssignmentModel assignment;

  const AssignmentSubmissionPage({super.key, required this.assignment});

  @override
  State<AssignmentSubmissionPage> createState() => _AssignmentSubmissionPageState();
}

class _AssignmentSubmissionPageState extends State<AssignmentSubmissionPage> {
  final _textController = TextEditingController();
  File? _selectedFile;
  String? _selectedFileName;
  bool _isSubmitting = false;
  SubmissionModel? _existingSubmission;
  bool _loadingSubmission = true;

  @override
  void initState() {
    super.initState();
    _loadExistingSubmission();
  }

  Future<void> _loadExistingSubmission() async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) return;
    final sub = await AssignmentService()
        .getStudentSubmission(widget.assignment.id, auth.currentUser!.uid);
    if (mounted) {
      setState(() {
        _existingSubmission = sub;
        _loadingSubmission = false;
        if (sub?.textSubmission != null) {
          _textController.text = sub!.textSubmission!;
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    final userModel = auth.userModel;
    if (user == null || userModel == null) return;

    if (_textController.text.trim().isEmpty && _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter text or attach a file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AssignmentService().submitAssignment(
        assignmentId: widget.assignment.id,
        courseId: widget.assignment.courseId,
        courseName: widget.assignment.courseName,
        studentId: user.uid,
        studentName: userModel.name,
        studentEmail: userModel.email,
        textSubmission: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        submissionFile: _selectedFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Assignment submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // return true = submitted
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;
    final isOverdue = assignment.isOverdue;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text('Submit Assignment',
            style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingSubmission
          ? const Center(child: CircularProgressIndicator())
          : _existingSubmission != null
              ? _buildAlreadySubmitted()
              : _buildSubmissionForm(isOverdue),
    );
  }

  Widget _buildAlreadySubmitted() {
    final sub = _existingSubmission!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Submission Status',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  label: 'Status',
                  value: sub.isGraded ? 'Graded' : 'Submitted — Awaiting Grade',
                  color: sub.isGraded ? Colors.green : Colors.blue,
                ),
                if (sub.isGraded) ...[
                  const SizedBox(height: 12),
                  _StatusRow(
                    label: 'Score',
                    value:
                        '${sub.score?.toInt() ?? 0} / ${sub.totalPoints?.toInt() ?? widget.assignment.totalPoints}',
                    color: Colors.amber,
                  ),
                  if (sub.grade != null) ...[
                    const SizedBox(height: 12),
                    _StatusRow(
                        label: 'Grade', value: sub.grade!, color: Colors.white),
                  ],
                  if (sub.feedback != null) ...[
                    const SizedBox(height: 12),
                    const Text('Feedback',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2940),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(sub.feedback!,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ],
                ],
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Submitted',
                  value: DateFormat('MMM d, y – h:mm a').format(sub.submittedAt),
                  color: Colors.white70,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (sub.textSubmission != null && sub.textSubmission!.isNotEmpty)
            _SectionCard(
              title: 'Your Text Submission',
              child: Text(sub.textSubmission!,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 14)),
            ),
          const SizedBox(height: 16),
          if (sub.fileUrl != null)
            _SectionCard(
              title: 'Attached File',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.attach_file, color: Colors.blue),
                title: const Text('View Submitted File',
                    style: TextStyle(color: Colors.blue)),
                onTap: () => launchUrl(Uri.parse(sub.fileUrl!)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmissionForm(bool isOverdue) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment info card
          _SectionCard(
            title: widget.assignment.title,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.assignment.description,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Chip(
                      icon: Icons.calendar_today,
                      label: 'Due: ${DateFormat('MMM d, y').format(widget.assignment.dueDate)}',
                      color: isOverdue ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _Chip(
                      icon: Icons.star,
                      label: '${widget.assignment.totalPoints} pts',
                      color: Colors.amber,
                    ),
                  ],
                ),
                if (widget.assignment.attachmentUrl != null) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => launchUrl(
                        Uri.parse(widget.assignment.attachmentUrl!)),
                    child: const Row(
                      children: [
                        Icon(Icons.download, color: Colors.blue, size: 18),
                        SizedBox(width: 6),
                        Text('Download Assignment Brief',
                            style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline)),
                      ],
                    ),
                  ),
                ],
                if (isOverdue)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'This assignment is overdue. Late submissions may be penalised.',
                          style:
                              TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Text submission
          _SectionCard(
            title: 'Text Answer',
            child: TextField(
              controller: _textController,
              maxLines: 8,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Type your answer here...',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // File attachment
          _SectionCard(
            title: 'Attach a File (optional)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supported: PDF, DOC, DOCX, TXT, PNG, JPG',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                if (_selectedFile != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: Colors.blue.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_selectedFileName ?? '',
                              style:
                                  const TextStyle(color: Colors.white)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.red, size: 18),
                          onPressed: () => setState(() {
                            _selectedFile = null;
                            _selectedFileName = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                      _selectedFile == null ? 'Choose File' : 'Change File'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                disabledBackgroundColor: Colors.blue.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Submit Assignment',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Shared widgets ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1120),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E2D4A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
