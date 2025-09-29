import 'dart:io';
import 'package:flutter/foundation.dart';

/// ネットワーク関連のユーティリティクラス
class NetworkUtils {
  /// ネットワーク接続エラーかどうかを判定
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
        error is HttpException ||
        error is OSError ||
        error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException') ||
        error.toString().contains('Connection failed');
  }

  /// タイムアウトエラーかどうかを判定
  static bool isTimeoutError(dynamic error) {
    return error.toString().contains('TimeoutException') ||
        error.toString().contains('timeout') ||
        error.toString().contains('timed out');
  }

  /// 接続エラーの詳細メッセージを取得
  static String getNetworkErrorMessage(dynamic error) {
    if (isTimeoutError(error)) {
      return '接続がタイムアウトしました。ネットワーク接続を確認してから再試行してください。';
    }

    if (isNetworkError(error)) {
      return 'ネットワーク接続を確認してください。インターネットに接続されているか確認してください。';
    }

    return 'ネットワークエラーが発生しました。しばらく時間をおいてから再試行してください。';
  }

  /// デバッグ用のエラー情報をログ出力
  static void logError(
    dynamic error, {
    String? operation,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      print('=== エラーログ ===');
      print('操作: $operation');
      print('エラー: $error');
      if (stackTrace != null) {
        print('スタックトレース: $stackTrace');
      }
      print('================');
    }
  }

  /// エラーの種類を判定
  static String getErrorType(dynamic error) {
    if (isNetworkError(error)) return 'ネットワークエラー';
    if (isTimeoutError(error)) return 'タイムアウトエラー';
    if (error.toString().contains('AuthException')) return '認証エラー';
    if (error.toString().contains('ValidationException')) return 'バリデーションエラー';
    return '不明なエラー';
  }
}
