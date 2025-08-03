import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../gradients.dart';
import '../widgets/schedule/add_schedule_bottom_sheet.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final Map<DateTime, List<Map<String, dynamic>>> _schedules = {};
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  void _deleteSchedule(Map<String, dynamic> schedule) {
    setState(() {
      final date = DateTime(
        schedule['date'].year,
        schedule['date'].month,
        schedule['date'].day,
      );
      _schedules[date]?.remove(schedule);
      if (_schedules[date]?.isEmpty == true) {
        _schedules.remove(date);
      }
    });
  }

  List<Map<String, dynamic>> _getSchedulesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _schedules[normalizedDate] ?? [];
  }

  void _addSchedule(Map<String, dynamic> schedule) {
    setState(() {
      final date = DateTime(
        schedule['date'].year,
        schedule['date'].month,
        schedule['date'].day,
      );
      if (_schedules[date] != null) {
        _schedules[date]!.add(schedule);
      } else {
        _schedules[date] = [schedule];
      }
    });
  }

  // 外部（MainScreenなど）から呼び出すためのpublicメソッド
  void addScheduleFromExternal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true,
      builder: (context) => AddScheduleBottomSheet(
        selectedDate: _selectedDate,
        onAdd: _addSchedule,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todaySchedules = _getSchedulesForDate(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: CustomScrollView(
        slivers: [
          // カレンダー部分
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: TableCalendar<Map<String, dynamic>>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDate,
                selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
                calendarFormat: _calendarFormat,
                eventLoader: _getSchedulesForDate,
                startingDayOfWeek: StartingDayOfWeek.sunday,
                locale: 'ja_JP',
                calendarStyle: CalendarStyle(
                  // 背景色
                  outsideDaysVisible: true,
                  weekendTextStyle: const TextStyle(color: Colors.white),
                  holidayTextStyle: const TextStyle(color: Colors.white),
                  defaultTextStyle: const TextStyle(color: Colors.white),
                  // 前月・次月の日付スタイル（薄いグレー）
                  outsideTextStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  // 選択された日
                  selectedDecoration: BoxDecoration(
                    gradient: createOrangeYellowGradient(),
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  // 今日
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFFE85A3B).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                                  // イベントマーカー（カスタム数値表示を使用）
                markersMaxCount: 0, // デフォルトマーカーを無効化
                markerSize: 0, // デフォルトマーカーサイズを0に
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    gradient: createOrangeYellowGradient(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  leftChevronIcon: const Icon(
                    Icons.chevron_left,
                    color: Colors.white,
                  ),
                  rightChevronIcon: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                  titleTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  titleTextFormatter: (date, locale) {
                    return DateFormat.yMMMM('ja_JP').format(date);
                  },
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekendStyle: TextStyle(color: Colors.white),
                  weekdayStyle: TextStyle(color: Colors.white),
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    final weekdays = ['日', '月', '火', '水', '木', '金', '土'];
                    return Center(
                      child: Text(
                        weekdays[day.weekday % 7],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                  markerBuilder: (context, day, events) {
                    final eventCount = events.length;
                    if (eventCount > 0) {
                      return Positioned(
                        right: 1,
                        bottom: 1,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          width: 18,
                          height: 18,
                          child: Center(
                            child: Text(
                              eventCount > 99 ? '99+' : eventCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDate = selectedDay;
                    _focusedDate = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDate = focusedDay;
                },
              ),
            ),
          ),
          
          // スケジュールリストのタイトル
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日のスケジュール',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          // スケジュールリスト部分
          todaySchedules.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShaderMask(
                            shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
                            child: const Icon(
                              Icons.event_note,
                              size: 48,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'この日にスケジュールはありません',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final schedule = todaySchedules[index];
                        final isAllDay = schedule['isAllDay'] ?? false;
                        final startTime = schedule['startTime'] ?? schedule['time'] as TimeOfDay?;
                        final endTime = schedule['endTime'] as TimeOfDay?;
                        final colorHex = schedule['colorHex'] ?? '#E85A3B';
                        final scheduleColor = Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
                        final isNotificationEnabled = schedule['notificationMode'] != 'none' && schedule['notificationMode'] != null;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 色ラベル
                                Container(
                                  width: 4,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: scheduleColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 時間表示
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheduleColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: scheduleColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    isAllDay 
                                        ? '終日'
                                        : startTime != null
                                            ? endTime != null
                                                ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}-${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'
                                                : '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'
                                            : '--:--',
                                    style: TextStyle(
                                      color: scheduleColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    schedule['title'],
                                    style: const TextStyle(color: Colors.white, fontSize: 14),
                                  ),
                                ),
                                // 通知アイコン
                                if (isNotificationEnabled)
                                  Icon(
                                    Icons.notifications,
                                    color: Colors.grey[500],
                                    size: 16,
                                  ),
                              ],
                            ),
                            subtitle: schedule['description']?.isNotEmpty == true
                                ? Text(
                                    schedule['description'],
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            trailing: IconButton(
                              onPressed: () => _deleteSchedule(schedule),
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.grey[500],
                                size: 18,
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: todaySchedules.length,
                    ),
                  ),
                ),
          
          // 最下部の余白
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 16),
          ),
        ],
      ),
    );
  }
} 