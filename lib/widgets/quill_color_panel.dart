import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class QuillColorPanel extends StatelessWidget {
  final QuillController controller;
  final bool isBackgroundColorMode;
  final VoidCallback onClose;
  final VoidCallback onColorChanged;

  const QuillColorPanel({
    super.key,
    required this.controller,
    required this.isBackgroundColorMode,
    required this.onClose,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 色のリストを定義
    final List<Color?> firstRowColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
    ];
    
    final List<Color?> secondRowColors = [
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.black,
      null, // リセットボタン
    ];

    // 動的に横幅を計算
    const double buttonSize = 24.0;
    const double buttonSpacing = 12.0;
    const double sidePadding = 8.0;
    const int buttonCount = 5;
    
    final double panelWidth = (buttonCount * buttonSize) + 
                             ((buttonCount - 1) * buttonSpacing) + 
                             (sidePadding * 2);

    return Positioned(
      top: 60,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 8),
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // タイトルと閉じるボタンの行
              SizedBox(
                width: panelWidth - (sidePadding * 2),
                height: 22,
                child: Stack(
                  children: [
                    // 中央に配置されたタイトル
                    Center(
                      child: Text(
                        isBackgroundColorMode ? '背景色' : '文字色',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // 右端に配置された閉じるボタン
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              
              // 最初の行（5色）
              Row(
                children: firstRowColors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final color = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < firstRowColors.length - 1 ? buttonSpacing : 0
                    ),
                    child: _buildSmallColorButton(color),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 10),
              
              // 2番目の行（5色、リセットボタン含む）
              Row(
                children: secondRowColors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final color = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < secondRowColors.length - 1 ? buttonSpacing : 0
                    ),
                    child: _buildSmallColorButton(color),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallColorButton(Color? color) {
    const double buttonSize = 24.0;
    
    return GestureDetector(
      onTap: () {
        if (color != null) {
          _setTypingColor(color);
        } else {
          _removeTypingColor();
        }
        onClose();
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isBackgroundColorMode
              ? (color != null 
                  ? Color.fromRGBO(
                      (color.r * 255).round(),
                      (color.g * 255).round(),
                      (color.b * 255).round(),
                      0.3,
                    )
                  : const Color(0xFF3A3A3A)) // リセットボタンはエディタの背景色
              : const Color(0xFF4A4A4A), // 文字色ボタンの背景
          border: Border.all(color: Colors.grey[400]!, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isBackgroundColorMode
            ? null // 背景色は色そのものを表示（nullの場合は通常の背景色）
            : Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: color ?? Colors.white, // 文字色またはリセット時は白
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  void _setTypingColor(Color color) {
    final selection = controller.selection;
    if (selection.isValid) {
      String colorString;
      
      if (isBackgroundColorMode) {
        final r = (color.r * 255).round();
        final g = (color.g * 255).round();
        final b = (color.b * 255).round();
        colorString = 'rgba($r, $g, $b, 0.3)';
        controller.formatSelection(BackgroundAttribute(colorString));
      } else {
        final colorHex = '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}';
        controller.formatSelection(ColorAttribute(colorHex));
      }
      
      onColorChanged();
    }
  }

  void _removeTypingColor() {
    final selection = controller.selection;
    if (selection.isValid) {
      if (isBackgroundColorMode) {
        controller.formatSelection(const BackgroundAttribute(null));
      } else {
        controller.formatSelection(const ColorAttribute(null));
      }
      
      onColorChanged();
    }
  }

  /// カラーパネルを表示するためのヘルパーメソッド
  static OverlayEntry createOverlay({
    required BuildContext context,
    required QuillController controller,
    required bool isBackgroundColorMode,
    required VoidCallback onClose,
    required VoidCallback onColorChanged,
  }) {
    return OverlayEntry(
      builder: (context) => QuillColorPanel(
        controller: controller,
        isBackgroundColorMode: isBackgroundColorMode,
        onClose: onClose,
        onColorChanged: onColorChanged,
      ),
    );
  }
} 