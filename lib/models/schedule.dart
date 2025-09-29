import 'package:flutter/material.dart';
import 'dart:convert';

/// 型安全なスケジュールモデルクラス
class Schedule {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime scheduleDate;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final bool isAllDay;
  final String? location;
  final int reminderMinutes;
  final String colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Schedule({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.scheduleDate,
    required this.startTime,
    this.endTime,
    required this.isAllDay,
    this.location,
    required this.reminderMinutes,
    required this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  });

  /// MapからScheduleオブジェクトを作成
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      scheduleDate: DateTime.parse(map['schedule_date'] as String).toLocal(),
      startTime: _parseTimeOfDay(map['start_time'] as String?),
      endTime:
          map['end_time'] != null
              ? _parseTimeOfDay(map['end_time'] as String)
              : null,
      isAllDay: map['is_all_day'] as bool? ?? false,
      location: map['location'] as String?,
      reminderMinutes: map['reminder_minutes'] as int? ?? 0,
      colorHex: map['color_hex'] as String? ?? '#E85A3B',
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }

  /// ScheduleオブジェクトをMapに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'schedule_date':
          '${scheduleDate.year}-${scheduleDate.month.toString().padLeft(2, '0')}-${scheduleDate.day.toString().padLeft(2, '0')}',
      'start_time':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00',
      'end_time':
          endTime != null
              ? '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}:00'
              : null,
      'is_all_day': isAllDay,
      'location': location,
      'reminder_minutes': reminderMinutes,
      'color_hex': colorHex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// JSON文字列からScheduleオブジェクトを作成
  factory Schedule.fromJson(String source) {
    return Schedule.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }

  /// ScheduleオブジェクトをJSON文字列に変換
  String toJson() {
    return jsonEncode(toMap());
  }

  /// 文字列の時刻をTimeOfDayに変換
  static TimeOfDay _parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) {
      return const TimeOfDay(hour: 0, minute: 0);
    }

    final parts = timeString.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return const TimeOfDay(hour: 0, minute: 0);
  }

  /// スケジュールのコピーを作成（指定されたフィールドを更新）
  Schedule copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? scheduleDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    bool? isAllDay,
    String? location,
    int? reminderMinutes,
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      location: location ?? this.location,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// スケジュールの継続時間を取得（分単位）
  int get durationInMinutes {
    if (isAllDay) return 24 * 60;
    if (endTime == null) return 60; // デフォルト1時間

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime!.hour * 60 + endTime!.minute;

    if (endMinutes > startMinutes) {
      return endMinutes - startMinutes;
    } else {
      // 翌日までの継続時間
      return (24 * 60) - startMinutes + endMinutes;
    }
  }

  /// スケジュールが今日かどうか
  bool get isToday {
    final now = DateTime.now();
    return scheduleDate.year == now.year &&
        scheduleDate.month == now.month &&
        scheduleDate.day == now.day;
  }

  /// スケジュールが過去かどうか
  bool get isPast {
    final now = DateTime.now();
    final scheduleDateTime = DateTime(
      scheduleDate.year,
      scheduleDate.month,
      scheduleDate.day,
      startTime.hour,
      startTime.minute,
    );
    return scheduleDateTime.isBefore(now);
  }

  /// スケジュールが未来かどうか
  bool get isFuture {
    return !isPast && !isToday;
  }

  /// 時刻の表示文字列を取得
  String get timeDisplayString {
    if (isAllDay) return '終日';

    final startTimeStr =
        '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

    if (endTime != null) {
      final endTimeStr =
          '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
      return '$startTimeStr - $endTimeStr';
    }

    return startTimeStr;
  }

  /// 日付の表示文字列を取得
  String get dateDisplayString {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    final scheduleDay = DateTime(
      scheduleDate.year,
      scheduleDate.month,
      scheduleDate.day,
    );

    if (scheduleDay == today) {
      return '今日';
    } else if (scheduleDay == tomorrow) {
      return '明日';
    } else if (scheduleDay == yesterday) {
      return '昨日';
    } else {
      return '${scheduleDate.month}/${scheduleDate.day}';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Schedule &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.scheduleDate == scheduleDate &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.isAllDay == isAllDay &&
        other.location == location &&
        other.reminderMinutes == reminderMinutes &&
        other.colorHex == colorHex;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      title,
      description,
      scheduleDate,
      startTime,
      endTime,
      isAllDay,
      location,
      reminderMinutes,
      colorHex,
    );
  }

  @override
  String toString() {
    return 'Schedule(id: $id, title: $title, date: $scheduleDate, time: $timeDisplayString, color: $colorHex)';
  }
}

/// スケジュールフィルター用のクラス
class ScheduleFilter {
  final String? title;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? colorHex;
  final bool? isAllDay;
  final bool? hasLocation;
  final bool? hasReminder;
  final ScheduleSortOrder sortOrder;

  const ScheduleFilter({
    this.title,
    this.startDate,
    this.endDate,
    this.colorHex,
    this.isAllDay,
    this.hasLocation,
    this.hasReminder,
    this.sortOrder = ScheduleSortOrder.dateTime,
  });

  /// フィルターに一致するかチェック
  bool matches(Schedule schedule) {
    // タイトル検索
    if (title != null && title!.isNotEmpty) {
      if (!schedule.title.toLowerCase().contains(title!.toLowerCase())) {
        return false;
      }
    }

    // 日付範囲フィルター
    if (startDate != null) {
      if (schedule.scheduleDate.isBefore(startDate!)) {
        return false;
      }
    }
    if (endDate != null) {
      if (schedule.scheduleDate.isAfter(endDate!)) {
        return false;
      }
    }

    // 色フィルター
    if (colorHex != null) {
      if (schedule.colorHex != colorHex) {
        return false;
      }
    }

    // 終日フィルター
    if (isAllDay != null) {
      if (schedule.isAllDay != isAllDay) {
        return false;
      }
    }

    // 場所フィルター
    if (hasLocation != null) {
      final hasLocationValue =
          schedule.location != null && schedule.location!.isNotEmpty;
      if (hasLocationValue != hasLocation) {
        return false;
      }
    }

    // リマインダーフィルター
    if (hasReminder != null) {
      final hasReminderValue = schedule.reminderMinutes > 0;
      if (hasReminderValue != hasReminder) {
        return false;
      }
    }

    return true;
  }

  /// フィルターが設定されているかチェック
  bool get hasFilter {
    return title != null ||
        startDate != null ||
        endDate != null ||
        colorHex != null ||
        isAllDay != null ||
        hasLocation != null ||
        hasReminder != null;
  }
}

/// スケジュールソート順
enum ScheduleSortOrder {
  dateTime, // 日時順（デフォルト）
  title, // タイトル順
  duration, // 継続時間順
  created, // 作成日時順
  updated, // 更新日時順
}

/// スケジュールリストの拡張メソッド
extension ScheduleListExtension on List<Schedule> {
  /// フィルターを適用
  List<Schedule> applyFilter(ScheduleFilter filter) {
    return where(filter.matches).toList();
  }

  /// ソートを適用
  List<Schedule> applySort(ScheduleSortOrder sortOrder) {
    switch (sortOrder) {
      case ScheduleSortOrder.dateTime:
        return _sortByDateTime();
      case ScheduleSortOrder.title:
        return _sortByTitle();
      case ScheduleSortOrder.duration:
        return _sortByDuration();
      case ScheduleSortOrder.created:
        return _sortByCreated();
      case ScheduleSortOrder.updated:
        return _sortByUpdated();
    }
  }

  /// フィルターとソートを適用
  List<Schedule> filterAndSort(ScheduleFilter filter) {
    final filtered = applyFilter(filter);
    return filtered.applySort(filter.sortOrder);
  }

  List<Schedule> _sortByDateTime() {
    final sorted = List<Schedule>.from(this);
    sorted.sort((a, b) {
      // 日付で比較
      final dateComparison = a.scheduleDate.compareTo(b.scheduleDate);
      if (dateComparison != 0) return dateComparison;

      // 日付が同じ場合は開始時刻で比較
      final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
      final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
      return aMinutes.compareTo(bMinutes);
    });
    return sorted;
  }

  List<Schedule> _sortByTitle() {
    final sorted = List<Schedule>.from(this);
    sorted.sort((a, b) => a.title.compareTo(b.title));
    return sorted;
  }

  List<Schedule> _sortByDuration() {
    final sorted = List<Schedule>.from(this);
    sorted.sort((a, b) => a.durationInMinutes.compareTo(b.durationInMinutes));
    return sorted;
  }

  List<Schedule> _sortByCreated() {
    final sorted = List<Schedule>.from(this);
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  List<Schedule> _sortByUpdated() {
    final sorted = List<Schedule>.from(this);
    sorted.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    return sorted;
  }

  /// 日付ごとにグループ化
  Map<DateTime, List<Schedule>> groupByDate() {
    final Map<DateTime, List<Schedule>> grouped = {};

    for (final schedule in this) {
      final date = DateTime(
        schedule.scheduleDate.year,
        schedule.scheduleDate.month,
        schedule.scheduleDate.day,
      );
      grouped.putIfAbsent(date, () => []).add(schedule);
    }

    // 各グループ内で時刻順にソート
    for (final schedules in grouped.values) {
      schedules.sort((a, b) {
        final aMinutes = a.startTime.hour * 60 + a.startTime.minute;
        final bMinutes = b.startTime.hour * 60 + b.startTime.minute;
        return aMinutes.compareTo(bMinutes);
      });
    }

    return grouped;
  }
}
