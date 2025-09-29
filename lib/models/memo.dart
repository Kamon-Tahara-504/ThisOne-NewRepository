import 'dart:convert';

/// メモの種類を表すenum
enum MemoMode {
  memo('memo', 'メモ'),
  calculator('calculator', '計算機'),
  rich('rich', 'リッチテキスト');

  const MemoMode(this.value, this.displayName);

  final String value;
  final String displayName;

  /// 文字列からMemoModeを取得
  static MemoMode fromString(String value) {
    switch (value) {
      case 'memo':
        return MemoMode.memo;
      case 'calculator':
        return MemoMode.calculator;
      case 'rich':
        return MemoMode.rich;
      default:
        return MemoMode.memo; // デフォルトはメモ
    }
  }
}

/// 型安全なメモモデルクラス
class Memo {
  final String id;
  final String userId;
  final String title;
  final String content;
  final MemoMode mode;
  final String? richContent; // JSON文字列として保存
  final List<String> tags;
  final bool isPinned;
  final String colorTag;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Memo({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.mode,
    this.richContent,
    required this.tags,
    required this.isPinned,
    required this.colorTag,
    required this.createdAt,
    required this.updatedAt,
  });

  /// SupabaseのMapデータからMemoオブジェクトを作成
  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      mode: MemoMode.fromString(map['mode'] as String? ?? 'memo'),
      richContent: map['rich_content'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      isPinned: map['is_pinned'] as bool? ?? false,
      colorTag: map['color_tag'] as String? ?? '#FFD700',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Supabaseに保存するためのMapデータに変換
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'mode': mode.value,
      'rich_content': richContent,
      'tags': tags,
      'is_pinned': isPinned,
      'color_tag': colorTag,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Supabaseに挿入するためのMapデータに変換（IDとタイムスタンプを除外）
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'title': title,
      'content': content,
      'mode': mode.value,
      'rich_content': richContent,
      'tags': tags,
      'is_pinned': isPinned,
      'color_tag': colorTag,
    };
  }

  /// Supabaseで更新するためのMapデータに変換
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'content': content,
      'mode': mode.value,
      'rich_content': richContent,
      'tags': tags,
      'is_pinned': isPinned,
      'color_tag': colorTag,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// リッチコンテンツをMap形式で取得
  Map<String, dynamic>? get richContentAsMap {
    if (richContent == null || richContent!.isEmpty) return null;

    try {
      return jsonDecode(richContent!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// リッチコンテンツを設定
  Memo copyWithRichContent(Map<String, dynamic>? richContentMap) {
    return copyWith(
      richContent: richContentMap != null ? jsonEncode(richContentMap) : null,
    );
  }

  /// メモのコピーを作成（指定されたフィールドを更新）
  Memo copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    MemoMode? mode,
    String? richContent,
    List<String>? tags,
    bool? isPinned,
    String? colorTag,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Memo(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      mode: mode ?? this.mode,
      richContent: richContent ?? this.richContent,
      tags: tags ?? this.tags,
      isPinned: isPinned ?? this.isPinned,
      colorTag: colorTag ?? this.colorTag,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// メモが空かどうかを判定
  bool get isEmpty => title.isEmpty && content.isEmpty;

  /// メモが計算機モードかどうかを判定
  bool get isCalculatorMode =>
      mode == MemoMode.calculator || mode == MemoMode.rich;

  /// メモがリッチテキストかどうかを判定
  bool get hasRichContent => richContent != null && richContent!.isNotEmpty;

  /// メモのプレビューテキストを取得（表示用）
  String get previewText {
    if (hasRichContent) {
      // リッチコンテンツがある場合はプレーンテキストに変換
      final richMap = richContentAsMap;
      if (richMap != null && richMap['ops'] != null) {
        final ops = richMap['ops'] as List<dynamic>;
        final plainText = ops
            .where((op) => op['insert'] != null)
            .map((op) => op['insert'].toString())
            .join('');
        return plainText.isNotEmpty ? plainText : content;
      }
    }
    return content;
  }

  @override
  String toString() {
    return 'Memo(id: $id, title: $title, mode: ${mode.displayName}, isPinned: $isPinned, colorTag: $colorTag)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Memo && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// メモの並び順を表すenum
enum MemoSortOrder {
  createdAt('created_at', '作成日時'),
  updatedAt('updated_at', '更新日時'),
  title('title', 'タイトル'),
  pinnedFirst('pinned_first', 'ピン留め優先');

  const MemoSortOrder(this.field, this.displayName);

  final String field;
  final String displayName;
}

/// メモのフィルター条件
class MemoFilter {
  final MemoMode? mode;
  final String? colorTag;
  final bool? isPinned;
  final String? searchQuery;
  final MemoSortOrder sortOrder;

  const MemoFilter({
    this.mode,
    this.colorTag,
    this.isPinned,
    this.searchQuery,
    this.sortOrder = MemoSortOrder.updatedAt,
  });

  /// デフォルトフィルター（フィルターなし）
  static const MemoFilter none = MemoFilter();

  /// フィルターが適用されているかどうか
  bool get hasFilter =>
      mode != null ||
      colorTag != null ||
      isPinned != null ||
      (searchQuery != null && searchQuery!.isNotEmpty);

  /// メモがフィルター条件に合致するかどうか
  bool matches(Memo memo) {
    if (mode != null && memo.mode != mode) return false;
    if (colorTag != null && memo.colorTag != colorTag) return false;
    if (isPinned != null && memo.isPinned != isPinned) return false;

    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!memo.title.toLowerCase().contains(query) &&
          !memo.content.toLowerCase().contains(query)) {
        return false;
      }
    }

    return true;
  }
}
