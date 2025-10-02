import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/task.dart';
import '../../repositories/task/task_repository.dart';

/// タスクの状態
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  const TaskState({this.tasks = const [], this.isLoading = false, this.error});

  TaskState copyWith({List<Task>? tasks, bool? isLoading, String? error}) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// タスクの状態管理クラス
class TaskNotifier extends StateNotifier<TaskState> {
  final TaskRepository _repository;

  TaskNotifier(this._repository) : super(const TaskState());

  /// タスク一覧を取得
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final tasks = await _repository.getTasks();
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'タスクの取得に失敗しました: $e');
    }
  }

  /// タスクを追加
  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.low,
  }) async {
    try {
      final newTask = await _repository.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
      );

      // ローカルの状態を更新
      state = state.copyWith(tasks: [newTask, ...state.tasks]);
    } catch (e) {
      state = state.copyWith(error: 'タスクの追加に失敗しました: $e');
    }
  }

  /// タスクを更新
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
  }) async {
    try {
      await _repository.updateTask(
        taskId: taskId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
      );

      // データを再読み込み
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: 'タスクの更新に失敗しました: $e');
    }
  }

  /// タスクを削除
  Future<void> deleteTask(String id) async {
    try {
      await _repository.deleteTask(id);

      // ローカルの状態を更新
      state = state.copyWith(
        tasks: state.tasks.where((task) => task.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'タスクの削除に失敗しました: $e');
    }
  }

  /// タスクの完了状態を切り替え
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _repository.updateTaskCompletion(
        taskId: taskId,
        isCompleted: isCompleted,
      );

      // ローカルの状態を更新
      state = state.copyWith(
        tasks:
            state.tasks.map((task) {
              if (task.id == taskId) {
                return task.copyWith(
                  isCompleted: isCompleted,
                  completedAt: isCompleted ? DateTime.now() : null,
                );
              }
              return task;
            }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'タスクの完了状態の更新に失敗しました: $e');
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}
