import 'dart:convert';

/// タスクの優先度を表すenum
enum TaskPriority {
  low(0, '低', 'Low'),
  medium(1, '中', 'Medium'),
  high(2, '高', 'High');

  const TaskPriority(this.value, this.displayName, this.displayNameEn);

  final int value;
  final String displayName;
  final String displayNameEn;

  /// 数値からTaskPriorityを取得
  static TaskPriority fromValue(int value) {
    switch (value) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      case 2:
        return TaskPriority.high;
      default:
        return TaskPriority.low; // デフォルトは低
    }
  }
}

/// 型安全なタスクモデルクラス
class Task {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// MapからTaskオブジェクトを作成
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: map['is_completed'] as bool? ?? false,
      priority: TaskPriority.fromValue(map['priority'] as int? ?? 0),
      dueDate:
          map['due_date'] != null
              ? DateTime.parse(map['due_date'] as String).toLocal()
              : null,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
      completedAt:
          map['completed_at'] != null
              ? DateTime.parse(map['completed_at'] as String).toLocal()
              : null,
    );
  }

  /// TaskオブジェクトをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_completed': isCompleted,
      'priority': priority.value,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// JSON文字列からTaskオブジェクトを作成
  factory Task.fromJson(String source) {
    return Task.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  /// TaskオブジェクトをJSON文字列に変換
  String toJson() {
    return jsonEncode(toMap());
  }

  /// タスクのコピーを作成（指定されたフィールドを更新）
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// タスクが期限切れかどうか
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueDay.isBefore(today);
  }

  /// タスクが今日期限かどうか
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueDay.isAtSameMomentAs(today);
  }

  /// タスクが明日期限かどうか
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueDay.isAtSameMomentAs(tomorrow);
  }

  /// タスクが今週期限かどうか
  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return dueDate!.isAfter(startOfWeek) && dueDate!.isBefore(endOfWeek);
  }

  /// 期限の表示文字列を取得
  String get dueDateDisplayString {
    if (dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    if (dueDay == today) {
      return '今日';
    } else if (dueDay == tomorrow) {
      return '明日';
    } else if (dueDay == yesterday) {
      return '昨日';
    } else {
      return '${dueDate!.month}/${dueDate!.day}';
    }
  }

  /// 優先度の色を取得
  String get priorityColorHex {
    switch (priority) {
      case TaskPriority.low:
        return '#4CAF50'; // Green
      case TaskPriority.medium:
        return '#FF9800'; // Orange
      case TaskPriority.high:
        return '#F44336'; // Red
    }
  }

  /// 完了から経過した日数を取得
  int get daysSinceCompletion {
    if (completedAt == null) return 0;
    final now = DateTime.now();
    return now.difference(completedAt!).inDays;
  }

  /// 期限までの残り日数を取得
  int get daysUntilDue {
    if (dueDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return dueDay.difference(today).inDays;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Task &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.isCompleted == isCompleted &&
        other.priority == priority &&
        other.dueDate == dueDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      description,
      isCompleted,
      priority,
      dueDate,
    );
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted, priority: ${priority.displayName}, dueDate: $dueDate)';
  }
}

/// タスクフィルター用のクラス
class TaskFilter {
  final String? title;
  final bool? isCompleted;
  final TaskPriority? priority;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;
  final bool? isOverdue;
  final TaskSortOrder sortOrder;

  const TaskFilter({
    this.title,
    this.isCompleted,
    this.priority,
    this.dueDateFrom,
    this.dueDateTo,
    this.isOverdue,
    this.sortOrder = TaskSortOrder.createdAt,
  });

  /// フィルターに一致するかチェック
  bool matches(Task task) {
    // タイトル検索
    if (title != null && title!.isNotEmpty) {
      if (!task.title.toLowerCase().contains(title!.toLowerCase())) {
        return false;
      }
    }

    // 完了状態フィルター
    if (isCompleted != null) {
      if (task.isCompleted != isCompleted) {
        return false;
      }
    }

    // 優先度フィルター
    if (priority != null) {
      if (task.priority != priority) {
        return false;
      }
    }

    // 期限範囲フィルター
    if (dueDateFrom != null) {
      if (task.dueDate == null || task.dueDate!.isBefore(dueDateFrom!)) {
        return false;
      }
    }
    if (dueDateTo != null) {
      if (task.dueDate == null || task.dueDate!.isAfter(dueDateTo!)) {
        return false;
      }
    }

    // 期限切れフィルター
    if (isOverdue != null) {
      if (task.isOverdue != isOverdue) {
        return false;
      }
    }

    return true;
  }

  /// フィルターが設定されているかチェック
  bool get hasFilter {
    return title != null ||
        isCompleted != null ||
        priority != null ||
        dueDateFrom != null ||
        dueDateTo != null ||
        isOverdue != null;
  }
}

/// タスクソート順
enum TaskSortOrder {
  createdAt, // 作成日時順（デフォルト）
  updatedAt, // 更新日時順
  title, // タイトル順
  priority, // 優先度順
  dueDate, // 期限順
  completedAt, // 完了日時順
}

/// タスクリストの拡張メソッド
extension TaskListExtension on List<Task> {
  /// フィルターを適用
  List<Task> applyFilter(TaskFilter filter) {
    return where(filter.matches).toList();
  }

  /// ソートを適用
  List<Task> applySort(TaskSortOrder sortOrder) {
    switch (sortOrder) {
      case TaskSortOrder.createdAt:
        return _sortByCreatedAt();
      case TaskSortOrder.updatedAt:
        return _sortByUpdatedAt();
      case TaskSortOrder.title:
        return _sortByTitle();
      case TaskSortOrder.priority:
        return _sortByPriority();
      case TaskSortOrder.dueDate:
        return _sortByDueDate();
      case TaskSortOrder.completedAt:
        return _sortByCompletedAt();
    }
  }

  /// フィルターとソートを適用
  List<Task> filterAndSort(TaskFilter filter) {
    final filtered = applyFilter(filter);
    return filtered.applySort(filter.sortOrder);
  }

  List<Task> _sortByCreatedAt() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  List<Task> _sortByUpdatedAt() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return sorted;
  }

  List<Task> _sortByTitle() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) => a.title.compareTo(b.title));
    return sorted;
  }

  List<Task> _sortByPriority() {
    final sorted = List<Task>.from(this);
    sorted.sort(
      (a, b) => b.priority.value.compareTo(a.priority.value),
    ); // 高い優先度が先
    return sorted;
  }

  List<Task> _sortByDueDate() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });
    return sorted;
  }

  List<Task> _sortByCompletedAt() {
    final sorted = List<Task>.from(this);
    sorted.sort((a, b) {
      if (a.completedAt == null && b.completedAt == null) return 0;
      if (a.completedAt == null) return 1;
      if (b.completedAt == null) return -1;
      return b.completedAt!.compareTo(a.completedAt!); // 最新の完了が先
    });
    return sorted;
  }

  /// 完了済みタスクのみを取得
  List<Task> get completedTasks {
    return where((task) => task.isCompleted).toList();
  }

  /// 未完了タスクのみを取得
  List<Task> get pendingTasks {
    return where((task) => !task.isCompleted).toList();
  }

  /// 期限切れタスクのみを取得
  List<Task> get overdueTasks {
    return where((task) => task.isOverdue).toList();
  }

  /// 今日期限のタスクのみを取得
  List<Task> get todayTasks {
    return where((task) => task.isDueToday).toList();
  }

  /// 明日期限のタスクのみを取得
  List<Task> get tomorrowTasks {
    return where((task) => task.isDueTomorrow).toList();
  }

  /// 今週期限のタスクのみを取得
  List<Task> get thisWeekTasks {
    return where((task) => task.isDueThisWeek).toList();
  }

  /// 優先度別にグループ化
  Map<TaskPriority, List<Task>> groupByPriority() {
    final Map<TaskPriority, List<Task>> grouped = {};

    for (final task in this) {
      grouped.putIfAbsent(task.priority, () => []).add(task);
    }

    return grouped;
  }

  /// 完了状態別にグループ化
  Map<bool, List<Task>> groupByCompletion() {
    final Map<bool, List<Task>> grouped = {};

    for (final task in this) {
      grouped.putIfAbsent(task.isCompleted, () => []).add(task);
    }

    return grouped;
  }

  /// 統計情報を取得
  TaskStatistics get statistics {
    final total = length;
    final completed = completedTasks.length;
    final pending = pendingTasks.length;
    final overdue = overdueTasks.length;

    return TaskStatistics(
      total: total,
      completed: completed,
      pending: pending,
      overdue: overdue,
      completionRate: total > 0 ? (completed / total) * 100 : 0,
    );
  }
}

/// タスク統計情報
class TaskStatistics {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final double completionRate;

  const TaskStatistics({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.completionRate,
  });

  @override
  String toString() {
    return 'TaskStatistics(total: $total, completed: $completed, pending: $pending, overdue: $overdue, completionRate: ${completionRate.toStringAsFixed(1)}%)';
  }
}
