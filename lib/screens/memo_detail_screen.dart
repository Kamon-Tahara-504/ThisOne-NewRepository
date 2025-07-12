import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'dart:async';
import '../widgets/memo_back_header.dart';
import '../widgets/quill_rich_editor.dart';
import '../widgets/memo_save_manager.dart';

class MemoDetailScreen extends StatefulWidget {
  final String memoId;
  final String title;
  final String content;
  final String mode;
  final String? richContent;
  final String? colorHex; // 色ラベルのパラメータを追加
  final DateTime? updatedAt;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
    required this.title,
    required this.content,
    required this.mode,
    this.richContent,
    this.colorHex, // 色ラベルのパラメータを追加
    this.updatedAt,
  });

  @override
  State<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends State<MemoDetailScreen> with WidgetsBindingObserver {
  late TextEditingController _titleController;
  late QuillController _quillController;
  late MemoSaveManager _saveManager;
  final FocusNode _titleFocusNode = FocusNode();
  
  bool _isMemoFocused = false; // メモのフォーカス状態を管理
  
  // 保存状態を管理
  MemoSaveState _saveState = const MemoSaveState();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addObserver(this);
    
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
    
    // MemoSaveManagerを初期化
    _saveManager = MemoSaveManager(
      memoId: widget.memoId,
      titleController: _titleController,
      quillController: _quillController,
      onStateChanged: _onSaveStateChanged,
      initialLastUpdated: widget.updatedAt,
    );
    
    // 初期化処理（PostFrameCallbackで初期化）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveManager.initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveManager.dispose();
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  /// 保存状態の変更コールバック
  void _onSaveStateChanged(MemoSaveState state) {
    setState(() {
      _saveState = state;
    });
    
    // エラーがある場合はSnackBarで表示
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存に失敗しました: ${state.errorMessage}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _handleBackPressed() async {
    if (_saveState.hasChanges) {
      await _saveManager.saveChanges();
    }
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _onMemoFocusChanged(bool isFocused) {
    if (_isMemoFocused != isFocused) {
      setState(() {
        _isMemoFocused = isFocused;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'memo-${widget.memoId}',
      child: Material(
        color: const Color(0xFF2B2B2B),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            // 入力欄以外をタップしたときにキーボードを隠す
            FocusScope.of(context).unfocus();
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF2B2B2B),
            body: Stack(
              children: [
                // メモバックヘッダー（常に表示）
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: const Color(0xFF2B2B2B),
                    child: MemoBackHeader(
                      titleController: _titleController,
                      titleFocusNode: _titleFocusNode,
                      mode: widget.mode,
                      lastUpdated: _saveState.lastUpdated,
                      isSaving: _saveState.isSaving,
                      onBackPressed: _handleBackPressed,
                      colorHex: widget.colorHex, // 色ラベル情報を渡す
                    ),
                  ),
                ),

                // メモ編集エリア(メモの視認性を上げる上下動作)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: _isMemoFocused ? 120 : 180, // フォーカス時は上に移動、通常時は少し下に、
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: GestureDetector(
                    onTap: () {
                      // QuillRichEditorエリアのタップでは親のunfocus()を無効化
                    },
                    child: QuillRichEditor(
                      controller: _quillController,
                      onFocusChanged: _onMemoFocusChanged,
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

} 