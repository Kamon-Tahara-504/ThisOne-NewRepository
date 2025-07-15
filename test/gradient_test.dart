import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:thisone/gradients.dart';
import 'package:thisone/utils/color_utils.dart';

void main() {
  group('Color Gradients Test', () {
    test('全ての色ラベルでグラデーションが作成できる', () {
      final colorNames = [
        'グレー', '濃い緑', '黄', 'オレンジ', '茶',
        'シアン', '青', '紫', 'ピンク', '赤'
      ];
      
      for (final colorName in colorNames) {
        final gradient = createColorGradient(colorName);
        expect(gradient, isA<LinearGradient>());
        expect(gradient.colors.length, 3);
      }
    });

    test('水平グラデーションが正しく作成される', () {
      final gradient = createHorizontalColorGradient('赤');
      expect(gradient.begin, Alignment.centerLeft);
      expect(gradient.end, Alignment.centerRight);
    });

    test('垂直グラデーションが正しく作成される', () {
      final gradient = createVerticalColorGradient('青');
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
    });

    test('円形グラデーションが正しく作成される', () {
      final gradient = createRadialColorGradient('紫');
      expect(gradient, isA<RadialGradient>());
      expect(gradient.colors.length, 3);
    });

    test('ColorUtilsからグラデーションが取得できる', () {
      // 全ての色ラベルHexコードでテスト
      final hexCodes = [
        '#9E9E9E', '#2E7D32', '#FFEB3B', '#FF9500', '#795548',
        '#00BCD4', '#3F51B5', '#9C27B0', '#E91E63', '#F44336'
      ];
      
      for (final hex in hexCodes) {
        expect(ColorUtils.isGradientColor(hex), true);
        final gradient = ColorUtils.getGradientFromHex(hex);
        expect(gradient, isA<LinearGradient>());
      }
    });

    test('英語の色名でもグラデーションが作成される', () {
      final englishNames = [
        'grey', 'darkgreen', 'yellow', 'orange', 'brown',
        'cyan', 'blue', 'purple', 'pink', 'red'
      ];
      
      for (final colorName in englishNames) {
        final gradient = createColorGradient(colorName);
        expect(gradient, isA<LinearGradient>());
        expect(gradient.colors.length, 3);
      }
    });

    test('未知の色名はデフォルトグラデーションを返す', () {
      final gradient = createColorGradient('unknown');
      expect(gradient, isA<LinearGradient>());
      // デフォルトはオレンジグラデーション
      expect(gradient.colors.length, 3);
    });
  });

  group('Gradient Usage Examples', () {
    testWidgets('Container with gradient decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: createColorGradient('赤'),
              ),
              child: const Text('Red Gradient'),
            ),
          ),
        ),
      );
      
      expect(find.text('Red Gradient'), findsOneWidget);
    });

    testWidgets('Multiple gradient containers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: createHorizontalColorGradient('青'),
                  ),
                  child: const Text('Blue Horizontal'),
                ),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: createVerticalColorGradient('濃い緑'),
                  ),
                  child: const Text('Green Vertical'),
                ),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: createRadialColorGradient('紫'),
                  ),
                  child: const Text('Purple Radial'),
                ),
              ],
            ),
          ),
        ),
      );
      
      expect(find.text('Blue Horizontal'), findsOneWidget);
      expect(find.text('Green Vertical'), findsOneWidget);
      expect(find.text('Purple Radial'), findsOneWidget);
    });
  });
} 