import 'package:flutter/material.dart';

/// 누를 수 없는 태그 칩 — radius 9999
///
/// 사용처: 영화 상세 장르 칩(로맨스, 드라마…), 마이페이지 선호하는 장르
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: ShapeDecoration(
        color: backgroundColor,
        shape: const StadiumBorder(),
      ),
      child: Text(label, style: textStyle?.copyWith(color: foregroundColor)),
    );
  }
}
