import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';

class CollapsibleAppBar extends StatelessWidget {
  final VoidCallback onAccountButtonPressed;
  final double scrollProgress; // スクロール進行度（0.0=完全表示, 1.0=完全隠れ）

  const CollapsibleAppBar({
    super.key,
    required this.onAccountButtonPressed,
    this.scrollProgress = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // 🎯 ガイドライン保護システム（元の良い状態）
    final headerHeight = 54.0; // 固定ヘッダー高さ
    final guidelineHeight = 2.0; // ガイドライン高さ
    
    // ガイドライン分を残して隠す（元の良いアプローチ）
    final maxHideDistance = headerHeight + 10 - guidelineHeight; // ガイドライン2px分は保護
    final hideOffset = scrollProgress * maxHideDistance;
    
    // ヘッダーコンテンツの透明度（95%以上で完全透明）
    final contentOpacity = scrollProgress >= 0.95 ? 0.0 : (1.0 - scrollProgress * 1.2).clamp(0.0, 1.0);
    
    // ガイドラインは常に不透明（透明化しない）
    const guidelineOpacity = 1.0;
    
    // デバッグ出力
    if (scrollProgress > 0) {
      print('🚀 ガイドライン保護（元状態） - 進行度: ${(scrollProgress * 100).toInt()}%, 隠れ量: ${hideOffset.toStringAsFixed(1)}px/${maxHideDistance.toStringAsFixed(1)}px, ガイドライン${guidelineHeight.toInt()}px保護');
    }
    
    // 🎯 ガイドライン常時表示構造
    return Transform.translate(
      offset: Offset(0, -hideOffset),
      child: Container(
        height: headerHeight,
        color: const Color(0xFF2B2B2B), // BoxDecorationを削除（境界線回避）
        child: Column(
          children: [
            // ヘッダーコンテンツ（透明化対象）
            Opacity(
              opacity: contentOpacity,
              child: Container(
                height: 52.0,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
                child: Row(
                  children: [
                    // タイトル
                    Transform.translate(
                      offset: const Offset(0, -3),
                      child: Text(
                        'ThisOne',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // アカウントボタン
                    _buildAccountButton(),
                  ],
                ),
              ),
            ),
            // ガイドライン（常時表示・透明化しない）
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE85A3B).withOpacity(guidelineOpacity), // 常に不透明
                    const Color(0xFFFFA726).withOpacity(guidelineOpacity), // 常に不透明
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
