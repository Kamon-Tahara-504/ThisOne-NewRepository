import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // TODO: 実際のSupabaseプロジェクトのURLとキーに置き換えてください
  static const String supabaseUrl = 'https://gpbyfivahcqkebvvpuuo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwYnlmaXZhaGNxa2VidnZwdXVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgzMzAwNTUsImV4cCI6MjA2MzkwNjA1NX0.T-NC0Q6ogfDg3-XsAl9zNdx6ShJwoYJyyjQ1wiOrcdA';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}

// Supabaseクライアントへの簡単なアクセス
final supabase = Supabase.instance.client; 