import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/exam_model.dart';
import '../../models/submission_model.dart';
import '../../services/exam_service.dart';
import '../../services/auth_service.dart';

class ExamTakingPage extends StatefulWidget {
  final ExamModel exam;

  const ExamTakingPage({super.key, required this.exam});

  @override
  State<ExamTakingPage> createState() => _ExamTakingPageState();
}

class _ExamTakingPageState extends State<ExamTakingPage> {
  late List<int?> _answers; // index of selected option per question, null = unanswered
  int _currentQuestion = 0;
  late Timer _timer;
  late int _remainingSeconds;
  bool _isSubmitting = false;
  bool _examFinished = false;
  SubmissionModel? _result;

  @override
  void initState() {
    super.initState();
    _answers = List.filled(widget.exam.questions.length, null);
    _remainingSeconds = widget.exam.durationMinutes * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoSubmit();
      } else {
        if (mounted) setState(() => _remainingSeconds--);
      }
    });
  }

  Future<void> _autoSubmit() async {
    if (_examFinished || _isSubmitting) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Time is up! Submitting automatically...'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
    await _submitExam();
  }

  Future<void> _submitExam() async {
    if (_isSubmitting) return;

    // Confirm if not all questions are answered
    final unanswered = _answers.where((a) => a == null).length;
    if (unanswered > 0 && !_examFinished) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF0B1120),
          title: const Text('Submit Exam?',
              style: TextStyle(color: Colors.white)),
          content: Text(
            '$unanswered question${unanswered == 1 ? '' : 's'} unanswered. Submit anyway?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Submit'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    _timer.cancel();

    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    final userModel = auth.userModel;

    if (user == null || userModel == null) return;

    try {
      // Replace nulls (unanswered) with -1 so they don't match any correct answer
      final finalAnswers = _answers.map((a) => a ?? -1).toList();

      await ExamService().submitExamAttempt(
        examId: widget.exam.id,
        courseId: widget.exam.courseId,
        courseName: widget.exam.courseName,
        studentId: user.uid,
        studentName: userModel.name,
        studentEmail: userModel.email,
        answers: finalAnswers,
      );

      // Fetch the submission to show result
      final submission =
          await ExamService().getStudentExamAttempt(widget.exam.id, user.uid);

      if (mounted) {
        setState(() {
          _examFinished = true;
          _isSubmitting = false;
          _result = submission;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get _timerDisplay {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Color get _timerColor {
    if (_remainingSeconds > 300) return Colors.green; // > 5 min
    if (_remainingSeconds > 60) return Colors.orange; // 1–5 min
    return Colors.red; // < 1 min
  }

  @override
  Widget build(BuildContext context) {
    if (_examFinished && _result != null) {
      return _ResultScreen(
        exam: widget.exam,
        submission: _result!,
        answers: _answers,
      );
    }

    final question = widget.exam.questions[_currentQuestion];
    final totalQ = widget.exam.questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.exam.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            Text(widget.exam.courseName,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          // Timer
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _timerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _timerColor.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: _timerColor, size: 16),
                const SizedBox(width: 6),
                Text(_timerDisplay,
                    style: TextStyle(
                        color: _timerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar + question navigator
          Container(
            color: const Color(0xFF0B1120),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestion + 1} of $totalQ',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                    Text(
                      '${_answers.where((a) => a != null).length} answered',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: (_currentQuestion + 1) / totalQ,
                  backgroundColor: const Color(0xFF1E2D4A),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 4,
                ),
              ],
            ),
          ),

          // Question content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1120),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFF1E2D4A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${question.points} pt${question.points == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          question.question,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...question.options.asMap().entries.map((entry) {
                    final optIndex = entry.key;
                    final optText = entry.value;
                    final isSelected = _answers[_currentQuestion] == optIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() =>
                            _answers[_currentQuestion] = optIndex);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withOpacity(0.2)
                              : const Color(0xFF0B1120),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : const Color(0xFF1E2D4A),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.blue
                                    : const Color(0xFF1A2940),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.white24,
                                ),
                              ),
                              child: Center(
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        color: Colors.white, size: 18)
                                    : Text(
                                        String.fromCharCode(
                                            65 + optIndex), // A, B, C, D
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                optText,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Bottom navigation
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF0B1120),
            child: Row(
              children: [
                // Previous
                if (_currentQuestion > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          setState(() => _currentQuestion--),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side:
                            const BorderSide(color: Colors.white24),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                if (_currentQuestion > 0) const SizedBox(width: 12),

                // Next / Submit
                Expanded(
                  flex: 2,
                  child: _currentQuestion < totalQ - 1
                      ? ElevatedButton.icon(
                          onPressed: () =>
                              setState(() => _currentQuestion++),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed:
                              _isSubmitting ? null : _submitExam,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.send),
                          label: const Text('Submit Exam'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Question dots navigator
          Container(
            color: const Color(0xFF080C14),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(totalQ, (i) {
                  final answered = _answers[i] != null;
                  final isCurrent = i == _currentQuestion;
                  return GestureDetector(
                    onTap: () => setState(() => _currentQuestion = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? Colors.blue
                            : answered
                                ? Colors.green
                                : const Color(0xFF1A2940),
                        border: Border.all(
                            color: isCurrent
                                ? Colors.blue
                                : answered
                                    ? Colors.green
                                    : Colors.white24),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Result Screen ─────────────────────────────────────────────────────

class _ResultScreen extends StatelessWidget {
  final ExamModel exam;
  final SubmissionModel submission;
  final List<int?> answers;

  const _ResultScreen({
    required this.exam,
    required this.submission,
    required this.answers,
  });

  @override
  Widget build(BuildContext context) {
    final score = submission.score?.toInt() ?? 0;
    final total = exam.totalPoints;
    final percentage =
        total > 0 ? (score / total * 100).toStringAsFixed(1) : '0';
    final passed = score >= total * 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Exam Result',
            style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: passed
                      ? [Colors.green.shade800, Colors.green.shade600]
                      : [Colors.red.shade900, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    passed ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    passed ? 'Well Done!' : 'Better Luck Next Time',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '$score / $total',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Answer review
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Answer Review',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            ...exam.questions.asMap().entries.map((entry) {
              final i = entry.key;
              final q = entry.value;
              final selectedAnswer = answers[i] ?? -1;
              final correct = selectedAnswer == q.correctAnswerIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1120),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: correct
                        ? Colors.green.withOpacity(0.5)
                        : Colors.red.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          correct ? Icons.check_circle : Icons.cancel,
                          color: correct ? Colors.green : Colors.red,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Q${i + 1}: ${q.question}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!correct) ...[
                      Text(
                        'Your answer: ${selectedAnswer >= 0 ? q.options[selectedAnswer] : "Not answered"}',
                        style: const TextStyle(
                            color: Colors.red, fontSize: 13),
                      ),
                    ],
                    Text(
                      'Correct: ${q.options[q.correctAnswerIndex]}',
                      style: const TextStyle(
                          color: Colors.green, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
