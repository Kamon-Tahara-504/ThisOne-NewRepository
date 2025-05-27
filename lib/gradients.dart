import 'package:flutter/material.dart';

// グラデーション関数 - オレンジから黄色へ（オレンジの割合を増加）
LinearGradient createOrangeYellowGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFFE85A3B), // 赤みの強いオレンジ（画像の色に近い）
      Color(0xFFFF9B50), // オレンジと黄色の中間色でバランス調整
      Color(0xFFFFD700), // 黄色（Gold）
    ],
    stops: const [0.0, 0.6, 1.0], // より自然な配分に調整
  );
}

// 水平グラデーション用の便利関数
LinearGradient createHorizontalOrangeYellowGradient() {
  return createOrangeYellowGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// 垂直グラデーション用の便利関数
LinearGradient createVerticalOrangeYellowGradient() {
  return createOrangeYellowGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

// 円形グラデーション用の関数
RadialGradient createRadialOrangeYellowGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFFE85A3B), // 赤みの強いオレンジ（画像の色に近い）
      Color(0xFFFF9B50), // オレンジと黄色の中間色でバランス調整
      Color(0xFFFFD700), // 黄色（Gold）
    ],
    stops: const [0.0, 0.6, 1.0],
  );
} 