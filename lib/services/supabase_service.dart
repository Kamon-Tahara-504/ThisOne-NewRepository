import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class SupabaseService {
  
  // ユーザー認証関連
  
  /// サインアップ
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  /// サインイン
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// サインアウト
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
  
  /// 現在のユーザーを取得
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }
  
  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
  
  // ユーザープロフィール関連

  /// ユーザープロフィールを取得
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final response = await supabase
          .from('user_profiles')
          .select('*')
          .eq('user_id', user.id)
          .single();
      
      return response;
    } catch (e) {
      // プロフィールが存在しない場合は作成
      await _createUserProfile();
      return await getUserProfile();
    }
  }

  /// ユーザープロフィールを作成
  Future<void> _createUserProfile() async {
    final user = getCurrentUser();
    if (user == null) return;

    await supabase
        .from('user_profiles')
        .insert({
          'user_id': user.id,
          'display_name': null,
          'phone_number': null,
        });
  }

  /// ユーザープロフィールを更新
  Future<void> updateUserProfile({
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    final updateData = <String, dynamic>{};
    if (displayName != null) updateData['display_name'] = displayName.isEmpty ? null : displayName;
    if (phoneNumber != null) updateData['phone_number'] = phoneNumber.isEmpty ? null : phoneNumber;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl.isEmpty ? null : avatarUrl;

    if (updateData.isNotEmpty) {
      await supabase
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', user.id);
    }
  }
  
  // データベース操作の例
  
  /// データを取得
  Future<List<Map<String, dynamic>>> getData(String tableName) async {
    final response = await supabase
        .from(tableName)
        .select('*');
    return List<Map<String, dynamic>>.from(response);
  }
  
  /// データを挿入
  Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    await supabase
        .from(tableName)
        .insert(data);
  }
  
  /// データを更新
  Future<void> updateData(
    String tableName, 
    Map<String, dynamic> data,
    String idColumn,
    dynamic id,
  ) async {
    await supabase
        .from(tableName)
        .update(data)
        .eq(idColumn, id);
  }
  
  /// データを削除
  Future<void> deleteData(
    String tableName,
    String idColumn,
    dynamic id,
  ) async {
    await supabase
        .from(tableName)
        .delete()
        .eq(idColumn, id);
  }

  // タスク専用メソッド

  /// ユーザーのタスクを全て取得
  Future<List<Map<String, dynamic>>> getUserTasks() async {
    final user = getCurrentUser();
    if (user == null) return [];

    final response = await supabase
        .from('tasks')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  /// タスクを追加
  Future<Map<String, dynamic>?> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    int priority = 0,
  }) async {
    final user = getCurrentUser();
    if (user == null) return null;

    final taskData = {
      'user_id': user.id,
      'title': title,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'is_completed': false,
    };

    final response = await supabase
        .from('tasks')
        .insert(taskData)
        .select()
        .single();

    return response;
  }

  /// タスクの完了状態を更新
  Future<void> updateTaskCompletion({
    required String taskId,
    required bool isCompleted,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    await supabase
        .from('tasks')
        .update({
          'is_completed': isCompleted,
          'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', taskId)
        .eq('user_id', user.id);
  }

  /// タスクを削除
  Future<void> deleteTask(String taskId) async {
    final user = getCurrentUser();
    if (user == null) return;

    await supabase
        .from('tasks')
        .delete()
        .eq('id', taskId)
        .eq('user_id', user.id);
  }

  /// タスクを更新
  Future<void> updateTask({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? priority,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    final updateData = <String, dynamic>{};
    if (title != null) updateData['title'] = title;
    if (description != null) updateData['description'] = description;
    if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
    if (priority != null) updateData['priority'] = priority;

    if (updateData.isNotEmpty) {
      await supabase
          .from('tasks')
          .update(updateData)
          .eq('id', taskId)
          .eq('user_id', user.id);
    }
  }
} 