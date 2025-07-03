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
          richContent: memo['rich_content'],
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