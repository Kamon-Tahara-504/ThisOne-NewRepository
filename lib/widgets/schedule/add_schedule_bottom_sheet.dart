import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../gradients.dart';
import '../../utils/color_utils.dart';

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
  String _selectedColorHex = '#9E9E9E';
  bool _isNotificationEnabled = false;
  String _timePickerMode = 'start'; // 'start' or 'end'
  int _reminderMinutes = 15;
  late FixedExtentScrollController _timeController;
  int _timeInterval = 5; // 時間間隔（分単位）
  bool _isCustomReminder = false;
  int _customValue = 15;
  String _customUnit = 'minutes'; // 'minutes', 'hours', 'days'
  bool _isTimeWheelScrolling = false;
  late int _currentIntervalIndex;
  bool _isIntervalSliding = false;
  int _previewIntervalIndex = 0;
  double? _dragStartX;
  int? _dragStartIndex;

  // 通知時間オプション
  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': '5分前', 'minutes': 5},
    {'label': '15分前', 'minutes': 15},
    {'label': '30分前', 'minutes': 30},
    {'label': '1時間前', 'minutes': 60},
    {'label': '1日前', 'minutes': 1440},
    {'label': 'カスタム', 'minutes': -1}, // -1はカスタムの識別子
  ];

  // 時間間隔オプション
  // 表示ラベルは描画時に分/時間の単位を付けるため、ここでは数値のみを設定
  final List<Map<String, dynamic>> _timeIntervalOptions = [
    // 1分を5分の左側に表示するため、先頭に配置
    {'label': '1', 'minutes': 1},
    {'label': '5', 'minutes': 5},
    {'label': '10', 'minutes': 10},
    {'label': '15', 'minutes': 15},
    {'label': '30', 'minutes': 30},
    {'label': '60', 'minutes': 60},
  ];

  @override
  void initState() {
    super.initState();
    _timeController = FixedExtentScrollController(
      initialItem: _getClosestTimeIndex(_startTime),
    );
    _currentIntervalIndex = _timeIntervalOptions.indexWhere(
      (option) => option['minutes'] == _timeInterval,
    );
    if (_currentIntervalIndex < 0) {
      _currentIntervalIndex = 0;
    }
    _previewIntervalIndex = _currentIntervalIndex;
  }

  // 間隔に基づいた時刻選択肢を生成
  List<String> _getTimeOptions() {
    List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += _timeInterval) {
        final timeString =
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        times.add(timeString);
      }
    }
    return times;
  }

  // TimeOfDayを時刻選択肢の最も近いインデックスに変換
  int _getClosestTimeIndex(TimeOfDay time) {
    final options = _getTimeOptions();
    final targetMinutes = time.hour * 60 + time.minute;
    int closestIndex = 0;
    int minDifference = 24 * 60; // 1日分の分数

    for (int i = 0; i < options.length; i++) {
      final timeParts = options[i].split(':');
      final optionHour = int.parse(timeParts[0]);
      final optionMinute = int.parse(timeParts[1]);
      final optionTotalMinutes = optionHour * 60 + optionMinute;

      final difference = (targetMinutes - optionTotalMinutes).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  // インデックスからTimeOfDayを取得
  TimeOfDay _getTimeFromIndex(int index) {
    final options = _getTimeOptions();
    if (index < options.length) {
      final timeParts = options[index].split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return TimeOfDay(hour: hour, minute: minute);
    }
    return TimeOfDay.now();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _timeController.dispose();
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

      widget.onAdd({
        'id': DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': widget.selectedDate,
        'startTime': _startTime,
        'endTime': _endTime,
        'isAllDay': false,
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

  Widget _buildTimeWheelPicker({
    required List<String> items,
    required int selectedIndex,
    required Function(int) onChanged,
    required FixedExtentScrollController controller,
  }) {
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            // スクロール中はフラグONにし、停止検知はデバウンスで行う
            if (notification is ScrollStartNotification ||
                notification is ScrollUpdateNotification ||
                notification is UserScrollNotification) {
              if (!_isTimeWheelScrolling) {
                setState(() {
                  _isTimeWheelScrolling = true;
                });
              }
              // ラベルは遅延なく常時更新されるため、ここではフラグのみON
            }

            if (notification is ScrollEndNotification) {
              if (_isTimeWheelScrolling) {
                setState(() {
                  _isTimeWheelScrolling = false;
                });
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (controller.hasClients) {
                  final currentIndex = controller.selectedItem;
                  if (currentIndex != selectedIndex) {
                    onChanged(currentIndex);
                  }
                }
              });
              HapticFeedback.selectionClick();
            }

            return false;
          },
          child: ListWheelScrollView.useDelegate(
            itemExtent: 32,
            diameterRatio: 2.5,
            perspective: 0.004,
            physics: const FixedExtentScrollPhysics(),
            controller: controller,
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                // 中央からの距離に応じて不透明度のみを変化させる
                final distance = (index - selectedIndex).abs();
                double opacity;
                if (distance == 0) {
                  // スクロール中は下層テキストを見せ、停止時は隠す
                  opacity = _isTimeWheelScrolling ? 1.0 : 0.0;
                } else if (distance == 1) {
                  opacity = 0.7;
                } else if (distance == 2) {
                  opacity = 0.4;
                } else {
                  opacity = 0.2;
                }

                return Container(
                  alignment: Alignment.center,
                  child: Text(
                    items[index],
                    style: TextStyle(
                      color: Colors.white.withOpacity(opacity),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        // 中央の選択行の前面にグラデーションボックスを配置（通常は下を通過）
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: createHorizontalOrangeYellowGradient(),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 選択中の時刻ラベル（HH:mm - HH:mm）をボックスの上に重ねる
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedScale(
                  scale: _isTimeWheelScrolling ? 0.98 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  child: Text(
                    '${_formatTimeOfDay(_startTime)} - ${_formatTimeOfDay(_endTime)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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

                  // 詳細設定セクション
                  _buildDetailedSettings(),
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

  // 詳細設定セクション
  Widget _buildDetailedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 時間設定
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '時間',
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
                  children: [
                    // 開始時刻・終了時刻切替ボタン
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _timePickerMode = 'start');
                            // ピッカーの位置を開始時刻に移動
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_timeController.hasClients) {
                                _timeController.animateToItem(
                                  _getClosestTimeIndex(_startTime),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _timePickerMode == 'start'
                                      ? const Color(0xFFE85A3B)
                                      : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    _timePickerMode == 'start'
                                        ? Colors.transparent
                                        : Colors.grey[700]!,
                              ),
                            ),
                            child: Text(
                              '開始: ${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() => _timePickerMode = 'end');
                            // ピッカーの位置を終了時刻に移動
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_timeController.hasClients) {
                                _timeController.animateToItem(
                                  _getClosestTimeIndex(_endTime),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _timePickerMode == 'end'
                                      ? const Color(0xFFE85A3B)
                                      : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color:
                                    _timePickerMode == 'end'
                                        ? Colors.transparent
                                        : Colors.grey[700]!,
                              ),
                            ),
                            child: Text(
                              '終了: ${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // 統合時刻ピッカー
                    Container(
                      height: 120,
                      child: _buildTimeWheelPicker(
                        items: _getTimeOptions(),
                        selectedIndex:
                            _timePickerMode == 'start'
                                ? _getClosestTimeIndex(_startTime)
                                : _getClosestTimeIndex(_endTime),
                        controller: _timeController,
                        onChanged: (index) {
                          setState(() {
                            final newTime = _getTimeFromIndex(index);
                            if (_timePickerMode == 'start') {
                              _startTime = newTime;
                            } else {
                              _endTime = newTime;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 間隔選択スライダー
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '時間間隔',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE85A3B),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _currentIntervalIndex >= 0
                                    ? (() {
                                      final minutes =
                                          _timeIntervalOptions[_currentIntervalIndex]['minutes']
                                              as int;
                                      if (minutes < 60) {
                                        return '${minutes}m';
                                      }
                                      final hours = (minutes ~/ 60);
                                      return '${hours}h';
                                    })()
                                    : '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F2F2F),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[700]!),
                          ),
                          child: Stack(
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final itemCount = _timeIntervalOptions.length;
                                  final barPadding = 12.0;
                                  final totalWidth =
                                      constraints.maxWidth - barPadding * 2;
                                  final segmentWidth = totalWidth / itemCount;
                                  final highlightWidth = segmentWidth * 0.8;
                                  // 位置計算用のユーティリティ関数
                                  int indexFromDx(double dx) {
                                    final clamped = dx.clamp(
                                      0.0,
                                      constraints.maxWidth,
                                    );
                                    final relative =
                                        (clamped - barPadding) / totalWidth;
                                    final idx = (relative * itemCount).floor();
                                    return idx.clamp(0, itemCount - 1);
                                  }

                                  final displayIndex =
                                      _isIntervalSliding
                                          ? _previewIntervalIndex
                                          : _currentIntervalIndex;
                                  final left =
                                      barPadding +
                                      (displayIndex * segmentWidth) +
                                      (segmentWidth - highlightWidth) / 2;

                                  void selectPreviewIndex(int index) {
                                    if (index < 0 || index >= itemCount) return;
                                    if (_previewIntervalIndex == index) return;
                                    setState(() {
                                      _previewIntervalIndex = index;
                                      _isIntervalSliding = true;
                                    });
                                  }

                                  void startDragSession(double x, int index) {
                                    _dragStartX = x;
                                    _dragStartIndex = index;
                                  }

                                  void updateDragPreview(double x) {
                                    if (_dragStartX == null) return;

                                    // すでにスライディング中の場合は常に更新
                                    if (_isIntervalSliding) {
                                      final idx = indexFromDx(x);
                                      if (idx != _previewIntervalIndex) {
                                        setState(() {
                                          _previewIntervalIndex = idx;
                                        });
                                      }
                                      return;
                                    }

                                    // まだスライディングが開始されていない場合、一定距離以上移動したらプレビュー開始
                                    final dragDistance =
                                        (x - _dragStartX!).abs();
                                    if (dragDistance > 25.0) {
                                      // 25px以上移動したらプレビュー開始
                                      final idx = indexFromDx(x);
                                      selectPreviewIndex(idx);
                                    }
                                  }

                                  void confirmSelection() {
                                    // セッション情報をリセット
                                    _dragStartX = null;
                                    _dragStartIndex = null;

                                    if (_currentIntervalIndex ==
                                        _previewIntervalIndex) {
                                      // プレビューが同じでもスライディング状態は停止
                                      if (_isIntervalSliding) {
                                        setState(() {
                                          _isIntervalSliding = false;
                                        });
                                      }
                                      return;
                                    }
                                    setState(() {
                                      _currentIntervalIndex =
                                          _previewIntervalIndex;
                                      _timeInterval =
                                          _timeIntervalOptions[_previewIntervalIndex]['minutes'];
                                      _isIntervalSliding = false;
                                    });
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          final currentTime =
                                              _timePickerMode == 'start'
                                                  ? _startTime
                                                  : _endTime;
                                          final newIndex = _getClosestTimeIndex(
                                            currentTime,
                                          );
                                          if (_timeController.hasClients) {
                                            _timeController.animateToItem(
                                              newIndex,
                                              duration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              curve: Curves.easeInOut,
                                            );
                                          }
                                          final adjustedTime =
                                              _getTimeFromIndex(newIndex);
                                          setState(() {
                                            if (_timePickerMode == 'start') {
                                              _startTime = adjustedTime;
                                            } else {
                                              _endTime = adjustedTime;
                                            }
                                          });
                                        });
                                  }

                                  return Stack(
                                    children: [
                                      // バックグラウンドのタッチ可能エリア（下層テキスト）
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTapDown: (details) {
                                          final x = details.localPosition.dx;
                                          final idx = indexFromDx(x);
                                          startDragSession(x, idx);

                                          // タップした位置が現在選択中と全く同じ場合は何もしない
                                          // 隣接（1つ離れ）の場合も何もしない（ユーザーの微細な操作を許容）
                                          // 2つ以上離れている場合のみ即座にプレビュー
                                          final distance =
                                              (idx - _currentIntervalIndex)
                                                  .abs();
                                          if (distance >= 2) {
                                            selectPreviewIndex(idx);
                                          }
                                        },
                                        onTap: () {
                                          // ドラッグセッション中でない場合（単純タップ）の処理
                                          if (_dragStartX != null &&
                                              _dragStartIndex != null) {
                                            final tappedIndex =
                                                _dragStartIndex!;
                                            final distance =
                                                (tappedIndex -
                                                        _currentIntervalIndex)
                                                    .abs();

                                            // 隣接項目をタップした場合はその項目に移動
                                            if (distance == 1 &&
                                                !_isIntervalSliding) {
                                              setState(() {
                                                _previewIntervalIndex =
                                                    tappedIndex;
                                              });
                                            }
                                          }

                                          // タップ完了時に確定
                                          Future.delayed(
                                            const Duration(milliseconds: 200),
                                            confirmSelection,
                                          );
                                        },
                                        onHorizontalDragStart: (details) {
                                          final x = details.localPosition.dx;
                                          final idx = indexFromDx(x);
                                          startDragSession(x, idx);
                                        },
                                        onHorizontalDragUpdate: (details) {
                                          updateDragPreview(
                                            details.localPosition.dx,
                                          );
                                        },
                                        onHorizontalDragEnd: (details) {
                                          // ドラッグ終了時に確定
                                          Future.delayed(
                                            const Duration(milliseconds: 150),
                                            confirmSelection,
                                          );
                                        },
                                        child: Row(
                                          children: List.generate(
                                            itemCount,
                                            (i) => Expanded(
                                              child: Center(
                                                child: Text(
                                                  (() {
                                                    final minutes =
                                                        _timeIntervalOptions[i]['minutes']
                                                            as int;
                                                    if (minutes < 60) {
                                                      return '${minutes}m';
                                                    }
                                                    final hours =
                                                        (minutes ~/ 60);
                                                    return '${hours}h';
                                                  })(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // オレンジグラデーションボックス（中層）
                                      AnimatedPositioned(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        left: left,
                                        top: 8,
                                        bottom: 8,
                                        width: highlightWidth,
                                        child: IgnorePointer(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient:
                                                  createHorizontalOrangeYellowGradient(),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      // 選択中の間隔テキスト（上層）
                                      AnimatedPositioned(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        curve: Curves.easeInOut,
                                        left: left,
                                        top: 0,
                                        bottom: 0,
                                        width: highlightWidth,
                                        child: IgnorePointer(
                                          child: Center(
                                            child: AnimatedScale(
                                              scale:
                                                  _isIntervalSliding
                                                      ? 0.98
                                                      : 1.0,
                                              duration: const Duration(
                                                milliseconds: 120,
                                              ),
                                              curve: Curves.easeOut,
                                              child: Text(
                                                (() {
                                                  final minutes =
                                                      _timeIntervalOptions[displayIndex]['minutes']
                                                          as int;
                                                  if (minutes < 60) {
                                                    return '${minutes}m';
                                                  }
                                                  final hours = (minutes ~/ 60);
                                                  return '${hours}h';
                                                })(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 通知設定
        Column(
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
                      onTap:
                          () => setState(() => _isNotificationEnabled = false),
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
                      onTap:
                          () => setState(() => _isNotificationEnabled = true),
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
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
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
                                    final isCustomOption =
                                        option['minutes'] == -1;
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
                                            _reminderMinutes =
                                                option['minutes'];
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
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
        ),

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
