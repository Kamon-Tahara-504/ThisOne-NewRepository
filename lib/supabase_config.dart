import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  // セキュリティ強化: 環境変数から値を取得
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');

    if (url.isEmpty) {
      throw Exception('SUPABASE_URLが設定されていません。環境変数を設定してください。');
    }

    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    // 本番環境とデバッグ環境両方で必須チェック
    if (key.isEmpty) {
      throw Exception('SUPABASE_ANON_KEYが設定されていません。環境変数を設定してください。');
    }

    // 本番環境では追加のセキュリティチェック
    if (kReleaseMode && (key.length < 100 || !key.contains('.'))) {
      throw Exception('無効なSUPABASE_ANON_KEYです。正しいキーを設定してください。');
    }

    return key;
  }

  static Future<void> initialize() async {
    try {
      // セキュリティチェック: URLとキーの基本検証
      _validateConfiguration();

      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

      if (kDebugMode) {
        print('Supabase初期化完了');
        print('URL: ${supabaseUrl.substring(0, 20)}...'); // セキュリティのため一部のみ表示
      }
    } catch (e) {
      if (kDebugMode) {
        print('Supabase初期化エラー: $e');
      }
      // 本番環境では詳細なエラー情報を隠す
      if (kReleaseMode) {
        throw Exception('データベースの初期化に失敗しました。');
      }
      rethrow;
    }
  }

  /// 設定値の検証
  static void _validateConfiguration() {
    final url = supabaseUrl;
    final key = supabaseAnonKey;

    // URLの基本検証
    if (!url.startsWith('https://') || !url.contains('supabase.co')) {
      throw Exception('無効なSupabase URLです。');
    }

    // キーの基本検証（JWT形式の確認）
    if (!key.contains('.') || key.split('.').length != 3) {
      throw Exception('無効なSupabaseキーです。');
    }
  }
}

// Supabaseクライアントへの簡単なアクセス
final supabase = Supabase.instance.client;
