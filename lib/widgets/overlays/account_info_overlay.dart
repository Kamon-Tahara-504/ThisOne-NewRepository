import 'package:flutter/material.dart';
import '../../gradients.dart';
import '../../services/supabase_service.dart';
import '../../screens/unified_auth_screen.dart';
import '../../screens/account_screen.dart';

class AccountInfoOverlay {
  OverlayEntry? _overlayEntry;
  final BuildContext context;
  final SupabaseService _supabaseService = SupabaseService();
  final VoidCallback? onTasksNeedReload;

  AccountInfoOverlay({
    required this.context,
    this.onTasksNeedReload,
  });

  void dispose() {
    _closeOverlay();
  }

  void _closeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }

  void handleAccountButtonPressed() {
    final user = _supabaseService.getCurrentUser();
    
    if (user != null) {
      // ログイン済みの場合：アカウント情報を表示
      if (_overlayEntry != null) {
        // 既に表示されている場合は閉じる
        _closeOverlay();
      } else {
        // まだ表示されていない場合は開く
        _showAccountInfoOverlay();
      }
    } else {
      // 未ログインの場合：認証画面に移動
      _navigateToAccountOrAuth();
    }
  }

  void _showAccountInfoOverlay() async {
    final user = _supabaseService.getCurrentUser();
    if (user == null) return;

    // 既存のオーバーレイがあれば先に閉じる
    _closeOverlay();

    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: () => _closeOverlay(), // タップで閉じる
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            // ポップアップ本体
            Positioned(
              top: MediaQuery.of(context).padding.top + 40 + 8, // ヘッダー高さ + 余白
              right: 16, // 右端から16px
              child: GestureDetector(
                onTap: () {}, // ポップアップ内のタップは伝播を止める
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: 170,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _buildAccountInfoContent(user),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  Widget _buildAccountInfoContent(dynamic user) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _supabaseService.getUserProfile(),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        
        return Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ログイン状態表示
              Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: const Color(0xFFE85A3B),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  ShaderMask(
                    shaderCallback: (bounds) => createHorizontalOrangeYellowGradient().createShader(bounds),
                    child: const Text(
                      'ログイン中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // ユーザー名
              Text(
                'ユーザー名',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                userProfile?['display_name']?.isNotEmpty == true
                    ? userProfile!['display_name']
                    : '未設定',
                style: TextStyle(
                  color: userProfile?['display_name']?.isNotEmpty == true
                      ? Colors.white
                      : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              
              // メールアドレス
              Text(
                'メールアドレス',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                user.email ?? '未設定',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // アカウント管理リンク
              GestureDetector(
                onTap: () {
                  _closeOverlay();
                  _navigateToAccountOrAuth();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(1), // グラデーション境界線の幅
                  decoration: BoxDecoration(
                    gradient: createHorizontalOrangeYellowGradient(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A3A), // 背景色を元に戻す
                      borderRadius: BorderRadius.circular(7), // 少し小さくして境界線を見せる
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => createHorizontalOrangeYellowGradient().createShader(bounds),
                      child: const Text(
                        'アカウント管理',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToAccountOrAuth() async {
    final user = _supabaseService.getCurrentUser();
    
    if (user != null) {
      // ログイン済みの場合はアカウント画面に移動
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AccountScreen()),
      );
      
      // アカウント画面から戻った時にタスクを再読み込み（ログアウトした可能性）
      if (result == true || result == null) {
        onTasksNeedReload?.call();
      }
    } else {
      // 未ログインの場合は認証画面に移動
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UnifiedAuthScreen()),
      );
      
      // 認証画面から戻った時にタスクを再読み込み
      if (result == true) {
        onTasksNeedReload?.call();
      }
    }
  }
} 