import 'package:flutter/material.dart';
import '../utils/color_utils.dart';

class ColorPalette extends StatelessWidget {
  final String? selectedColorHex;
  final Function(String) onColorSelected;
  final bool showSelection;
  final double itemSize;
  final bool showCheckIcon;

  const ColorPalette({
    super.key,
    this.selectedColorHex,
    required this.onColorSelected,
    this.showSelection = true,
    this.itemSize = 56.0,
    this.showCheckIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 色パレット（2行5列）
        for (int row = 0; row < 2; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 0; col < 5; col++)
                  if (row * 5 + col < ColorUtils.colorLabelPalette.length)
                    _buildColorOption(
                      context,
                      ColorUtils.colorLabelPalette[row * 5 + col],
                    ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildColorOption(BuildContext context, Map<String, dynamic> colorItem) {
    final colorHex = colorItem['hex'] as String;
    final isGradient = colorItem['isGradient'] as bool;
    final color = colorItem['color'] as Color?;
    final isSelected = showSelection && selectedColorHex == colorHex;

    return GestureDetector(
      onTap: () => onColorSelected(colorHex),
      child: Container(
        width: itemSize,
        height: itemSize,
        decoration: BoxDecoration(
          gradient: isGradient ? ColorUtils.getGradientFromHex(colorHex) : null,
          color: isGradient ? null : color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.grey[600]!,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: isSelected && showCheckIcon
            ? const Icon(
                Icons.check,
                color: Colors.white,
                size: 28,
              )
            : null,
      ),
    );
  }
} 