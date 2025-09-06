import 'package:flutter/material.dart';
import '../utils/color_utils.dart'; // 色分けラベル用のユーティリティを追加

class MemoBackHeader extends StatelessWidget {
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final String mode;
  final String? colorHex; // 色ラベルのパラメータを追加
  final DateTime? lastUpdated;
  final bool isSaving;
  final VoidCallback onBackPressed;

  const MemoBackHeader({
    super.key,
    required this.titleController,
    required this.titleFocusNode,
    required this.mode,
    this.colorHex, // 色ラベルのパラメータを追加
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
          padding: const EdgeInsets.fromLTRB(22, 0, 12, 12), // 下部パディングを増加
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start, // 上部揃えに変更
            children: [
              // 左端の小テープ（位置調整）
              Container(
                margin: const EdgeInsets.only(top: 8), // 上部マージンで位置調整
                width: 6,
                height: 38, // 高さを短縮
                decoration: BoxDecoration(
                  gradient: ColorUtils.isGradientColor(colorHex ?? ColorUtils.defaultColorHex)
                      ? ColorUtils.getGradientFromHex(colorHex ?? ColorUtils.defaultColorHex)
                      : null,
                  color: ColorUtils.isGradientColor(colorHex ?? ColorUtils.defaultColorHex)
                      ? null
                      : ColorUtils.getColorFromHex(colorHex ?? ColorUtils.defaultColorHex),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              // タイトル入力とメタ情報（Androidシミュレーター対応：固定高さ）
              Expanded(
                child: Container(
                  height: 54, // 固定高さでオーバーフロー防止
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // タイトル入力フィールド
                      SizedBox(
                        height: 32, // タイトルフィールドの固定高さ
                        child: TextField(
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
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4), // 間隔を調整
                      // モードラベルと更新時刻を横並びに（Androidシミュレーター対応：最小高さ）
                      SizedBox(
                        height: 18, // 固定高さでオーバーフロー防止
                        child: Row(
                          children: [
                            // モード表示ラベル
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey[600]!.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                mode == 'memo' ? 'メモ' : (mode == 'calculator' || mode == 'rich') ? '計算機' : mode,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 更新時刻（Androidシミュレーター対応：Flexibleでオーバーフロー防止）
                            Flexible(
                              child: Text(
                                _getLastUpdatedText(),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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