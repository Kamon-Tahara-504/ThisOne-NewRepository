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
  bool _isBackgroundColorMode = false;
  
  Timer? _debounceTimer;
  Timer? _selectionTimer;
  OverlayEntry? _colorPanelOverlay;
  
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
      
      // 選択範囲変更を監視（定期的にチェック）
      _startSelectionMonitor();
    });
    
    // フォーカス変更を監視
    _titleFocusNode.addListener(_onFocusChanged);
    _memoFocusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {
      final newShowToolbar = _memoFocusNode.hasFocus;
      // ツールバーが隠れる場合はカラーパネルも閉じる
      if (_showToolbar && !newShowToolbar && _colorPanelOverlay != null) {
        _hideColorPanel();
      }
      _showToolbar = newShowToolbar;
    });
    
    // フォーカス変更時にツールバーの状態を更新
    if (_showToolbar && mounted) {
      // 短い遅延を追加して、フォーカスが完全に設定されるまで待つ
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  void _startSelectionMonitor() {
    // 前の選択範囲を保存
    TextSelection? previousSelection = _quillController.selection;
    
    // 定期的に選択範囲をチェック
    _selectionTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final currentSelection = _quillController.selection;
      
      // 選択範囲が変更された場合
      if (currentSelection != previousSelection) {
        previousSelection = currentSelection;
        
        // ツールバーが表示されている場合のみ更新
        if (_showToolbar) {
          setState(() {});
        }
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    setState(() {
      final newShowToolbar = keyboardHeight > 0 && _memoFocusNode.hasFocus;
      // ツールバーが隠れる場合はカラーパネルも閉じる
      if (_showToolbar && !newShowToolbar && _colorPanelOverlay != null) {
        _hideColorPanel();
      }
      _showToolbar = newShowToolbar;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _selectionTimer?.cancel();
    _colorPanelOverlay?.remove();
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
                // カラーパネルも閉じる
                if (_colorPanelOverlay != null) {
                  _hideColorPanel();
                }
              },
          child: Scaffold(
            backgroundColor: const Color(0xFF2B2B2B),
            appBar: AppBar(
              backgroundColor: const Color(0xFF2B2B2B),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
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
                              config: QuillEditorConfig(
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
    return GestureDetector(
      onTap: () {
        // ツールバーエリアをタップしたときに状態を更新
        setState(() {});
      },
      child: LayoutBuilder(
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
          _buildColorButton(
            icon: Icons.text_format,
            isTextColor: true,
            onPressed: () => _toggleColorPanel(false),
            buttonSize: buttonSize,
            margin: buttonMargin,
          ),
          _buildColorButton(
            icon: Icons.format_color_fill,
            isTextColor: false,
            onPressed: () => _toggleColorPanel(true),
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
      ),
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
      decoration: isActive
          ? BoxDecoration(
              gradient: createOrangeYellowGradient(),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        margin: isActive ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4A),
          borderRadius: BorderRadius.circular(isActive ? 4.5 : 6),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(isActive ? 4.5 : 6),
            child: Center(
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.grey[400],
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorButton({
    required IconData icon,
    required bool isTextColor,
    required VoidCallback onPressed,
    required double buttonSize,
    required double margin,
  }) {
    // アイコンサイズを設定（文字色ボタンは少し大きく）
    double iconSize = isTextColor ? buttonSize * 0.7 : buttonSize * 0.5;
    
    // 現在の色を取得
    Color? currentColor;
    if (isTextColor) {
      currentColor = _getCurrentTextColor();
    } else {
      currentColor = _getCurrentBackgroundColor();
    }
    
    // アイコンの色を決定
    Color iconColor;
    if (currentColor != null) {
      iconColor = currentColor;
    } else {
      iconColor = Colors.grey[400]!;
    }
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin / 2),
      width: buttonSize,
      height: buttonSize,
      decoration: currentColor != null
          ? BoxDecoration(
              gradient: createOrangeYellowGradient(),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        margin: currentColor != null ? const EdgeInsets.all(1.5) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4A),
          borderRadius: BorderRadius.circular(currentColor != null ? 4.5 : 6),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(currentColor != null ? 4.5 : 6),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: iconSize,
              ),
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
      
      // 選択範囲がない場合（カーソルのみ）は、現在の位置のスタイルを取得
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
      
      // 各属性の値をチェック
      final attributeValue = style.attributes[attribute.key];
      
      // 太文字、イタリック、アンダーライン、取り消し線の場合
      if (attribute.key == 'bold' || 
          attribute.key == 'italic' || 
          attribute.key == 'underline' || 
          attribute.key == 'strike') {
        // 属性が存在する場合はアクティブ（キーの一致は前提条件として成立）
        return attributeValue != null;
      }
      
      // その他の属性
      return attributeValue == attribute;
    } catch (e) {
      return false;
    }
  }

  // 現在のカーソル位置の文字色を取得
  Color? _getCurrentTextColor() {
    try {
      final selection = _quillController.selection;
      if (!selection.isValid) return null;
      
      final style = _quillController.getSelectionStyle();
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

  // 現在のカーソル位置の背景色を取得
  Color? _getCurrentBackgroundColor() {
    try {
      final selection = _quillController.selection;
      if (!selection.isValid) return null;
      
      final style = _quillController.getSelectionStyle();
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

  void _toggleColorPanel(bool isBackground) {
    if (_colorPanelOverlay != null) {
      _hideColorPanel();
    } else {
      _showColorPanelOverlay(isBackground);
    }
  }

  void _showColorPanelOverlay(bool isBackground) {
    setState(() {
      _isBackgroundColorMode = isBackground;
    });

    _colorPanelOverlay = OverlayEntry(
      builder: (context) => _buildOverlayColorPanel(),
    );

    Overlay.of(context).insert(_colorPanelOverlay!);
  }

  void _hideColorPanel() {
    _colorPanelOverlay?.remove();
    _colorPanelOverlay = null;
  }

  Widget _buildOverlayColorPanel() {
    // 色のリストを定義
    final List<Color?> firstRowColors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
    ];
    
    final List<Color?> secondRowColors = [
      Colors.purple,
      Colors.pink,
      Colors.brown,
      Colors.black,
      null, // リセットボタン（白色）
    ];

    // 動的に横幅を計算
    const double buttonSize = 24.0; // ボタンサイズ
    const double buttonSpacing = 12.0; // ボタン間の間隔
    const double sidePadding = 8.0; // 左右パディング
    const int buttonCount = 5; // ボタン数
    
    final double panelWidth = (buttonCount * buttonSize) + ((buttonCount - 1) * buttonSpacing) + (sidePadding * 2);

    return Positioned(
      top: 60, // モードレスにの縦位置
      right: 16, // モードレスにの横位置
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.fromLTRB(sidePadding, 8, sidePadding, 8), // 動的パディング
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!, width: 1),
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
              // タイトルと閉じるボタンの行
              SizedBox(
                width: panelWidth - (sidePadding * 2), // 動的に計算された幅
                height: 22, // ボタンサイズに合わせて高さも2px増やす
                child: Stack(
                  children: [
                    // 中央に配置されたタイトル
                    Center(
                      child: Text(
                        _isBackgroundColorMode ? '背景色' : '文字色',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12, // 元のサイズに戻す
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // 右端に配置された閉じるボタン
                    Positioned(
                      right: 0,
                      top: 0,
                      child: GestureDetector(
                        onTap: _hideColorPanel,
                        child: Container(
                          width: 22, // 2px大きく
                          height: 22, // 2px大きく
                          decoration: BoxDecoration(
                            color: Colors.grey[700],
                            borderRadius: BorderRadius.circular(11), // 角丸も調整
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16, // アイコンも少し大きく
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10), // 2px増やす
              
              // 最初の行（5色）
              Row(
                children: firstRowColors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final color = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < firstRowColors.length - 1 ? buttonSpacing : 0
                    ),
                    child: _buildSmallColorButton(color, _isBackgroundColorMode),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 10), // 上下ボタンの間隔を広げる
              
              // 2番目の行（5色、リセットボタン含む）
              Row(
                children: secondRowColors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final color = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < secondRowColors.length - 1 ? buttonSpacing : 0
                    ),
                    child: _buildSmallColorButton(color, _isBackgroundColorMode),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
        );
  }

  Widget _buildSmallColorButton(Color? color, bool isBackground) {
    const double buttonSize = 24.0; // 定数として定義
    
    return GestureDetector(
      onTap: () {
        if (color != null) {
          _setTypingColor(color, isBackground);
        } else {
          _removeTypingColor(isBackground);
        }
        // 色選択後はOverlayを閉じる
        _hideColorPanel();
      },
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: isBackground
              ? (color != null 
                  ? Color.fromRGBO(
                      (color.r * 255).round(),
                      (color.g * 255).round(),
                      (color.b * 255).round(),
                      0.3, // 背景色の透明度
                    )
                  : Colors.white) // リセットボタンは白色
              : const Color(0xFF4A4A4A), // 文字色ボタンの背景
          border: Border.all(color: Colors.grey[400]!, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isBackground
            ? null // 背景色は色そのものを表示
            : Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: color ?? Colors.white, // 文字色またはリセット時は白
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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