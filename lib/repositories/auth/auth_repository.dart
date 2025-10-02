import 'package:supabase_flutter/supabase_flutter.dart';

/// 認証リポジトリのインターフェース
abstract class AuthRepository {
  /// サインアップ
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  /// サインイン
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// サインアウト
  Future<void> signOut();

  /// 現在のユーザーを取得
  User? getCurrentUser();

  /// 認証状態の変更を監視
  Stream<AuthState> get authStateChanges;

  /// Google認証
  Future<bool> signInWithGoogle();

  /// X(Twitter)認証
  Future<bool> signInWithTwitter();
}
