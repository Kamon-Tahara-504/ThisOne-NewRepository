import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../gradients.dart';
import 'google_signin_button.dart';

class LoginBottomSheet extends StatefulWidget {
  final VoidCallback? onLoginSuccess;

  const LoginBottomSheet({
    super.key,
    this.onLoginSuccess,
  });

  @override
  State<LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<LoginBottomSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showEmailLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインしました！')),
        );
        widget.onLoginSuccess?.call();
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

  Future<void> _loginWithGoogle() async {
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
          widget.onLoginSuccess?.call();
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

  Future<void> _loginWithX() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _supabaseService.signInWithTwitter();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xでログインしました！')),
          );
          widget.onLoginSuccess?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('X認証がキャンセルされました'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('X認証エラー: $error'),
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
    return DraggableScrollableSheet(
      initialChildSize: _showEmailLogin ? 0.8 : 0.35,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF2B2B2B),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // ハンドル
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 60,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // コンテンツ
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _showEmailLogin ? _buildEmailLoginForm() : _buildLoginOptions(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginOptions() {
    return Column(
      children: [
        const SizedBox(height: 20),
        
        // メールログインボタン
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: createHorizontalOrangeYellowGradient(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {
              setState(() {
                _showEmailLogin = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_outlined, color: Colors.white, size: 22),
                SizedBox(width: 12),
                Text(
                  'メールアドレスでログイン',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Googleログインボタン - ブランディングガイドライン準拠
        GoogleSignInButton(
          onPressed: _isLoading ? null : _loginWithGoogle,
          text: "Googleでログイン",
          borderRadius: 12.0,
        ),
        const SizedBox(height: 16),
        
        // Xログインボタン
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _loginWithX,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.close,
                  color: Colors.grey[300],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  'Xでログイン',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildEmailLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 戻るボタン
        TextButton.icon(
          onPressed: () {
            setState(() {
              _showEmailLogin = false;
            });
          },
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
          label: const Text(
            '戻る',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(height: 20),
        
        // メールアドレス入力
        const Text(
          'メールアドレス',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: TextField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'example@email.com',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
              prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // パスワード入力
        const Text(
          'パスワード',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF3A3A3A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[600]!),
          ),
          child: TextField(
            controller: _passwordController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'パスワードを入力',
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              prefixIcon: const Icon(Icons.lock_outlined, color: Colors.grey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        
        // ログインボタン
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: createHorizontalOrangeYellowGradient(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _loginWithEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'ログイン',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        
        // パスワードを忘れた方
        Center(
          child: TextButton(
            onPressed: () {
              // パスワードリセット機能の実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('パスワードリセット機能は準備中です'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: Text(
              'パスワードを忘れた方',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
