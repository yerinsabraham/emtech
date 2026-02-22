import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_task_model.dart';
import '../services/daily_task_service.dart';
import '../services/auth_service.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final DailyTaskService _taskService = DailyTaskService();
  bool _completingTaskId = false;
  String? _completingId;

  @override
  void initState() {
    super.initState();
    // Seed default tasks once if none exist
    _taskService.seedDefaultTasks();
  }

  Future<void> _completeTask(DailyTaskModel task) async {
    if (_completingTaskId) return;
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() {
      _completingTaskId = true;
      _completingId = task.id;
    });

    try {
      await _taskService.completeTask(
        userId: user.uid,
        userEmail: user.email ?? '',
        task: task,
        authService: auth,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Earned ${task.rewardEmc} EMC!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingTaskId = false;
          _completingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final userId = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1120),
        elevation: 0,
        title: const Text(
          'Daily Tasks',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: userId == null
          ? const Center(
              child: Text('Please log in to view tasks',
                  style: TextStyle(color: Colors.white54)))
          : StreamBuilder<List<DailyTaskModel>>(
              stream: _taskService.getActiveTasks(),
              builder: (context, tasksSnap) {
                if (tasksSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allTasks = tasksSnap.data ?? [];

                return StreamBuilder<Set<String>>(
                  stream: _taskService.watchCompletedTaskIds(userId),
                  builder: (context, completedSnap) {
                    final completedIds = completedSnap.data ?? {};
                    final incompleteTasks = allTasks
                        .where((t) => !completedIds.contains(t.id))
                        .toList();
                    final completedTasks = allTasks
                        .where((t) => completedIds.contains(t.id))
                        .toList();

                    final earnedToday = completedTasks.fold(
                        0, (sum, t) => sum + t.rewardEmc);
                    final possibleEarnings =
                        allTasks.fold(0, (sum, t) => sum + t.rewardEmc);

                    return Column(
                      children: [
                        // Stats Header
                        Container(
                          margin: const EdgeInsets.all(18),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Today\'s Progress',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$earnedToday / $possibleEarnings EMC',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${completedTasks.length}/${allTasks.length} tasks completed',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.amber,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Progress Bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Completion',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${(allTasks.isEmpty ? 0 : (completedTasks.length / allTasks.length * 100)).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: allTasks.isEmpty
                                      ? 0
                                      : completedTasks.length / allTasks.length,
                                  backgroundColor: const Color(0xFF1E2D4A),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Color(0xFF3B82F6)),
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tasks List
                        Expanded(
                          child: allTasks.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No tasks available today',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                )
                              : ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                  children: [
                                    if (incompleteTasks.isNotEmpty) ...[
                                      const Text(
                                        'Available Tasks',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...incompleteTasks.map((task) =>
                                          _buildTaskCard(task, false)),
                                    ],
                                    if (completedTasks.isNotEmpty) ...[
                                      const SizedBox(height: 24),
                                      const Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...completedTasks.map((task) =>
                                          _buildTaskCard(task, true)),
                                    ],
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }

  Widget _buildTaskCard(DailyTaskModel task, bool isCompleted) {
    final isLoading = _completingTaskId && _completingId == task.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted 
            ? const Color(0xFF0E1827).withOpacity(0.5)
            : const Color(0xFF111C2F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompleted 
              ? const Color(0xFF1A2940).withOpacity(0.5)
              : const Color(0xFF1E2D4A),
          width: 0.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCompleted || isLoading ? null : () => _completeTask(task),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.withOpacity(0.2)
                        : _getCategoryColor(task.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _getCategoryColor(task.category),
                          ),
                        )
                      : Icon(
                          isCompleted ? Icons.check_circle : _getTaskIcon(task.iconName),
                          color: isCompleted ? Colors.green : _getCategoryColor(task.category),
                        ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: isCompleted ? Colors.white38 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: isCompleted ? Colors.white24 : Colors.white60,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Reward Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? Colors.green.withOpacity(0.1)
                        : const Color(0xFFFBBF24).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCompleted 
                          ? Colors.green.withOpacity(0.3)
                          : const Color(0xFFFBBF24).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: isCompleted ? Colors.green : const Color(0xFFFBBF24),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.rewardEmc}',
                        style: TextStyle(
                          color: isCompleted ? Colors.green : const Color(0xFFFBBF24),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'learning':
        return const Color(0xFF3B82F6);
      case 'social':
        return const Color(0xFF8B5CF6);
      case 'achievement':
        return const Color(0xFFFBBF24);
      default:
        return Colors.grey;
    }
  }

  IconData _getTaskIcon(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'assignment_turned_in':
        return Icons.assignment_turned_in;
      case 'video_call':
        return Icons.video_call;
      case 'forum':
        return Icons.forum;
      case 'people':
        return Icons.people;
      case 'article':
        return Icons.article;
      case 'timer':
        return Icons.timer;
      default:
        return Icons.task_alt;
    }
  }
}
