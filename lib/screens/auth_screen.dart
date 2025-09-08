import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import '../services/supabase_service.dart';
import '../gradients.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        final response = await _supabaseService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        if (mounted) {
          if (response.user != null && response.user!.emailConfirmedAt == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('サインアップが完了しました！メールを確認してアカウントを有効化してください。'),
                duration: Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('サインアップが完了しました！')),
            );
          }
        }
      } else {
        await _supabaseService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ログインしました！')),
          );
          // ログイン成功時は前の画面に戻る
          Navigator.pop(context, true);
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        String errorMessage;
        switch (error.message) {
          case 'Email not confirmed':
            errorMessage = 'メールアドレスが確認されていません。メールボックスを確認してください。';
            break;
          case 'Invalid login credentials':
            errorMessage = 'メールアドレスまたはパスワードが正しくありません。';
            break;
          case 'User already registered':
            errorMessage = 'このメールアドレスは既に登録されています。';
            break;
          default:
            errorMessage = 'エラー: ${error.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('予期しないエラーが発生しました: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _supabaseService.signInWithGoogle();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Googleでログインしました！')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google認証がキャンセルされました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google認証エラー: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: Container(
          color: const Color(0xFF2B2B2B),
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  // 戻るボタン
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // タイトル
                  Text(
                    _isSignUp ? 'サインアップ' : 'ログイン',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // グラデーションガイドライン
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: createHorizontalOrangeYellowGradient(),
            ),
          ),
          // メインコンテンツ
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'パスワード',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: createHorizontalOrangeYellowGradient(),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _authenticate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isSignUp ? 'サインアップ' : 'ログイン',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                      });
                    },
                    child: Text(
                      _isSignUp 
                          ? '既にアカウントをお持ちですか？ ログイン' 
                          : 'アカウントをお持ちでない方は サインアップ',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // OR区切り
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[600])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'または',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[600])),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Google Sign-In ボタン
                  SignInButton(
                    Buttons.Google,
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    text: "Googleでログイン",
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  
                  if (!_isSignUp) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '※ メール確認が必要な場合があります',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}