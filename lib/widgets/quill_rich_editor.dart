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
    
    // 自動フォーカスは無効にし、ユーザーがタップした時のみフォーカスを設定
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _colorPanelOverlay?.remove();
    _memoFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    // フォーカス変更を遅延処理で確実に反映
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        final shouldShow = _memoFocusNode.hasFocus;
        if (_showToolbar != shouldShow) {
          setState(() {
            _showToolbar = shouldShow;
            if (!_memoFocusNode.hasFocus && _colorPanelOverlay != null) {
              _hideColorPanel();
            }
          });
        }
      }
    });
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    
    // カラーパネルが表示されている場合のみキーボード状態を監視
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    if (keyboardHeight == 0 && _colorPanelOverlay != null) {
      _hideColorPanel();
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
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _memoFocusNode.requestFocus();
                // 即座にツールバーを表示
                if (!_showToolbar) {
                  setState(() {
                    _showToolbar = true;
                  });
                }
              },
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
          ),
        ],
      ),
    );
  }
} 