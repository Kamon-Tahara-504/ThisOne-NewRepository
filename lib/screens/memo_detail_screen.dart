import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'dart:async';
import '../gradients.dart';
import '../services/supabase_service.dart';

class MemoDetailScreen extends StatefulWidget {
  final String memoId;
  final String title;
  final String content;
  final String mode;
  final String? richContent;
  final DateTime? updatedAt;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
    required this.title,
    required this.content,
    required this.mode,
    this.richContent,
    this.updatedAt,
  });

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late QuillController _quillController;
  final SupabaseService _supabaseService = SupabaseService();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _memoFocusNode = FocusNode();
  
  bool _hasChanges = false;
  bool _isSaving = false;
  bool _showToolbar = false;
  
  Timer? _debounceTimer;
  
  // 初期値を保存
  late String _initialTitle;
  late String _initialContent;
  late String _initialRichContent;
  
  // 最後の更新時刻を管理
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 初期更新時刻を設定
    _lastUpdated = widget.updatedAt;
    
    _titleController = TextEditingController(text: widget.title);
    
    // QuillControllerを初期化
    Document document;
    if (widget.richContent != null && widget.richContent!.isNotEmpty) {
      try {
        final deltaJson = jsonDecode(widget.richContent!);
        List<dynamic> ops;
        if (deltaJson is Map<String, dynamic> && deltaJson.containsKey('ops')) {
          ops = deltaJson['ops'] as List<dynamic>;
        } else if (deltaJson is List<dynamic>) {
          ops = deltaJson;
        } else {
          throw Exception('不正なDelta形式: $deltaJson');
        }
        document = Document.fromJson(ops);
      } catch (e) {
        document = Document()..insert(0, widget.content);
      }
    } else {
      document = Document()..insert(0, widget.content);
    }
    
    _quillController = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    
    // リスナーを追加（初期化後に追加することで、初期化時の不要な呼び出しを防ぐ）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 実際のコントローラーの内容を初期値として設定
      _initialTitle = _titleController.text.trim();
      _initialContent = _quillController.document.toPlainText();
      _initialRichContent = jsonEncode({'ops': _quillController.document.toDelta().toJson()});
      
      // リスナーを追加
      _titleController.addListener(_onTextChanged);
      _quillController.addListener(_onTextChanged);
    });
    
    // フォーカス変更を監視
    _titleFocusNode.addListener(_onFocusChanged);
    _memoFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {
      _showToolbar = _memoFocusNode.hasFocus;
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    setState(() {
      _showToolbar = keyboardHeight > 0 && _memoFocusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    _memoFocusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    // 現在の内容を取得
    final currentTitle = _titleController.text.trim();
    final currentContent = _quillController.document.toPlainText();
    final currentRichContent = jsonEncode({'ops': _quillController.document.toDelta().toJson()});
    
    // 初期値と比較して実際に変更があったかチェック
    final hasActualChanges = currentTitle != _initialTitle || 
                            currentContent != _initialContent ||
                            currentRichContent != _initialRichContent;
    
    if (hasActualChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasActualChanges;
      });
    }
    
    if (_hasChanges) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(seconds: 1), () {
        if (_hasChanges && !_isSaving && mounted) {
          _saveChanges();
        }
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isSaving) return;
    
    setState(() {
      _isSaving = true;
    });
    
    try {
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
      
      // 保存成功時に更新時刻を記録し、初期値を更新
      setState(() {
        _hasChanges = false;
        _isSaving = false;
        _lastUpdated = DateTime.now();
        
        // 初期値を現在の値に更新
        _initialTitle = _titleController.text.trim().isEmpty ? '無題' : _titleController.text.trim();
        _initialContent = plainText;
        _initialRichContent = jsonEncode(richContentMap);
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
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'memo-${widget.memoId}',
      child: Material(
        color: const Color(0xFF2B2B2B),
        child: GestureDetector(
          onTap: () {
            // 入力欄以外をタップしたときにキーボードを隠す
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF2B2B2B),
            appBar: AppBar(
              backgroundColor: const Color(0xFF2B2B2B),
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: _handleBackPressed,
                  ),
                  Transform.translate(
                    offset: const Offset(-6, 0), // 左に6px移動して近づける
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              leadingWidth: 100,
              actions: [
                if (_isSaving) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFE85A3B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            body: Column(
              children: [
                // タイトル編集エリア（コンパクト化）
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // 上下パディングを減らす
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // パディングを元に戻す
                        decoration: BoxDecoration(
                          gradient: createOrangeYellowGradient(),
                          borderRadius: BorderRadius.circular(16), // 角丸をさらに大きく
                        ),
                        child: Text(
                          widget.mode == 'memo' ? 'メモ' : widget.mode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12, // フォントサイズを元に戻す
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8), // 間隔を狭める
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _titleController,
                                    focusNode: _titleFocusNode,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16, // フォントサイズを少し小さく
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'タイトルを入力...',
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 4), // パディングを減らす
                                      isDense: true, // 密度を高める
                                    ),
                                  ),
                                  Text(
                                    _getLastUpdatedText(),
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 11, // フォントサイズを小さく
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // メモ編集エリア（拡大）
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // 上マージンを削除
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // ツールバー
                        if (_showToolbar)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // パディングを減らす
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A4A4A),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: _buildToolbar(),
                          ),
                        
                        // エディタ
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A3A),
                              borderRadius: _showToolbar 
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    )
                                  : BorderRadius.circular(12),
                            ),
                            child: QuillEditor.basic(
                              controller: _quillController,
                              focusNode: _memoFocusNode,
                              configurations: QuillEditorConfigurations(
                                padding: const EdgeInsets.all(16),
                                placeholder: 'メモを入力してください...',
                                autoFocus: false,
                                expands: true,
                                scrollable: true,
                                keyboardAppearance: Brightness.dark,
                                customStyles: DefaultStyles(
                                  paragraph: DefaultTextBlockStyle(
                                    const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16.0,
                                    ),
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
                      ],
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

  // ツールバーボタン一覧
  Widget _buildToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 利用可能な幅からパディングを引く
        double availableWidth = constraints.maxWidth - 16; // 左右のパディング分
        
        // 画面サイズに応じてボタン間の間隔を設定
        double buttonMargin;
        if (availableWidth < 400) {
          buttonMargin = 2; // 小さい画面：2px
        } else if (availableWidth < 800) {
          buttonMargin = 4; // 中画面：4px
        } else {
          buttonMargin = 6; // 大画面（タブレット）：6px
        }
        
        // 8つのボタンとマージンを考慮してボタンサイズを計算
        int buttonCount = 8;
        double totalMargin = (buttonCount - 1) * buttonMargin; // 各ボタン間のマージン
        double buttonSize = (availableWidth - totalMargin) / buttonCount;
        
        // 画面サイズに応じてボタンサイズの制限を動的に設定
        double minButtonSize, maxButtonSize;
        if (availableWidth < 400) {
          // 小画面（スマートフォン）
          minButtonSize = 24.0;
          maxButtonSize = 40.0;
        } else if (availableWidth < 800) {
          // 中画面（大きいスマートフォン）
          minButtonSize = 36.0;
          maxButtonSize = 56.0;
        } else {
          // 大画面（タブレット）
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
          _buildToolbarButton(
            icon: Icons.text_format,
            isActive: false,
            onPressed: () => _showColorPicker(false),
            buttonSize: buttonSize,
            margin: buttonMargin,
          ),
          _buildToolbarButton(
            icon: Icons.format_color_fill,
            isActive: false,
            onPressed: () => _showColorPicker(true),
            buttonSize: buttonSize,
            margin: buttonMargin,
          ),
        ];
        
        // 固定サイズのボタンを等間隔で配置
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: toolbarButtons,
        );
      },
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required double buttonSize,
    required double margin,
  }) {
    // アイコンサイズはボタンサイズの50%に設定
    double iconSize = buttonSize * 0.5;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin / 2),
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        gradient: isActive ? createOrangeYellowGradient() : null,
        color: isActive ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Icon(
              icon,
              color: isActive ? Colors.white : Colors.grey[400],
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }

  bool _isFormatActive(Attribute attribute) {
    try {
      final selection = _quillController.selection;
      if (!selection.isValid) return false;
      
      final style = _quillController.getSelectionStyle();
      
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
      
      return style.containsKey(attribute.key) && 
             style.attributes[attribute.key] != null;
    } catch (e) {
      return false;
    }
  }

  void _toggleFormat(Attribute attribute) {
    final selection = _quillController.selection;
    
    if (selection.isValid) {
      final style = _quillController.getSelectionStyle();
      final isCurrentlyActive = style.containsKey(attribute.key) && 
                               style.attributes[attribute.key] != null;
      
      if (attribute.key == 'list') {
        if (isCurrentlyActive) {
          _quillController.formatSelection(Attribute.clone(attribute, null));
        } else {
          final isOlActive = style.containsKey('list') && 
                            style.attributes['list'] == Attribute.ol;
          final isUlActive = style.containsKey('list') && 
                            style.attributes['list'] == Attribute.ul;
          
          if (isOlActive || isUlActive) {
            _quillController.formatSelection(Attribute.clone(Attribute.ol, null));
            _quillController.formatSelection(Attribute.clone(Attribute.ul, null));
          }
          
          _quillController.formatSelection(attribute);
        }
      } else {
        if (isCurrentlyActive) {
          _quillController.formatSelection(Attribute.clone(attribute, null));
        } else {
          _quillController.formatSelection(attribute);
        }
      }
      
      _onTextChanged();
      setState(() {});
    }
  }

  void _showColorPicker(bool isBackground) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF3A3A3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isBackground ? '背景色を選択' : '文字色を選択',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildColorButton(Colors.red, isBackground),
                  _buildColorButton(Colors.orange, isBackground),
                  _buildColorButton(Colors.yellow, isBackground),
                  _buildColorButton(Colors.green, isBackground),
                  _buildColorButton(Colors.blue, isBackground),
                  _buildColorButton(Colors.purple, isBackground),
                  _buildColorButton(Colors.pink, isBackground),
                  _buildColorButton(Colors.brown, isBackground),
                  _buildColorButton(Colors.grey, isBackground),
                  _buildColorButton(Colors.black, isBackground),
                  _buildColorButton(null, isBackground),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorButton(Color? color, bool isBackground) {
    return GestureDetector(
      onTap: () {
        if (color != null) {
          _setTypingColor(color, isBackground);
        } else {
          _removeTypingColor(isBackground);
        }
        Navigator.pop(context);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color ?? Colors.transparent,
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: color == null
            ? const Icon(Icons.clear, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  void _setTypingColor(Color color, bool isBackground) {
    final selection = _quillController.selection;
    if (selection.isValid) {
      String colorString;
      
      if (isBackground) {
        final r = (color.r * 255).round();
        final g = (color.g * 255).round();
        final b = (color.b * 255).round();
        colorString = 'rgba($r, $g, $b, 0.3)';
        _quillController.formatSelection(BackgroundAttribute(colorString));
      } else {
        final colorHex = '#${(color.r * 255).round().toRadixString(16).padLeft(2, '0')}${(color.g * 255).round().toRadixString(16).padLeft(2, '0')}${(color.b * 255).round().toRadixString(16).padLeft(2, '0')}';
        _quillController.formatSelection(ColorAttribute(colorHex));
      }
      
      _onTextChanged();
    }
    
    setState(() {});
  }

  void _removeTypingColor(bool isBackground) {
    final selection = _quillController.selection;
    if (selection.isValid) {
      if (isBackground) {
        _quillController.formatSelection(const BackgroundAttribute(null));
      } else {
        _quillController.formatSelection(const ColorAttribute(null));
      }
      
      _onTextChanged();
    }
    
    setState(() {});
  }

  String _getLastUpdatedText() {
    if (_lastUpdated == null) {
      return '更新: 未更新';
    }
    
    final year = _lastUpdated!.year;
    final month = _lastUpdated!.month;
    final day = _lastUpdated!.day;
    final hour = _lastUpdated!.hour.toString().padLeft(2, '0');
    final minute = _lastUpdated!.minute.toString().padLeft(2, '0');
    
    return '更新: $year/$month/$day $hour:$minute';
  }
} 