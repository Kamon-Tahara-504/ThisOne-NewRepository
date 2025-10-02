import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_repository.dart';
import '../core/repository_exceptions.dart';
import '../../services/supabase_service.dart';

/// Supabaseを使ったAuthRepositoryの実装
class AuthRepositoryImpl implements AuthRepository {
  final SupabaseService _supabaseService;

  AuthRepositoryImpl(this._supabaseService);

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabaseService.signUp(email: email, password: password);
    } catch (e) {
      throw AuthRepositoryException('サインアップに失敗しました', e);
    }
  }

  @override
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabaseService.signIn(email: email, password: password);
    } catch (e) {
      throw AuthRepositoryException('サインインに失敗しました', e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      throw AuthRepositoryException('サインアウトに失敗しました', e);
    }
  }

  @override
  User? getCurrentUser() {
    return _supabaseService.getCurrentUser();
  }

  @override
  Stream<AuthState> get authStateChanges => _supabaseService.authStateChanges;

  @override
  Future<bool> signInWithGoogle() async {
    try {
      return await _supabaseService.signInWithGoogle();
    } catch (e) {
      throw AuthRepositoryException('Google認証に失敗しました', e);
    }
  }

  @override
  Future<bool> signInWithTwitter() async {
    try {
      return await _supabaseService.signInWithTwitter();
    } catch (e) {
      throw AuthRepositoryException('X認証に失敗しました', e);
    }
  }
}
