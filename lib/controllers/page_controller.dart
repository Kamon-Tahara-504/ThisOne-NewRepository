import 'package:flutter/material.dart';

/// ページ管理を担当するクラス
class AppPageController extends ChangeNotifier {
  late PageController _pageController;
  int _currentIndex = 0;
  int? _targetIndex; // ナビゲーションバーからの遷移時の目標ページ

  // 定数定義
  static const int taskPageIndex = 0;
  static const int schedulePageIndex = 1;
  static const int memoPageIndex = 2;
  static const int settingsPageIndex = 3;
  static const int memoTabIndex = 3;
  static const int settingsTabIndex = 4;

  /// 現在のタブインデックス
  int get currentIndex => _currentIndex;

  /// FlutterのPageControllerを取得
  PageController get pageController => _pageController;

  /// ページコントローラーを初期化
  void initializePageController({int initialPage = 0}) {
    _pageController = PageController(initialPage: initialPage);
    _currentIndex = initialPage;
  }

  /// ページを変更
  void changePage(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// PageViewのページ変更処理
  void onPageChanged(int pageIndex) {
    // ナビゲーションバーからの遷移中の場合
    if (_targetIndex != null) {
      // 目標ページに到達した場合のみ状態を更新
      final targetPageIndex = getCurrentPageIndexForTabIndex(_targetIndex!);
      if (pageIndex == targetPageIndex) {
        final newCurrentIndex = _convertPageIndexToTabIndex(pageIndex);
        changePage(newCurrentIndex);
        _targetIndex = null; // 遷移完了
      }
      // 中間ページの場合は無視
      return;
    }

    // スワイプによる通常の遷移の場合
    final newCurrentIndex = _convertPageIndexToTabIndex(pageIndex);
    changePage(newCurrentIndex);
  }

  /// PageViewのインデックスをタブインデックスに変換
  int _convertPageIndexToTabIndex(int pageIndex) {
    switch (pageIndex) {
      case taskPageIndex:
        return taskPageIndex;
      case schedulePageIndex:
        return schedulePageIndex;
      case memoPageIndex:
        return memoTabIndex;
      case settingsPageIndex:
        return settingsTabIndex;
      default:
        return taskPageIndex;
    }
  }

  /// 現在のPageViewインデックスを取得
  int getCurrentPageIndex() {
    return getCurrentPageIndexForTabIndex(_currentIndex);
  }

  /// 指定されたタブインデックスに対応するPageViewインデックスを取得
  int getCurrentPageIndexForTabIndex(int tabIndex) {
    switch (tabIndex) {
      case taskPageIndex:
        return taskPageIndex;
      case schedulePageIndex:
        return schedulePageIndex;
      case memoTabIndex:
        return memoPageIndex;
      case settingsTabIndex:
        return settingsPageIndex;
      default:
        return taskPageIndex;
    }
  }

  /// 指定されたタブに移動
  void navigateToTab(int tabIndex) {
    if (tabIndex != _currentIndex) {
      // 目標ページを設定（中間ページの変更を無視するため）
      _targetIndex = tabIndex;

      // 即座にUIを更新（アイコンの色を変更）
      changePage(tabIndex);

      final pageIndex = getCurrentPageIndexForTabIndex(tabIndex);
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  /// ページコントローラーを解放
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
