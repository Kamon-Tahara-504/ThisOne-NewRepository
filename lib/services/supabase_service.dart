import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../utils/color_utils.dart';

// Supabaseクライアントを使用
final supabase = Supabase.instance.client;

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

  // メモ専用メソッド

  /// ユーザーのメモを全て取得
  Future<List<Map<String, dynamic>>> getUserMemos() async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final response = await supabase
          .from('memos')
          .select('*')
          .eq('user_id', user.id)
          .order('is_pinned', ascending: false) // ピン留めを上部に
          .order('updated_at', ascending: false); // 更新日時で降順
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('メモ取得エラー: $e');
      
      // modeカラムが存在しない場合の対処
      if (e.toString().contains('column "mode" of relation "memos" does not exist')) {
        try {
          final response = await supabase
              .from('memos')
              .select('id, user_id, title, content, created_at, updated_at, is_pinned, tags, color_tag')
              .eq('user_id', user.id)
              .order('is_pinned', ascending: false) // ピン留めを上部に
              .order('updated_at', ascending: false); // 更新日時で降順
          
          // modeカラムがない場合はデフォルト値を追加
          final memosWithMode = List<Map<String, dynamic>>.from(response)
              .map((memo) => {
                ...memo, 
                'mode': 'memo',
                'rich_content': null,
              })
              .toList();
          
          return memosWithMode;
        } catch (e2) {
          debugPrint('modeなしでのメモ取得エラー: $e2');
          rethrow;
        }
      }
      
      rethrow;
    }
  }

  /// メモのピン留め状態を更新
  Future<void> updateMemoPinStatus({
    required String memoId,
    required bool isPinned,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      // ピン留め状態のみを更新（クライアント側でソートを制御するためシンプルに）
      await supabase
          .from('memos')
          .update({
            'is_pinned': isPinned,
          })
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('ピン留め状態の更新エラー: $e');
      rethrow;
    }
  }

  /// メモの色ラベルを更新
  Future<void> updateMemoColorLabel({
    required String memoId,
    required String colorHex,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      // 色ラベルのみを更新
      await supabase
          .from('memos')
          .update({
            'color_tag': colorHex,
          })
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('色ラベルの更新エラー: $e');
      rethrow;
    }
  }

  /// メモのモードを更新
  Future<void> updateMemoMode({
    required String memoId,
    required String mode,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('memos')
          .update({
            'mode': mode,
          })
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('メモモードの更新エラー: $e');
      rethrow;
    }
  }

  /// メモの設定（モードと色ラベル）を一括更新
  Future<void> updateMemoSettings({
    required String memoId,
    required String mode,
    required String colorHex,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('memos')
          .update({
            'mode': mode,
            'color_tag': colorHex,
          })
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('メモ設定の更新エラー: $e');
      rethrow;
    }
  }

  /// メモを追加
  Future<Map<String, dynamic>?> addMemo({
    required String title,
    String content = '',
    String mode = 'memo',
    Map<String, dynamic>? richContent,
    String? colorHex, // 色ラベルのパラメータを追加
  }) async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final memoData = {
        'user_id': user.id,
        'title': title,
        'content': content,
        'mode': mode,
        'color_tag': colorHex ?? '#9E9E9E', // デフォルトはグレー
        // リッチコンテンツ（QuillのDelta）をJSON文字列として保存
        'rich_content': richContent != null ? jsonEncode(richContent) : null,
      };

      final response = await supabase
          .from('memos')
          .insert(memoData)
          .select()
          .single();

      return response;
    } catch (e) {
      // エラーの詳細をログに出力
      debugPrint('メモ追加エラー: $e');
      
      // modeカラムが存在しない場合の対処
      if (e.toString().contains('column "mode" of relation "memos" does not exist') ||
          e.toString().contains('column "rich_content" of relation "memos" does not exist')) {
        try {
          final memoDataWithoutMode = {
            'user_id': user.id,
            'title': title,
            'content': content,
          };

          final response = await supabase
              .from('memos')
              .insert(memoDataWithoutMode)
              .select()
              .single();

          return response;
        } catch (e2) {
          debugPrint('modeなしでのメモ追加エラー: $e2');
          rethrow;
        }
      }
      
      rethrow;
    }
  }

  /// メモを更新
  Future<void> updateMemo({
    required String memoId,
    String? title,
    String? content,
    String? mode,
    Map<String, dynamic>? richContent,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (mode != null) updateData['mode'] = mode;
      if (richContent != null) updateData['rich_content'] = jsonEncode(richContent);

      await supabase
          .from('memos')
          .update(updateData)
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('メモ更新エラー: $e');
      
      // modeカラムやrich_contentカラムが存在しない場合の対処
      if (e.toString().contains('column "mode" of relation "memos" does not exist') ||
          e.toString().contains('column "rich_content" of relation "memos" does not exist')) {
        try {
          final updateDataWithoutMode = <String, dynamic>{
            'updated_at': DateTime.now().toIso8601String(),
          };
          if (title != null) updateDataWithoutMode['title'] = title;
          if (content != null) updateDataWithoutMode['content'] = content;

          await supabase
              .from('memos')
              .update(updateDataWithoutMode)
              .eq('id', memoId)
              .eq('user_id', user.id);
        } catch (e2) {
          debugPrint('modeなしでのメモ更新エラー: $e2');
          rethrow;
        }
      } else {
        rethrow;
      }
    }
  }

  /// メモを削除
  Future<void> deleteMemo(String memoId) async {
    final user = getCurrentUser();
    if (user == null) return;

    await supabase
        .from('memos')
        .delete()
        .eq('id', memoId)
        .eq('user_id', user.id);
  }

  // スケジュール専用メソッド

  /// ユーザーのスケジュールを全て取得
  Future<List<Map<String, dynamic>>> getUserSchedules() async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final response = await supabase
          .from('schedules')
          .select('*')
          .eq('user_id', user.id)
          .order('schedule_date', ascending: true)
          .order('start_time', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('スケジュール取得エラー: $e');
      return [];
    }
  }

  /// 特定の日付のスケジュールを取得
  Future<List<Map<String, dynamic>>> getSchedulesForDate(DateTime date) async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      final response = await supabase
          .from('schedules')
          .select('*')
          .eq('user_id', user.id)
          .eq('schedule_date', dateString)
          .order('start_time', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('日付別スケジュール取得エラー: $e');
      return [];
    }
  }

  /// スケジュールを追加
  Future<Map<String, dynamic>?> addSchedule({
    required String title,
    String? description,
    required DateTime date,
    required TimeOfDay startTime,
    TimeOfDay? endTime,
    bool isAllDay = false,
    String? location,
    int reminderMinutes = 0,
    String? colorHex,
  }) async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final dateString = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final startTimeString = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeString = endTime != null 
          ? '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00'
          : null;

      final scheduleData = {
        'user_id': user.id,
        'title': title,
        'description': description,
        'schedule_date': dateString,
        'start_time': startTimeString,
        'end_time': endTimeString,
        'is_all_day': isAllDay,
        'location': location,
        'reminder_minutes': reminderMinutes,
      };

      final response = await supabase
          .from('schedules')
          .insert(scheduleData)
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('スケジュール追加エラー: $e');
      return null;
    }
  }

  /// スケジュールを更新
  Future<void> updateSchedule({
    required String scheduleId,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    String? location,
    int? reminderMinutes,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (date != null) {
        updateData['schedule_date'] = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      if (startTime != null) {
        updateData['start_time'] = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      }
      if (endTime != null) {
        updateData['end_time'] = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';
      }
      if (isAllDay != null) updateData['is_all_day'] = isAllDay;
      if (location != null) updateData['location'] = location;
      if (reminderMinutes != null) updateData['reminder_minutes'] = reminderMinutes;

      if (updateData.isNotEmpty) {
        await supabase
            .from('schedules')
            .update(updateData)
            .eq('id', scheduleId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('スケジュール更新エラー: $e');
      rethrow;
    }
  }

  /// スケジュールを削除
  Future<void> deleteSchedule(String scheduleId) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('schedules')
          .delete()
          .eq('id', scheduleId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('スケジュール削除エラー: $e');
      rethrow;
    }
  }

  /// データベースのスケジュールデータをアプリ用に変換
  Map<String, dynamic> convertDatabaseScheduleToApp(Map<String, dynamic> dbSchedule) {
    final startTimeString = dbSchedule['start_time'] as String?;
    final endTimeString = dbSchedule['end_time'] as String?;
    final scheduleDateString = dbSchedule['schedule_date'] as String;

    // TIME型からTimeOfDayに変換
    TimeOfDay? parseTimeString(String? timeString) {
      if (timeString == null) return null;
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour != null && minute != null) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
      return null;
    }

    // DATE型からDateTimeに変換
    DateTime parseDate(String dateString) {
      return DateTime.parse(dateString);
    }

    // スケジュールIDを基に色パレットから色を選択
    String getScheduleColor(String scheduleId) {
      final colorPalette = ColorUtils.colorLabelPalette;
      // スケジュールIDのハッシュ値を使って色のインデックスを決定
      final hash = scheduleId.hashCode.abs();
      final colorIndex = hash % colorPalette.length;
      return colorPalette[colorIndex]['hex'] as String;
    }

    return {
      'id': dbSchedule['id'],
      'title': dbSchedule['title'],
      'description': dbSchedule['description'],
      'date': parseDate(scheduleDateString),
      'startTime': parseTimeString(startTimeString),
      'endTime': parseTimeString(endTimeString),
      'isAllDay': dbSchedule['is_all_day'] ?? false,
      'colorHex': getScheduleColor(dbSchedule['id']), // IDを基に色を選択
      'notificationMode': (dbSchedule['reminder_minutes'] as int? ?? 0) > 0 ? 'reminder' : 'none',
      'reminderMinutes': dbSchedule['reminder_minutes'] ?? 0,
      'isAlarmEnabled': false,
      'createdAt': DateTime.parse(dbSchedule['created_at']),
      'location': dbSchedule['location'],
    };
  }
} 