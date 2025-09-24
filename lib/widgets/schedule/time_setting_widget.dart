import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../gradients.dart';

class TimeSettingWidget extends StatefulWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final int timeInterval;
  final Function(TimeOfDay, TimeOfDay, int) onTimeChange;

  const TimeSettingWidget({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.timeInterval,
    required this.onTimeChange,
  });

  @override
  State<TimeSettingWidget> createState() => _TimeSettingWidgetState();
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

    // 時間間隔が異常な値でないかチェック
    if (_timeInterval <= 0 || _timeInterval > 60) {
      _timeInterval = 5; // 安全な値に設定
    }

    _timeController = FixedExtentScrollController(
      initialItem: _getClosestTimeIndex(_startTime),
    );
    _currentIntervalIndex = _timeIntervalOptions.indexWhere(
      (option) => option['minutes'] == _timeInterval,
    );
    if (_currentIntervalIndex < 0) {
      _currentIntervalIndex = 1; // デフォルトは5分間隔
      _timeInterval = 5; // 値も確実に5分に設定
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
        final targetTime = _timePickerMode == 'start' ? _startTime : _endTime;
        _handleTimePickerModeChange(targetTime);
      });
    }
  }

  @override
  void dispose() {
    try {
      if (_timeController.hasClients) {
        _timeController.dispose();
      }
    } catch (e) {
      // コントローラーのdisposeでエラーが発生した場合は無視
    }
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

    // 時間間隔に合わせて最も近い有効な時刻を計算
    final adjustedMinutes = _roundToNearestInterval(
      targetMinutes,
      _timeInterval,
    );
    final adjustedHour = (adjustedMinutes ~/ 60) % 24;
    final adjustedMinute = adjustedMinutes % 60;

    final targetTimeString =
        '${adjustedHour.toString().padLeft(2, '0')}:${adjustedMinute.toString().padLeft(2, '0')}';

    // 正確にマッチする時刻を探す
    for (int i = 0; i < options.length; i++) {
      if (options[i] == targetTimeString) {
        return i;
      }
    }

    // 見つからない場合は最も近い時刻を探す（フォールバック）
    int closestIndex = 0;
    int minDifference = 24 * 60;

    for (int i = 0; i < options.length; i++) {
      final timeParts = options[i].split(':');
      final optionHour = int.parse(timeParts[0]);
      final optionMinute = int.parse(timeParts[1]);
      final optionTotalMinutes = optionHour * 60 + optionMinute;

      final difference = (adjustedMinutes - optionTotalMinutes).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  // 指定された間隔に最も近い分数に丸める
  int _roundToNearestInterval(int totalMinutes, int interval) {
    if (interval <= 0) return totalMinutes;

    final remainder = totalMinutes % interval;
    if (remainder <= interval / 2) {
      // 下に丸める
      return totalMinutes - remainder;
    } else {
      // 上に丸める
      return totalMinutes + (interval - remainder);
    }
  }

  TimeOfDay _getTimeFromIndex(int index) {
    final options = _getTimeOptions();

    // インデックスが有効範囲内かチェック
    if (index >= 0 && index < options.length) {
      try {
        final timeParts = options[index].split(':');
        if (timeParts.length == 2) {
          final hour = int.parse(timeParts[0]);
          final minute = int.parse(timeParts[1]);

          // 時間・分が有効範囲内かチェック
          if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      } catch (e) {
        // 時刻のパース中にエラーが発生
      }
    }

    // フォールバック: 現在のモードに応じて適切な時刻を返す
    if (_timePickerMode == 'start') {
      return _startTime;
    } else {
      return _endTime;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // スクロール終了時の処理を分離
  void _handleScrollEnd(FixedExtentScrollController controller) {
    if (!mounted || !controller.hasClients) return;

    try {
      // より安全にselectedItemを取得
      if (controller.positions.isNotEmpty &&
          controller.positions.first.hasViewportDimension &&
          controller.positions.first.hasContentDimensions) {
        final finalIndex = controller.selectedItem;
        final options = _getTimeOptions();

        // インデックスが有効範囲内かチェック
        if (finalIndex >= 0 && finalIndex < options.length) {
          final newTime = _getTimeFromIndex(finalIndex);

          if (mounted) {
            setState(() {
              if (_timePickerMode == 'start') {
                _startTime = newTime;
              } else {
                _endTime = newTime;
              }
            });

            widget.onTimeChange(_startTime, _endTime, _timeInterval);
          }
        }
      }
    } catch (e) {
      // エラーが発生した場合は何もしない
    }
  }

  // 間隔変更時の処理を分離
  void _handleIntervalChange(TimeOfDay currentTime) {
    if (!mounted) return;

    try {
      // 新しい間隔でのオプションを取得
      final newOptions = _getTimeOptions();
      final newIndex = _getClosestTimeIndex(currentTime);

      // インデックスが有効範囲内かチェック
      if (newIndex >= 0 && newIndex < newOptions.length) {
        // コントローラーを最適化して再初期化
        _recreateScrollController(newIndex);

        final adjustedTime = _getTimeFromIndex(newIndex);

        if (mounted) {
          setState(() {
            if (_timePickerMode == 'start') {
              _startTime = adjustedTime;
            } else {
              _endTime = adjustedTime;
            }
          });

          widget.onTimeChange(_startTime, _endTime, _timeInterval);
        }
      }
    } catch (e) {
      // 間隔変更でエラーが発生
    }
  }

  // タイムピッカーモード変更時の処理を分離
  void _handleTimePickerModeChange(TimeOfDay targetTime) {
    if (!mounted) return;

    try {
      final newIndex = _getClosestTimeIndex(targetTime);
      final options = _getTimeOptions();

      // インデックスが有効範囲内かチェック
      if (newIndex >= 0 && newIndex < options.length) {
        _recreateScrollController(newIndex);

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      // タイムピッカーモード変更でエラーが発生
    }
  }

  // ScrollControllerを安全に再作成する最適化メソッド
  void _recreateScrollController(int initialItem) {
    try {
      // 既存のコントローラーを安全に破棄
      if (_timeController.hasClients) {
        _timeController.dispose();
      }

      // 新しいコントローラーを作成
      _timeController = FixedExtentScrollController(initialItem: initialItem);
    } catch (e) {
      // ScrollController作成でエラーが発生した場合のフォールバック
      try {
        _timeController = FixedExtentScrollController(initialItem: 0);
      } catch (e2) {
        // 最後の手段として現在時刻を使用
      }
    }
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

                // スクロール終了時に最終的な時刻を確定（PostFrameCallbackを使用）
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _handleScrollEnd(controller);
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
              // リアルタイム更新は避けて、スクロール終了時のみ処理
            },
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: items.length,
              builder: (context, index) {
                // selectedIndexを直接使用（build中のcontroller.selectedItemアクセスを避ける）
                final currentSelectedIndex = selectedIndex.clamp(
                  0,
                  items.length - 1,
                );
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
                      color: Colors.white.withValues(alpha: opacity),
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
                      color: Colors.black.withValues(alpha: 0.3),
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
                          _handleTimePickerModeChange(_startTime);
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
                          _handleTimePickerModeChange(_endTime);
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
                SizedBox(
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
                      // 実際の時刻変更はスクロール終了時に処理されるため、ここでは何もしない
                      // この処理は_handleScrollEndで行われる
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
                color: Colors.white.withValues(alpha: 0.8),
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

                      // 間隔変更時の処理を分離してPostFrameCallbackで実行
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _handleIntervalChange(currentTime);
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

                            // タップ処理も分離してPostFrameCallbackで実行
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _handleIntervalChange(currentTime);
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
                                            : Colors.white.withValues(
                                              alpha: 0.7,
                                            ),
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
                                  color: Colors.black.withValues(alpha: 0.3),
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
