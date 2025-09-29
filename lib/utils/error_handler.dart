import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_error.dart';
import 'network_utils.dart';

/// アプリケーション全体で使用する統一エラーハンドリングクラス
class AppErrorHandler {
  /// エラーを処理してユーザーに適切なメッセージを表示
  static void handleError(
    BuildContext context,
    dynamic error, {
    String? operation,
    VoidCallback? onRetry,
    bool showSnackBar = true,
  }) {
    final appError = _convertToAppError(error, operation);

    // デバッグ用ログ出力
    NetworkUtils.logError(error, operation: operation);

    if (showSnackBar && context.mounted) {
      _showErrorSnackBar(context, appError, onRetry);
    }
  }

  /// エラーをAppErrorに変換
  static AppError _convertToAppError(dynamic error, String? operation) {
    final errorString = error.toString();
    final stackTrace = error is Error ? error.stackTrace?.toString() : null;

    // ネットワークエラー
    if (NetworkUtils.isNetworkError(error)) {
      return AppError.network(
        NetworkUtils.getNetworkErrorMessage(error),
        code: 'NETWORK_ERROR',
        stackTrace: stackTrace,
      );
    }

    // タイムアウトエラー
    if (NetworkUtils.isTimeoutError(error)) {
      return AppError.network(
        '接続がタイムアウトしました。しばらく時間をおいてから再試行してください。',
        code: 'TIMEOUT_ERROR',
        stackTrace: stackTrace,
      );
    }

    // Supabase認証エラー
    if (error is AuthException) {
      return AppError.authentication(
        _getAuthErrorMessage(error.message),
        code: error.message,
        stackTrace: stackTrace,
      );
    }

    // データベースエラー
    if (errorString.contains('column') &&
        errorString.contains('does not exist')) {
      return AppError.database(
        'データベースの構造が変更されました。アプリを更新してください。',
        code: 'SCHEMA_ERROR',
        stackTrace: stackTrace,
      );
    }

    // バリデーションエラー
    if (errorString.contains('validation') || errorString.contains('invalid')) {
      return AppError.validation(
        '入力内容に問題があります。入力内容を確認してください。',
        code: 'VALIDATION_ERROR',
        stackTrace: stackTrace,
      );
    }

    // その他のエラー
    return AppError.unknown(
      _getGenericErrorMessage(errorString, operation),
      code: 'UNKNOWN_ERROR',
      stackTrace: stackTrace,
    );
  }

  /// 認証エラーメッセージを取得
  static String _getAuthErrorMessage(String message) {
    switch (message) {
      case 'Email not confirmed':
        return 'メールアドレスが確認されていません。メールボックスを確認してください。';
      case 'Invalid login credentials':
        return 'メールアドレスまたはパスワードが正しくありません。';
      case 'User already registered':
        return 'このメールアドレスは既に登録されています。';
      case 'Password should be at least 6 characters':
        return 'パスワードは6文字以上で入力してください。';
      case 'Invalid email':
        return '有効なメールアドレスを入力してください。';
      case 'User not found':
        return 'ユーザーが見つかりません。';
      case 'Too many requests':
        return 'リクエストが多すぎます。しばらく時間をおいてから再試行してください。';
      default:
        return '認証エラーが発生しました: $message';
    }
  }

  /// 汎用エラーメッセージを取得
  static String _getGenericErrorMessage(String errorString, String? operation) {
    if (operation != null) {
      return '$operationに失敗しました。しばらく時間をおいてから再試行してください。';
    }

    if (errorString.contains('Exception')) {
      return '予期しないエラーが発生しました。アプリを再起動してください。';
    }

    return 'エラーが発生しました。しばらく時間をおいてから再試行してください。';
  }

  /// エラースナックバーを表示
  static void _showErrorSnackBar(
    BuildContext context,
    AppError error,
    VoidCallback? onRetry,
  ) {
    final errorLevel = getErrorLevel(error);

    Color backgroundColor;
    Duration duration;

    switch (errorLevel) {
      case ErrorLevel.info:
        backgroundColor = Colors.blue[600]!;
        duration = const Duration(seconds: 3);
        break;
      case ErrorLevel.warning:
        backgroundColor = Colors.orange[600]!;
        duration = const Duration(seconds: 4);
        break;
      case ErrorLevel.error:
        backgroundColor = Colors.red[600]!;
        duration = const Duration(seconds: 5);
        break;
      case ErrorLevel.critical:
        backgroundColor = Colors.red[800]!;
        duration = const Duration(seconds: 7);
        break;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(_getErrorIcon(errorLevel), color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error.message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action:
          onRetry != null
              ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
              : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// エラーレベルに応じたアイコンを取得
  static IconData _getErrorIcon(ErrorLevel level) {
    switch (level) {
      case ErrorLevel.info:
        return Icons.info_outline;
      case ErrorLevel.warning:
        return Icons.warning_outlined;
      case ErrorLevel.error:
        return Icons.error_outline;
      case ErrorLevel.critical:
        return Icons.error;
    }
  }

  /// 成功メッセージを表示
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: duration,
      ),
    );
  }

  /// 情報メッセージを表示
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        duration: duration,
      ),
    );
  }
}
