import 'package:flutter/material.dart';
import '../gradients.dart';
import '../utils/color_utils.dart';
import '../models/memo.dart'; // 型安全なMemoモデル

class MemoItemCard extends StatelessWidget {
  final Memo memo; // 型安全なMemoモデルに変更
  final bool isAnimating;
  final Animation<double>? popAnimation;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final VoidCallback onEditMemo; // 編集ボタン用のコールバック

  const MemoItemCard({
    super.key,
    required this.memo,
    required this.isAnimating,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
    required this.onEditMemo, // 編集コールバックを必須に
    this.popAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final updatedAt = memo.updatedAt;
    final isPinned = memo.isPinned;

    Widget memoCard = Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A), // ピン留め状態に関係なく統一
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[700]!), // ピン留め状態に関係なく統一
        // アニメーション中は特別な装飾を追加
        boxShadow:
            isAnimating
                ? [
                  BoxShadow(
                    color: const Color(0xFFE85A3B).withValues(alpha: 0.6),
                    blurRadius: 20,
                    offset: const Offset(0, 5),
                  ),
                ]
                : null,
      ),
      child: InkWell(
        onTap: isAnimating ? null : onTap, // アニメーション中はタップを無効化
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 左側の付箋テープ部分
              Container(
                width: 8,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient:
                      ColorUtils.isGradientColor(memo.colorTag)
                          ? ColorUtils.getGradientFromHex(memo.colorTag)
                          : null,
                  color:
                      ColorUtils.isGradientColor(memo.colorTag)
                          ? null
                          : ColorUtils.getColorFromHex(memo.colorTag),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // メモ本体部分
              Expanded(
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
                              shaderCallback:
                                  (bounds) => createOrangeYellowGradient()
                                      .createShader(bounds),
                              child: const Icon(
                                Icons.push_pin,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          // モード表示ラベル
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[600]!.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              memo.mode.displayName,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              memo.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          // ピン留めボタン
                          IconButton(
                            onPressed: onTogglePin,
                            icon: Icon(
                              isPinned
                                  ? Icons.push_pin
                                  : Icons.push_pin_outlined,
                              color:
                                  isPinned
                                      ? const Color(0xFFE85A3B)
                                      : Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          // 編集ボタン
                          IconButton(
                            onPressed: onEditMemo,
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: onDelete,
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
                      if (memo.content.isNotEmpty) ...[
                        Text(
                          memo.previewText,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 2, // メモ詳細を2行まで表示
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                      ],
                      // 更新日時
                      Text(
                        '${updatedAt.year}/${updatedAt.month}/${updatedAt.day} ${updatedAt.hour.toString().padLeft(2, '0')}:${updatedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // アニメーション中の場合は、スケールとバウンス効果を適用
    if (isAnimating && popAnimation != null) {
      return Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: popAnimation!,
          builder: (context, child) {
            return Transform.scale(
              scale: 0.8 + (popAnimation!.value * 0.2),
              child: Transform.translate(
                offset: Offset(0, -10 * (1 - popAnimation!.value)),
                child: child,
              ),
            );
          },
          child: memoCard,
        ),
      );
    }

    // 通常状態
    return Material(color: Colors.transparent, child: memoCard);
  }
}
