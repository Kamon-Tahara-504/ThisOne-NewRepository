

class CalculatorUtils {
  // テキストから数値（+123, -456, 123など）を抽出
  static List<CalculatorEntry> extractCalculations(String text) {
    final List<CalculatorEntry> entries = [];
    
    // 行ごとに処理して、各行の数値を抽出
    final lines = text.split('\n');
    
    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex].trim();
      if (line.isEmpty) continue;
      
      // 数値パターンを検索（+123, -456, 123 形式）
      final RegExp numberPattern = RegExp(r'([+-]?\d+(?:\.\d+)?)');
      final Iterable<RegExpMatch> matches = numberPattern.allMatches(line);
      
      for (final match in matches) {
        final numberStr = match.group(1);
        if (numberStr != null) {
          final double value = double.tryParse(numberStr) ?? 0.0;
          if (value != 0) {
            // 数値の前の文字列を取得（項目名として使用）
            String description = '';
            if (match.start > 0) {
              description = line.substring(0, match.start).trim();
            }
            
            // 数値の後の文字列も確認
            if (description.isEmpty && match.end < line.length) {
              description = line.substring(match.end).trim();
            }
            
            // それでも項目名がない場合はデフォルト名を使用
            if (description.isEmpty) {
              if (value > 0) {
                description = '収入';
              } else if (value < 0) {
                description = '支出';
              } else {
                description = '項目';
              }
            }
            
            entries.add(CalculatorEntry(
              description: description,
              amount: value,
              position: match.start,
              length: match.end - match.start,
            ));
          }
        }
      }
    }
    
    return entries;
  }
  
  // 合計金額を計算
  static double calculateTotal(List<CalculatorEntry> entries) {
    return entries.fold(0.0, (sum, entry) => sum + entry.amount);
  }
  
  // 収入の合計を計算
  static double calculateIncome(List<CalculatorEntry> entries) {
    return entries
        .where((entry) => entry.amount > 0)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }
  
  // 支出の合計を計算
  static double calculateExpense(List<CalculatorEntry> entries) {
    return entries
        .where((entry) => entry.amount < 0)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }
  
  // 金額をフォーマット
  static String formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      return '¥${amount.round().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    } else {
      return '¥${amount.toStringAsFixed(1).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
    }
  }
  
  // 合計のサマリーテキストを生成
  static String generateSummary(List<CalculatorEntry> entries) {
    final total = calculateTotal(entries);
    final income = calculateIncome(entries);
    final expense = calculateExpense(entries);
    
    final buffer = StringBuffer();
    
    if (income > 0) {
      buffer.write('収入: ${formatAmount(income)}');
    }
    
    if (expense < 0) {
      if (buffer.isNotEmpty) buffer.write(' | ');
      buffer.write('支出: ${formatAmount(expense)}');
    }
    
    if (buffer.isNotEmpty) buffer.write(' | ');
    buffer.write('残高: ${formatAmount(total)}');
    
    return buffer.toString();
  }
}

class CalculatorEntry {
  final String description;
  final double amount;
  final int position;
  final int length;
  
  const CalculatorEntry({
    required this.description,
    required this.amount,
    required this.position,
    required this.length,
  });
  
  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;
  
  @override
  String toString() {
    return 'CalculatorEntry(description: $description, amount: $amount, position: $position)';
  }
} 