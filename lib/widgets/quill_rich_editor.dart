import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'quill_toolbar.dart';
import 'quill_color_panel.dart';

class QuillRichEditor extends StatefulWidget {
  final QuillController controller;
  final VoidCallback onContentChanged;

  const QuillRichEditor({
    super.key,
    required this.controller,
    required this.onContentChanged,
  });

  @override
  State<QuillRichEditor> createState() => _QuillRichEditorState();
}

class _QuillRichEditorState extends State<QuillRichEditor> with WidgetsBindingObserver {
  final FocusNode _memoFocusNode = FocusNode();
  
  bool _showToolbar = false;
  bool _isBackgroundColorMode = false;
  OverlayEntry? _colorPanelOverlay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // フォーカス変更を監視
    _memoFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _colorPanelOverlay?.remove();
    _memoFocusNode.dispose();
    super.dispose();
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

    _colorPanelOverlay = QuillColorPanel.createOverlay(
      context: context,
      controller: widget.controller,
      isBackgroundColorMode: isBackground,
      onClose: _hideColorPanel,
      onColorChanged: () {
        widget.onContentChanged();
        setState(() {});
      },
    );

    Overlay.of(context).insert(_colorPanelOverlay!);
  }

  void _hideColorPanel() {
    _colorPanelOverlay?.remove();
    _colorPanelOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // ツールバー
          if (_showToolbar)
            QuillToolbar(
              controller: widget.controller,
              onTextColorPressed: () => _toggleColorPanel(false),
              onBackgroundColorPressed: () => _toggleColorPanel(true),
              onStateChanged: () {
                widget.onContentChanged();
                setState(() {});
              },
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
                controller: widget.controller,
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
    );
  }
} 