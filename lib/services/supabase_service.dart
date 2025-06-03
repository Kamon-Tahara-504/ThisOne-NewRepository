import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

class SupabaseService {
  
  // ユーザー認証関連
  
  /// サインアップ
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signUp(
      email: email,
      password: password,
    );
  }
  
  /// サインイン
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  /// サインアウト
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
  
  /// 現在のユーザーを取得
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }
  
  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
  
  // データベース操作の例
  
  /// データを取得
  Future<List<Map<String, dynamic>>> getData(String tableName) async {
    final response = await supabase
        .from(tableName)
        .select('*');
    return response as List<Map<String, dynamic>>;
  }
  
  /// データを挿入
  Future<void> insertData(String tableName, Map<String, dynamic> data) async {
    await supabase
        .from(tableName)
        .insert(data);
  }
  
  /// データを更新
  Future<void> updateData(
    String tableName, 
    Map<String, dynamic> data,
    String idColumn,
    dynamic id,
  ) async {
    await supabase
        .from(tableName)
        .update(data)
        .eq(idColumn, id);
  }
  
  /// データを削除
  Future<void> deleteData(
    String tableName,
    String idColumn,
    dynamic id,
  ) async {
    await supabase
        .from(tableName)
        .delete()
        .eq(idColumn, id);
  }
} 