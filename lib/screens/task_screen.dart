import 'package:flutter/material.dart';
import '../gradients.dart';
import '../services/supabase_service.dart';

class TaskScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? tasks;
  final Function(List<Map<String, dynamic>>)? onTasksChanged;
  final ScrollController? scrollController;

  const TaskScreen({
    super.key,
    this.tasks,
    this.onTasksChanged,
    this.scrollController,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late List<Map<String, dynamic>> _tasks;
  final TextEditingController _taskController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _tasks = widget.tasks != null ? List.from(widget.tasks!) : [];
  }

  @override
  void didUpdateWidget(TaskScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tasks != null) {
      _tasks = List.from(widget.tasks!);
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void addTask(String title) {
    if (title.trim().isNotEmpty) {
      setState(() {
        _tasks.add({
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'title': title.trim(),
          'isCompleted': false,
          'createdAt': DateTime.now(),
          'description': null,
          'dueDate': null,
          'priority': 0,
        });
      });
      _notifyTasksChanged();
    }
  }

  Future<void> _toggleTask(int index) async {
    final task = _tasks[index];
    final newCompletionStatus = !task['isCompleted'];

    try {
      // Supabaseで更新（IDがStringの場合のみ、つまりSupabaseのタスク）
      if (task['id'] is String && task['id'].length > 10) {
        await _supabaseService.updateTaskCompletion(
          taskId: task['id'],
          isCompleted: newCompletionStatus,
        );
      }

      setState(() {
        _tasks[index]['isCompleted'] = newCompletionStatus;
      });
      _notifyTasksChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('タスクの更新に失敗しました: $e')));
      }
    }
  }

  Future<void> _deleteTask(int index) async {
    final task = _tasks[index];

    try {
      // Supabaseで削除（IDがStringの場合のみ、つまりSupabaseのタスク）
      if (task['id'] is String && task['id'].length > 10) {
        await _supabaseService.deleteTask(task['id']);
      }

      setState(() {
        _tasks.removeAt(index);
      });
      _notifyTasksChanged();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('タスクの削除に失敗しました: $e')));
      }
    }
  }

  void _notifyTasksChanged() {
    if (widget.onTasksChanged != null) {
      widget.onTasksChanged!(_tasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Column(
        children: [
          // タスクリスト
          Expanded(
            child:
                _tasks.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback:
                                (bounds) => createOrangeYellowGradient()
                                    .createShader(bounds),
                            child: Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'タスクがありません',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '下部の + ボタンから新しいタスクを追加してください',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      controller: widget.scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  task['isCompleted']
                                      ? const Color(
                                        0xFFE85A3B,
                                      ).withValues(alpha: 0.3)
                                      : Colors.grey[700]!,
                            ),
                          ),
                          child: ListTile(
                            leading: GestureDetector(
                              onTap: () => _toggleTask(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        task['isCompleted']
                                            ? const Color(0xFFE85A3B)
                                            : Colors.grey[500]!,
                                    width: 2,
                                  ),
                                  color:
                                      task['isCompleted']
                                          ? const Color(0xFFE85A3B)
                                          : Colors.transparent,
                                ),
                                child:
                                    task['isCompleted']
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                        : null,
                              ),
                            ),
                            title: Text(
                              task['title'],
                              style: TextStyle(
                                color:
                                    task['isCompleted']
                                        ? Colors.grey[500]
                                        : Colors.white,
                                fontSize: 16,
                                decoration:
                                    task['isCompleted']
                                        ? TextDecoration.lineThrough
                                        : null,
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () => _deleteTask(index),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
