import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'dart:async';
import '../gradients.dart';
import '../services/supabase_service.dart';
import '../widgets/memo_back_header.dart';
import '../widgets/quill_rich_editor.dart';

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

class _MemoDetailScreenState extends State<MemoDetailScreen> {
  late TextEditingController _titleController;
  late QuillController _quillController;
  final SupabaseService _supabaseService = SupabaseService();
  final FocusNode _titleFocusNode = FocusNode();
  
  bool _hasChanges = false;
  bool _isSaving = false;
  
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
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _quillController.dispose();
    _titleFocusNode.dispose();
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
            body: Column(
              children: [
                // メモバックヘッダー
                MemoBackHeader(
                  titleController: _titleController,
                  titleFocusNode: _titleFocusNode,
                  mode: widget.mode,
                  lastUpdated: _lastUpdated,
                  isSaving: _isSaving,
                  onBackPressed: _handleBackPressed,
                ),
                
                // メモ編集エリア（拡大）
                Expanded(
                  child: QuillRichEditor(
                    controller: _quillController,
                    onContentChanged: _onTextChanged,
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