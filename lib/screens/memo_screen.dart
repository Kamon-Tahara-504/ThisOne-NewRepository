import 'package:flutter/material.dart';
import '../gradients.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  final List<Map<String, dynamic>> _memos = [];

  void addMemo(Map<String, dynamic> memo) {
    setState(() {
      _memos.add(memo);
    });
  }

  void _editMemo(int index) {
    showDialog(
      context: context,
      builder: (context) => _AddMemoDialog(
        memo: _memos[index],
        onAdd: (memo) {
          setState(() {
            _memos[index] = memo;
          });
        },
      ),
    );
  }

  void _deleteMemo(int index) {
    setState(() {
      _memos.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      body: _memos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_alt_outlined,
                    size: 64,
                    color: Colors.grey[600],
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
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _memos.length,
              itemBuilder: (context, index) {
                final memo = _memos[index];
                final createdAt = memo['createdAt'] as DateTime;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: InkWell(
                    onTap: () => _editMemo(index),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
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
                            '${createdAt.year}/${createdAt.month}/${createdAt.day} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
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