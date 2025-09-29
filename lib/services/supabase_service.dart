import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../models/memo.dart';
import '../models/schedule.dart';
import '../models/task.dart';

// Supabaseクライアントを使用
final supabase = Supabase.instance.client;

class SupabaseService {
  // ユーザー認証関連

  /// サインアップ
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(email: email, password: password);
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
      final response =
          await supabase
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

    await supabase.from('user_profiles').insert({
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
    if (displayName != null)
      updateData['display_name'] = displayName.isEmpty ? null : displayName;
    if (phoneNumber != null)
      updateData['phone_number'] = phoneNumber.isEmpty ? null : phoneNumber;
    if (avatarUrl != null)
      updateData['avatar_url'] = avatarUrl.isEmpty ? null : avatarUrl;

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
    final response = await supabase.from(tableName).select('*');
    return List<Map<String, dynamic>>.from(response);
  }

  /// データを挿入
  Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    await supabase.from(tableName).insert(data);
  }

  /// データを更新
  Future<void> updateData(
    String tableName,
    Map<String, dynamic> data,
    String idColumn,
    dynamic id,
  ) async {
    await supabase.from(tableName).update(data).eq(idColumn, id);
  }

  /// データを削除
  Future<void> deleteData(String tableName, String idColumn, dynamic id) async {
    await supabase.from(tableName).delete().eq(idColumn, id);
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

    final response =
        await supabase.from('tasks').insert(taskData).select().single();

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
      if (e.toString().contains(
        'column "mode" of relation "memos" does not exist',
      )) {
        try {
          final response = await supabase
              .from('memos')
              .select(
                'id, user_id, title, content, created_at, updated_at, is_pinned, tags, color_tag',
              )
              .eq('user_id', user.id)
              .order('is_pinned', ascending: false) // ピン留めを上部に
              .order('updated_at', ascending: false); // 更新日時で降順

          // modeカラムがない場合はデフォルト値を追加
          final memosWithMode =
              List<Map<String, dynamic>>.from(response)
                  .map(
                    (memo) => {...memo, 'mode': 'memo', 'rich_content': null},
                  )
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
          .update({'is_pinned': isPinned})
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
          .update({'color_tag': colorHex})
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
          .update({'mode': mode})
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
          .update({'mode': mode, 'color_tag': colorHex})
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

      final response =
          await supabase.from('memos').insert(memoData).select().single();

      return response;
    } catch (e) {
      // エラーの詳細をログに出力
      debugPrint('メモ追加エラー: $e');

      // modeカラムが存在しない場合の対処
      if (e.toString().contains(
            'column "mode" of relation "memos" does not exist',
          ) ||
          e.toString().contains(
            'column "rich_content" of relation "memos" does not exist',
          )) {
        try {
          final memoDataWithoutMode = {
            'user_id': user.id,
            'title': title,
            'content': content,
          };

          final response =
              await supabase
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
      if (richContent != null)
        updateData['rich_content'] = jsonEncode(richContent);

      await supabase
          .from('memos')
          .update(updateData)
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('メモ更新エラー: $e');

      // modeカラムやrich_contentカラムが存在しない場合の対処
      if (e.toString().contains(
            'column "mode" of relation "memos" does not exist',
          ) ||
          e.toString().contains(
            'column "rich_content" of relation "memos" does not exist',
          )) {
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
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

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
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final startTimeString =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeString =
          endTime != null
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
        'color_hex': colorHex,
      };

      final response =
          await supabase
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
        updateData['schedule_date'] =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      if (startTime != null) {
        updateData['start_time'] =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      }
      if (endTime != null) {
        updateData['end_time'] =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';
      }
      if (isAllDay != null) updateData['is_all_day'] = isAllDay;
      if (location != null) updateData['location'] = location;
      if (reminderMinutes != null)
        updateData['reminder_minutes'] = reminderMinutes;

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

  /// Google認証でサインアップ/ログイン
  Future<bool> signInWithGoogle() async {
    try {
      final result = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: null, // アプリの設定に応じて調整
      );
      return result;
    } catch (e) {
      debugPrint('Google認証エラー: $e');
      rethrow;
    }
  }

  /// X(Twitter)認証でサインアップ/ログイン
  Future<bool> signInWithTwitter() async {
    try {
      final result = await supabase.auth.signInWithOAuth(
        OAuthProvider.twitter,
        redirectTo: null, // アプリの設定に応じて調整
      );
      return result;
    } catch (e) {
      debugPrint('X認証エラー: $e');
      rethrow;
    }
  }

  /// データベースのスケジュールデータをアプリ用に変換
  Map<String, dynamic> convertDatabaseScheduleToApp(
    Map<String, dynamic> dbSchedule,
  ) {
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

    // データベースから色情報を取得、なければデフォルト色を使用
    String getScheduleColor() {
      final savedColorHex = dbSchedule['color_hex'] as String?;
      if (savedColorHex != null && savedColorHex.isNotEmpty) {
        return savedColorHex;
      }
      // デフォルト色
      return '#E85A3B';
    }

    return {
      'id': dbSchedule['id'],
      'title': dbSchedule['title'],
      'description': dbSchedule['description'],
      'date': parseDate(scheduleDateString),
      'startTime': parseTimeString(startTimeString),
      'endTime': parseTimeString(endTimeString),
      'isAllDay': dbSchedule['is_all_day'] ?? false,
      'colorHex': getScheduleColor(), // データベースの色情報を使用
      'notificationMode':
          (dbSchedule['reminder_minutes'] as int? ?? 0) > 0
              ? 'reminder'
              : 'none',
      'reminderMinutes': dbSchedule['reminder_minutes'] ?? 0,
      'isAlarmEnabled': false,
      'createdAt': DateTime.parse(dbSchedule['created_at']),
      'location': dbSchedule['location'],
    };
  }

  // 型安全なメモメソッド（新規追加）
  /// ユーザーのメモを全て取得（型安全版）
  Future<List<Memo>> getUserMemosTyped() async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final response = await supabase
          .from('memos')
          .select('*')
          .eq('user_id', user.id)
          .order('is_pinned', ascending: false) // ピン留めを上部に
          .order('updated_at', ascending: false); // 更新日時で降順

      return (response as List)
          .map((memoData) => Memo.fromMap(memoData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('メモ取得エラー: $e');

      // modeカラムが存在しない場合の対処
      if (e.toString().contains(
        'column "mode" of relation "memos" does not exist',
      )) {
        try {
          final response = await supabase
              .from('memos')
              .select(
                'id, user_id, title, content, created_at, updated_at, is_pinned, tags, color_tag',
              )
              .eq('user_id', user.id)
              .order('is_pinned', ascending: false)
              .order('updated_at', ascending: false);

          return (response as List).map((memoData) {
            final map = memoData as Map<String, dynamic>;
            // modeカラムがない場合はデフォルト値を追加
            map['mode'] = 'memo';
            map['rich_content'] = null;
            return Memo.fromMap(map);
          }).toList();
        } catch (e2) {
          debugPrint('modeなしでのメモ取得エラー: $e2');
          rethrow;
        }
      }

      rethrow;
    }
  }

  /// メモを追加（型安全版）
  Future<Memo?> addMemoTyped({
    required String title,
    String content = '',
    MemoMode mode = MemoMode.memo,
    Map<String, dynamic>? richContent,
    String? colorHex,
    List<String> tags = const [],
  }) async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final memoData = {
        'user_id': user.id,
        'title': title,
        'content': content,
        'mode': mode.value,
        'color_tag': colorHex ?? '#9E9E9E',
        'tags': tags,
        // リッチコンテンツ（QuillのDelta）をJSON文字列として保存
        'rich_content': richContent != null ? jsonEncode(richContent) : null,
      };

      final response =
          await supabase.from('memos').insert(memoData).select().single();

      return Memo.fromMap(response);
    } catch (e) {
      debugPrint('メモ追加エラー: $e');
      rethrow;
    }
  }

  /// メモを更新（型安全版）
  Future<void> updateMemoTyped(Memo memo) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('memos')
          .update(memo.toUpdateMap())
          .eq('id', memo.id)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('メモ更新エラー: $e');
      rethrow;
    }
  }

  /// メモのピン留め状態を更新（型安全版）
  Future<void> updateMemoPinStatusTyped({
    required String memoId,
    required bool isPinned,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('memos')
          .update({'is_pinned': isPinned})
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('ピン留め状態の更新エラー: $e');
      rethrow;
    }
  }

  /// メモを削除（型安全版）
  Future<void> deleteMemoTyped(String memoId) async {
    final user = getCurrentUser();
    if (user == null) return;

    await supabase
        .from('memos')
        .delete()
        .eq('id', memoId)
        .eq('user_id', user.id);
  }

  /// メモの設定（モードと色ラベル）を一括更新（型安全版）
  Future<void> updateMemoSettingsTyped({
    required String memoId,
    required MemoMode mode,
    required String colorHex,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('memos')
          .update({'mode': mode.value, 'color_tag': colorHex})
          .eq('id', memoId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('メモ設定の更新エラー: $e');
      rethrow;
    }
  }

  /// フィルター条件に基づいてメモを取得（型安全版）
  Future<List<Memo>> getFilteredMemos(MemoFilter filter) async {
    final allMemos = await getUserMemosTyped();

    // フィルター適用
    var filteredMemos = allMemos.where(filter.matches).toList();

    // ソート適用
    switch (filter.sortOrder) {
      case MemoSortOrder.pinnedFirst:
        filteredMemos.sort((a, b) {
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return b.updatedAt.compareTo(a.updatedAt);
        });
        break;
      case MemoSortOrder.createdAt:
        filteredMemos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case MemoSortOrder.updatedAt:
        filteredMemos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case MemoSortOrder.title:
        filteredMemos.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return filteredMemos;
  }

  // ========================================
  // 型安全なスケジュールメソッド（新規追加）
  // ========================================

  /// ユーザーのスケジュールを全て取得（型安全版）
  Future<List<Schedule>> getUserSchedulesTyped() async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final response = await supabase
          .from('schedules')
          .select('*')
          .eq('user_id', user.id)
          .order('schedule_date', ascending: true)
          .order('start_time', ascending: true);

      return (response as List)
          .map(
            (scheduleData) =>
                Schedule.fromMap(scheduleData as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('スケジュール取得エラー: $e');
      return [];
    }
  }

  /// 特定の日付のスケジュールを取得（型安全版）
  Future<List<Schedule>> getSchedulesForDateTyped(DateTime date) async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await supabase
          .from('schedules')
          .select('*')
          .eq('user_id', user.id)
          .eq('schedule_date', dateString)
          .order('start_time', ascending: true);

      return (response as List)
          .map(
            (scheduleData) =>
                Schedule.fromMap(scheduleData as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('日付別スケジュール取得エラー: $e');
      return [];
    }
  }

  /// スケジュールを追加（型安全版）
  Future<Schedule?> addScheduleTyped({
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
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final startTimeString =
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      final endTimeString =
          endTime != null
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
        'color_hex': colorHex ?? '#E85A3B',
      };

      final response =
          await supabase
              .from('schedules')
              .insert(scheduleData)
              .select()
              .single();

      return Schedule.fromMap(response);
    } catch (e) {
      debugPrint('スケジュール追加エラー: $e');
      return null;
    }
  }

  /// スケジュールを更新（型安全版）
  Future<void> updateScheduleTyped({
    required String scheduleId,
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    String? location,
    int? reminderMinutes,
    String? colorHex,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (date != null) {
        updateData['schedule_date'] =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
      if (startTime != null) {
        updateData['start_time'] =
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
      }
      if (endTime != null) {
        updateData['end_time'] =
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';
      }
      if (isAllDay != null) updateData['is_all_day'] = isAllDay;
      if (location != null) updateData['location'] = location;
      if (reminderMinutes != null)
        updateData['reminder_minutes'] = reminderMinutes;
      if (colorHex != null) updateData['color_hex'] = colorHex;

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

  /// スケジュールを削除（型安全版）
  Future<void> deleteScheduleTyped(String scheduleId) async {
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

  /// フィルターされたスケジュールを取得（型安全版）
  Future<List<Schedule>> getFilteredSchedules(ScheduleFilter filter) async {
    final allSchedules = await getUserSchedulesTyped();

    // フィルター適用
    var filteredSchedules = allSchedules.where(filter.matches).toList();

    // ソート適用
    switch (filter.sortOrder) {
      case ScheduleSortOrder.dateTime:
        filteredSchedules.sort((a, b) {
          final dateComparison = a.scheduleDate.compareTo(b.scheduleDate);
          if (dateComparison != 0) return dateComparison;
          final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
          final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
          return aMinutes.compareTo(bMinutes);
        });
        break;
      case ScheduleSortOrder.title:
        filteredSchedules.sort((a, b) => a.title.compareTo(b.title));
        break;
      case ScheduleSortOrder.duration:
        filteredSchedules.sort(
          (a, b) => a.durationInMinutes.compareTo(b.durationInMinutes),
        );
        break;
      case ScheduleSortOrder.created:
        filteredSchedules.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case ScheduleSortOrder.updated:
        filteredSchedules.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
    }

    return filteredSchedules;
  }

  // 型安全なタスクメソッド（新規追加）

  /// ユーザーのタスクを全て取得（型安全版）
  Future<List<Task>> getUserTasksTyped() async {
    final user = getCurrentUser();
    if (user == null) return [];

    try {
      final response = await supabase
          .from('tasks')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List)
          .map((taskData) => Task.fromMap(taskData as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('タスク取得エラー: $e');
      return [];
    }
  }

  /// タスクを追加（型安全版）
  Future<Task?> addTaskTyped({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.low,
  }) async {
    final user = getCurrentUser();
    if (user == null) return null;

    try {
      final taskData = {
        'user_id': user.id,
        'title': title,
        'description': description,
        'due_date': dueDate?.toIso8601String(),
        'priority': priority.value,
        'is_completed': false,
      };

      final response =
          await supabase.from('tasks').insert(taskData).select().single();

      return Task.fromMap(response);
    } catch (e) {
      debugPrint('タスク追加エラー: $e');
      return null;
    }
  }

  /// タスクの完了状態を更新（型安全版）
  Future<void> updateTaskCompletionTyped({
    required String taskId,
    required bool isCompleted,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('tasks')
          .update({
            'is_completed': isCompleted,
            'completed_at':
                isCompleted ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', taskId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('タスク完了状態更新エラー: $e');
      rethrow;
    }
  }

  /// タスクを削除（型安全版）
  Future<void> deleteTaskTyped(String taskId) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      await supabase
          .from('tasks')
          .delete()
          .eq('id', taskId)
          .eq('user_id', user.id);
    } catch (e) {
      debugPrint('タスク削除エラー: $e');
      rethrow;
    }
  }

  /// タスクを更新（型安全版）
  Future<void> updateTaskTyped({
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    try {
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (priority != null) updateData['priority'] = priority.value;

      if (updateData.isNotEmpty) {
        await supabase
            .from('tasks')
            .update(updateData)
            .eq('id', taskId)
            .eq('user_id', user.id);
      }
    } catch (e) {
      debugPrint('タスク更新エラー: $e');
      rethrow;
    }
  }

  /// フィルターされたタスクを取得（型安全版）
  Future<List<Task>> getFilteredTasks(TaskFilter filter) async {
    final allTasks = await getUserTasksTyped();

    // フィルター適用
    var filteredTasks = allTasks.where(filter.matches).toList();

    // ソート適用
    switch (filter.sortOrder) {
      case TaskSortOrder.createdAt:
        filteredTasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TaskSortOrder.updatedAt:
        filteredTasks.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case TaskSortOrder.title:
        filteredTasks.sort((a, b) => a.title.compareTo(b.title));
        break;
      case TaskSortOrder.priority:
        filteredTasks.sort(
          (a, b) => b.priority.value.compareTo(a.priority.value),
        );
        break;
      case TaskSortOrder.dueDate:
        filteredTasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case TaskSortOrder.completedAt:
        filteredTasks.sort((a, b) {
          if (a.completedAt == null && b.completedAt == null) return 0;
          if (a.completedAt == null) return 1;
          if (b.completedAt == null) return -1;
          return b.completedAt!.compareTo(a.completedAt!);
        });
        break;
    }

    return filteredTasks;
  }
}
