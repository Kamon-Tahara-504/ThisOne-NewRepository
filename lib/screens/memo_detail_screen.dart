import 'package:flutter/material.dart';
import '../gradients.dart';
import '../services/supabase_service.dart';

class MemoDetailScreen extends StatefulWidget {
  final String memoId;
  final String title;
  final String content;
  final String mode;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
    required this.title,
    required this.content,
    required this.mode,
  });

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final SupabaseService _supabaseService = SupabaseService();
  
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
    
    // テキスト変更を監視
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
    
    // 1秒後に自動保存（デバウンス）
    Future.delayed(const Duration(seconds: 1), () {
      if (_hasChanges && !_isSaving) {
        _saveChanges();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      await _supabaseService.updateMemo(
        memoId: widget.memoId,
        title: _titleController.text.trim().isEmpty 
            ? '無題' 
            : _titleController.text.trim(),
        content: _contentController.text,
      );
      
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _handleBackPressed() async {
    if (_hasChanges) {
      await _saveChanges();
    }
    if (mounted) {
      Navigator.pop(context, true); // 変更があったことを通知
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && _hasChanges) {
          await _saveChanges();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            color: const Color(0xFF2B2B2B),
            child: Column(
              children: [
                // ステータスバー部分
                Container(
                  height: MediaQuery.of(context).padding.top,
                  width: double.infinity,
                  color: const Color(0xFF2B2B2B),
                ),
                // AppBar部分
                Expanded(
                  child: Container(
                    color: const Color(0xFF2B2B2B),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              children: [
                                // 戻るボタン
                                IconButton(
                                  onPressed: _handleBackPressed,
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                
                                // 保存状態表示
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isSaving) ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: const Color(0xFFE85A3B),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '保存中...',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else if (_hasChanges) ...[
                                        Text(
                                          '未保存の変更があります',
                                          style: TextStyle(
                                            color: Colors.orange[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          '保存済み',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // メニューボタン（今後の拡張用）
                                IconButton(
                                  onPressed: () {
                                    // TODO: メニュー機能
                                  },
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // グラデーションガイドライン
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: createHorizontalOrangeYellowGradient(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // タイトル入力
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'タイトル',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  maxLines: 1,
                ),
                
                const SizedBox(height: 16),
                
                // 日付・モード表示
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: createOrangeYellowGradient(),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.mode == 'memo' ? 'メモモード' : widget.mode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // 内容入力
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'ここに内容を入力してください...',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 