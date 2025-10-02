import 'memo_repository.dart';
import '../core/repository_exceptions.dart';
import '../../models/memo.dart';
import '../../services/supabase_service.dart';

/// Supabaseを使ったMemoRepositoryの実装
class MemoRepositoryImpl implements MemoRepository {
  final SupabaseService _supabaseService;

  MemoRepositoryImpl(this._supabaseService);

  @override
  Future<List<Memo>> getMemos() async {
    try {
      return await _supabaseService.getUserMemosTyped();
    } catch (e) {
      throw MemoRepositoryException('メモの取得に失敗しました', e);
    }
  }

  @override
  Future<Memo> createMemo({
    required String title,
    String content = '',
    MemoMode mode = MemoMode.memo,
    String? colorHex,
    List<String> tags = const [],
    Map<String, dynamic>? richContent,
  }) async {
    try {
      final memo = await _supabaseService.addMemoTyped(
        title: title,
        content: content,
        mode: mode,
        colorHex: colorHex,
        tags: tags,
        richContent: richContent,
      );

      if (memo == null) {
        throw MemoRepositoryException('メモの作成に失敗しました');
      }

      return memo;
    } catch (e) {
      throw MemoRepositoryException('メモの作成に失敗しました', e);
    }
  }

  @override
  Future<void> updateMemo(Memo memo) async {
    try {
      await _supabaseService.updateMemoTyped(memo);
    } catch (e) {
      throw MemoRepositoryException('メモの更新に失敗しました', e);
    }
  }

  @override
  Future<void> deleteMemo(String memoId) async {
    try {
      await _supabaseService.deleteMemoTyped(memoId);
    } catch (e) {
      throw MemoRepositoryException('メモの削除に失敗しました', e);
    }
  }

  @override
  Future<void> updateMemoPinStatus({
    required String memoId,
    required bool isPinned,
  }) async {
    try {
      await _supabaseService.updateMemoPinStatusTyped(
        memoId: memoId,
        isPinned: isPinned,
      );
    } catch (e) {
      throw MemoRepositoryException('ピン留め状態の更新に失敗しました', e);
    }
  }

  @override
  Future<void> updateMemoSettings({
    required String memoId,
    required MemoMode mode,
    required String colorHex,
  }) async {
    try {
      await _supabaseService.updateMemoSettingsTyped(
        memoId: memoId,
        mode: mode,
        colorHex: colorHex,
      );
    } catch (e) {
      throw MemoRepositoryException('メモ設定の更新に失敗しました', e);
    }
  }

  @override
  Future<List<Memo>> getFilteredMemos(MemoFilter filter) async {
    try {
      return await _supabaseService.getFilteredMemos(filter);
    } catch (e) {
      throw MemoRepositoryException('フィルターされたメモの取得に失敗しました', e);
    }
  }
}
