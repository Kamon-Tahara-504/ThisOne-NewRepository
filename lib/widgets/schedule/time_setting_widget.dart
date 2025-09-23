import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../gradients.dart';

class TimeSettingWidget extends StatefulWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int timeInterval;
  final Function(TimeOfDay, TimeOfDay, int) onTimeChange;

  const TimeSettingWidget({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.timeInterval,
    required this.onTimeChange,
  }) : super(key: key);

  @override
  _TimeSettingWidgetState createState() => _TimeSettingWidgetState();
}

class _TimeSettingWidgetState extends State<TimeSettingWidget> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _timeInterval;
  late FixedExtentScrollController _timeController;
  String _timePickerMode = 'start';
  bool _isTimeWheelScrolling = false;
  late int _currentIntervalIndex;
  bool _isIntervalSliding = false;
  int _previewIntervalIndex = 0;
  double? _dragStartX;
  Key _timePickerKey = UniqueKey();

  // 時間間隔オプション
  final List<Map<String, dynamic>> _timeIntervalOptions = [
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
    _startTime = widget.startTime;
    _endTime = widget.endTime;
    _timeInterval = widget.timeInterval;
    _timeController = FixedExtentScrollController(
      initialItem: _getClosestTimeIndex(_startTime),
    );
    _currentIntervalIndex = _timeIntervalOptions.indexWhere(
      (option) => option['minutes'] == _timeInterval,
    );
    if (_currentIntervalIndex < 0) {
      _currentIntervalIndex = 1; // デフォルトは5分間隔
    }
    _previewIntervalIndex = _currentIntervalIndex;
  }

  @override
  void didUpdateWidget(TimeSettingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeInterval != widget.timeInterval ||
        oldWidget.startTime != widget.startTime ||
        oldWidget.endTime != widget.endTime) {
      setState(() {
        _startTime = widget.startTime;
        _endTime = widget.endTime;
        _timeInterval = widget.timeInterval;
        _currentIntervalIndex = _timeIntervalOptions.indexWhere(
          (option) => option['minutes'] == _timeInterval,
        );
        if (_currentIntervalIndex < 0) {
          _currentIntervalIndex = 1;
        }
        _previewIntervalIndex = _currentIntervalIndex;
        _timePickerKey = UniqueKey();
      });

      // コントローラーを再初期化
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _timeController.dispose();
        _timeController = FixedExtentScrollController(
          initialItem: _getClosestTimeIndex(
            _timePickerMode == 'start' ? _startTime : _endTime,
          ),
        );
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

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

  int _getClosestTimeIndex(TimeOfDay time) {
    final options = _getTimeOptions();
    final targetMinutes = time.hour * 60 + time.minute;
    int closestIndex = 0;
    int minDifference = 24 * 60;

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
            if (notification is ScrollStartNotification) {
              if (mounted) {
                setState(() {
                  _isTimeWheelScrolling = true;
                });
              }
            } else if (notification is ScrollEndNotification) {
              if (mounted) {
                setState(() {
                  _isTimeWheelScrolling = false;
                });

                // スクロール終了時に最終的な時刻を確定
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (controller.hasClients && mounted) {
                    final finalIndex = controller.selectedItem;
                    final newTime = _getTimeFromIndex(finalIndex);
                    setState(() {
                      if (_timePickerMode == 'start') {
                        _startTime = newTime;
                      } else {
                        _endTime = newTime;
                      }
                    });
                    widget.onTimeChange(_startTime, _endTime, _timeInterval);
                  }
                });

                // スクロール終了時にハプティックフィードバック
                HapticFeedback.selectionClick();
              }
            }
            return false;
          },
          child: ListWheelScrollView.useDelegate(
            itemExtent: 32, // アイテム高さを小さくしてより多く表示
            diameterRatio: 4.0, // より大きな円周で多くのアイテムを表示
            perspective: 0.002, // より平坦にしてより多くの項目を見えるように
            physics: const BouncingScrollPhysics(), // バウンス効果でスムーズに
            controller: controller,
            onSelectedItemChanged: (index) {
              // スクロール終了時に処理されるため、ここでは何もしない
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                // リアルタイムでコントローラーから現在の選択インデックスを取得
                final currentSelectedIndex =
                    controller.hasClients
                        ? controller.selectedItem
                        : selectedIndex;
                final distance = (index - currentSelectedIndex).abs();

                double opacity;
                if (distance == 0) {
                  // 選択中のアイテムは透明（グラデーションボックス上のラベルで表示）
                  opacity = 0.0;
                } else if (distance == 1) {
                  // 隣接する時刻: 90%の透明度（非常によく見える）
                  opacity = 0.8;
                } else {
                  // それ以外の時刻: 80%の透明度（よく見える）
                  opacity = 0.4;
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
        // 中央の選択行のグラデーションボックス
        Positioned.fill(
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                height: 36, // itemExtent(32)に合わせて調整
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: createHorizontalOrangeYellowGradient(),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 選択中の時刻ラベル
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
    return Column(
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
                        setState(() {
                          _timePickerMode = 'start';
                          _timePickerKey = UniqueKey();
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final newIndex = _getClosestTimeIndex(_startTime);
                          _timeController.dispose();
                          _timeController = FixedExtentScrollController(
                            initialItem: newIndex,
                          );
                          setState(() {});
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
                        setState(() {
                          _timePickerMode = 'end';
                          _timePickerKey = UniqueKey();
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final newIndex = _getClosestTimeIndex(_endTime);
                          _timeController.dispose();
                          _timeController = FixedExtentScrollController(
                            initialItem: newIndex,
                          );
                          setState(() {});
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
                  height: 160, // より多くの項目を表示するため高さを拡大
                  key: _timePickerKey,
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
                      widget.onTimeChange(_startTime, _endTime, _timeInterval);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // 間隔選択スライダー
                _buildIntervalSlider(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntervalSlider() {
    return Column(
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
            // 時間間隔の表示を削除
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
                  final totalWidth = constraints.maxWidth - barPadding * 2;
                  final segmentWidth = totalWidth / itemCount;
                  final highlightWidth = segmentWidth * 0.85; // サイズを95%に拡大

                  int indexFromDx(double dx) {
                    final clamped = dx.clamp(0.0, constraints.maxWidth);
                    final relative = (clamped - barPadding) / totalWidth;
                    final idx = (relative * itemCount).floor();
                    return idx.clamp(0, itemCount - 1);
                  }

                  final displayIndex =
                      _isIntervalSliding
                          ? _previewIntervalIndex
                          : _currentIntervalIndex;

                  // ボックスの位置を計算（端のアイテムは完全に端まで移動）
                  final double left;
                  if (displayIndex == 0) {
                    // 最初の要素：完全に左端から開始（paddingを無視）
                    left = 4.0; // 僅かなマージンのみ
                  } else if (displayIndex == itemCount - 1) {
                    // 最後の要素：完全に右端まで（paddingを無視）
                    left =
                        constraints.maxWidth -
                        highlightWidth -
                        4.0; // 僅かなマージンのみ
                  } else {
                    // 中間の要素：中央配置
                    left =
                        barPadding +
                        (displayIndex * segmentWidth) +
                        (segmentWidth - highlightWidth) / 2;
                  }

                  void startDragSession(double x, int index) {
                    _dragStartX = x;
                    setState(() {
                      _isIntervalSliding = true;
                    });
                  }

                  void updateDragPreview(double x) {
                    if (_dragStartX == null) return;
                    final idx = indexFromDx(x);
                    if (idx != _previewIntervalIndex) {
                      final newInterval = _timeIntervalOptions[idx]['minutes'];
                      final currentTime =
                          _timePickerMode == 'start' ? _startTime : _endTime;

                      setState(() {
                        _previewIntervalIndex = idx;
                        _timeInterval = newInterval;
                        _timePickerKey = UniqueKey();
                      });

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        final newIndex = _getClosestTimeIndex(currentTime);
                        _timeController.dispose();
                        _timeController = FixedExtentScrollController(
                          initialItem: newIndex,
                        );

                        final adjustedTime = _getTimeFromIndex(newIndex);
                        setState(() {
                          if (_timePickerMode == 'start') {
                            _startTime = adjustedTime;
                          } else {
                            _endTime = adjustedTime;
                          }
                        });
                        widget.onTimeChange(
                          _startTime,
                          _endTime,
                          _timeInterval,
                        );
                      });
                    }
                  }

                  void confirmSelection() {
                    _dragStartX = null;
                    setState(() {
                      _currentIntervalIndex = _previewIntervalIndex;
                      _isIntervalSliding = false;
                    });
                  }

                  return Stack(
                    children: [
                      // バックグラウンドのタッチ可能エリア
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final x = details.localPosition.dx;
                          final idx = indexFromDx(x);
                          startDragSession(x, idx);
                        },
                        onTap: () {
                          if (_dragStartX != null) {
                            final tappedIndex = indexFromDx(_dragStartX!);
                            final newInterval =
                                _timeIntervalOptions[tappedIndex]['minutes'];
                            final currentTime =
                                _timePickerMode == 'start'
                                    ? _startTime
                                    : _endTime;

                            setState(() {
                              _previewIntervalIndex = tappedIndex;
                              _timeInterval = newInterval;
                              _timePickerKey = UniqueKey();
                            });

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              final newIndex = _getClosestTimeIndex(
                                currentTime,
                              );
                              _timeController.dispose();
                              _timeController = FixedExtentScrollController(
                                initialItem: newIndex,
                              );

                              final adjustedTime = _getTimeFromIndex(newIndex);
                              setState(() {
                                if (_timePickerMode == 'start') {
                                  _startTime = adjustedTime;
                                } else {
                                  _endTime = adjustedTime;
                                }
                              });
                              widget.onTimeChange(
                                _startTime,
                                _endTime,
                                _timeInterval,
                              );
                            });
                          }
                          confirmSelection();
                        },
                        onHorizontalDragStart: (details) {
                          final x = details.localPosition.dx;
                          final idx = indexFromDx(x);
                          startDragSession(x, idx);
                        },
                        onHorizontalDragUpdate: (details) {
                          updateDragPreview(details.localPosition.dx);
                        },
                        onHorizontalDragEnd: (details) {
                          confirmSelection();
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
                                    final hours = (minutes ~/ 60);
                                    return '${hours}h';
                                  })(),
                                  style: TextStyle(
                                    color:
                                        i == displayIndex
                                            ? (_isIntervalSliding
                                                ? Colors.white
                                                : Colors.transparent)
                                            : Colors.white.withOpacity(0.7),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // オレンジグラデーションボックス
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: left,
                        top: 8,
                        bottom: 8,
                        width: highlightWidth,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: createHorizontalOrangeYellowGradient(),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // 選択中の間隔テキスト
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        left: left,
                        top: 0,
                        bottom: 0,
                        width: highlightWidth,
                        child: IgnorePointer(
                          child: Center(
                            child: AnimatedScale(
                              scale: _isIntervalSliding ? 0.98 : 1.0,
                              duration: const Duration(milliseconds: 120),
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
                                style: TextStyle(
                                  color:
                                      _isIntervalSliding
                                          ? Colors.transparent
                                          : Colors.white,
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
    );
  }
}
