import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../gradients.dart';
import '../utils/error_handler.dart';
import '../models/task.dart';
import '../providers/repository_providers.dart';

class TaskScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;

  const TaskScreen({super.key, this.scrollController});

  @override
  ConsumerState<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends ConsumerState<TaskScreen> {
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // タスクを読み込み
    Future.microtask(() {
      ref.read(taskNotifierProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void addTask(String title) async {
    if (title.trim().isNotEmpty) {
      try {
        await ref
            .read(taskNotifierProvider.notifier)
            .addTask(title: title.trim(), priority: TaskPriority.low);
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

  Future<void> _toggleTask(Task task) async {
    final newCompletionStatus = !task.isCompleted;

    try {
      await ref
          .read(taskNotifierProvider.notifier)
          .toggleTaskCompletion(task.id, newCompletionStatus);
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'タスクの完了状態更新',
          onRetry: () => _toggleTask(task),
        );
      }
    }
  }

  Future<void> _deleteTask(Task task) async {
    try {
      await ref.read(taskNotifierProvider.notifier).deleteTask(task.id);
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'タスクの削除',
          onRetry: () => _deleteTask(task),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // タスクの状態を監視
    final taskState = ref.watch(taskNotifierProvider);
    final tasks = taskState.tasks;

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Column(
        children: [
          // タスクリスト
          Expanded(
            child:
                taskState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : tasks.isEmpty
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
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
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
                              onTap: () => _toggleTask(task),
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
                              onPressed: () => _deleteTask(task),
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
