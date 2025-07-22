import 'package:flutter/material.dart';
import '../gradients.dart';
import '../utils/color_utils.dart';

/// グラデーションの使用例を示すデモページ
class GradientShowcasePage extends StatelessWidget {
  const GradientShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('グラデーションショーケース'),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: createHorizontalColorGradient('オレンジ'),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFF2B2B2B),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('線形グラデーション'),
              _buildLinearGradientGrid(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('円形グラデーション'),
              _buildRadialGradientGrid(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('使用例'),
              _buildUsageExamples(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLinearGradientGrid() {
    final colorNames = [
      'グレー', '濃い緑', '黄', 'オレンジ', '茶',
      'シアン', '青', '紫', 'ピンク', '赤'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: colorNames.length,
      itemBuilder: (context, index) {
        final colorName = colorNames[index];
        return _buildGradientCard(colorName, false);
      },
    );
  }

  Widget _buildRadialGradientGrid() {
    final colorNames = [
      'グレー', '濃い緑', '黄', 'オレンジ', '茶',
      'シアン', '青', '紫', 'ピンク', '赤'
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: colorNames.length,
      itemBuilder: (context, index) {
        final colorName = colorNames[index];
        return _buildGradientCard(colorName, true);
      },
    );
  }

  Widget _buildGradientCard(String colorName, bool isRadial) {
    return Container(
      decoration: BoxDecoration(
        gradient: isRadial 
            ? createRadialColorGradient(colorName)
            : createHorizontalColorGradient(colorName),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              colorName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 4,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isRadial ? 'Radial' : 'Linear',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 2,
                    offset: Offset(1, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageExamples() {
    return Column(
      children: [
        // ボタン例
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: createColorGradient('赤'),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'グラデーションボタン',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // カード例
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            gradient: createVerticalColorGradient('紫'),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'グラデーションカード',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'このカードは紫の垂直グラデーションを使用しています。',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Hexコードからの使用例
        Container(
          width: double.infinity,
          height: 80,
          decoration: BoxDecoration(
            gradient: ColorUtils.getGradientFromHex('#00BCD4'), // シアン
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'HexコードからのGradient (#00BCD4)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
} 