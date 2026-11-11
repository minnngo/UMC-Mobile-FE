import 'package:flutter/material.dart';

import '../data/models/tmdb_movie_dto.dart';
import 'movie_card.dart';
import 'poster_badge.dart';
import 'tmdb_poster_image.dart';

/// 영화 그리드 — 2열, column-gap 16, row-gap 24
class MovieGrid extends StatelessWidget {
  const MovieGrid({
    super.key,
    required this.movies,
    this.genreNames = const {},
  });

  final List<TmdbMovieDto> movies;

  /// TMDB 장르 id → 이름 (소제목에 첫 번째 장르 이름을 표시)
  final Map<int, String> genreNames;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 카드 너비 171 기준: 포스터 2:3(256.5) + 12 + 제목 24 + 소제목 24
        final itemWidth = (constraints.maxWidth - 16 * 2 - 16) / 2;
        return GridView.builder(
          // 영화가 적어 화면을 다 채우지 않아도 당겨서 새로고침할 수 있도록 항상 스크롤 가능하게 둡니다.
          physics: const AlwaysScrollableScrollPhysics(),
          // Figma padding-bottom 96 = 하단 네비(80) + 여백 16.
          // 네비가 본문을 덮지 않으므로 16만 둡니다.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 24,
            mainAxisExtent: itemWidth * 1.5 + 12 + 24 + 24,
          ),
          itemCount: movies.length,
          itemBuilder: (context, index) =>
              _MovieGridItem(movie: movies[index], genreNames: genreNames),
        );
      },
    );
  }
}

/// 영화 아이템 — 공통 [MovieCard], 171 x 316.5
/// 포스터 171 x 256.5 (2:3, radius 12) + 12 + 제목 24 + 소제목 24
class _MovieGridItem extends StatelessWidget {
  const _MovieGridItem({required this.movie, required this.genreNames});

  final TmdbMovieDto movie;
  final Map<int, String> genreNames;

  /// 소제목 — "2023 · 드라마". 개봉일이 없으면 연도를, 장르가 없으면 장르를 뺍니다.
  String get _subtitle {
    final releaseDate = movie.releaseDate;
    final year = releaseDate != null && releaseDate.length >= 4
        ? releaseDate.substring(0, 4)
        : null;
    final genre = movie.genreIds.isEmpty
        ? null
        : genreNames[movie.genreIds.first];
    return [?year, ?genre].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MovieCard(
      movieId: movie.id,
      title: movie.title,
      poster: TmdbPosterImage(
        posterPath: movie.posterPath,
        // 크기는 카드의 AspectRatio(2:3)가 정하므로 가득 채웁니다.
        width: double.infinity,
        height: double.infinity,
      ),
      posterAspectRatio: 2 / 3,
      posterRadius: 12,
      // 별점 칩 — 48 x 24, 배경 #322F35CC, 글자 #F5EFF7
      badge: Positioned(
        top: 8,
        right: 8,
        child: PosterBadge(
          // TMDB 평점은 10점 만점이라 앱의 5점 만점으로 바꿔 표시
          label: '★ ${(movie.voteAverage / 2).toStringAsFixed(1)}',
          // #322F35 + 투명도 CC(204/255)
          backgroundColor: colors.inverseSurface.withValues(alpha: 0xCC / 0xFF),
          foregroundColor: colors.onInverseSurface,
        ),
      ),
      // 소제목 — 높이 24, opacity 0.8, Manrope 400 / 16 / 24, #494551
      subtitle: SizedBox(
        height: 24,
        child: Opacity(
          opacity: 0.8,
          child: Text(
            _subtitle,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
