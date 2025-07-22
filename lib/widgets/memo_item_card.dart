import 'package:flutter/material.dart';
import '../gradients.dart';
import '../utils/color_utils.dart';

class MemoItemCard extends StatelessWidget {
  final Map<String, dynamic> memo;
  final bool isAnimating;
  final Animation<double>? popAnimation;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;
  final VoidCallback onChangeColorLabel;

  const MemoItemCard({
    super.key,
    required this.memo,
    required this.isAnimating,
    required this.onTap,
    required this.onTogglePin,
    required this.onDelete,
    required this.onChangeColorLabel,
    this.popAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final updatedAt = memo['updatedAt'] as DateTime;
    final isPinned = memo['is_pinned'] ?? false;
    
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
        onTap: isAnimating ? null : onTap, // アニメーション中はタップを無効化
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
                  // 色分けラベル表示（色背景+モード文字・タップで色変更可能）
                  GestureDetector(
                    onTap: onChangeColorLabel,
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
                        memo['mode'] == 'memo' ? 'メモ' : (memo['mode'] == 'calculator' || memo['mode'] == 'rich') ? '計算機' : memo['mode'],
                        style: TextStyle(
                          color: (memo['color_tag'] == '#FFEB3B') ? Colors.black : Colors.white, // 黄色の場合は黒文字
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
                    onPressed: onTogglePin,
                    icon: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      color: isPinned 
                          ? const Color(0xFFE85A3B)
                          : Colors.grey[500],
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
              if (memo['content'] != null && memo['content'].isNotEmpty) ...[
                Text(
                  memo['content'],
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
    return Material(
      color: Colors.transparent,
      child: memoCard,
    );
  }
} 