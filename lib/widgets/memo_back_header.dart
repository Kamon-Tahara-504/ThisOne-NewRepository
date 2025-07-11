import 'package:flutter/material.dart';
import '../gradients.dart';

class MemoBackHeader extends StatelessWidget {
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final String mode;
  final DateTime? lastUpdated;
  final bool isSaving;
  final VoidCallback onBackPressed;

  const MemoBackHeader({
    super.key,
    required this.titleController,
    required this.titleFocusNode,
    required this.mode,
    required this.lastUpdated,
    required this.isSaving,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBarエリア
        Container(
          color: const Color(0xFF2B2B2B),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 56, // AppBarの標準高さ
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Backボタンとラベル
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: onBackPressed,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Transform.translate(
                          offset: const Offset(-6, 0),
                          child: const Text(
                            'Back',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 保存インジケーター
                  if (isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE85A3B),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        // タイトル編集エリア
        Container(
          color: const Color(0xFF2B2B2B),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), //メモ全体の高さ調整
          child: Row(
            children: [
              // モードバッジ
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: createOrangeYellowGradient(),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  mode == 'memo' ? 'メモ' : mode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // タイトル編集とメタ情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      focusNode: titleFocusNode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'タイトルを入力...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        isDense: true,
                      ),
                    ),
                    Text(
                      _getLastUpdatedText(),
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getLastUpdatedText() {
    if (lastUpdated == null) {
      return '更新: 未更新';
    }
    
    final year = lastUpdated!.year;
    final month = lastUpdated!.month;
    final day = lastUpdated!.day;
    final hour = lastUpdated!.hour.toString().padLeft(2, '0');
    final minute = lastUpdated!.minute.toString().padLeft(2, '0');
    
    return '更新: $year/$month/$day $hour:$minute';
  }
} 