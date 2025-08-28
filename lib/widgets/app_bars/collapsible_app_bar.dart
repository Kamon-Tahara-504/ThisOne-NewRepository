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
    final headerHeight = 52.0;
    
    return Container(
      height: headerHeight,
      color: const Color(0xFF2B2B2B),
      child: Container(
        height: 52.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
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
