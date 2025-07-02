import 'package:flutter/material.dart';
import '../gradients.dart';
import '../services/supabase_service.dart';
import 'memo_detail_screen.dart';

class MemoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> memos;
  final Function(List<Map<String, dynamic>>) onMemosChanged;

  const MemoScreen({
    super.key,
    required this.memos,
    required this.onMemosChanged,
  });

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
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
        'createdAt': DateTime.parse(memo['created_at']),
        'updatedAt': DateTime.parse(memo['updated_at']),
      }).toList();
      
      widget.onMemosChanged(updatedMemos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メモの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  void _openMemoDetail(int index) async {
    final memo = widget.memos[index];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoDetailScreen(
          memoId: memo['id'],
          title: memo['title'],
          content: memo['content'],
          mode: memo['mode'],
        ),
      ),
    );
    
    // 詳細画面から戻った時にメモリストを再読み込み
    if (result == true) {
      _loadMemos();
    }
  }

  void _deleteMemo(int index) async {
    final memo = widget.memos[index];
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: widget.memos.isEmpty
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
                    'メモがありません',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '下部の + ボタンから新しいメモを追加してください',
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
                padding: const EdgeInsets.all(16),
                itemCount: widget.memos.length,
                itemBuilder: (context, index) {
                  final memo = widget.memos[index];
                  final updatedAt = memo['updatedAt'] as DateTime;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: InkWell(
                      onTap: () => _openMemoDetail(index),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // モード表示
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: createOrangeYellowGradient(),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    memo['mode'] == 'memo' ? 'メモ' : memo['mode'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
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
                                IconButton(
                                  onPressed: () => _deleteMemo(index),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.grey[500],
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            if (memo['content'].isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                memo['content'],
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              '更新: ${updatedAt.year}/${updatedAt.month}/${updatedAt.day} ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _AddMemoDialog extends StatefulWidget {
  final Map<String, dynamic>? memo;
  final Function(Map<String, dynamic>) onAdd;

  const _AddMemoDialog({
    this.memo,
    required this.onAdd,
  });

  @override
  State<_AddMemoDialog> createState() => _AddMemoDialogState();
}

class _AddMemoDialogState extends State<_AddMemoDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.memo != null) {
      _titleController.text = widget.memo!['title'];
      _contentController.text = widget.memo!['content'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveMemo() {
    if (_titleController.text.trim().isNotEmpty) {
      widget.onAdd({
        'id': widget.memo?['id'] ?? DateTime.now().millisecondsSinceEpoch,
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'createdAt': widget.memo?['createdAt'] ?? DateTime.now(),
        'updatedAt': DateTime.now(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF3A3A3A),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.memo != null ? 'メモを編集' : '新しいメモ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'タイトル',
                labelStyle: TextStyle(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE85A3B)),
                ),
                filled: true,
                fillColor: const Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _contentController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: '内容',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE85A3B)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2B2B2B),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'キャンセル',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: createOrangeYellowGradient(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextButton(
                      onPressed: _saveMemo,
                      child: const Text(
                        '保存',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 