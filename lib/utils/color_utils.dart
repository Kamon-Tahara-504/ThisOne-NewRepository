import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// QuillControllerの色管理を行うユーティリティクラス
class ColorUtils {
  
  /// 現在のカーソル位置の文字色を取得
  static Color? getCurrentTextColor(QuillController controller) {
    try {
      final selection = controller.selection;
      if (!selection.isValid) return null;
      
      final style = controller.getSelectionStyle();
      final colorAttribute = style.attributes['color'];
      
      if (colorAttribute != null && colorAttribute.value != null) {
        final colorString = colorAttribute.value as String;
        // #で始まる16進数カラーコードをパース
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

  /// 現在のカーソル位置の背景色を取得
  static Color? getCurrentBackgroundColor(QuillController controller) {
    try {
      final selection = controller.selection;
      if (!selection.isValid) return null;
      
      final style = controller.getSelectionStyle();
      final backgroundAttribute = style.attributes['background'];
      
      if (backgroundAttribute != null && backgroundAttribute.value != null) {
        final colorString = backgroundAttribute.value as String;
        // rgba形式の背景色をパース
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

  /// 文字色を設定
  static void setTextColor(QuillController controller, Color color) {
    final selection = controller.selection;
    if (selection.isValid) {
      final colorHex = '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}';
      controller.formatSelection(ColorAttribute(colorHex));
    }
  }

  /// 背景色を設定
  static void setBackgroundColor(QuillController controller, Color color) {
    final selection = controller.selection;
    if (selection.isValid) {
      final r = (color.r * 255).round();
      final g = (color.g * 255).round();
      final b = (color.b * 255).round();
      final colorString = 'rgba($r, $g, $b, 0.3)';
      controller.formatSelection(BackgroundAttribute(colorString));
    }
  }

  /// 文字色をリセット
  static void removeTextColor(QuillController controller) {
    final selection = controller.selection;
    if (selection.isValid) {
      controller.formatSelection(const ColorAttribute(null));
    }
  }

  /// 背景色をリセット
  static void removeBackgroundColor(QuillController controller) {
    final selection = controller.selection;
    if (selection.isValid) {
      controller.formatSelection(const BackgroundAttribute(null));
    }
  }

  /// 色を設定（文字色または背景色）
  static void setColor(QuillController controller, Color color, bool isBackground) {
    if (isBackground) {
      setBackgroundColor(controller, color);
    } else {
      setTextColor(controller, color);
    }
  }

  /// 色をリセット（文字色または背景色）
  static void removeColor(QuillController controller, bool isBackground) {
    if (isBackground) {
      removeBackgroundColor(controller);
    } else {
      removeTextColor(controller);
    }
  }

  /// Color値をCSS用の16進数文字列に変換
  static String colorToHex(Color color) {
    return '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}';
  }

  /// Color値をCSS用のrgba文字列に変換
  static String colorToRgba(Color color, {double alpha = 0.3}) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();
    return 'rgba($r, $g, $b, $alpha)';
  }

  /// 16進数文字列をColor値に変換
  static Color? hexToColor(String hex) {
    try {
      if (hex.startsWith('#') && hex.length == 7) {
        final hexColor = hex.substring(1);
        final intColor = int.parse(hexColor, radix: 16);
        return Color(intColor + 0xFF000000);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// rgba文字列をColor値に変換
  static Color? rgbaToColor(String rgba) {
    try {
      if (rgba.startsWith('rgba(')) {
        final rgbaMatch = RegExp(r'rgba\((\d+),\s*(\d+),\s*(\d+),\s*[\d.]+\)').firstMatch(rgba);
        if (rgbaMatch != null) {
          final r = int.parse(rgbaMatch.group(1)!);
          final g = int.parse(rgbaMatch.group(2)!);
          final b = int.parse(rgbaMatch.group(3)!);
          return Color.fromARGB(255, r, g, b);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
} 