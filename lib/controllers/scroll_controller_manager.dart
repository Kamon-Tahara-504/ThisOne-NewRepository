import 'package:flutter/material.dart';

/// スクロール制御を管理するクラス
class ScrollControllerManager {
  final Map<int, ScrollController> _scrollControllers = {};
  bool _isDisposed = false;

  // 定数
  static const double _scrollSensitivity = 10.0;
  static const double _scrollThreshold = 5.0;

  /// スクロールコントローラーを初期化
  void initializeScrollControllers({
    required int pageCount,
    required Function(int pageIndex) onScroll,
  }) {
    if (_isDisposed) return;

    for (int i = 0; i < pageCount; i++) {
      // 既存のコントローラーがあれば先にdispose
      _scrollControllers[i]?.dispose();

      _scrollControllers[i] = ScrollController();
      _scrollControllers[i]!.addListener(() => _onScroll(i, onScroll));
    }
  }

  /// スクロールイベントを処理
  void _onScroll(int pageIndex, Function(int pageIndex) onScroll) {
    if (_isDisposed) return;

    final controller = _scrollControllers[pageIndex];
    if (controller == null ||
        !controller.hasClients ||
        controller.hasClients == false) {
      return;
    }

    // スクロールイベントを外部に通知
    onScroll(pageIndex);
  }

  /// 指定されたページのスクロールコントローラーを取得
  ScrollController? getScrollController(int pageIndex) {
    return _scrollControllers[pageIndex];
  }

  /// スクロールコントローラーを安全に解放
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final entry in _scrollControllers.entries) {
      try {
        entry.value.dispose();
      } catch (e) {
        debugPrint('ScrollController dispose error for ${entry.key}: $e');
      }
    }
    _scrollControllers.clear();
  }

  /// スクロール感度を取得
  static double get scrollSensitivity => _scrollSensitivity;

  /// スクロール閾値を取得
  static double get scrollThreshold => _scrollThreshold;
}
