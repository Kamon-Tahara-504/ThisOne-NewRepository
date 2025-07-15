import 'package:flutter/material.dart';
import '../gradients.dart';
import '../utils/color_utils.dart';

class MemoFilterHeader extends StatelessWidget {
  final String? selectedColorFilter;
  final int memoCount;
  final VoidCallback onShowColorFilterBottomSheet;
  final VoidCallback onClearColorFilter;

  const MemoFilterHeader({
    super.key,
    required this.selectedColorFilter,
    required this.memoCount,
    required this.onShowColorFilterBottomSheet,
    required this.onClearColorFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
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
                color: selectedColorFilter != null ? Colors.transparent : const Color(0xFF3A3A3A),
                borderRadius: BorderRadius.circular(20),
                border: selectedColorFilter != null
                    ? Border.all(
                        width: 1,
                        color: Colors.transparent,
                      )
                    : Border.all(
                        color: Colors.grey[600]!,
                      ),
                gradient: selectedColorFilter != null
                    ? createOrangeYellowGradient()
                    : null,
              ),
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: selectedColorFilter != null ? Colors.transparent : const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onShowColorFilterBottomSheet,
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
                              selectedColorFilter != null ? '色フィルタ中' : '色で検索',
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
            if (selectedColorFilter != null) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: ColorUtils.isGradientColor(selectedColorFilter!)
                      ? ColorUtils.getGradientFromHex(selectedColorFilter!)
                      : null,
                  color: ColorUtils.isGradientColor(selectedColorFilter!)
                      ? null
                      : ColorUtils.getColorFromHex(selectedColorFilter!),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'フィルタ中',
                      style: TextStyle(
                        color: (selectedColorFilter == '#FFEB3B') ? Colors.black : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onClearColorFilter,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: (selectedColorFilter == '#FFEB3B') ? Colors.black : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            // メモ数表示
            Text(
              '$memoCount件のメモ',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 