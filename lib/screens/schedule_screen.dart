import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../gradients.dart';
import '../utils/color_utils.dart';

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
      builder: (context) => _AddScheduleBottomSheet(
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
      body: Column(
        children: [
          // カレンダー
          Container(
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
                // イベントマーカー
                markerDecoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                markerSize: 6,
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
          // 選択された日のスケジュールリスト
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      '${_selectedDate.year}年${_selectedDate.month}月${_selectedDate.day}日のスケジュール',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: todaySchedules.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
                                  child: Icon(
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
                          )
                        : ListView.builder(
                            itemCount: todaySchedules.length,
                            itemBuilder: (context, index) {
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
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AddScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onAdd;

  const _AddScheduleBottomSheet({
    required this.selectedDate,
    required this.onAdd,
  });

  @override
  State<_AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<_AddScheduleBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  bool _isAllDay = false;
  String _selectedColorHex = '#9E9E9E';
  bool _isNotificationEnabled = false;
  int _reminderMinutes = 15;
  bool _showDetailedSettings = false;
  late PageController _pageController;



  // 通知時間オプション
  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': '5分前', 'minutes': 5},
    {'label': '15分前', 'minutes': 15},
    {'label': '30分前', 'minutes': 30},
    {'label': '1時間前', 'minutes': 60},
    {'label': '1日前', 'minutes': 1440},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _addSchedule() {
    if (_titleController.text.trim().isNotEmpty) {
      widget.onAdd({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': widget.selectedDate,
        'startTime': _startTime,
        'endTime': _endTime,
        'isAllDay': _isAllDay,
        'colorHex': _selectedColorHex,
        'notificationMode': _isNotificationEnabled ? 'reminder' : 'none',
        'reminderMinutes': _isNotificationEnabled ? _reminderMinutes : 0,
        'isAlarmEnabled': false,
        'createdAt': DateTime.now(),
      });
      Navigator.pop(context);
    }
  }

  Widget _buildColorOption(Map<String, dynamic> colorOption) {
    final isSelected = _selectedColorHex == colorOption['hex'];
    final colorHex = colorOption['hex'] as String;
    final isGradient = colorOption['isGradient'] as bool;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedColorHex = colorHex),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: isGradient ? ColorUtils.getGradientFromHex(colorHex) : null,
          color: isGradient ? null : ColorUtils.getColorFromHex(colorHex),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 14,
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF2B2B2B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const PageScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _showDetailedSettings = index == 1;
                });
              },
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildBasicSettings(),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _buildDetailedSettings(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 第1段階：基本設定
  Widget _buildBasicSettings() {
    return Column(
      key: const ValueKey('basic'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付表示
        Text(
          '${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        // タイトル
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
              child: const Icon(
                Icons.event_note,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'スケジュール作成',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // タイトル入力
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'タイトル',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'スケジュールのタイトルを入力...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 時間設定
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 終日設定
                Row(
                  children: [
                    const Text(
                      '終日',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _isAllDay,
                      onChanged: (value) => setState(() => _isAllDay = value),
                      activeColor: const Color(0xFFE85A3B),
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[700],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 時間設定
                AnimatedOpacity(
                  opacity: _isAllDay ? 0.3 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: _isAllDay,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '開始時間',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _startTime,
                                  );
                                  if (time != null) {
                                    setState(() => _startTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3A3A3A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[600]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '終了時間',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () async {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: _endTime,
                                  );
                                  if (time != null) {
                                    setState(() => _endTime = time);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3A3A3A),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[600]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.access_time, color: Colors.grey[400], size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(color: Colors.white, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 色設定
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '色ラベル',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // カラーパレット（横スクロール一列）
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const SizedBox(width: 8), // 左端の余白
                      for (int i = 0; i < ColorUtils.colorLabelPalette.length; i++) ...[
                        _buildColorOption(ColorUtils.colorLabelPalette[i]),
                        if (i < ColorUtils.colorLabelPalette.length - 1)
                          const SizedBox(width: 12), // アイテム間の間隔
                      ],
                      const SizedBox(width: 8), // 右端の余白
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // ボタン
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    '詳細設定',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: createHorizontalOrangeYellowGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _addSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '作成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 第2段階：詳細設定
  Widget _buildDetailedSettings() {
    return Column(
      key: const ValueKey('detailed'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日付表示
        Text(
          '${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        // タイトル
        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '詳細設定',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 説明入力
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '説明',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[600]!),
                  ),
                  child: TextField(
                    controller: _descriptionController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: '詳細な説明を入力...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        
        // 通知設定
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[700]!, width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 通知スイッチ
                Row(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '通知を有効にする',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Switch(
                      value: _isNotificationEnabled,
                      onChanged: (value) => setState(() => _isNotificationEnabled = value),
                      activeColor: const Color(0xFFE85A3B),
                      inactiveThumbColor: Colors.grey[400],
                      inactiveTrackColor: Colors.grey[700],
                    ),
                  ],
                ),
                
                // 通知設定詳細
                AnimatedOpacity(
                  opacity: _isNotificationEnabled ? 1.0 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_isNotificationEnabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        const Text(
                          '通知タイミング',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _reminderOptions.map((option) {
                            final isSelected = _reminderMinutes == option['minutes'];
                            return GestureDetector(
                              onTap: () => setState(() => _reminderMinutes = option['minutes']),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFE85A3B) : const Color(0xFF3A3A3A),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Colors.transparent : Colors.grey[600]!,
                                  ),
                                ),
                                child: Text(
                                  option['label'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // ボタン
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[600]!),
                ),
                child: TextButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text(
                    '戻る',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: createHorizontalOrangeYellowGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: _addSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'スケジュールを作成',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
} 