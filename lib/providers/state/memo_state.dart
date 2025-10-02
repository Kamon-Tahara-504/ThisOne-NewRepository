import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/memo.dart';
import '../../repositories/memo/memo_repository.dart';

/// メモの状態
class MemoState {
  final List<Memo> memos;
  final bool isLoading;
  final String? error;

  const MemoState({this.memos = const [], this.isLoading = false, this.error});

  MemoState copyWith({List<Memo>? memos, bool? isLoading, String? error}) {
    return MemoState(
      memos: memos ?? this.memos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// メモの状態管理クラス
class MemoNotifier extends StateNotifier<MemoState> {
  final MemoRepository _repository;

  MemoNotifier(this._repository) : super(const MemoState());

  /// メモ一覧を取得
  Future<void> loadMemos() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final memos = await _repository.getMemos();
      state = state.copyWith(memos: memos, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'メモの取得に失敗しました: $e');
    }
  }

  /// メモを追加
  Future<void> addMemo({
    required String title,
    String content = '',
    MemoMode mode = MemoMode.memo,
    String? colorHex,
    List<String> tags = const [],
    Map<String, dynamic>? richContent,
  }) async {
    try {
      final newMemo = await _repository.createMemo(
        title: title,
        content: content,
        mode: mode,
        colorHex: colorHex,
        tags: tags,
        richContent: richContent,
      );

      // ローカルの状態を更新
      state = state.copyWith(memos: [newMemo, ...state.memos]);
    } catch (e) {
      state = state.copyWith(error: 'メモの追加に失敗しました: $e');
    }
  }

  /// メモを更新
  Future<void> updateMemo(Memo memo) async {
    try {
      await _repository.updateMemo(memo);

      // ローカルの状態を更新
      state = state.copyWith(
        memos:
            state.memos.map((m) {
              return m.id == memo.id ? memo : m;
            }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'メモの更新に失敗しました: $e');
    }
  }

  /// メモを削除
  Future<void> deleteMemo(String memoId) async {
    try {
      await _repository.deleteMemo(memoId);

      // ローカルの状態を更新
      state = state.copyWith(
        memos: state.memos.where((memo) => memo.id != memoId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'メモの削除に失敗しました: $e');
    }
  }

  /// メモのピン留め状態を更新
  Future<void> toggleMemoPinStatus(String memoId, bool isPinned) async {
    try {
      await _repository.updateMemoPinStatus(memoId: memoId, isPinned: isPinned);

      // ローカルの状態を更新
      state = state.copyWith(
        memos:
            state.memos.map((memo) {
              if (memo.id == memoId) {
                return memo.copyWith(isPinned: isPinned);
              }
              return memo;
            }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'ピン留め状態の更新に失敗しました: $e');
    }
  }

  /// メモの設定を更新
  Future<void> updateMemoSettings({
    required String memoId,
    required MemoMode mode,
    required String colorHex,
  }) async {
    try {
      await _repository.updateMemoSettings(
        memoId: memoId,
        mode: mode,
        colorHex: colorHex,
      );

      // ローカルの状態を更新
      state = state.copyWith(
        memos:
            state.memos.map((memo) {
              if (memo.id == memoId) {
                return memo.copyWith(mode: mode, colorTag: colorHex);
              }
              return memo;
            }).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'メモ設定の更新に失敗しました: $e');
    }
  }

  /// フィルターされたメモを取得
  Future<void> loadFilteredMemos(MemoFilter filter) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final memos = await _repository.getFilteredMemos(filter);
      state = state.copyWith(memos: memos, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'フィルターされたメモの取得に失敗しました: $e',
      );
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}
