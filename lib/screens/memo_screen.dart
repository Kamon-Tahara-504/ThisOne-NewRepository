
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../utils/color_utils.dart'; // 色分けラベル用のユーティリティを追加
import '../widgets/memo_item_card.dart';
import '../widgets/memo_filter_header.dart';
import '../widgets/empty_memo_state.dart';
import 'memo_detail_screen.dart';

class MemoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> memos;
  final Function(List<Map<String, dynamic>>) onMemosChanged;
  final String? newlyCreatedMemoId; // 新しく作成されたメモのID
  final VoidCallback? onPopAnimationComplete; // ポップアニメーション完了時のコールバック

  const MemoScreen({
    super.key,
    required this.memos,
    required this.onMemosChanged,
    this.newlyCreatedMemoId,
    this.onPopAnimationComplete,
  });

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> with TickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  late AnimationController _popAnimationController;
  late Animation<double> _popAnimation;
  String? _animatingMemoId; // アニメーション中のメモID
  String? _selectedColorFilter; // 選択された色フィルタ

  @override
  void initState() {
    super.initState();
    
    // ポップアニメーションコントローラー
    _popAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _popAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _popAnimationController,
      curve: Curves.elasticOut,
    ));
    
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

  // フィルタリングされたメモを取得
  List<Map<String, dynamic>> get _filteredMemos {
    if (_selectedColorFilter == null) {
      return widget.memos;
    }
    return widget.memos.where((memo) => 
      memo['color_tag'] == _selectedColorFilter
    ).toList();
  }

  // 色フィルタリングを設定
  void _setColorFilter(String? colorHex) {
    setState(() {
      _selectedColorFilter = colorHex;
    });
  }

  // 色フィルタリングをクリア
  void _clearColorFilter() {
    setState(() {
      _selectedColorFilter = null;
    });
  }

  // 色フィルタリングBottomSheetを表示
  void _showColorFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ColorFilterBottomSheet(
        selectedColorFilter: _selectedColorFilter,
        onColorSelected: _setColorFilter,
      ),
    );
  }

  // Supabaseからメモを再読み込み
  Future<void> _loadMemos() async {
    try {
      final memos = await _supabaseService.getUserMemos();
      final updatedMemos = memos.map((memo) => {
        'id': memo['id'],
        'title': memo['title'],
        'content': memo['content'] ?? '',
        'mode': memo['mode'] ?? 'memo',
        'rich_content': memo['rich_content'],
        'is_pinned': memo['is_pinned'] ?? false, // ピン留め状態を追加
        'tags': memo['tags'] ?? [], // タグを追加
        'color_tag': memo['color_tag'] ?? '#FFD700', // 色タグを追加
        'createdAt': DateTime.parse(memo['created_at']).toLocal(),
        'updatedAt': DateTime.parse(memo['updated_at']).toLocal(),
      }).toList();
      
      // データベース側でソート済みなので、クライアント側ソートは不要
      widget.onMemosChanged(updatedMemos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メモの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  void _openMemoDetail(Map<String, dynamic> memo) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MemoDetailScreen(
          memoId: memo['id'],
          title: memo['title'],
          content: memo['content'],
          mode: memo['mode'],
          richContent: memo['rich_content'],
          colorHex: memo['color_tag'], // 色ラベル情報を追加
          updatedAt: memo['updatedAt'],
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

  void _deleteMemo(Map<String, dynamic> memo) async {
    // 削除確認ダイアログ
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3A3A3A),
        title: const Text(
          'メモを削除',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '「${memo['title']}」を削除しますか？\nこの操作は取り消せません。',
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
    ) ?? false;

    if (shouldDelete) {
      try {
        await _supabaseService.deleteMemo(memo['id']);
        _loadMemos(); // リストを再読み込み
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メモ「${memo['title']}」を削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メモの削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  // ピン留め状態を切り替え
  void _togglePin(Map<String, dynamic> memo) async {
    final newPinStatus = !(memo['is_pinned'] ?? false);
    
    try {
      await _supabaseService.updateMemoPinStatus(
        memoId: memo['id'],
        isPinned: newPinStatus,
      );
      
      // 成功した場合はリストを再読み込み
      _loadMemos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ピン留めの更新に失敗しました: $e')),
        );
      }
    }
  }

  // 色分けラベルを変更
  void _changeColorLabel(Map<String, dynamic> memo) async {
    // 色選択ダイアログを表示
    final selectedColorHex = await showDialog<String>(
      context: context,
      builder: (context) => _ColorLabelDialog(
        currentColorHex: memo['color_tag'] ?? ColorUtils.defaultColorHex,
      ),
    );
    
    if (selectedColorHex != null && selectedColorHex != memo['color_tag']) {
      try {
        await _supabaseService.updateMemoColorLabel(
          memoId: memo['id'],
          colorHex: selectedColorHex,
        );
        
        // 成功した場合はリストを再読み込み
        _loadMemos();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('色ラベルの更新に失敗しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMemos = _filteredMemos;
    
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: Stack(
        children: [
          // メモリスト（全体に表示）
          filteredMemos.isEmpty
              ? EmptyMemoState(
                  hasColorFilter: _selectedColorFilter != null,
                )
              : RefreshIndicator(
                  color: const Color(0xFFE85A3B),
                  backgroundColor: const Color(0xFF3A3A3A),
                  onRefresh: _loadMemos,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
                    itemCount: filteredMemos.length,
                    itemBuilder: (context, index) {
                      final memo = filteredMemos[index];
                      return MemoItemCard(
                        memo: memo,
                        isAnimating: _animatingMemoId == memo['id'],
                        popAnimation: _popAnimation,
                        onTap: () => _openMemoDetail(memo),
                        onTogglePin: () => _togglePin(memo),
                        onDelete: () => _deleteMemo(memo),
                        onChangeColorLabel: () => _changeColorLabel(memo),
                      );
                    },
                  ),
                ),
          // 色フィルタリングボタンとステータス表示（浮かせる）
          MemoFilterHeader(
            selectedColorFilter: _selectedColorFilter,
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
        color: Color(0xFF3A3A3A),
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
              const Icon(
                Icons.palette,
                color: Colors.white,
                size: 24,
              ),
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
                    style: TextStyle(
                      color: Color(0xFFE85A3B),
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '表示したいメモの色を選択してください',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          // 色パレット（2行5列）
          for (int row = 0; row < 2; row++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 0; col < 5; col++)
                    if (row * 5 + col < ColorUtils.colorLabelPalette.length)
                      _buildColorFilterOption(
                        context,
                        ColorUtils.colorLabelPalette[row * 5 + col],
                      ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildColorFilterOption(BuildContext context, Map<String, dynamic> colorItem) {
    final colorHex = colorItem['hex'] as String;
    final isGradient = colorItem['isGradient'] as bool;
    final color = colorItem['color'] as Color?;
    final isSelected = selectedColorFilter == colorHex;

    return GestureDetector(
      onTap: () {
        onColorSelected(colorHex);
        Navigator.pop(context);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: isGradient ? ColorUtils.getGradientFromHex(colorHex) : null,
          color: isGradient ? null : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[600]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              )
            : null,
      ),
    );
  }
}

// 色選択ダイアログ
class _ColorLabelDialog extends StatelessWidget {
  final String currentColorHex;

  const _ColorLabelDialog({
    required this.currentColorHex,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF3A3A3A),
      title: const Text(
        '色ラベルを選択',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 10色のパレットを表示（2行5列）
          for (int row = 0; row < 2; row++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int col = 0; col < 5; col++)
                    if (row * 5 + col < ColorUtils.colorLabelPalette.length)
                      _buildColorOption(
                        context,
                        ColorUtils.colorLabelPalette[row * 5 + col],
                      ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'キャンセル',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ],
    );
  }

  Widget _buildColorOption(BuildContext context, Map<String, dynamic> colorItem) {
    final colorHex = colorItem['hex'] as String;
    final isGradient = colorItem['isGradient'] as bool;
    final color = colorItem['color'] as Color?;
    final isSelected = currentColorHex == colorHex;

    return GestureDetector(
      onTap: () => Navigator.pop(context, colorHex),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: isGradient ? ColorUtils.getGradientFromHex(colorHex) : null,
          color: isGradient ? null : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[600]!,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
} 