import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../gradients.dart';
import '../widgets/schedule/add_schedule_bottom_sheet.dart';
import '../widgets/overlays/custom_bottom_sheet.dart';
import '../services/supabase_service.dart';

class ScheduleScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const ScheduleScreen({super.key, this.scrollController});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final Map<DateTime, List<Map<String, dynamic>>> _schedules = {};
  final SupabaseService _supabaseService = SupabaseService();
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  /// Supabaseからスケジュールデータを読み込み
  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final dbSchedules = await _supabaseService.getUserSchedules();

      // データベースのデータをアプリ用に変換してMapに格納
      final scheduleMap = <DateTime, List<Map<String, dynamic>>>{};

      for (final dbSchedule in dbSchedules) {
        final appSchedule = _supabaseService.convertDatabaseScheduleToApp(
          dbSchedule,
        );
        final date = DateTime(
          appSchedule['date'].year,
          appSchedule['date'].month,
          appSchedule['date'].day,
        );

        if (scheduleMap[date] != null) {
          scheduleMap[date]!.add(appSchedule);
        } else {
          scheduleMap[date] = [appSchedule];
        }
      }

      setState(() {
        _schedules.clear();
        _schedules.addAll(scheduleMap);
      });
    } catch (e) {
      debugPrint('スケジュール読み込みエラー: $e');
      // エラーダイアログを表示（オプション）
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('スケジュールの読み込みに失敗しました: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// スケジュールを削除（データベースからも削除）
  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
    try {
      // データベースから削除
      await _supabaseService.deleteSchedule(schedule['id']);

      // ローカルのMapからも削除
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

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('スケジュールを削除しました')));
      }
    } catch (e) {
      debugPrint('スケジュール削除エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
      }
    }
  }

  List<Map<String, dynamic>> _getSchedulesForDate(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _schedules[normalizedDate] ?? [];
  }

  /// カレンダー表示形式を切り替える
  void _toggleCalendarFormat() {
    setState(() {
      switch (_calendarFormat) {
        case CalendarFormat.month:
          _calendarFormat = CalendarFormat.twoWeeks;
          break;
        case CalendarFormat.twoWeeks:
          _calendarFormat = CalendarFormat.week;
          break;
        case CalendarFormat.week:
          _calendarFormat = CalendarFormat.month;
          break;
      }
    });
  }

  /// 現在のカレンダー表示形式に応じたテキストを取得
  String _getCalendarFormatText() {
    switch (_calendarFormat) {
      case CalendarFormat.month:
        return 'Month';
      case CalendarFormat.twoWeeks:
        return '2 Weeks';
      case CalendarFormat.week:
        return 'Week';
    }
  }

  /// スケジュールを追加（データベースにも保存）
  Future<void> _addSchedule(Map<String, dynamic> schedule) async {
    try {
      // データベースに保存
      final dbSchedule = await _supabaseService.addSchedule(
        title: schedule['title'],
        description: schedule['description'],
        date: schedule['date'],
        startTime: schedule['startTime'],
        endTime: schedule['endTime'],
        isAllDay: schedule['isAllDay'],
        reminderMinutes: schedule['reminderMinutes'],
        colorHex: schedule['colorHex'],
      );

      if (dbSchedule != null) {
        // データベースの結果をアプリ用に変換（IDベースの色が自動的に設定される）
        final appSchedule = _supabaseService.convertDatabaseScheduleToApp(
          dbSchedule,
        );

        // ローカルのMapに追加
        setState(() {
          final date = DateTime(
            schedule['date'].year,
            schedule['date'].month,
            schedule['date'].day,
          );
          if (_schedules[date] != null) {
            _schedules[date]!.add(appSchedule);
          } else {
            _schedules[date] = [appSchedule];
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('スケジュールを保存しました')));
        }
      } else {
        throw Exception('データベースへの保存に失敗しました');
      }
    } catch (e) {
      debugPrint('スケジュール追加エラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    }
  }

  // 外部（MainScreenなど）から呼び出すためのpublicメソッド
  void addScheduleFromExternal() {
    showCustomBottomSheet(
      context: context,
      initialHeight: 0.75, // 0.7から0.75に変更
      minHeight: 0.3,
      maxHeight: 0.95,
      enableDrag: true,
      snapToInitial: true,
      child: AddScheduleBottomSheet(
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
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFE85A3B)),
              )
              : CustomScrollView(
                controller: widget.scrollController,
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
                      child: Column(
                        children: [
                          // カスタムヘッダー
                          Container(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // 左矢印
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _focusedDate = DateTime(
                                        _focusedDate.year,
                                        _focusedDate.month - 1,
                                      );
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.chevron_left,
                                    color: Colors.white,
                                  ),
                                  iconSize: 24,
                                  splashRadius: 20,
                                ),

                                // 中央に配置するためのSpacer
                                const Spacer(),

                                // 年月表示
                                Text(
                                  '${_focusedDate.year}年${_focusedDate.month}月',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // 表示形式切り替えボタン
                                GestureDetector(
                                  onTap: _toggleCalendarFormat,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient:
                                          createHorizontalOrangeYellowGradient(),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _getCalendarFormatText(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // 中央に配置するためのSpacer
                                const Spacer(),

                                // 右矢印
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _focusedDate = DateTime(
                                        _focusedDate.year,
                                        _focusedDate.month + 1,
                                      );
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.chevron_right,
                                    color: Colors.white,
                                  ),
                                  iconSize: 24,
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                          ),

                          // TableCalendar（ヘッダー非表示）
                          TableCalendar<Map<String, dynamic>>(
                            firstDay: DateTime.utc(2020, 1, 1),
                            lastDay: DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDate,
                            selectedDayPredicate:
                                (day) => isSameDay(_selectedDate, day),
                            calendarFormat: _calendarFormat,
                            eventLoader: _getSchedulesForDate,
                            startingDayOfWeek: StartingDayOfWeek.sunday,
                            headerVisible: false,
                            calendarStyle: CalendarStyle(
                              outsideDaysVisible: true,
                              weekendTextStyle: const TextStyle(
                                color: Colors.white,
                              ),
                              defaultTextStyle: const TextStyle(
                                color: Colors.white,
                              ),
                              // 前月・次月の日付スタイル（薄いグレー）
                              outsideTextStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                              // 過去の日付も白色で表示（期限切れでも色を変えない）
                              todayTextStyle: const TextStyle(
                                color: Colors.white,
                              ),
                              selectedTextStyle: const TextStyle(
                                color: Colors.white,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              todayDecoration: BoxDecoration(
                                gradient: createOrangeYellowGradient(),
                                shape: BoxShape.circle,
                              ),
                              markerDecoration: const BoxDecoration(
                                color: Colors.transparent,
                              ),
                              markersMaxCount: 1,
                              markerSize: 0,
                            ),
                            calendarBuilders: CalendarBuilders(
                              // 曜日ビルダー（日〜土）
                              dowBuilder: (context, day) {
                                final weekdays = [
                                  '日',
                                  '月',
                                  '火',
                                  '水',
                                  '木',
                                  '金',
                                  '土',
                                ];
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

                              selectedBuilder: (context, day, focusedDay) {
                                final isToday = isSameDay(day, DateTime.now());

                                return Container(
                                  margin: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: createOrangeYellowGradient(),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3A3A3A), // 背景色に合わせる
                                      shape: BoxShape.circle,
                                    ),
                                    child:
                                        isToday
                                            ? Container(
                                              margin: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                gradient:
                                                    createOrangeYellowGradient(),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  day.day.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            )
                                            : Center(
                                              child: Text(
                                                day.day.toString(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
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
                                          eventCount > 99
                                              ? '99+'
                                              : eventCount.toString(),
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
                        ],
                      ),
                    ),
                  ),

                  // スケジュールリストのタイトル
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                                  shaderCallback:
                                      (bounds) => createOrangeYellowGradient()
                                          .createShader(bounds),
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
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final schedule = todaySchedules[index];
                            final isAllDay = schedule['isAllDay'] ?? false;
                            final startTime =
                                schedule['startTime'] ??
                                schedule['time'] as TimeOfDay?;
                            final endTime = schedule['endTime'] as TimeOfDay?;
                            final colorHex = schedule['colorHex'] ?? '#E85A3B';
                            final scheduleColor = Color(
                              int.parse(colorHex.substring(1), radix: 16) +
                                  0xFF000000,
                            );
                            final isNotificationEnabled =
                                schedule['notificationMode'] != 'none' &&
                                schedule['notificationMode'] != null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A3A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[700]!),
                              ),
                              child: IntrinsicHeight(
                                child: Row(
                                  children: [
                                    // 左側の色バー（メモと同じスタイル）
                                    Container(
                                      width: 8,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: scheduleColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          bottomLeft: Radius.circular(12),
                                        ),
                                      ),
                                    ),
                                    // スケジュール本体部分
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // タイトル行
                                            Row(
                                              children: [
                                                // 時間表示（大きくする）
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: scheduleColor
                                                        .withValues(alpha: 0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: scheduleColor
                                                          .withValues(
                                                            alpha: 0.5,
                                                          ),
                                                    ),
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
                                                      fontSize: 14, // 10から14に変更
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    schedule['title'],
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                                // 通知アイコン
                                                if (isNotificationEnabled)
                                                  Icon(
                                                    Icons.notifications,
                                                    color: Colors.grey[500],
                                                    size: 18,
                                                  ),
                                                const SizedBox(width: 4),
                                                // 削除ボタン
                                                IconButton(
                                                  onPressed:
                                                      () => _deleteSchedule(
                                                        schedule,
                                                      ),
                                                  icon: Icon(
                                                    Icons.delete_outline,
                                                    color: Colors.grey[500],
                                                    size: 20,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // 説明文（ある場合のみ表示）
                                            if (schedule['description']
                                                    ?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                schedule['description'],
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }, childCount: todaySchedules.length),
                        ),
                      ),

                  // 最下部の余白
                  const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
                ],
              ),
    );
  }
}
