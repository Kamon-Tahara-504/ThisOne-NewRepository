import 'package:flutter/material.dart';
import '../../gradients.dart';
import '../../utils/color_utils.dart';
import 'time_setting_widget.dart';

class AddScheduleBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final Function(Map<String, dynamic>) onAdd;

  const AddScheduleBottomSheet({
    super.key,
    required this.selectedDate,
    required this.onAdd,
  });

  @override
  State<AddScheduleBottomSheet> createState() => _AddScheduleBottomSheetState();
}

class _AddScheduleBottomSheetState extends State<AddScheduleBottomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  );
  bool _isAllDay = false;
  String _selectedColorHex = '#9E9E9E';
  bool _isNotificationEnabled = false;
  int _reminderMinutes = 15;
  int _timeInterval = 5; // 時間間隔（分単位）
  bool _isCustomReminder = false;
  int _customValue = 15;
  String _customUnit = 'minutes'; // 'minutes', 'hours', 'days'

  // 通知時間オプション
  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': '5分前', 'minutes': 5},
    {'label': '15分前', 'minutes': 15},
    {'label': '30分前', 'minutes': 30},
    {'label': '1時間前', 'minutes': 60},
    {'label': '1日前', 'minutes': 1440},
    {'label': 'カスタム', 'minutes': -1}, // -1はカスタムの識別子
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // カスタム時間を分単位で計算
  int _getCustomReminderMinutes() {
    switch (_customUnit) {
      case 'minutes':
        return _customValue;
      case 'hours':
        return _customValue * 60;
      case 'days':
        return _customValue * 1440;
      default:
        return _customValue;
    }
  }

  // カスタム設定ダイアログを表示
  void _showCustomReminderDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => _CustomReminderDialog(
            initialValue: _customValue,
            initialUnit: _customUnit,
          ),
    );

    if (result != null) {
      setState(() {
        _customValue = result['value'];
        _customUnit = result['unit'];
        _isCustomReminder = true;
        _reminderMinutes = _getCustomReminderMinutes();
      });
    }
  }

  void _addSchedule() {
    if (_titleController.text.trim().isNotEmpty) {
      final finalReminderMinutes =
          _isCustomReminder ? _getCustomReminderMinutes() : _reminderMinutes;

      final startForSave =
          _isAllDay ? const TimeOfDay(hour: 0, minute: 0) : _startTime;
      final TimeOfDay? endForSave = _isAllDay ? null : _endTime;

      widget.onAdd({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': widget.selectedDate,
        'startTime': startForSave,
        'endTime': endForSave,
        'isAllDay': _isAllDay,
        'colorHex': _selectedColorHex,
        'notificationMode': _isNotificationEnabled ? 'reminder' : 'none',
        'reminderMinutes': _isNotificationEnabled ? finalReminderMinutes : 0,
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
          boxShadow: null,
        ),
        child:
            isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 入力欄以外をタップした時にキーボードを格納
        FocusScope.of(context).unfocus();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          // ハンドルタッチエリア
          Container(
            width: double.infinity,
            height: 24,
            decoration: BoxDecoration(
              gradient: createHorizontalOrangeYellowGradient(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Center(
              child: Container(
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 8,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 日付表示
                  Text(
                    '${widget.selectedDate.year}年${widget.selectedDate.month}月${widget.selectedDate.day}日',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  // タイトル
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback:
                            (bounds) => createOrangeYellowGradient()
                                .createShader(bounds),
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
                  const SizedBox(height: 20),

                  // 基本設定セクション
                  _buildBasicSettings(),
                  const SizedBox(height: 20),

                  // 時間設定セクション
                  TimeSettingWidget(
                    startTime: _startTime,
                    endTime: _endTime,
                    timeInterval: _timeInterval,
                    isAllDay: _isAllDay,
                    onTimeChange: (newStartTime, newEndTime, newInterval) {
                      setState(() {
                        _startTime = newStartTime;
                        _endTime = newEndTime;
                        _timeInterval = newInterval;
                      });
                    },
                    onAllDayChange: (value) {
                      setState(() {
                        _isAllDay = value;
                        if (value) {
                          _startTime = const TimeOfDay(hour: 0, minute: 0);
                          _endTime = const TimeOfDay(hour: 23, minute: 59);
                        }
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // 通知設定セクション
                  _buildNotificationSettings(),

                  const SizedBox(height: 20),

                  // 作成ボタン
                  Container(
                    width: double.infinity,
                    height: 56,
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 基本設定セクション
  Widget _buildBasicSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // タイトル入力
        Column(
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
        const SizedBox(height: 10),

        // 説明入力
        Column(
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
        const SizedBox(height: 10),

        // 色設定
        Column(
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
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[600]!),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // カラーパレット（横スクロール一列）
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const SizedBox(width: 8), // 左端の余白
                          for (
                            int i = 0;
                            i < ColorUtils.colorLabelPalette.length;
                            i++
                          ) ...[
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
          ],
        ),
      ],
    );
  }

  // 通知設定セクション
  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 通知スイッチ
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '通知設定',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isNotificationEnabled = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          !_isNotificationEnabled
                              ? const Color(0xFFE85A3B)
                              : const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            !_isNotificationEnabled
                                ? Colors.transparent
                                : Colors.grey[600]!,
                      ),
                    ),
                    child: const Text(
                      '通知なし',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _isNotificationEnabled = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _isNotificationEnabled
                              ? const Color(0xFFE85A3B)
                              : const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            _isNotificationEnabled
                                ? Colors.transparent
                                : Colors.grey[600]!,
                      ),
                    ),
                    child: const Text(
                      '通知あり',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          children:
                              _reminderOptions.map((option) {
                                final isCustomOption = option['minutes'] == -1;
                                final isSelected =
                                    isCustomOption
                                        ? _isCustomReminder
                                        : _reminderMinutes ==
                                                option['minutes'] &&
                                            !_isCustomReminder;

                                return GestureDetector(
                                  onTap: () {
                                    if (isCustomOption) {
                                      _showCustomReminderDialog();
                                    } else {
                                      setState(() {
                                        _isCustomReminder = false;
                                        _reminderMinutes = option['minutes'];
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? const Color(0xFFE85A3B)
                                              : const Color(0xFF3A3A3A),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.transparent
                                                : Colors.grey[600]!,
                                      ),
                                    ),
                                    child: Text(
                                      isCustomOption && _isCustomReminder
                                          ? 'カスタム ($_customValue${_customUnit == 'minutes'
                                              ? '分'
                                              : _customUnit == 'hours'
                                              ? '時間'
                                              : '日'}前)'
                                          : option['label'],
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
      ],
    );
  }
}

// カスタム通知設定用の独立ダイアログ
class _CustomReminderDialog extends StatefulWidget {
  final int initialValue;
  final String initialUnit;

  const _CustomReminderDialog({
    required this.initialValue,
    required this.initialUnit,
  });

  @override
  State<_CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<_CustomReminderDialog> {
  late TextEditingController _controller;
  late int _value;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
    _unit = widget.initialUnit;
    _controller = TextEditingController(text: _value.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF3A3A3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'カスタム通知設定',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE85A3B)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final intValue = int.tryParse(value);
                    if (intValue != null && intValue > 0) {
                      _value = intValue;
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _unit,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF2B2B2B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                  ),
                  dropdownColor: const Color(0xFF3A3A3A),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'minutes', child: Text('分前')),
                    DropdownMenuItem(value: 'hours', child: Text('時間前')),
                    DropdownMenuItem(value: 'days', child: Text('日前')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _unit = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('キャンセル', style: TextStyle(color: Colors.grey[400])),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: createHorizontalOrangeYellowGradient(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.pop(context, {'value': _value, 'unit': _unit});
            },
            child: const Text('設定', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }
}
