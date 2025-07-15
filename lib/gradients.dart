import 'package:flutter/material.dart';

// ==============================================
// 色ラベル用グラデーション関数群
// ==============================================

/// 色名から対応するグラデーションを取得する関数
/// 
/// 使用例:
/// ```dart
/// // 線形グラデーション
/// Container(
///   decoration: BoxDecoration(
///     gradient: createColorGradient('赤'),
///   ),
/// );
/// 
/// // 水平グラデーション
/// Container(
///   decoration: BoxDecoration(
///     gradient: createHorizontalColorGradient('紫'),
///   ),
/// );
/// 
/// // 円形グラデーション
/// Container(
///   decoration: BoxDecoration(
///     gradient: createRadialColorGradient('青'),
///   ),
/// );
/// ```
/// 
/// サポートされている色名:
/// - 日本語: グレー、濃い緑、黄、オレンジ、茶、シアン、青、紫、ピンク、赤
/// - 英語: grey, darkgreen, yellow, orange, brown, cyan, blue, purple, pink, red

// グラデーションを作成する関数
LinearGradient createColorGradient(
  String colorName, {
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  switch (colorName.toLowerCase()) {
    case 'グレー':
    case 'grey':
      return _createGreyGradient(begin: begin, end: end);
    case '濃い緑':
    case 'darkgreen':
      return _createDarkGreenGradient(begin: begin, end: end);
    case '黄':
    case 'yellow':
      return _createYellowGradient(begin: begin, end: end);
    case 'オレンジ':
    case 'orange':
      return createOrangeYellowGradient(begin: begin, end: end);
    case '茶':
    case 'brown':
      return _createBrownGradient(begin: begin, end: end);
    case 'シアン':
    case 'cyan':
      return _createCyanGradient(begin: begin, end: end);
    case '青':
    case 'blue':
      return _createBlueGradient(begin: begin, end: end);
    case '紫':
    case 'purple':
      return _createPurpleGradient(begin: begin, end: end);
    case 'ピンク':
    case 'pink':
      return _createPinkGradient(begin: begin, end: end);
    case '赤':
    case 'red':
      return _createRedGradient(begin: begin, end: end);
    default:
      return createOrangeYellowGradient(begin: begin, end: end);
  }
}

/// 水平グラデーション用の便利関数
LinearGradient createHorizontalColorGradient(String colorName) {
  return createColorGradient(
    colorName,
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

/// 垂直グラデーション用の便利関数
LinearGradient createVerticalColorGradient(String colorName) {
  return createColorGradient(
    colorName,
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

/// 円形グラデーション用の関数
RadialGradient createRadialColorGradient(
  String colorName, {
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  switch (colorName.toLowerCase()) {
    case 'グレー':
    case 'grey':
      return _createGreyRadialGradient(center: center, radius: radius);
    case '濃い緑':
    case 'darkgreen':
      return _createDarkGreenRadialGradient(center: center, radius: radius);
    case '黄':
    case 'yellow':
      return _createYellowRadialGradient(center: center, radius: radius);
    case 'オレンジ':
    case 'orange':
      return createRadialOrangeYellowGradient(center: center, radius: radius);
    case '茶':
    case 'brown':
      return _createBrownRadialGradient(center: center, radius: radius);
    case 'シアン':
    case 'cyan':
      return _createCyanRadialGradient(center: center, radius: radius);
    case '青':
    case 'blue':
      return _createBlueRadialGradient(center: center, radius: radius);
    case '紫':
    case 'purple':
      return _createPurpleRadialGradient(center: center, radius: radius);
    case 'ピンク':
    case 'pink':
      return _createPinkRadialGradient(center: center, radius: radius);
    case '赤':
    case 'red':
      return _createRedRadialGradient(center: center, radius: radius);
    default:
      return createRadialOrangeYellowGradient(center: center, radius: radius);
  }
}

// ==============================================
// 個別のグラデーション関数群
// ==============================================

/// グレーグラデーション
LinearGradient _createGreyGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFFE0E0E0), // 明るいグレー
      Color(0xFFBDBDBD), // 中間グレー
      Color(0xFF9E9E9E), // ベースグレー
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// 濃い緑グラデーション
LinearGradient _createDarkGreenGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFF4CAF50), // 明るい緑
      Color(0xFF388E3C), // 中間緑
      Color(0xFF2E7D32), // 濃い緑
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// 黄色グラデーション
LinearGradient _createYellowGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFFFFF176), // 明るい黄色
      Color(0xFFFFEB3B), // ベース黄色
      Color(0xFFFBC02D), // 濃い黄色
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// 茶色グラデーション
LinearGradient _createBrownGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFFA1887F), // 明るい茶色
      Color(0xFF8D6E63), // 中間茶色
      Color(0xFF795548), // 濃い茶色
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// シアングラデーション
LinearGradient _createCyanGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFF4DD0E1), // 明るいシアン
      Color(0xFF26C6DA), // 中間シアン
      Color(0xFF00BCD4), // ベースシアン
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// 青グラデーション
LinearGradient _createBlueGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFF7986CB), // 明るい青
      Color(0xFF5C6BC0), // 中間青
      Color(0xFF3F51B5), // 濃い青（インディゴ）
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// 紫グラデーション
LinearGradient _createPurpleGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFFBA68C8), // 明るい紫
      Color(0xFFAB47BC), // 中間紫
      Color(0xFF9C27B0), // 濃い紫
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// ピンクグラデーション
LinearGradient _createPinkGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFFF06292), // 明るいピンク
      Color(0xFFEC407A), // 中間ピンク
      Color(0xFFE91E63), // 濃いピンク
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

/// 赤グラデーション
LinearGradient _createRedGradient({
  AlignmentGeometry begin = Alignment.topLeft,
  AlignmentGeometry end = Alignment.bottomRight,
}) {
  return LinearGradient(
    begin: begin,
    end: end,
    colors: const [
      Color(0xFFEF5350), // 明るい赤
      Color(0xFFF44336), // ベース赤
      Color(0xFFD32F2F), // 濃い赤
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

// ==============================================
// 円形グラデーション関数群
// ==============================================

RadialGradient _createGreyRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFFE0E0E0),
      Color(0xFFBDBDBD),
      Color(0xFF9E9E9E),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createDarkGreenRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFF4CAF50),
      Color(0xFF388E3C),
      Color(0xFF2E7D32),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createYellowRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFFFFF176),
      Color(0xFFFFEB3B),
      Color(0xFFFBC02D),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createBrownRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFFA1887F),
      Color(0xFF8D6E63),
      Color(0xFF795548),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createCyanRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFF4DD0E1),
      Color(0xFF26C6DA),
      Color(0xFF00BCD4),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createBlueRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFF7986CB),
      Color(0xFF5C6BC0),
      Color(0xFF3F51B5),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createPurpleRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFFBA68C8),
      Color(0xFFAB47BC),
      Color(0xFF9C27B0),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createPinkRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFFF06292),
      Color(0xFFEC407A),
      Color(0xFFE91E63),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

RadialGradient _createRedRadialGradient({
  AlignmentGeometry center = Alignment.center,
  double radius = 0.5,
}) {
  return RadialGradient(
    center: center,
    radius: radius,
    colors: const [
      Color(0xFFEF5350),
      Color(0xFFF44336),
      Color(0xFFD32F2F),
    ],
    stops: const [0.0, 0.5, 1.0],
  );
}

// ==============================================
// 既存のオレンジ-黄色グラデーション関数
// ==============================================

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