import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/mock/movie_mock_data.dart';
import '../data/models/tmdb_movie_dto.dart';
import '../models/movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/app_header.dart';
import '../widgets/movie_card.dart';
import '../widgets/pill_button.dart';
import '../widgets/poster_badge.dart';
import '../widgets/poster_image.dart';
import '../widgets/tmdb_poster_image.dart';
import '../view_models/movie_home_view_model.dart';

/// W3-01 영화 홈 화면입니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [AppHeader] MovieLog 로고, 검색 버튼
/// - [_GreetingSection] 오늘은 어떤 영화를 볼까요?
/// - [_FeaturedBanner] 추천 신작 배너
/// - [_PopularSection] 인기 영화 가로 목록 — 5주차부터 [MovieHomeViewModel]의 TMDB 인기 영화 5개
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 추천 신작 — 목록·상세와 같은 Mock(id 1, 별빛 아래 우리)을 사용합니다.
    final featured = movies.first;
    final featuredDetail = findMovieDetailById(featured.id)!;

    // 홈에서는 시스템 뒤로가기(Android 뒤로 버튼 등)로 회원가입·시작 화면에 돌아가지 않습니다.
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: const AppHeader.tab(title: 'MovieLog'),
        body: ListView(
          // Figma padding-bottom 96 = 하단 네비(80)에 가려지는 영역 + 여백 16.
          // 여기서는 네비가 본문을 덮지 않으므로 여백 16만 둡니다.
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            const _GreetingSection(),
            // 중간 섹션 — padding 0 / 16 / 24 / 16
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: _FeaturedBanner(
                movie: featured,
                // 배너 배경 — 상세 히어로와 같은 가로형 이미지
                backdropAsset: featuredDetail.heroAsset ?? featured.posterAsset,
                // 로맨스 · 드라마 · 124분
                meta: [
                  ...featuredDetail.genres,
                  if (featuredDetail.runtimeMinutes != null)
                    '${featuredDetail.runtimeMinutes}분',
                ].join(' · '),
              ),
            ),
            const _PopularSection(),
          ],
        ),
      ),
    );
  }
}

/// greeting section — 388 x 104, padding 16
class _GreetingSection extends StatelessWidget {
  const _GreetingSection();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      // Manrope 500 / 28 / 36 / -0.7, #1D1B20
      child: Text(
        '오늘은 어떤\n영화를 볼까요?',
        style: textTheme.headlineMedium?.copyWith(
          letterSpacing: -0.7,
          color: colors.onSurface,
        ),
      ),
    );
  }
}

/// 중간 배너 — 356 x 534, radius 24, 배경 #E6E0E9
/// 포스터 → 오버레이(#000000B2) → 하단 정보(칩, 제목, 설명, 버튼) 순으로 쌓습니다.
class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner({
    required this.movie,
    required this.backdropAsset,
    required this.meta,
  });

  final Movie movie;

  /// 배너 배경 이미지 (가로형)
  final String backdropAsset;

  /// 장르·러닝타임 문구 (예: 로맨스 · 드라마 · 124분)
  final String meta;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 534,
      // 뒤에 포스터 — 가로형 이미지를 가운데 기준으로 잘라 채웁니다.
      child: PosterImage(
        asset: backdropAsset,
        borderRadius: 24,
        overlays: [
          const ColoredBox(color: AppColors.imageOverlay),
          // 배너 하단 — 356 x 218, padding 24
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 칩 마진 — padding-bottom 8
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _BannerChip(label: '추천 신작'),
                    ),
                  ),
                  // 제목 — padding-bottom 4, Manrope 500 / 28 / 36, #FFFFFF
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      movie.title,
                      style: textTheme.headlineMedium?.copyWith(
                        color: AppColors.onImage,
                        shadows: AppShadows.textOnImage,
                      ),
                    ),
                  ),
                  // 하단 설명 — padding-bottom 16, opacity 0.9
                  // Manrope 400 / 16 / 24, #F8F2FA
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Opacity(
                      opacity: 0.9,
                      child: Text(
                        meta,
                        style: textTheme.bodyLarge?.copyWith(
                          color: AppColors.onImageVariant,
                          shadows: AppShadows.textOnImage,
                        ),
                      ),
                    ),
                  ),
                  // 상세보기 — 308 x 48, gap 8, 배경 #4F378A, 아이콘 16.67 #FFFFFF
                  // box-shadow 0 2 4 -2 #0000001A, 0 4 6 -1 #0000001A
                  PillButton(
                    label: '상세보기',
                    iconAsset: 'assets/icons/banner_info_filled.svg',
                    iconSize: const Size.square(50 / 3),
                    color: colors.onPrimaryContainer,
                    foregroundColor: AppColors.onImage,
                    gap: 8,
                    shadows: AppShadows.raisedButton,
                    // 추천 신작은 Mock 영화라 상세 정보를 함께 넘겨 TMDB를 조회하지 않습니다.
                    onPressed: () => context.push(
                      '/movies/${movie.id}',
                      extra: findMovieDetailById(movie.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 추천 신작 칩 — 75 x 34, radius 9999, padding 9.5 / 12 / 6.5 / 12
/// 배경 #4F378AE5, border 1px #FFFFFF33, box-shadow 0 1 2 #0000000D, backdrop blur 12
class _BannerChip extends StatelessWidget {
  const _BannerChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: AppShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 9.5, 12, 6.5),
            decoration: ShapeDecoration(
              // #4F378A + 투명도 E5(229/255)
              color: colors.onPrimaryContainer.withValues(alpha: 0xE5 / 0xFF),
              shape: const StadiumBorder(
                side: BorderSide(color: AppColors.onImageOutline),
              ),
            ),
            // 글자 스펙이 없어 칩 크기(높이 34 = 9.5 + 16 + 6.5 + 테두리 2)에서 역산: 12 / 16
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(color: AppColors.onImage),
            ),
          ),
        ),
      ),
    );
  }
}

/// 인기 영화 섹션 — 388 x 324, padding-bottom 8, gap 16
/// 제목 줄(28) + 가로 목록(272)
///
/// 가로 목록 영역만 [Consumer]로 구독해, 상태가 바뀌어도 홈의 다른 섹션은 다시 그리지 않습니다.
class _PopularSection extends StatelessWidget {
  const _PopularSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 내부 컨테이너 — 388 x 28, padding 0 / 16, space-between
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Manrope 500 / 22 / 28, #1D1B20
                  Text('인기 영화', style: textTheme.titleLarge),
                  _SeeAllButton(onPressed: () => context.go('/movies')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 중앙 컨테이너 — 388 x 272, 카드 140 x 256, 간격 16
          // 상태가 바뀌어도 높이를 유지해 아래 내용이 흔들리지 않게 합니다.
          SizedBox(
            height: 272,
            child: Consumer<MovieHomeViewModel>(
              builder: (context, viewModel, child) {
                return switch (viewModel.status) {
                  MovieHomeLoadStatus.idle || MovieHomeLoadStatus.loading =>
                    const Center(child: CircularProgressIndicator()),
                  MovieHomeLoadStatus.error => _PopularMessage(
                    message: viewModel.message ?? '인기 영화를 불러오지 못했어요.',
                    onRetry: () =>
                        context.read<MovieHomeViewModel>().loadPopular(),
                  ),
                  MovieHomeLoadStatus.empty => const _PopularMessage(
                    message: '인기 영화가 없어요.',
                  ),
                  MovieHomeLoadStatus.success => _PopularList(
                    movies: viewModel.popularMovies,
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 인기 영화 가로 목록 — 순위는 목록 순서(1부터)
class _PopularList extends StatelessWidget {
  const _PopularList({required this.movies});

  final List<TmdbMovieDto> movies;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: movies.length,
      separatorBuilder: (context, index) => const SizedBox(width: 16),
      itemBuilder: (context, index) => Align(
        alignment: Alignment.topCenter,
        child: _PopularMovieCard(rank: index + 1, movie: movies[index]),
      ),
    );
  }
}

/// 인기 영화가 없거나 불러오지 못했을 때 — 안내 문구와 (실패 시) 다시 시도
class _PopularMessage extends StatelessWidget {
  const _PopularMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}

/// 전체보기 텍스트 버튼 — 67.93 x 24, gap 4, #4F378A
class _SeeAllButton extends StatelessWidget {
  const _SeeAllButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Manrope 500 / 16 / 24
          Text(
            '전체보기',
            style: textTheme.titleMedium?.copyWith(
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 4),
          // 아이콘 4.93 x 8
          SvgPicture.asset(
            'assets/icons/chevron_right.svg',
            width: 4.933,
            height: 8,
            colorFilter: ColorFilter.mode(
              colors.onPrimaryContainer,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}

/// 인기 영화 카드 — 공통 [MovieCard], 140 x 256
/// 포스터 140 x 200 (radius 16) + 마진 12 + 제목 24 + 별점 영역 20
class _PopularMovieCard extends StatelessWidget {
  const _PopularMovieCard({required this.rank, required this.movie});

  final int rank;
  final TmdbMovieDto movie;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 140,
      child: MovieCard(
        movieId: movie.id,
        title: movie.title,
        poster: TmdbPosterImage(
          posterPath: movie.posterPath,
          // 크기는 카드의 AspectRatio(140:200)가 정하므로 가득 채웁니다.
          width: double.infinity,
          height: double.infinity,
        ),
        posterAspectRatio: 140 / 200,
        posterRadius: 16,
        // 순위 칩 — 24 x 26, 배경 #00000099, border 1px #FFFFFF1A
        badge: Positioned(
          left: 8,
          top: 8,
          child: PosterBadge(
            label: '$rank',
            backgroundColor: AppColors.rankChip,
            foregroundColor: AppColors.onImage,
            borderColor: AppColors.rankChipOutline,
          ),
        ),
        // 별점 영역 — padding-top 4, 내부 16, gap 4
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                // 별 11.67 x 11.08, #C9A74D
                SvgPicture.asset(
                  'assets/icons/rating_star_filled.svg',
                  width: 11.667,
                  height: 11.083,
                  colorFilter: ColorFilter.mode(
                    colors.tertiary,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 4),
                // Manrope 400 / 12 / 16, #494551
                // Figma 홈 카드는 10점 만점(9.6) — TMDB 평점도 10점 만점이라 그대로 표시
                Text(
                  movie.voteAverage.toStringAsFixed(1),
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
