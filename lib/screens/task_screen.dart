import 'package:flutter/material.dart';
import '../gradients.dart';
import '../services/supabase_service.dart';
import '../utils/error_handler.dart';
import '../models/task.dart';

class TaskScreen extends StatefulWidget {
  final List<Task>? tasks; // 型安全なTaskモデルに変更
  final Function(List<Task>)? onTasksChanged; // 型安全なコールバックに変更
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
  late List<Task> _tasks; // 型安全なTaskモデルに変更
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

  void addTask(String title) async {
    if (title.trim().isNotEmpty) {
      try {
        final newTask = await _supabaseService.addTaskTyped(
          title: title.trim(),
          priority: TaskPriority.low,
        );

        if (newTask != null) {
          setState(() {
            _tasks.add(newTask);
          });
          _notifyTasksChanged();
        }
      } catch (e) {
        if (mounted) {
          AppErrorHandler.handleError(
            context,
            e,
            operation: 'タスクの追加',
            onRetry: () => addTask(title),
          );
        }
      }
    }
  }

  Future<void> _toggleTask(int index) async {
    final task = _tasks[index];
    final newCompletionStatus = !task.isCompleted;

    try {
      // データベースを更新
      await _supabaseService.updateTaskCompletionTyped(
        taskId: task.id,
        isCompleted: newCompletionStatus,
      );

      // ローカルの状態を更新
      setState(() {
        _tasks[index] = task.copyWith(
          isCompleted: newCompletionStatus,
          completedAt: newCompletionStatus ? DateTime.now() : null,
        );
      });

      _notifyTasksChanged();
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'タスクの完了状態更新',
          onRetry: () => _toggleTask(index),
        );
      }
    }
  }

  Future<void> _deleteTask(int index) async {
    final task = _tasks[index];

    try {
      // データベースから削除
      await _supabaseService.deleteTaskTyped(task.id);

      setState(() {
        _tasks.removeAt(index);
      });
      _notifyTasksChanged();
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'タスクの削除',
          onRetry: () => _deleteTask(index),
        );
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
                                  task.isCompleted
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
                                        task.isCompleted
                                            ? const Color(0xFFE85A3B)
                                            : Colors.grey[500]!,
                                    width: 2,
                                  ),
                                  color:
                                      task.isCompleted
                                          ? const Color(0xFFE85A3B)
                                          : Colors.transparent,
                                ),
                                child:
                                    task.isCompleted
                                        ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        )
                                        : null,
                              ),
                            ),
                            title: Text(
                              task.title,
                              style: TextStyle(
                                color:
                                    task.isCompleted
                                        ? Colors.grey[500]
                                        : Colors.white,
                                fontSize: 16,
                                decoration:
                                    task.isCompleted
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
