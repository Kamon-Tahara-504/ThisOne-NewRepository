import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../gradients.dart';
import '../../services/supabase_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAccountButtonPressed;

  const CustomAppBar({
    super.key,
    required this.onAccountButtonPressed,
  });

  @override
  Size get preferredSize => const Size.fromHeight(40.0);

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 12), // ヘッダー全体を12px下に移動
      child: Container(
        color: const Color(0xFF2B2B2B), // 全体を黒背景に統一
        child: Column(
          children: [
            // ステータスバー部分（黒背景に変更）
            Container(
              height: MediaQuery.of(context).padding.top,
              width: double.infinity,
              color: const Color(0xFF2B2B2B), // 黒背景
            ),
            // AppBar部分（黒背景）
            Expanded(
              child: Container(
                color: const Color(0xFF2B2B2B), // サブカラーの黒
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // 縦パディングを追加
                        child: Row(
                          children: [
                            // ヘッダー左寄せのタイトル 
                            Transform.translate(
                              offset: const Offset(0, -6), // 2px上に移動
                              child: Text(
                                'ThisOne',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500, // 文字の太さ
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const Spacer(), // 右側にスペースを作る
                            // 右側にアカウントボタンを配置
                            _buildAccountButton(),
                          ],
                        ),
                      ),
                    ),
                    // グラデーションガイドライン（黒い影）
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: createHorizontalOrangeYellowGradient(),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2), // ナビゲーションバーと同じ黒い影
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountButton() {
    return Builder(
      builder: (context) {
        final supabaseService = SupabaseService();
        final user = supabaseService.getCurrentUser();
        
        return IconButton(
          onPressed: onAccountButtonPressed,
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
          icon: Icon(
            user != null ? Icons.person : Icons.person_outline,
            color: user != null ? const Color(0xFFE85A3B) : Colors.white,
            size: 26,
          ),
        );
      }
    );
  }
}