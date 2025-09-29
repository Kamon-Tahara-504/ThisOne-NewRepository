import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseConfig {
  // 環境変数から値を取得（セキュア）
  static String get supabaseUrl {
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://gpbyfivahcqkebvvpuuo.supabase.co',
    );
    return url;
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwYnlmaXZhaGNxa2VidnZwdXVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMzAwNTUsImV4cCI6MjA2MzkwNjA1NX0.T-NC0Q6ogfDg3-XsAl9zNdx6ShJwoYJyyjQ1wiOrcdA',
    );

    // 本番環境では必須チェック
    if (kReleaseMode && key == 'your-anon-key-here') {
      throw Exception('SUPABASE_ANON_KEYが設定されていません。本番環境では環境変数の設定が必要です。');
    }

    return key;
  }

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

      if (kDebugMode) {
        print('Supabase初期化完了');
        print('URL: $supabaseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Supabase初期化エラー: $e');
      }
      rethrow;
    }
  }
}

// Supabaseクライアントへの簡単なアクセス
final supabase = Supabase.instance.client;
