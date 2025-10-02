import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/schedule.dart';
import '../../repositories/schedule/schedule_repository.dart';

/// スケジュールの状態
class ScheduleState {
  final List<Schedule> schedules;
  final bool isLoading;
  final String? error;

  const ScheduleState({
    this.schedules = const [],
    this.isLoading = false,
    this.error,
  });

  ScheduleState copyWith({
    List<Schedule>? schedules,
    bool? isLoading,
    String? error,
  }) {
    return ScheduleState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// スケジュールの状態管理クラス
class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleNotifier(this._repository) : super(const ScheduleState());

  /// スケジュール一覧を取得
  Future<void> loadSchedules() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedules = await _repository.getSchedules();
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'スケジュールの取得に失敗しました: $e');
    }
  }

  /// 特定の日付のスケジュールを取得
  Future<void> loadSchedulesForDate(DateTime date) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedules = await _repository.getSchedulesForDate(date);
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '日付別スケジュールの取得に失敗しました: $e',
      );
    }
  }

  /// スケジュールを追加
  Future<void> addSchedule({
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
      final newSchedule = await _repository.createSchedule(
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

      // ローカルの状態を更新
      state = state.copyWith(schedules: [...state.schedules, newSchedule]);
    } catch (e) {
      state = state.copyWith(error: 'スケジュールの追加に失敗しました: $e');
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
    String? colorHex,
  }) async {
    try {
      await _repository.updateSchedule(
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

      // データを再読み込み
      await loadSchedules();
    } catch (e) {
      state = state.copyWith(error: 'スケジュールの更新に失敗しました: $e');
    }
  }

  /// スケジュールを削除
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      await _repository.deleteSchedule(scheduleId);

      // ローカルの状態を更新
      state = state.copyWith(
        schedules:
            state.schedules
                .where((schedule) => schedule.id != scheduleId)
                .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'スケジュールの削除に失敗しました: $e');
    }
  }

  /// フィルターされたスケジュールを取得
  Future<void> loadFilteredSchedules(ScheduleFilter filter) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final schedules = await _repository.getFilteredSchedules(filter);
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'フィルターされたスケジュールの取得に失敗しました: $e',
      );
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}
