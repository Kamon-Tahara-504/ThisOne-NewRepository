import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class XSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? borderRadius;
  final EdgeInsets? padding;

  const XSignInButton({
    super.key,
    required this.onPressed,
    this.text = "Xでログイン",
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFF000000), // Xのブランドカラー
        borderRadius: BorderRadius.circular(borderRadius!),
        border: Border.all(color: Colors.grey[600]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius!),
          ),
          padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // X ロゴ（公式SVG）
            SvgPicture.asset(
              'assets/x_logo_white.svg',
              width: 20,
              height: 20,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
