import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/task.dart';
import '../models/memo.dart';

/// メイン画面のデータ管理を担当するクラス
class MainDataService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  // データ
  final List<Task> _tasks = [];
  final List<Memo> _memos = [];

  // 状態
  bool _isLoading = true;
  bool _isLoadingMemos = true;
  String? _newlyCreatedMemoId;
  bool _isDisposed = false;

  // ゲッター
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Memo> get memos => List.unmodifiable(_memos);
  bool get isLoading => _isLoading;
  bool get isLoadingMemos => _isLoadingMemos;
  String? get newlyCreatedMemoId => _newlyCreatedMemoId;

  /// タスクを読み込み
  Future<void> loadTasks() async {
    if (_isDisposed) return;

    try {
      final tasks = await _supabaseService.getUserTasksTyped();
      if (!_isDisposed) {
        _tasks.clear();
        _tasks.addAll(tasks);
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
        // エラーハンドリングは呼び出し元で行う
        rethrow;
      }
    }
  }

  /// メモを読み込み
  Future<void> loadMemos() async {
    if (_isDisposed) return;

    try {
      final memos = await _supabaseService.getUserMemosTyped();
      if (!_isDisposed) {
        _memos.clear();
        _memos.addAll(memos);
        _isLoadingMemos = false;
        notifyListeners();
      }
    } catch (e) {
      if (!_isDisposed) {
        _isLoadingMemos = false;
        notifyListeners();
        // エラーハンドリングは呼び出し元で行う
        rethrow;
      }
    }
  }

  /// タスクを追加
  Future<void> addTask(String title) async {
    if (_isDisposed || title.trim().isEmpty) return;

    try {
      final newTask = await _supabaseService.addTaskTyped(title: title.trim());

      if (!_isDisposed) {
        if (newTask != null) {
          _tasks.add(newTask);
          notifyListeners();
        } else {
          // 認証されていない場合はローカルに保存
          final localTask = Task(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: 'local',
            title: title.trim(),
            isCompleted: false,
            priority: TaskPriority.low,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          _tasks.add(localTask);
          notifyListeners();
        }
      }
    } catch (e) {
      // エラーハンドリングは呼び出し元で行う
      rethrow;
    }
  }

  /// メモを作成
  Future<void> createMemo(String title, String mode, String colorHex) async {
    if (_isDisposed) return;

    try {
      // modeをMemoModeに変換
      final memoMode = MemoMode.fromString(mode);
      final newMemo = await _supabaseService.addMemoTyped(
        title: title,
        mode: memoMode,
        colorHex: colorHex,
      );

      if (!_isDisposed) {
        if (newMemo != null) {
          // 新しく作成されたメモのIDを設定
          _newlyCreatedMemoId = newMemo.id;
          notifyListeners();

          // メモリストを再読み込み
          await loadMemos();
        }
      }
    } catch (e) {
      // エラーハンドリングは呼び出し元で行う
      rethrow;
    }
  }

  /// 新しく作成されたメモIDをクリア
  void clearNewlyCreatedMemoId() {
    if (_newlyCreatedMemoId != null) {
      _newlyCreatedMemoId = null;
      notifyListeners();
    }
  }

  /// タスクを更新
  void updateTasks(List<Task> updatedTasks) {
    if (_isDisposed) return;
    _tasks.clear();
    _tasks.addAll(updatedTasks);
    notifyListeners();
  }

  /// メモを更新
  void updateMemos(List<Memo> updatedMemos) {
    if (_isDisposed) return;
    _memos.clear();
    _memos.addAll(updatedMemos);
    notifyListeners();
  }

  /// 認証状態の変更を監視
  void startAuthStateListener() {
    _supabaseService.authStateChanges.listen((AuthState data) {
      if (!_isDisposed) {
        loadTasks();
        loadMemos();
      }
    });
  }

  /// リソースを解放
  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    super.dispose();
  }
}
