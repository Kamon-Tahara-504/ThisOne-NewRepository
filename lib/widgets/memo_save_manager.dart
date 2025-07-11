import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'dart:async';
import '../services/supabase_service.dart';

/// メモの保存状態を表すクラス
class MemoSaveState {
  final bool hasChanges;
  final bool isSaving;
  final DateTime? lastUpdated;
  final String? errorMessage;

  const MemoSaveState({
    this.hasChanges = false,
    this.isSaving = false,
    this.lastUpdated,
    this.errorMessage,
  });

  MemoSaveState copyWith({
    bool? hasChanges,
    bool? isSaving,
    DateTime? lastUpdated,
    String? errorMessage,
  }) {
    return MemoSaveState(
      hasChanges: hasChanges ?? this.hasChanges,
      isSaving: isSaving ?? this.isSaving,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// メモの保存管理を行うクラス
class MemoSaveManager {
  final String memoId;
  final TextEditingController titleController;
  final QuillController quillController;
  final SupabaseService _supabaseService = SupabaseService();
  final ValueChanged<MemoSaveState> onStateChanged;
  final Duration debounceDuration;

  Timer? _debounceTimer;
  MemoSaveState _state = const MemoSaveState();
  
  // 初期値を保存
  late String _initialTitle;
  late String _initialContent;
  late String _initialRichContent;
  
  bool _isInitialized = false;

  MemoSaveManager({
    required this.memoId,
    required this.titleController,
    required this.quillController,
    required this.onStateChanged,
    this.debounceDuration = const Duration(seconds: 1),
    DateTime? initialLastUpdated,
  }) {
    _state = MemoSaveState(lastUpdated: initialLastUpdated);
    // 初期状態を即座に通知
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onStateChanged(_state);
    });
  }

  /// 初期化処理（PostFrameCallbackで呼び出すことを推奨）
  void initialize() {
    if (_isInitialized) return;
    
    // 実際のコントローラーの内容を初期値として設定
    _initialTitle = titleController.text.trim();
    _initialContent = quillController.document.toPlainText();
    _initialRichContent = jsonEncode({'ops': quillController.document.toDelta().toJson()});
    
    // リスナーを追加
    titleController.addListener(_onTextChanged);
    quillController.addListener(_onTextChanged);
    
    _isInitialized = true;
  }

  /// リソースの破棄
  void dispose() {
    _debounceTimer?.cancel();
    if (_isInitialized) {
      titleController.removeListener(_onTextChanged);
      quillController.removeListener(_onTextChanged);
    }
  }

  /// 現在の保存状態を取得
  MemoSaveState get currentState => _state;

  /// 変更検知とデバウンス処理
  void _onTextChanged() {
    if (!_isInitialized) return;
    
    // 現在の内容を取得
    final currentTitle = titleController.text.trim();
    final currentContent = quillController.document.toPlainText();
    final currentRichContent = jsonEncode({'ops': quillController.document.toDelta().toJson()});
    
    // 初期値と比較して実際に変更があったかチェック
    final hasActualChanges = currentTitle != _initialTitle || 
                            currentContent != _initialContent ||
                            currentRichContent != _initialRichContent;
    
    if (hasActualChanges != _state.hasChanges) {
      _updateState(_state.copyWith(hasChanges: hasActualChanges));
    }
    
    if (_state.hasChanges) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(debounceDuration, () {
        if (_state.hasChanges && !_state.isSaving) {
          saveChanges();
        }
      });
    }
  }

  /// 強制保存（戻るボタン押下時など）
  Future<void> saveChanges() async {
    if (!_state.hasChanges || _state.isSaving) return;
    
    _updateState(_state.copyWith(isSaving: true, errorMessage: null));
    
    try {
      final plainText = quillController.document.toPlainText();
      final richContentMap = {'ops': quillController.document.toDelta().toJson()};
      
      await _supabaseService.updateMemo(
        memoId: memoId,
        title: titleController.text.trim().isEmpty 
            ? '無題' 
            : titleController.text.trim(),
        content: plainText,
        richContent: richContentMap,
      );
      
      // 保存成功時に初期値を更新
      _initialTitle = titleController.text.trim().isEmpty ? '無題' : titleController.text.trim();
      _initialContent = plainText;
      _initialRichContent = jsonEncode(richContentMap);
      
      _updateState(_state.copyWith(
        hasChanges: false,
        isSaving: false,
        lastUpdated: DateTime.now(),
        errorMessage: null,
      ));
    } catch (e) {
      _updateState(_state.copyWith(
        isSaving: false,
        errorMessage: e.toString(),
      ));
    }
  }

  /// 状態更新とコールバック呼び出し
  void _updateState(MemoSaveState newState) {
    _state = newState;
    onStateChanged(_state);
  }

  /// 変更があるかどうか
  bool get hasChanges => _state.hasChanges;

  /// 保存中かどうか
  bool get isSaving => _state.isSaving;

  /// 最終更新時刻
  DateTime? get lastUpdated => _state.lastUpdated;

  /// エラーメッセージ
  String? get errorMessage => _state.errorMessage;
} 