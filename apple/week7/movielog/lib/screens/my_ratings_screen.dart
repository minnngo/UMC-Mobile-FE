import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → 내가 등록한 평점 화면입니다.
///
/// [MyRatingsViewModel]의 상태를 [Consumer]로 구독해 그대로 그립니다.
/// - 불러오는 중: [MovieListLoading]
/// - 실패: [MovieListError] (상태 코드별 안내 + 다시 시도)
/// - 빈 목록: [_MyRatingsEmpty]
/// - 성공: 평점 카드 목록 (W6-02) — TMDB 영화를 못 찾은 평점도 placeholder로 남깁니다.
///
/// 로그인이 없어 학습용 memberId 1의 샘플 평점을 읽기만 합니다.
/// 현재 사용자의 평점이라고 안내하거나 수정·삭제 버튼을 두지 않습니다.
/// 하단 NavigationBar 없이 root Navigator 위에 열립니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(
        title: '내가 등록한 평점',
        titleStyle: AppTheme.appBarTitleBold,
      ),
      body: Consumer<MyRatingsViewModel>(
        builder: (context, viewModel, child) {
          return switch (viewModel.status) {
            MyRatingsLoadStatus.idle ||
            MyRatingsLoadStatus.loading => const MovieListLoading(),
            MyRatingsLoadStatus.error => MovieListError(
              message: viewModel.message,
              onRetry: viewModel.load,
            ),
            MyRatingsLoadStatus.empty => const _MyRatingsEmpty(),
            MyRatingsLoadStatus.success => _MyRatingsList(
              ratings: viewModel.ratings,
            ),
          };
        },
      ),
    );
  }
}

class _MyRatingsEmpty extends StatelessWidget {
  const _MyRatingsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('아직 등록된 평점이 없습니다.'));
  }
}

/// 평점 카드 목록 — 헤더 아래 32, 좌우 20, 카드 사이 18 (W6-02)
class _MyRatingsList extends StatelessWidget {
  const _MyRatingsList({required this.ratings});

  final List<RatingWithMovie> ratings;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      itemCount: ratings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) => _RatingCard(entry: ratings[index]),
    );
  }
}

/// 평점 카드 하나 — 350 x 156, 배경 #FFFFFF, 테두리 2px #D9D3E1 (W6-02)
///
/// 안쪽 여백 16 — 포스터 82 x 124, 포스터와 글자 사이 16
/// - 영화 제목 (TMDB) — 못 찾으면 "영화 #movieId"
/// - 별점 4 / 5
/// - 후기 — null이면 그리지 않고, 영화도 못 찾았으면 "포스터 정보 없음"
/// - 등록일
class _RatingCard extends StatelessWidget {
  const _RatingCard({required this.entry});

  final RatingWithMovie entry;

  static const _posterSize = Size(82, 124);

  /// 예) 2026.09.06
  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}.${twoDigits(local.month)}.${twoDigits(local.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final movie = entry.movie;
    final comment = rating.comment ?? (movie == null ? '포스터 정보 없음' : null);

    return Container(
      // Container는 테두리 2를 안쪽 여백에 더하므로 14 + 2 = 바깥에서 16
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ratingCardBackground,
        border: Border.all(color: AppColors.ratingCardBorder, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _Poster(posterPath: movie?.posterPath, size: _posterSize),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              // 제목은 포스터 위에서 15 아래 (Figma top 127 - 112)
              padding: const EdgeInsets.only(top: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie?.title ?? '영화 #${rating.movieId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.ratingCardTitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '별점 ${rating.score} / 5',
                    style: AppTheme.ratingCardScore,
                  ),
                  if (comment != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      comment,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.ratingCardBody,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(rating.createdAt),
                    style: AppTheme.ratingCardBody,
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

/// 평점 카드 포스터 — 경로가 없으면 Figma처럼 아이콘 없는 연보라 칸만 그립니다.
class _Poster extends StatelessWidget {
  const _Poster({required this.posterPath, required this.size});

  final String? posterPath;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final path = posterPath;
    if (path == null || path.isEmpty) {
      return Container(
        key: const ValueKey('rating-poster-placeholder'),
        width: size.width,
        height: size.height,
        color: AppColors.ratingUnrated,
      );
    }
    return TmdbPosterImage(
      posterPath: path,
      width: size.width,
      height: size.height,
    );
  }
}
