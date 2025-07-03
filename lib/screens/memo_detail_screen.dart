import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import '../gradients.dart';
import '../services/supabase_service.dart';

class MemoDetailScreen extends StatefulWidget {
  final String memoId;
  final String title;
  final String content;
  final String mode;
  final String? richContent;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
    required this.title,
    required this.content,
    required this.mode,
    this.richContent,
  });

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  final SupabaseService _supabaseService = SupabaseService();
  final FocusNode _focusNode = FocusNode();
  
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    
    // QuillControllerを初期化
    Document document;
    if (widget.richContent != null && widget.richContent!.isNotEmpty) {
      try {
        // リッチコンテンツが存在する場合はそれを使用
        final deltaJson = jsonDecode(widget.richContent!);
        document = Document.fromJson(deltaJson);
      } catch (e) {
        // リッチコンテンツの解析に失敗した場合はプレーンテキストを使用
        document = Document()..insert(0, widget.content);
      }
    } else {
      // リッチコンテンツがない場合はプレーンテキストを使用
      document = Document()..insert(0, widget.content);
    }
    
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    
    // テキスト変更を監視
    _titleController.addListener(_onTextChanged);
    _quillController.addListener(_onTextChanged);
    
    // 選択状態の変更を監視してUIを更新
    _quillController.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    // 選択位置が変わった時にツールバーの状態を更新
    setState(() {});
  }



  @override
  void dispose() {
    _closeColorPicker();
    _titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
    
    // 1秒後に自動保存（デバウンス）
    Future.delayed(const Duration(seconds: 1), () {
      if (_hasChanges && !_isSaving) {
        _saveChanges();
      }
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      // プレーンテキスト版とリッチテキスト版の両方を保存
      final plainText = _quillController.document.toPlainText();
      final richContentMap = {'ops': _quillController.document.toDelta().toJson()};
      
      await _supabaseService.updateMemo(
        memoId: widget.memoId,
        title: _titleController.text.trim().isEmpty 
            ? '無題' 
            : _titleController.text.trim(),
        content: plainText,
        richContent: richContentMap,
      );
      
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  Future<void> _handleBackPressed() async {
    if (_hasChanges) {
      await _saveChanges();
    }
    if (mounted) {
      Navigator.pop(context, true); // 変更があったことを通知
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop && _hasChanges) {
          await _saveChanges();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2B2B2B),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Container(
            color: const Color(0xFF2B2B2B),
            child: Column(
              children: [
                // ステータスバー部分
                Container(
                  height: MediaQuery.of(context).padding.top,
                  width: double.infinity,
                  color: const Color(0xFF2B2B2B),
                ),
                // AppBar部分
                Expanded(
                  child: Container(
                    color: const Color(0xFF2B2B2B),
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            child: Row(
                              children: [
                                // 戻るボタン
                                IconButton(
                                  onPressed: _handleBackPressed,
                                  icon: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                
                                // 保存状態表示
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (_isSaving) ...[
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: const Color(0xFFE85A3B),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '保存中...',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ] else if (_hasChanges) ...[
                                        Text(
                                          '未保存の変更があります',
                                          style: TextStyle(
                                            color: Colors.orange[400],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          '保存済み',
                                          style: TextStyle(
                                            color: Colors.grey[500],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                
                                // メニューボタン（今後の拡張用）
                                IconButton(
                                  onPressed: () {
                                    // TODO: メニュー機能
                                  },
                                  icon: Icon(
                                    Icons.more_vert,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // グラデーションガイドライン
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: createHorizontalOrangeYellowGradient(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // タイトル入力とモード・日付表示
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // タイトル入力（可変幅、制限あり）
                    Flexible(
                      child: IntrinsicWidth(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width - 200, // モード・日付分を確保
                          ),
                          child: TextField(
                            controller: _titleController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'タイトル',
                              hintStyle: TextStyle(
                                color: Colors.grey,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              isDense: true,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // モード・日付表示（固定幅確保）
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // モード表示
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: createOrangeYellowGradient(),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.mode == 'memo' ? 'メモモード' : widget.mode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // 日付表示
                        Text(
                          '${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // カスタムツールバー
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2B2B2B),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildToolbarButton(
                          icon: Icons.format_bold,
                          isActive: _isFormatActive(Attribute.bold),
                          onPressed: () => _toggleFormat(Attribute.bold),
                        ),
                        const SizedBox(width: 8),
                        _buildToolbarButton(
                          icon: Icons.format_italic,
                          isActive: _isFormatActive(Attribute.italic),
                          onPressed: () => _toggleFormat(Attribute.italic),
                        ),
                        const SizedBox(width: 8),
                        _buildToolbarButton(
                          icon: Icons.format_underlined,
                          isActive: _isFormatActive(Attribute.underline),
                          onPressed: () => _toggleFormat(Attribute.underline),
                        ),
                        const SizedBox(width: 8),
                        _buildToolbarButton(
                          icon: Icons.format_strikethrough,
                          isActive: _isFormatActive(Attribute.strikeThrough),
                          onPressed: () => _toggleFormat(Attribute.strikeThrough),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: Colors.grey[600],
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        _buildToolbarButton(
                          icon: Icons.format_list_numbered,
                          isActive: _isFormatActive(Attribute.ol),
                          onPressed: () => _toggleFormat(Attribute.ol),
                        ),
                        const SizedBox(width: 8),
                        _buildToolbarButton(
                          icon: Icons.format_list_bulleted,
                          isActive: _isFormatActive(Attribute.ul),
                          onPressed: () => _toggleFormat(Attribute.ul),
                        ),
                        Container(
                          width: 1,
                          height: 44,
                          color: Colors.grey[600],
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        _buildToolbarButton(
                          icon: Icons.redo,
                          isActive: false,
                          onPressed: () => _quillController.redo(),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // カスタムカラーボタン
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[700]!),
                  ),
                  child: Row(
                    children: [
                      // 文字色ボタン
                      _buildColorButton(
                        icon: Icons.text_format,
                        label: '文字色',
                        isBackgroundColor: false,
                      ),
                      const SizedBox(width: 12),
                      // 背景色ボタン
                      _buildColorButton(
                        icon: Icons.format_color_fill,
                        label: '背景色',
                        isBackgroundColor: true,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // 内容入力（Quillエディタ）
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2B2B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[700]!),
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        // 背景色のスタイルをカスタマイズ
                        textTheme: Theme.of(context).textTheme.copyWith(
                          bodyMedium: const TextStyle(color: Colors.white),
                        ),
                      ),
                      child: QuillEditor.basic(
                        controller: _quillController,
                        focusNode: _focusNode,
                        configurations: QuillEditorConfigurations(
                          padding: const EdgeInsets.all(16),
                          placeholder: 'ここに内容を入力してください...',
                          autoFocus: false,
                          expands: true,
                          scrollable: true,
                          customStyles: DefaultStyles(
                            // 背景色に角丸を適用するカスタムスタイル
                            paragraph: DefaultTextBlockStyle(
                              const TextStyle(color: Colors.white),
                              HorizontalSpacing.zero,
                              VerticalSpacing.zero,
                              VerticalSpacing.zero,
                              BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    }

  Widget _buildColorButton({
    required IconData icon,
    required String label,
    required bool isBackgroundColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showColorPicker(isBackgroundColor),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  OverlayEntry? _colorPickerOverlay;

  void _showColorPicker(bool isBackgroundColor) {
    // 既存のオーバーレイがあれば閉じる
    _closeColorPicker();

    final overlay = Overlay.of(context);

    _colorPickerOverlay = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _closeColorPicker(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // カラーパレット
            Positioned(
              right: 16,
              top: MediaQuery.of(context).padding.top + 200, // ヘッダーの下に配置
              child: GestureDetector(
                onTap: () {}, // パレット内のタップは伝播を止める
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isBackgroundColor ? '背景色を選択' : '文字色を選択',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                                                 Wrap(
                           runSpacing: 8,
                           spacing: 8,
                           children: [
                             const Color(0xFFE74C3C), // 落ち着いた赤
                             const Color(0xFFE91E63), // 落ち着いたピンク
                             const Color(0xFF9B59B6), // 落ち着いた紫
                             const Color(0xFF3498DB), // 落ち着いた青
                             const Color(0xFF27AE60), // 落ち着いた緑
                             const Color(0xFFF1C40F), // 落ち着いた黄色
                             const Color(0xFFE67E22), // 落ち着いたオレンジ
                             const Color(0xFF8D6E63), // 落ち着いた茶色
                             const Color(0xFF95A5A6), // 落ち着いた灰色
                             const Color(0xFFECF0F1), // 落ち着いた白
                           ].map((color) {
                            return GestureDetector(
                              onTap: () {
                                _closeColorPicker();
                                _setTypingColor(color, isBackgroundColor);
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey[600]!,
                                    width: 1,
                                  ),
                                ),
                                child: color == const Color(0xFFECF0F1)
                                    ? const Icon(
                                        Icons.circle,
                                        color: Colors.grey,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            _closeColorPicker();
                            _removeTypingColor(isBackgroundColor);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2B2B2B),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey[600]!),
                            ),
                            child: const Text(
                              '色をリセット',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_colorPickerOverlay!);
  }

  void _closeColorPicker() {
    if (_colorPickerOverlay != null) {
      _colorPickerOverlay!.remove();
      _colorPickerOverlay = null;
    }
  }



  Widget _buildToolbarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isActive ? createOrangeYellowGradient() : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey[600]!,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey[300],
          size: 22,
        ),
      ),
    );
  }

  bool _isFormatActive(Attribute attribute) {
    try {
      final selection = _quillController.selection;
      if (!selection.isValid) return false;
      
      final style = _quillController.getSelectionStyle();
      
      // 選択がない場合（カーソル位置）は、現在のフォーマット状態を取得
      if (selection.isCollapsed) {
        final typingStyle = _quillController.getSelectionStyle();
        return typingStyle.containsKey(attribute.key) && 
               typingStyle.attributes[attribute.key] != null;
      } else {
        // 選択がある場合は、選択範囲のフォーマット状態を取得
        return style.containsKey(attribute.key) && 
               style.attributes[attribute.key] != null;
      }
    } catch (e) {
      return false;
    }
  }

  void _toggleFormat(Attribute attribute) {
    final selection = _quillController.selection;
    
    if (selection.isValid) {
      // 現在のフォーマット状態を確認
      final style = _quillController.getSelectionStyle();
      final isCurrentlyActive = style.containsKey(attribute.key) && 
                               style.attributes[attribute.key] != null;
      
      if (isCurrentlyActive) {
        // フォーマットが適用されている場合は削除
        _quillController.formatSelection(Attribute.clone(attribute, null));
      } else {
        // フォーマットが適用されていない場合は追加
        _quillController.formatSelection(attribute);
      }
      
      setState(() {}); // UIを更新
    }
  }



  void _setTypingColor(Color color, bool isBackgroundColor) {
    // 現在の選択位置でフォーマットを設定
    final selection = _quillController.selection;
    if (selection.isValid) {
      String colorString;
      
      if (isBackgroundColor) {
        // 背景色の場合は透明度50%のRGBA形式で指定
        final r = color.r;
        final g = color.g;
        final b = color.b;
        colorString = 'rgba($r, $g, $b, 0.5)';
        _quillController.formatSelection(BackgroundAttribute(colorString));
      } else {
        // 文字色の場合は通常のHEX形式
        final colorHex = '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
        _quillController.formatSelection(ColorAttribute(colorHex));
      }
    }
    
    setState(() {});
  }

  void _removeTypingColor(bool isBackgroundColor) {
    // 現在の選択位置でフォーマットを削除
    final selection = _quillController.selection;
    if (selection.isValid) {
      if (isBackgroundColor) {
        _quillController.formatSelection(const BackgroundAttribute(null));
      } else {
        _quillController.formatSelection(const ColorAttribute(null));
      }
    }
    
    setState(() {});
  }
} 