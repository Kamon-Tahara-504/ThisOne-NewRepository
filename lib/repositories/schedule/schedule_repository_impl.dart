import 'package:flutter/material.dart';
import 'schedule_repository.dart';
import '../core/repository_exceptions.dart';
import '../../models/schedule.dart';
import '../../services/supabase_service.dart';

/// Supabaseを使ったScheduleRepositoryの実装
class ScheduleRepositoryImpl implements ScheduleRepository {
  final SupabaseService _supabaseService;

  ScheduleRepositoryImpl(this._supabaseService);

  @override
  Future<List<Schedule>> getSchedules() async {
    try {
      return await _supabaseService.getUserSchedulesTyped();
    } catch (e) {
      throw ScheduleRepositoryException('スケジュールの取得に失敗しました', e);
    }
  }

  @override
  Future<List<Schedule>> getSchedulesForDate(DateTime date) async {
    try {
      return await _supabaseService.getSchedulesForDateTyped(date);
    } catch (e) {
      throw ScheduleRepositoryException('日付別スケジュールの取得に失敗しました', e);
    }
  }

  @override
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
  }) async {
    try {
      final schedule = await _supabaseService.addScheduleTyped(
        title: title,
        description: description,
        date: date,
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        location: location,
        reminderMinutes: reminderMinutes,
        colorHex: colorHex,
      );

      if (schedule == null) {
        throw ScheduleRepositoryException('スケジュールの作成に失敗しました');
      }

      return schedule;
    } catch (e) {
      throw ScheduleRepositoryException('スケジュールの作成に失敗しました', e);
    }
  }

  @override
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
  }) async {
    try {
      await _supabaseService.updateScheduleTyped(
        scheduleId: scheduleId,
        title: title,
        description: description,
        date: date,
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        location: location,
        reminderMinutes: reminderMinutes,
        colorHex: colorHex,
      );
    } catch (e) {
      throw ScheduleRepositoryException('スケジュールの更新に失敗しました', e);
    }
  }

  @override
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _supabaseService.deleteScheduleTyped(scheduleId);
    } catch (e) {
      throw ScheduleRepositoryException('スケジュールの削除に失敗しました', e);
    }
  }

  @override
  Future<List<Schedule>> getFilteredSchedules(ScheduleFilter filter) async {
    try {
      return await _supabaseService.getFilteredSchedules(filter);
    } catch (e) {
      throw ScheduleRepositoryException('フィルターされたスケジュールの取得に失敗しました', e);
    }
  }
}
