import 'package:flutter/material.dart';

/// 再利用可能なカスタムボトムシートコンポーネント
/// ドラッグ可能で、少し下げただけで元の位置に戻る動作を提供
class CustomBottomSheet extends StatefulWidget {
  final Widget child;
  final double initialHeight; // 初期高さ（画面の割合、0.0-1.0）
  final double minHeight; // 最小高さ（画面の割合、0.0-1.0）
  final double maxHeight; // 最大高さ（画面の割合、0.0-1.0）
  final bool enableDrag; // ドラッグを有効にするか
  final bool snapToInitial; // 少し下げただけで元の位置に戻るか
  final Color backgroundColor;
  final BorderRadius borderRadius;

  const CustomBottomSheet({
    super.key,
    required this.child,
    this.initialHeight = 0.7,
    this.minHeight = 0.3,
    this.maxHeight = 0.95,
    this.enableDrag = true,
    this.snapToInitial = true,
    this.backgroundColor = const Color(0xFF2B2B2B),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(20),
      topRight: Radius.circular(20),
    ),
  });

  @override
  State<CustomBottomSheet> createState() => _CustomBottomSheetState();
}

class _CustomBottomSheetState extends State<CustomBottomSheet> {
  late DraggableScrollableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableDrag) {
      // ドラッグ無効の場合は固定高さのContainer
      return Container(
        height: MediaQuery.of(context).size.height * widget.initialHeight,
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      );
    }

    // ドラッグ有効の場合はDraggableScrollableSheet
    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: widget.initialHeight,
      minChildSize: widget.minHeight,
      maxChildSize: widget.maxHeight,
      snap: widget.snapToInitial,
      snapSizes: widget.snapToInitial ? [widget.initialHeight] : null,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// ボトムシートを表示するヘルパー関数
Future<T?> showCustomBottomSheet<T>({
  required BuildContext context,
  required Widget child,
  double initialHeight = 0.7,
  double minHeight = 0.3,
  double maxHeight = 0.95,
  bool enableDrag = true,
  bool snapToInitial = true,
  Color backgroundColor = const Color(0xFF2B2B2B),
  BorderRadius borderRadius = const BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  ),
  bool isScrollControlled = true,
  bool isDismissible = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: isScrollControlled,
    enableDrag: enableDrag,
    isDismissible: isDismissible,
    useSafeArea: useSafeArea,
    builder:
        (context) => CustomBottomSheet(
          initialHeight: initialHeight,
          minHeight: minHeight,
          maxHeight: maxHeight,
          enableDrag: enableDrag,
          snapToInitial: snapToInitial,
          backgroundColor: backgroundColor,
          borderRadius: borderRadius,
          child: child,
        ),
  );
}
