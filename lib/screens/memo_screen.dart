import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import '../gradients.dart';
import '../widgets/memo_item_card.dart';
import '../widgets/memo_filter_header.dart';
import '../widgets/empty_memo_state.dart';
import '../widgets/color_palette.dart';
import '../utils/error_handler.dart';
import '../models/memo.dart';
import '../providers/repository_providers.dart';
import 'memo_detail_screen.dart';

class MemoScreen extends ConsumerStatefulWidget {
  final String? newlyCreatedMemoId;
  final VoidCallback? onPopAnimationComplete;
  final ScrollController? scrollController;

  const MemoScreen({
    super.key,
    this.newlyCreatedMemoId,
    this.onPopAnimationComplete,
    this.scrollController,
  });

  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen>
    with TickerProviderStateMixin {
  late AnimationController _popAnimationController;
  late Animation<double> _popAnimation;
  String? _animatingMemoId; // アニメーション中のメモID

  // 型安全なフィルター管理
  MemoFilter _currentFilter = const MemoFilter();

  @override
  void initState() {
    super.initState();

    // メモを読み込み
    Future.microtask(() {
      ref.read(memoNotifierProvider.notifier).loadMemos();
    });

    // ポップアニメーションコントローラー
    _popAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _popAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _popAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    // アニメーション完了時のリスナー
    _popAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animatingMemoId = null;
        });
        widget.onPopAnimationComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _popAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MemoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 新しいメモが作成された場合にアニメーションを開始
    if (widget.newlyCreatedMemoId != null &&
        widget.newlyCreatedMemoId != oldWidget.newlyCreatedMemoId) {
      _startPopAnimation(widget.newlyCreatedMemoId!);
    }
  }

  void _startPopAnimation(String memoId) {
    setState(() {
      _animatingMemoId = memoId;
    });
    _popAnimationController.forward(from: 0.0);
  }

  // フィルタリングされたメモを取得（型安全版）
  List<Memo> get _filteredMemos {
    final memoState = ref.read(memoNotifierProvider);
    return memoState.memos.where(_currentFilter.matches).toList();
  }

  // 色フィルタリングを設定
  void _setColorFilter(String? colorHex) {
    setState(() {
      _currentFilter = MemoFilter(
        colorTag: colorHex,
        sortOrder: _currentFilter.sortOrder,
      );
    });
  }

  // 色フィルタリングをクリア
  void _clearColorFilter() {
    setState(() {
      _currentFilter = const MemoFilter();
    });
  }

  // 色フィルタリングBottomSheetを表示
  void _showColorFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => _ColorFilterBottomSheet(
            selectedColorFilter: _currentFilter.colorTag,
            onColorSelected: _setColorFilter,
          ),
    );
  }

  // Supabaseからメモを再読み込み（型安全版）
  Future<void> _loadMemos() async {
    try {
      await ref.read(memoNotifierProvider.notifier).loadMemos();
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'メモの読み込み',
          onRetry: _loadMemos,
        );
      }
    }
  }

  void _openMemoDetail(Memo memo) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => MemoDetailScreen(
              memo: memo, // 型安全なMemoオブジェクトを渡す
            ),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // より現代的なスケール＆フェードアニメーション
          return FadeTransition(
            opacity: animation.drive(
              Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(
                  begin: 0.8,
                  end: 1.0,
                ).chain(CurveTween(curve: Curves.easeOutBack)),
              ),
              child: child,
            ),
          );
        },
      ),
    );

    // 詳細画面から戻った時にメモリストを再読み込み
    if (result == true) {
      _loadMemos();
    }
  }

  void _deleteMemo(Memo memo) async {
    // 削除確認ダイアログ
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                backgroundColor: const Color(0xFF2B2B2B),
                title: const Text(
                  'メモを削除',
                  style: TextStyle(color: Colors.white),
                ),
                content: Text(
                  '「${memo.title}」を削除しますか？\nこの操作は取り消せません。',
                  style: TextStyle(color: Colors.grey[300]),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'キャンセル',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red[400]!, Colors.red[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '削除',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;

    if (shouldDelete) {
      try {
        await ref.read(memoNotifierProvider.notifier).deleteMemo(memo.id);
      } catch (e) {
        if (mounted) {
          AppErrorHandler.handleError(
            context,
            e,
            operation: 'メモの削除',
            onRetry: () => _deleteMemo(memo),
          );
        }
      }
    }
  }

  // ピン留め状態を切り替え（型安全版）
  void _togglePin(Memo memo) async {
    final newPinStatus = !memo.isPinned;

    try {
      await ref
          .read(memoNotifierProvider.notifier)
          .toggleMemoPinStatus(memo.id, newPinStatus);
    } catch (e) {
      if (mounted) {
        AppErrorHandler.handleError(
          context,
          e,
          operation: 'ピン留めの更新',
          onRetry: () => _togglePin(memo),
        );
      }
    }
  }

  // メモ編集ボトムシートを表示（型安全版）
  void _editMemo(Memo memo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) =>
              _EditMemoBottomSheet(memo: memo, onMemoUpdated: _loadMemos),
    );
  }

  @override
  Widget build(BuildContext context) {
    // メモの状態を監視
    final memoState = ref.watch(memoNotifierProvider);
    final allMemos = memoState.memos;

    // フィルター適用
    final filteredMemos = allMemos.where(_currentFilter.matches).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Stack(
        children: [
          // メモリスト（全体に表示）
          filteredMemos.isEmpty
              ? EmptyMemoState(hasColorFilter: _currentFilter.hasFilter)
              : RefreshIndicator(
                color: const Color(0xFFE85A3B),
                backgroundColor: const Color(0xFF2B2B2B),
                onRefresh: _loadMemos,
                child: ListView.builder(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.only(
                    top: 60,
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  itemCount: filteredMemos.length,
                  itemBuilder: (context, index) {
                    final memo = filteredMemos[index];
                    return MemoItemCard(
                      memo: memo,
                      isAnimating: _animatingMemoId == memo.id,
                      popAnimation: _popAnimation,
                      onTap: () => _openMemoDetail(memo),
                      onTogglePin: () => _togglePin(memo),
                      onDelete: () => _deleteMemo(memo),
                      onEditMemo: () => _editMemo(memo),
                    );
                  },
                ),
              ),
          // 色フィルタリングボタンとステータス表示（浮かせる）
          MemoFilterHeader(
            selectedColorFilter: _currentFilter.colorTag,
            memoCount: filteredMemos.length,
            onShowColorFilterBottomSheet: _showColorFilterBottomSheet,
            onClearColorFilter: _clearColorFilter,
          ),
        ],
      ),
    );
  }
}

// 色フィルタリング用のBottomSheet
class _ColorFilterBottomSheet extends StatelessWidget {
  final String? selectedColorFilter;
  final Function(String?) onColorSelected;

  const _ColorFilterBottomSheet({
    required this.selectedColorFilter,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF2B2B2B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.palette, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                '色でメモを検索',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (selectedColorFilter != null)
                TextButton(
                  onPressed: () {
                    onColorSelected(null);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'すべて表示',
                    style: TextStyle(color: Color(0xFFE85A3B), fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '表示したいメモの色を選択してください',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          // 色パレット
          ColorPalette(
            selectedColorHex: selectedColorFilter,
            onColorSelected: (colorHex) {
              onColorSelected(colorHex);
              Navigator.pop(context);
            },
            showCheckIcon: true,
            itemSize: 56.0,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// メモ編集用ボトムシート（型安全版）
class _EditMemoBottomSheet extends StatefulWidget {
  final Memo memo;
  final VoidCallback onMemoUpdated;

  const _EditMemoBottomSheet({required this.memo, required this.onMemoUpdated});

  @override
  State<_EditMemoBottomSheet> createState() => _EditMemoBottomSheetState();
}

class _EditMemoBottomSheetState extends State<_EditMemoBottomSheet> {
  final SupabaseService _supabaseService = SupabaseService();
  late MemoMode _selectedMode;
  late String _selectedColorHex;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.memo.mode;
    _selectedColorHex = widget.memo.colorTag;
  }

  Future<void> _saveMemoSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.updateMemoSettingsTyped(
        memoId: widget.memo.id,
        mode: _selectedMode,
        colorHex: _selectedColorHex,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onMemoUpdated();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('メモ設定を更新しました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('設定の更新に失敗しました: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Color(0xFF2B2B2B),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // ハンドル
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      const Text(
                        'メモ設定を編集',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // モード選択
                  const Text(
                    'メモの種類',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () =>
                                  setState(() => _selectedMode = MemoMode.memo),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient:
                                  _selectedMode == MemoMode.memo
                                      ? createHorizontalOrangeYellowGradient()
                                      : null,
                              color:
                                  _selectedMode == MemoMode.memo
                                      ? null
                                      : const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _selectedMode == MemoMode.memo
                                        ? Colors.transparent
                                        : Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.edit_note,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'メモ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap:
                              () => setState(
                                () => _selectedMode = MemoMode.calculator,
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              gradient:
                                  _selectedMode == MemoMode.calculator
                                      ? createHorizontalOrangeYellowGradient()
                                      : null,
                              color:
                                  _selectedMode == MemoMode.calculator
                                      ? null
                                      : const Color(0xFF3A3A3A),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _selectedMode == MemoMode.calculator
                                        ? Colors.transparent
                                        : Colors.grey[600]!,
                                width: 1,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.calculate,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '計算機',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 色選択
                  const Text(
                    '色ラベル',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ColorPalette(
                    selectedColorHex: _selectedColorHex,
                    onColorSelected:
                        (colorHex) =>
                            setState(() => _selectedColorHex = colorHex),
                    showCheckIcon: true,
                    itemSize: 50.0,
                  ),

                  const Spacer(),

                  // 保存ボタン
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: createHorizontalOrangeYellowGradient(),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveMemoSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                '保存',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
