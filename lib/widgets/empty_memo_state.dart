import 'package:flutter/material.dart';
import '../gradients.dart';

class EmptyMemoState extends StatelessWidget {
  final bool hasColorFilter;

  const EmptyMemoState({
    super.key,
    required this.hasColorFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
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
            hasColorFilter ? 'この色のメモがありません' : 'メモがありません',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasColorFilter 
                ? '他の色を選択するか、フィルタを解除してください'
                : '下部の + ボタンから新しいメモを追加してください',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 