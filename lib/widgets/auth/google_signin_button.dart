import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final double? borderRadius;
  final EdgeInsets? padding;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.text = "Googleでログイン",
    this.borderRadius = 12.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SignInButton(
        Buttons.Google,
        onPressed: onPressed,
        text: text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius!),
        ),
        padding: padding ?? const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
