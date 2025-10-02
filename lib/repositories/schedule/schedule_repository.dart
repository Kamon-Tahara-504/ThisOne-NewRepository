import 'package:flutter/material.dart';
import '../../models/schedule.dart';

/// スケジュールリポジトリのインターフェース
abstract class ScheduleRepository {
  /// ユーザーのスケジュールを全て取得
  Future<List<Schedule>> getSchedules();

  /// 特定の日付のスケジュールを取得
  Future<List<Schedule>> getSchedulesForDate(DateTime date);

  /// スケジュールを追加
  Future<Schedule> createSchedule({
    required String title,
    String? description,
    required DateTime date,
    required TimeOfDay startTime,
    TimeOfDay? endTime,
    bool isAllDay = false,
    String? location,
    int reminderMinutes = 0,
    String? colorHex,
  });

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
    String? colorHex,
  });

  /// スケジュールを削除
  Future<void> deleteSchedule(String scheduleId);

  /// フィルターされたスケジュールを取得
  Future<List<Schedule>> getFilteredSchedules(ScheduleFilter filter);
}
