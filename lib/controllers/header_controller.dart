import 'package:flutter/material.dart';
import 'scroll_controller_manager.dart';

/// ヘッダーの表示制御を管理するクラス
class HeaderController extends ChangeNotifier {
  bool _isHeaderVisible = true;
  double _lastScrollPosition = 0.0;

  // 定数
  static const double _headerHeight = 54.0;
  static const Duration _headerAnimationDuration = Duration(milliseconds: 200);

  /// ヘッダーの表示状態
  bool get isHeaderVisible => _isHeaderVisible;

  /// ヘッダーの高さ
  static double get headerHeight => _headerHeight;

  /// ヘッダーアニメーション時間
  static Duration get headerAnimationDuration => _headerAnimationDuration;

  /// スクロール位置を更新してヘッダーの表示状態を制御
  void updateScrollPosition({
    required double currentPosition,
    required int currentPageIndex,
    required int targetPageIndex,
  }) {
    // 現在のページのみ監視
    if (currentPageIndex != targetPageIndex) return;

    final scrollDelta = currentPosition - _lastScrollPosition;

    // 最小スクロール量のフィルタ
    if (scrollDelta.abs() > ScrollControllerManager.scrollSensitivity) {
      final shouldChangeState = _shouldChangeHeaderVisibility(scrollDelta);
      if (shouldChangeState) {
        _updateHeaderVisibility(scrollDelta);
      }
    }

    // 前回位置を更新
    _lastScrollPosition = currentPosition;
  }

  /// ヘッダーの表示/非表示を変更すべきかを判定
  bool _shouldChangeHeaderVisibility(double scrollDelta) {
    if (scrollDelta > 0) {
      // 下スクロール：ヘッダーを隠す
      if (_isHeaderVisible &&
          scrollDelta > ScrollControllerManager.scrollSensitivity) {
        return true;
      }
    } else {
      // 上スクロール：ヘッダーを表示
      if (!_isHeaderVisible &&
          (-scrollDelta) > ScrollControllerManager.scrollThreshold) {
        return true;
      }
    }
    return false;
  }

  /// ヘッダーの表示状態を更新
  void _updateHeaderVisibility(double scrollDelta) {
    if (scrollDelta > 0) {
      // 下スクロール：ヘッダーを隠す
      _isHeaderVisible = false;
    } else {
      // 上スクロール：ヘッダーを表示
      _isHeaderVisible = true;
    }
    notifyListeners();
  }

  /// 動的トップパディングを計算
  double calculateDynamicTopPadding(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const baseOffset = 4.0;
    final baseTop = statusBarHeight + baseOffset;

    // 表示時は通常、非表示時は詰める
    return _isHeaderVisible ? baseTop + _headerHeight : statusBarHeight;
  }

  /// ヘッダーの位置を計算
  double calculateHeaderTop(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const baseOffset = 4.0;
    final baseTop = statusBarHeight + baseOffset;

    // 表示/非表示の切り替え
    return _isHeaderVisible ? baseTop : baseTop - _headerHeight;
  }

  /// ヘッダーの表示状態を手動で設定
  void setHeaderVisible(bool visible) {
    if (_isHeaderVisible != visible) {
      _isHeaderVisible = visible;
      notifyListeners();
    }
  }

  /// ヘッダーの表示状態をリセット
  void reset() {
    _isHeaderVisible = true;
    _lastScrollPosition = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
