import 'dart:ui';

import 'package:flutter/material.dart';

/// 포스터 위에 올라가는 작은 배지 — radius 6, padding 4 / 8, backdrop blur 4
/// 글자 Manrope 700 / 12 / 16
///
/// 사용처: 인기 영화 순위(1, 2, 3), 영화 목록 별점(★ 4.8)
class PosterBadge extends StatelessWidget {
  const PosterBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  /// 테두리 1px — null이면 테두리 없음
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        // Container는 테두리 두께를 안쪽 여백에 더해 줍니다. (순위 칩 높이 26 = 4 + 16 + 4 + 2)
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: radius,
            border: borderColor == null
                ? null
                : Border.all(color: borderColor!),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w700, color: foregroundColor),
          ),
        ),
      ),
    );
  }
}
