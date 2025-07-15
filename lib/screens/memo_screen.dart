
import 'package:flutter/material.dart';
import '../gradients.dart';
import '../services/supabase_service.dart';
import '../utils/color_utils.dart'; // 色分けラベル用のユーティリティを追加
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
                        child: const Icon(
                          Icons.note_alt_outlined,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedColorFilter != null ? 'この色のメモがありません' : 'メモがありません',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedColorFilter != null 
                            ? '他の色を選択するか、フィルタを解除してください'
                            : '下部の + ボタンから新しいメモを追加してください',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: const Color(0xFFE85A3B),
                  backgroundColor: const Color(0xFF3A3A3A),
                  onRefresh: _loadMemos,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
                    itemCount: filteredMemos.length,
                    itemBuilder: (context, index) {
                      return _buildMemoItem(filteredMemos, index);
                    },
                  ),
                ),
          // 色フィルタリングボタンとステータス表示（浮かせる）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF2B2B2B).withOpacity(0.95),
                    const Color(0xFF2B2B2B).withOpacity(0.8),
                    const Color(0xFF2B2B2B).withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 色フィルタリングボタン
                  Container(
                    decoration: BoxDecoration(
                      color: _selectedColorFilter != null ? Colors.transparent : const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(20),
                      border: _selectedColorFilter != null
                          ? Border.all(
                              width: 1,
                              color: Colors.transparent,
                            )
                          : Border.all(
                              color: Colors.grey[600]!,
                            ),
                      gradient: _selectedColorFilter != null
                          ? createOrangeYellowGradient()
                          : null,
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: _selectedColorFilter != null ? Colors.transparent : const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showColorFilterBottomSheet,
                          borderRadius: BorderRadius.circular(19),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
                                  child: const Icon(
                                    Icons.palette,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
                                  child: Text(
                                    _selectedColorFilter != null ? '色フィルタ中' : '色で検索',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // フィルタリング状態表示と解除ボタン
                  if (_selectedColorFilter != null) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: ColorUtils.isGradientColor(_selectedColorFilter!)
                            ? ColorUtils.getGradientFromHex(_selectedColorFilter!)
                            : null,
                        color: ColorUtils.isGradientColor(_selectedColorFilter!)
                            ? null
                            : ColorUtils.getColorFromHex(_selectedColorFilter!),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'フィルタ中',
                            style: TextStyle(
                              color: (_selectedColorFilter == '#FFEB3B') ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearColorFilter,
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: (_selectedColorFilter == '#FFEB3B') ? Colors.black : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  // メモ数表示
                  Text(
                    '${filteredMemos.length}件のメモ',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
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

  Widget _buildMemoItem(List<Map<String, dynamic>> memos, int index) {
    final memo = memos[index];
    final updatedAt = memo['updatedAt'] as DateTime;
    final isPinned = memo['is_pinned'] ?? false;
    final isAnimating = _animatingMemoId == memo['id'];
    
    Widget memoCard = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A), // ピン留め状態に関係なく統一
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!), // ピン留め状態に関係なく統一
        // アニメーション中は特別な装飾を追加
        boxShadow: isAnimating ? [
          BoxShadow(
            color: const Color(0xFFE85A3B).withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ] : null,
      ),
      child: InkWell(
        onTap: isAnimating ? null : () => _openMemoDetail(memo), // アニメーション中はタップを無効化
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ピン留めアイコン
                  if (isPinned) ...[
                    ShaderMask(
                      shaderCallback: (bounds) => createOrangeYellowGradient().createShader(bounds),
                      child: const Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // 色分けラベル表示（色背景+モード文字・タップで変更可能）
                  GestureDetector(
                    onTap: () => _changeColorLabel(memo),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: ColorUtils.isGradientColor(memo['color_tag'] ?? ColorUtils.defaultColorHex)
                            ? ColorUtils.getGradientFromHex(memo['color_tag'] ?? ColorUtils.defaultColorHex)
                            : null,
                        color: ColorUtils.isGradientColor(memo['color_tag'] ?? ColorUtils.defaultColorHex)
                            ? null
                            : ColorUtils.getColorFromHex(memo['color_tag'] ?? ColorUtils.defaultColorHex),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        memo['mode'] == 'memo' ? 'メモ' : memo['mode'],
                        style: TextStyle(
                          color: (memo['color_tag'] == '#FFEB3B') ? Colors.black : Colors.white, // 黄色の場合は黒文字
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      memo['title'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // ピン留めボタン
                  IconButton(
                    onPressed: () => _togglePin(memo),
                    icon: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: isPinned 
                          ? const Color(0xFFE85A3B)
                          : Colors.grey[500],
                      size: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteMemo(memo),
                    icon: Icon(
                      Icons.delete_outline,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // メモの内容プレビュー
              if (memo['content'] != null && memo['content'].isNotEmpty) ...[
                Text(
                  memo['content'],
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
              // 更新日時
              Text(
                '${updatedAt.month}/${updatedAt.day} ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // アニメーション中の場合は、スケールとバウンス効果を適用
    if (isAnimating) {
      return Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _popAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (_popAnimation.value * 0.2),
              child: Transform.translate(
                offset: Offset(0, -10 * (1 - _popAnimation.value)),
                child: child,
              ),
            );
          },
          child: memoCard,
        ),
      );
    }
    
    // 通常状態（Heroウィジェットを削除）
    return Material(
      color: Colors.transparent,
      child: memoCard,
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