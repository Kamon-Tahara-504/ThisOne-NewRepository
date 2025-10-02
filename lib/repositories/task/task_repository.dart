import '../../models/task.dart';

/// タスクリポジトリのインターフェース
abstract class TaskRepository {
  /// ユーザーのタスクを全て取得
  Future<List<Task>> getTasks();

  /// タスクを追加
  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.low,
  });

  /// タスクの完了状態を更新
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  });

  /// タスクを更新
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
  });

  /// タスクを削除
  Future<void> deleteTask(String taskId);
}
