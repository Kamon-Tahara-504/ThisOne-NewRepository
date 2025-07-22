import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'dart:async';
import '../widgets/memo_back_header.dart';
import '../widgets/quill_rich_editor.dart';
import '../widgets/memo_save_manager.dart';
import '../utils/calculator_utils.dart';

class MemoDetailScreen extends StatefulWidget {
  final String memoId;
  final String title;
  final String content;
  final String mode;
  final String? richContent;
  final String? colorHex;
  final DateTime? updatedAt;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
    required this.title,
    required this.content,
    required this.mode,
    this.richContent,
    this.colorHex,
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
  
  bool _isMemoFocused = false;
  MemoSaveState _saveState = const MemoSaveState();
  
  // 計算機モード用の状態
  String _calculatorSummary = '';
  Map<String, dynamic> _summaryData = {};

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
    
    // 計算機モードの場合、テキスト変更リスナーを追加
    if (widget.mode == 'calculator' || widget.mode == 'rich') {
      _quillController.addListener(_onQuillTextChanged);
      // 初期計算
      _updateCalculations();
    }
    
    // 初期化処理
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveManager.initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveManager.dispose();
    _titleController.dispose();
    
    // 計算機モードのリスナーを削除
    if (widget.mode == 'calculator' || widget.mode == 'rich') {
      _quillController.removeListener(_onQuillTextChanged);
    }
    
    _quillController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _onSaveStateChanged(MemoSaveState state) {
    setState(() {
      _saveState = state;
    });
    
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存に失敗しました: ${state.errorMessage}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  // 計算機モード: テキスト変更リスナー
  void _onQuillTextChanged() {
    if (widget.mode == 'calculator' || widget.mode == 'rich') {
      _updateCalculations();
    }
  }

  // 計算機モード: 計算を更新
  void _updateCalculations() {
    final text = _quillController.document.toPlainText();
    final entries = CalculatorUtils.extractCalculations(text);
    final summary = CalculatorUtils.generateSummary(entries);
    final summaryData = CalculatorUtils.getSummaryData(entries);
    
    setState(() {
      _calculatorSummary = summary;
      _summaryData = summaryData;
    });
  }

  // カード風サマリー表示を作成
  Widget _buildColoredSummaryText() {
    // フォールバック: _summaryDataが空の場合は従来の表示
    if (_summaryData.isEmpty || _calculatorSummary.isEmpty) {
      return Text(
        _calculatorSummary,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 収入カード
        _buildSummaryCard(
          label: '収入',
          amount: _summaryData['incomeAmount'] ?? '¥0',
          color: Colors.green,
          isVisible: _summaryData['hasIncome'] == true,
        ),
        // 支出カード
        _buildSummaryCard(
          label: '支出',
          amount: _summaryData['expenseAmount'] ?? '¥0',
          color: Colors.red,
          isVisible: _summaryData['hasExpense'] == true,
        ),
        // 残高カード
        _buildSummaryCard(
          label: '残高',
          amount: _summaryData['totalAmount'] ?? '¥0',
          color: (_summaryData['total'] ?? 0) >= 0 ? Colors.blue : Colors.orange,
          isVisible: true, // 残高は常に表示
        ),
      ],
    );
  }

  // 個別のサマリーカードを作成
  Widget _buildSummaryCard({
    required String label,
    required String amount,
    required Color color,
    required bool isVisible,
  }) {
    return Expanded(
      child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$label ',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            Flexible(
              child: Text(
                amount,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
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
    return Material(
      color: const Color(0xFF2B2B2B),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          backgroundColor: const Color(0xFF2B2B2B),
          body: Stack(
            children: [
              // メモバックヘッダー
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
                    colorHex: widget.colorHex,
                  ),
                ),
              ),
              // メモ編集エリア
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                top: _isMemoFocused ? 120 : 180,
                left: 16,
                right: 16,
                bottom: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A3A3A), // メモ入力欄と同じ背景色
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // 計算機モード: 合計表示 (メモ入力中は非表示)
                      if ((widget.mode == 'calculator' || widget.mode == 'rich') && 
                          _calculatorSummary.isNotEmpty && 
                          !_isMemoFocused)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildColoredSummaryText(),
                        ),
                      // メモエディター
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
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
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 