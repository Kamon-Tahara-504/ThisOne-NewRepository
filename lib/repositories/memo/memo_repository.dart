import '../../models/memo.dart';

/// メモリポジトリのインターフェース
abstract class MemoRepository {
  /// ユーザーのメモを全て取得
  Future<List<Memo>> getMemos();

  /// メモを追加
  Future<Memo> createMemo({
    required String title,
    String content = '',
    MemoMode mode = MemoMode.memo,
    String? colorHex,
    List<String> tags = const [],
    Map<String, dynamic>? richContent,
  });

  /// メモを更新
  Future<void> updateMemo(Memo memo);

  /// メモを削除
  Future<void> deleteMemo(String memoId);

  /// メモのピン留め状態を更新
  Future<void> updateMemoPinStatus({
    required String memoId,
    required bool isPinned,
  });

  /// メモの設定（モードと色ラベル）を更新
  Future<void> updateMemoSettings({
    required String memoId,
    required MemoMode mode,
    required String colorHex,
  });

  /// フィルターされたメモを取得
  Future<List<Memo>> getFilteredMemos(MemoFilter filter);
}
