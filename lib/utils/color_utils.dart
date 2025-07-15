import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../gradients.dart'; // グラデーション用にインポート追加

/// QuillControllerの色管理を行うユーティリティクラス
class ColorUtils {
  
  // 色分けラベル用の10色パレット（カスタム並び：2行×5列）
  static const List<Map<String, dynamic>> colorLabelPalette = [
         // 1行目: 灰色、茶色、濃い緑、黄、オレンジ
    {'name': 'グレー', 'color': null, 'hex': '#9E9E9E', 'isGradient': true}, // グラデーション
    {'name': '濃い緑', 'color': null, 'hex': '#2E7D32', 'isGradient': true}, // グラデーション
    {'name': '黄', 'color': null, 'hex': '#FFEB3B', 'isGradient': true}, // グラデーション
    {'name': 'オレンジ', 'color': null, 'hex': '#FF9500', 'isGradient': true}, // グラデーション
    {'name': '茶', 'color': null, 'hex': '#795548', 'isGradient': true}, // グラデーション
    // 2行目: シアン、青、紫、ピンク、赤
    {'name': 'シアン', 'color': null, 'hex': '#00BCD4', 'isGradient': true}, // グラデーション
    {'name': '青', 'color': null, 'hex': '#3F51B5', 'isGradient': true}, // グラデーション
    {'name': '紫', 'color': null, 'hex': '#9C27B0', 'isGradient': true}, // グラデーション
    {'name': 'ピンク', 'color': null, 'hex': '#E91E63', 'isGradient': true}, // グラデーション
    {'name': '赤', 'color': null, 'hex': '#F44336', 'isGradient': true}, // グラデーション
  ];

  // Hexコードから色を取得（グラデーション色の場合は代表色を返す）
  static Color getColorFromHex(String hex) {
    // 各色の代表色を定義
    final colorMap = {
      '#9E9E9E': Colors.grey,           // グレー
      '#2E7D32': const Color(0xFF2E7D32), // 濃い緑
      '#FFEB3B': Colors.yellow,         // 黄
      '#FF9500': const Color(0xFFE85A3B), // オレンジ
      '#795548': Colors.brown,          // 茶
      '#00BCD4': Colors.cyan,           // シアン
      '#3F51B5': Colors.indigo,         // 青
      '#9C27B0': Colors.purple,         // 紫
      '#E91E63': Colors.pink,           // ピンク
      '#F44336': Colors.red,            // 赤
    };
    
    return colorMap[hex] ?? Colors.grey;
  }

  // Hexコードがグラデーションかどうかを判定
  static bool isGradientColor(String hex) {
    // 全ての色ラベルでグラデーションを使用可能にする
    return colorLabelPalette.any((color) => color['hex'] == hex);
  }

  // グラデーション取得
  static LinearGradient? getGradientFromHex(String hex) {
    // 色ラベルパレットから色名を取得
    final colorItem = colorLabelPalette.firstWhere(
      (color) => color['hex'] == hex,
      orElse: () => {'name': 'オレンジ'}, // デフォルト
    );
    
    final colorName = colorItem['name'] as String;
    return createColorGradient(colorName);
  }

  // Hexコードから色名を取得
  static String getColorNameFromHex(String hex) {
    final nameMap = {
      for (var item in colorLabelPalette) item['hex'] as String: item['name'] as String
    };
    return nameMap[hex] ?? 'グレー';
  }

  // デフォルトのラベル色（グレー）
  static const String defaultColorHex = '#9E9E9E';
  static const Color defaultColor = Colors.grey;

  // 既存の機能（Quillエディタ用）
  
  /// QuillControllerから現在の文字色を取得
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