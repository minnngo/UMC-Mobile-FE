import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'poster_image.dart';

/// 공통 영화 카드 — 포스터 + 제목 + 보조 줄, 누르면 [movieId]의 영화 상세로 이동
///
/// 포스터 아래 12 → 제목(Manrope 500 / 16 / 24) → [subtitle]
///
/// 사용처: 홈 인기 영화(140 x 256), 영화 목록 그리드(171 x 316.5)
class MovieCard extends StatelessWidget {
  const MovieCard({
    super.key,
    required this.movieId,
    required this.title,
    required this.poster,
    required this.posterAspectRatio,
    required this.posterRadius,
    required this.badge,
    required this.subtitle,
  });

  /// 상세 화면 경로에 쓰는 영화 ID — TMDB 영화는 TMDB id
  final int movieId;
  final String title;

  /// 포스터 이미지 (에셋 또는 TMDB 네트워크 이미지)
  final Widget poster;

  /// 포스터 가로 / 세로 (홈 140 / 200, 목록 2 / 3)
  final double posterAspectRatio;
  final double posterRadius;

  /// 포스터 위 배지 — Positioned로 위치를 정해 전달 (홈: 순위, 목록: 별점)
  final Widget badge;

  /// 제목 아래 줄 (홈: 별점, 목록: 연도 · 장르)
  final Widget subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // push: 상세에서 뒤로가기로 이 화면에 돌아옴
        onTap: () => context.push('/movies/$movieId'),
        child: Column(
          // 부모 높이를 채우지 않고 카드 높이만 차지
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 포스터 — 배경 #E6E0E9, box-shadow 0 1 2 #0000000D
            AspectRatio(
              aspectRatio: posterAspectRatio,
              child: PosterImage(
                image: poster,
                borderRadius: posterRadius,
                hasShadow: true,
                overlays: [badge],
              ),
            ),
            // 홈: padding-bottom 12 / 목록: gap 4 + padding-top 8
            const SizedBox(height: 12),
            // 제목 — 높이 24, Manrope 500 / 16 / 24, #1D1B20
            SizedBox(
              height: 24,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            subtitle,
          ],
        ),
      ),
    );
  }
}
