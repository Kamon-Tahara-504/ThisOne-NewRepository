import 'task_repository.dart';
import '../core/repository_exceptions.dart';
import '../../models/task.dart';
import '../../services/supabase_service.dart';

/// Supabaseを使ったTaskRepositoryの実装
class TaskRepositoryImpl implements TaskRepository {
  final SupabaseService _supabaseService;

  TaskRepositoryImpl(this._supabaseService);

  @override
  Future<List<Task>> getTasks() async {
    try {
      return await _supabaseService.getUserTasksTyped();
    } catch (e) {
      throw TaskRepositoryException('タスクの取得に失敗しました', e);
    }
  }

  @override
  Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.low,
  }) async {
    try {
      final task = await _supabaseService.addTaskTyped(
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
      );

      if (task == null) {
        throw TaskRepositoryException('タスクの作成に失敗しました');
      }

      return task;
    } catch (e) {
      throw TaskRepositoryException('タスクの作成に失敗しました', e);
    }
  }

  @override
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    try {
      await _supabaseService.updateTaskCompletionTyped(
        taskId: taskId,
        isCompleted: isCompleted,
      );
    } catch (e) {
      throw TaskRepositoryException('タスクの完了状態の更新に失敗しました', e);
    }
  }

  @override
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
  }) async {
    try {
      await _supabaseService.updateTaskTyped(
        taskId: taskId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
      );
    } catch (e) {
      throw TaskRepositoryException('タスクの更新に失敗しました', e);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabaseService.deleteTaskTyped(taskId);
    } catch (e) {
      throw TaskRepositoryException('タスクの削除に失敗しました', e);
    }
  }
}
