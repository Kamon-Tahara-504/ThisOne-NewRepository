import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../gradients.dart';

class QuillToolbar extends StatelessWidget {
  final QuillController controller;
  final VoidCallback onTextColorPressed;
  final VoidCallback onBackgroundColorPressed;
  final VoidCallback onStateChanged;

  const QuillToolbar({
    super.key,
    required this.controller,
    required this.onTextColorPressed,
    required this.onBackgroundColorPressed,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A4A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: GestureDetector(
        onTap: onStateChanged,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 利用可能な幅からパディングを引く
            double availableWidth = constraints.maxWidth - 16;
            
            // 画面サイズに応じてボタン間の間隔を設定
            double buttonMargin;
            if (availableWidth < 400) {
              buttonMargin = 2;
            } else if (availableWidth < 800) {
              buttonMargin = 4;
            } else {
              buttonMargin = 6;
            }
            
            // 8つのボタンとマージンを考慮してボタンサイズを計算
            int buttonCount = 8;
            double totalMargin = (buttonCount - 1) * buttonMargin;
            double buttonSize = (availableWidth - totalMargin) / buttonCount;
            
            // 画面サイズに応じてボタンサイズの制限を動的に設定
            double minButtonSize, maxButtonSize;
            if (availableWidth < 400) {
              minButtonSize = 24.0;
              maxButtonSize = 40.0;
            } else if (availableWidth < 800) {
              minButtonSize = 36.0;
              maxButtonSize = 56.0;
            } else {
              minButtonSize = 48.0;
              maxButtonSize = 80.0;
            }
            
            buttonSize = buttonSize.clamp(minButtonSize, maxButtonSize);
            
            // ツールバーボタンのリスト
            List<Widget> toolbarButtons = [
              _buildToolbarButton(
                icon: Icons.format_bold,
                isActive: _isFormatActive(Attribute.bold),
                onPressed: () => _toggleFormat(Attribute.bold),
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
              _buildToolbarButton(
                icon: Icons.format_italic,
                isActive: _isFormatActive(Attribute.italic),
                onPressed: () => _toggleFormat(Attribute.italic),
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
              _buildToolbarButton(
                icon: Icons.format_underlined,
                isActive: _isFormatActive(Attribute.underline),
                onPressed: () => _toggleFormat(Attribute.underline),
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
              _buildToolbarButton(
                icon: Icons.format_strikethrough,
                isActive: _isFormatActive(Attribute.strikeThrough),
                onPressed: () => _toggleFormat(Attribute.strikeThrough),
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
              _buildToolbarButton(
                icon: Icons.format_list_numbered,
                isActive: _isFormatActive(Attribute.ol),
                onPressed: () => _toggleFormat(Attribute.ol),
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
              _buildToolbarButton(
                icon: Icons.format_list_bulleted,
                isActive: _isFormatActive(Attribute.ul),
                onPressed: () => _toggleFormat(Attribute.ul),
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
              _buildColorButton(
                icon: Icons.text_format,
                isTextColor: true,
                onPressed: onTextColorPressed,
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
              _buildColorButton(
                icon: Icons.format_color_fill,
                isTextColor: false,
                onPressed: onBackgroundColorPressed,
                buttonSize: buttonSize,
                margin: buttonMargin,
              ),
            ];
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: toolbarButtons,
            );
          },
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required double buttonSize,
    required double margin,
  }) {
    double iconSize = buttonSize * 0.5;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin / 2),
      width: buttonSize,
      height: buttonSize,
      decoration: isActive
          ? BoxDecoration(
              gradient: createOrangeYellowGradient(),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        margin: isActive ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4A),
          borderRadius: BorderRadius.circular(isActive ? 4.5 : 6),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(isActive ? 4.5 : 6),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[400],
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton({
    required IconData icon,
    required bool isTextColor,
    required VoidCallback onPressed,
    required double buttonSize,
    required double margin,
  }) {
    double iconSize = isTextColor ? buttonSize * 0.7 : buttonSize * 0.5;
    
    // 現在の色を取得
    Color? currentColor;
    if (isTextColor) {
      currentColor = _getCurrentTextColor();
    } else {
      currentColor = _getCurrentBackgroundColor();
    }
    
    // アイコンの色を決定
    Color iconColor;
    if (currentColor != null) {
      iconColor = currentColor;
    } else {
      iconColor = Colors.grey[400]!;
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin / 2),
      width: buttonSize,
      height: buttonSize,
      decoration: currentColor != null
          ? BoxDecoration(
              gradient: createOrangeYellowGradient(),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        margin: currentColor != null ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4A),
          borderRadius: BorderRadius.circular(currentColor != null ? 4.5 : 6),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(currentColor != null ? 4.5 : 6),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isFormatActive(Attribute attribute) {
    try {
      final selection = controller.selection;
      if (!selection.isValid) return false;
      
      final style = controller.getSelectionStyle();
      
      if (attribute.key == 'list') {
        final listAttribute = style.attributes['list'];
        if (listAttribute != null) {
          if (attribute == Attribute.ol) {
            return listAttribute == Attribute.ol;
          } else if (attribute == Attribute.ul) {
            return listAttribute == Attribute.ul;
          }
        }
        return false;
      }
      
      final attributeValue = style.attributes[attribute.key];
      
      if (attribute.key == 'bold' || 
          attribute.key == 'italic' || 
          attribute.key == 'underline' || 
          attribute.key == 'strike') {
        return attributeValue != null;
      }
      
      return attributeValue == attribute;
    } catch (e) {
      return false;
    }
  }

  void _toggleFormat(Attribute attribute) {
    final selection = controller.selection;
    
    if (selection.isValid) {
      final style = controller.getSelectionStyle();
      final isCurrentlyActive = style.containsKey(attribute.key) && 
                               style.attributes[attribute.key] != null;
      
      if (attribute.key == 'list') {
        if (isCurrentlyActive) {
          controller.formatSelection(Attribute.clone(attribute, null));
        } else {
          final isOlActive = style.containsKey('list') && 
                            style.attributes['list'] == Attribute.ol;
          final isUlActive = style.containsKey('list') && 
                            style.attributes['list'] == Attribute.ul;
          
          if (isOlActive || isUlActive) {
            controller.formatSelection(Attribute.clone(Attribute.ol, null));
            controller.formatSelection(Attribute.clone(Attribute.ul, null));
          }
          
          controller.formatSelection(attribute);
        }
      } else {
        if (isCurrentlyActive) {
          controller.formatSelection(Attribute.clone(attribute, null));
        } else {
          controller.formatSelection(attribute);
        }
      }
      
      onStateChanged();
    }
  }

  Color? _getCurrentTextColor() {
    try {
      final selection = controller.selection;
      if (!selection.isValid) return null;
      
      final style = controller.getSelectionStyle();
      final colorAttribute = style.attributes['color'];
      
      if (colorAttribute != null && colorAttribute.value != null) {
        final colorString = colorAttribute.value as String;
        if (colorString.startsWith('#') && colorString.length == 7) {
          final hexColor = colorString.substring(1);
          final intColor = int.parse(hexColor, radix: 16);
          return Color(intColor + 0xFF000000);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Color? _getCurrentBackgroundColor() {
    try {
      final selection = controller.selection;
      if (!selection.isValid) return null;
      
      final style = controller.getSelectionStyle();
      final backgroundAttribute = style.attributes['background'];
      
      if (backgroundAttribute != null && backgroundAttribute.value != null) {
        final colorString = backgroundAttribute.value as String;
        if (colorString.startsWith('rgba(')) {
          final rgbaMatch = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*[\d.]+\)').firstMatch(colorString);
          if (rgbaMatch != null) {
            final r = int.parse(rgbaMatch.group(1)!);
            final g = int.parse(rgbaMatch.group(2)!);
            final b = int.parse(rgbaMatch.group(3)!);
            return Color.fromARGB(255, r, g, b);
          }
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
} 