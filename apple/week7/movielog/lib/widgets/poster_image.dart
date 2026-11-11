import 'package:flutter/material.dart';

import '../theme/app_shadows.dart';

/// 포스터 이미지 공통 틀 — 둥근 모서리, 로딩 전 배경색, 선택적 그림자, 위에 겹치는 요소
///
/// 크기는 부모(SizedBox, AspectRatio 등)가 정하고, 이미지는 가운데 기준으로 잘라 채웁니다.
/// 이미지가 없으면 배경색만 보여줍니다.
///
/// 사용처: 홈 배너·인기 영화 카드, 영화 목록 카드, 영화 상세 히어로
class PosterImage extends StatelessWidget {
  const PosterImage({
    super.key,
    this.asset,
    this.image,
    this.borderRadius = 0,
    this.backgroundColor,
    this.hasShadow = false,
    this.overlays = const [],
  }) : assert(asset != null || image != null, 'asset 또는 image가 필요합니다.');

  /// 에셋 포스터 경로 — [image]가 있으면 사용하지 않습니다.
  final String? asset;

  /// 에셋 대신 보여줄 이미지 (예: TMDB 네트워크 포스터)
  final Widget? image;
  final double borderRadius;

  /// null이면 #E6E0E9 (surfaceContainerHighest)
  final Color? backgroundColor;

  /// 카드 그림자 — box-shadow 0 1 2 #0000000D
  final bool hasShadow;

  /// 이미지 위에 겹칠 위젯 (오버레이, 칩 등)
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: radius,
        boxShadow: hasShadow ? AppShadows.card : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image ??
                Image.asset(
                  asset!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
            ...overlays,
          ],
        ),
      ),
    );
  }
}
