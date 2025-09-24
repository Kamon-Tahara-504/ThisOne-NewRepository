import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import '../../gradients.dart';

// カスタムScrollPhysics - ドラッグ中はスナップしない
class SmoothPageScrollPhysics extends ScrollPhysics {
  final bool allowSnap;

  const SmoothPageScrollPhysics({super.parent, this.allowSnap = true});

  @override
  SmoothPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothPageScrollPhysics(
      parent: buildParent(ancestor),
      allowSnap: allowSnap,
    );
  }

  @override
  SpringDescription get spring =>
      const SpringDescription(mass: 0.8, stiffness: 100.0, damping: 1.0);

  @override
  double get minFlingVelocity => 50.0;

  @override
  double get maxFlingVelocity => 2500.0;

  @override
  Tolerance get tolerance => const Tolerance(velocity: 1.0, distance: 0.5);

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    // ドラッグ中はスナップを無効化
    if (!allowSnap) {
      return super.createBallisticSimulation(position, velocity);
    }

    // 通常時はPageViewのスナップ動作
    final tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      return super.createBallisticSimulation(position, velocity);
    }

    // 低速時は最も近いページにスナップ
    final target = _getTargetPixels(position);
    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  double _getTargetPixels(ScrollMetrics position) {
    final page = position.pixels / position.viewportDimension;
    return page.roundToDouble() * position.viewportDimension;
  }
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
  late PageController _pageController;
  late int _selectedIndex;
  bool _isScrolling = false;
  bool _isDragging = false;
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(
      0,
      widget.timeOptions.length - 1,
    );
    _pageController = PageController(
      initialPage: _selectedIndex,
      viewportFraction: 0.2, // 5つのアイテムを表示（中央1つ + 上下2つずつ）
    );

    // スクロール位置の監視を追加
    _pageController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScrollChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onScrollChanged() {
    if (!mounted || !_pageController.hasClients) return;

    final page = _pageController.page ?? _selectedIndex.toDouble();

    if (_scrollOffset != page) {
      setState(() {
        _scrollOffset = page;
      });
    }
  }

  void _handlePageChanged(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
      _isScrolling = false;
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
                  _isDragging = notification.dragDetails != null;
                });
              } else if (notification is ScrollUpdateNotification) {
                setState(() {
                  _isDragging = notification.dragDetails != null;
                });
              } else if (notification is ScrollEndNotification) {
                setState(() {
                  _isScrolling = false;
                  _isDragging = false;
                });
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _handlePageChanged,
              itemCount: widget.timeOptions.length,
              physics: SmoothPageScrollPhysics(
                parent: const ClampingScrollPhysics(),
                allowSnap: !_isDragging, // ドラッグ中はスナップを無効化
              ),
              itemBuilder: (context, index) {
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
                      duration: const Duration(milliseconds: 150),
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

          // 中央の選択行のグラデーションボックス
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
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
