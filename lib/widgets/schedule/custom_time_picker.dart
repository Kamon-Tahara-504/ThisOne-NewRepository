import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../gradients.dart';

// カスタムScrollPhysics - ListWheelScrollView用の滑らかなスクロール
class SmoothListWheelScrollPhysics extends FixedExtentScrollPhysics {
  const SmoothListWheelScrollPhysics({super.parent});

  @override
  SmoothListWheelScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothListWheelScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 1.0, stiffness: 50.0, damping: 8.0);

  @override
  double get minFlingVelocity => 30.0;

  @override
  double get maxFlingVelocity => 1600.0;

  @override
  Tolerance get tolerance => const Tolerance(velocity: 0.3, distance: 0.15);
}

class CustomTimePicker extends StatefulWidget {
  final List<String> timeOptions;
  final int initialIndex;
  final Function(int) onChanged;
  final double itemHeight;

  const CustomTimePicker({
    super.key,
    required this.timeOptions,
    required this.initialIndex,
    required this.onChanged,
    this.itemHeight = 32.0,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late FixedExtentScrollController _scrollController;
  late int _selectedIndex;
  bool _isScrolling = false;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(
      0,
      widget.timeOptions.length - 1,
    );
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );

    // スクロール位置の監視を追加
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (!mounted || !_scrollController.hasClients) return;

    final currentOffset = _scrollController.offset;
    final itemExtent = widget.itemHeight;
    final currentIndex = (currentOffset / itemExtent).round();
    final page = currentOffset / itemExtent;

    if (_scrollOffset != page) {
      setState(() {
        _scrollOffset = page;
      });
    }

    // スクロール停止時に選択項目を更新
    if (!_isScrolling &&
        currentIndex != _selectedIndex &&
        currentIndex >= 0 &&
        currentIndex < widget.timeOptions.length) {
      _updateSelectedIndex(currentIndex);
    }
  }

  void _updateSelectedIndex(int index) {
    if (!mounted || index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    widget.onChanged(index);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.itemHeight * 5, // 5つのアイテム分の高さ
      child: Stack(
        children: [
          // 時刻リスト
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                setState(() {
                  _isScrolling = true;
                });
              } else if (notification is ScrollEndNotification) {
                setState(() {
                  _isScrolling = false;
                });
                // スクロール終了時に最終的な選択項目を確定
                final currentOffset = _scrollController.offset;
                final itemExtent = widget.itemHeight;
                final finalIndex = (currentOffset / itemExtent).round().clamp(
                  0,
                  widget.timeOptions.length - 1,
                );
                _updateSelectedIndex(finalIndex);
              }
              return false;
            },
            child: ListWheelScrollView.useDelegate(
              controller: _scrollController,
              itemExtent: widget.itemHeight,
              perspective: 0.003,
              diameterRatio: 2.5,
              physics: const SmoothListWheelScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: widget.timeOptions.length,
                builder: (context, index) {
                  // スクロール中は実際のスクロール位置を使用
                  final currentCenter =
                      _isScrolling ? _scrollOffset : _selectedIndex.toDouble();
                  final distance = (index - currentCenter).abs();

                  double opacity;
                  double scale = 1.0;

                  if (distance < 0.1) {
                    // 選択中のアイテムは透明（グラデーションボックス上のラベルで表示）
                    opacity = 0.0;
                    scale = 1.0;
                  } else if (distance <= 1.0) {
                    // 隣接する時刻: 距離に応じてスムーズに透明度変化
                    opacity = 0.8 - (distance - 0.1) * 0.2;
                    scale = 1.0 - distance * 0.1;
                  } else if (distance <= 2.0) {
                    // 2つ離れた時刻: より薄く
                    opacity = 0.4 - (distance - 1.0) * 0.2;
                    scale = 0.9 - (distance - 1.0) * 0.1;
                  } else {
                    // それ以外の時刻: 非常に薄く
                    opacity = 0.1;
                    scale = 0.8;
                  }

                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      height: widget.itemHeight,
                      alignment: Alignment.center,
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: opacity),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        child: Text(widget.timeOptions[index]),
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  height: widget.itemHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: createHorizontalOrangeYellowGradient(),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: _isScrolling ? 0.2 : 0.3,
                        ),
                        blurRadius: _isScrolling ? 8 : 10,
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
                    scale: _isScrolling ? 0.98 : 1.0,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: Text(
                      _selectedIndex >= 0 &&
                              _selectedIndex < widget.timeOptions.length
                          ? widget.timeOptions[_selectedIndex]
                          : '',
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
      ),
    );
  }
}
