import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/movie_detail.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/movie_rating_indicator.dart';
import '../widgets/pill_button.dart';
import '../widgets/poster_image.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/svg_icon_button.dart';
import '../widgets/tag_chip.dart';
import '../widgets/tmdb_poster_image.dart';
import '../view_models/movie_detail_view_model.dart';

/// W3-03 영화 상세 화면입니다.
///
/// 5주차부터 [movieId](TMDB id)로 [MovieDetailViewModel]이 불러온 상세를 보여줍니다.
/// [detail]을 직접 받으면(홈 추천 신작 Mock) 그대로 보여줍니다.
///
/// 화면은 의미 단위로 나뉩니다.
/// - [_DetailHeader] 뒤로가기, Cinema Archive, 공유
/// - [_HeroPoster] 2:3 히어로 이미지
/// - [_InfoSection] 제목, 연도·장르·러닝타임, 별점, 장르 칩
/// - [_SynopsisSection] 시놉시스
/// - [_ActionBar] 하단 고정 즐겨찾기·평점 남기기 버튼
class MovieDetailScreen extends StatefulWidget {
  const MovieDetailScreen({super.key, required this.movieId, this.detail});

  /// TMDB 영화 id — 평점 Dialog에 그대로 전달합니다.
  final int? movieId;

  /// 이미 가진 상세 정보 — null이면 [MovieDetailViewModel]의 상태를 구독합니다.
  final MovieDetail? detail;

  @override
  State<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  /// 즐겨찾기 여부 — 실제 API 연결은 8주차, 3주차에서는 화면 내부 상태만 바꿉니다.
  bool _bookmarked = false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _toggleBookmark() {
    setState(() => _bookmarked = !_bookmarked);
    _showMessage(_bookmarked ? '즐겨찾기에 추가했습니다.' : '즐겨찾기를 해제했습니다.');
  }

  Future<void> _rate() async {
    final rating = await showDialog<double>(
      context: context,
      builder: (context) => RatingDialog(movieId: widget.movieId),
    );
    // 바깥을 눌러 닫았거나 별을 고르지 않고 확인을 누른 경우
    if (!mounted || rating == null || rating < 0.5) return;
    _showMessage('평점 ${rating.toStringAsFixed(1)}점을 남겼습니다.');
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    if (detail != null) return _buildDetail(detail);

    return Consumer<MovieDetailViewModel>(
      builder: (context, viewModel, child) => switch (viewModel.status) {
        MovieDetailLoadStatus.idle ||
        MovieDetailLoadStatus.loading => const Scaffold(
          appBar: _DetailHeader(),
          body: Center(child: CircularProgressIndicator()),
        ),
        MovieDetailLoadStatus.error => Scaffold(
          appBar: const _DetailHeader(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(viewModel.message ?? '영화 정보를 불러오지 못했어요.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.read<MovieDetailViewModel>().load(),
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
        MovieDetailLoadStatus.success => _buildDetail(viewModel.detail!),
      },
    );
  }

  Widget _buildDetail(MovieDetail detail) {
    return Scaffold(
      appBar: const _DetailHeader(),
      body: ListView(
        children: [
          _HeroPoster(detail: detail),
          _InfoSection(detail: detail),
          _SynopsisSection(paragraphs: detail.synopsis),
        ],
      ),
      bottomNavigationBar: _ActionBar(
        bookmarked: _bookmarked,
        onBookmark: _toggleBookmark,
        onRate: _rate,
      ),
    );
  }
}

/// 상세 헤더 — 공통 [AppHeader]의 가운데 정렬형
/// 좌측 뒤로가기(32 x 32, left -8) · 가운데 Cinema Archive · 우측 공유(34 x 36)
class _DetailHeader extends StatelessWidget implements PreferredSizeWidget {
  const _DetailHeader();

  @override
  Size get preferredSize => const Size.fromHeight(AppHeader.height);

  void _back(BuildContext context) {
    // 앱을 상세 화면에서 바로 열었다면 돌아갈 화면이 없으므로 영화 목록으로 이동
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/movies');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppHeader(
      title: 'Cinema Archive',
      centerTitle: true,
      // Manrope 700 / 22 / 28, center, #6750A4
      titleStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.primary,
      ),
      // 좌측 아이콘 — 버튼 32 x 32, left -8, 아이콘 16 x 16 #6750A4
      leading: Transform.translate(
        offset: const Offset(-8, 0),
        child: SvgIconButton(
          asset: 'assets/icons/detail_arrow_back.svg',
          iconSize: const Size(16, 16),
          color: colors.primary,
          tooltip: '뒤로가기',
          onPressed: () => _back(context),
        ),
      ),
      // 우측 아이콘 — 버튼 34 x 36, 아이콘 18 x 20 #494551
      trailing: SvgIconButton(
        asset: 'assets/icons/detail_share.svg',
        iconSize: const Size(18, 20),
        color: colors.onSurfaceVariant,
        tooltip: '공유',
        onPressed: () {}, // 공유 기능은 아직 연결하지 않습니다.
      ),
    );
  }
}

/// 히어로 섹션 — 390 x 585 (2:3), 배경 #E3E2DF
/// Mock 영화는 에셋 이미지, TMDB 영화는 poster_path 이미지를 보여줍니다.
class _HeroPoster extends StatelessWidget {
  const _HeroPoster({required this.detail});

  final MovieDetail detail;

  @override
  Widget build(BuildContext context) {
    final heroAsset = detail.heroAsset;
    final backgroundColor = Theme.of(context).colorScheme.surfaceContainerHigh;

    return AspectRatio(
      aspectRatio: 2 / 3,
      child: heroAsset != null
          ? PosterImage(asset: heroAsset, backgroundColor: backgroundColor)
          : PosterImage(
              // poster_path가 없으면 TmdbPosterImage가 placeholder를 보여줍니다.
              image: TmdbPosterImage(
                posterPath: detail.posterPath,
                // 크기는 AspectRatio(2:3)가 정하므로 가득 채웁니다.
                width: double.infinity,
                height: double.infinity,
              ),
              backgroundColor: backgroundColor,
            ),
    );
  }
}

/// 인포 섹션 — 390 x 216, padding 24 / 16 / 40 / 16, gap 4
class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.detail});

  final MovieDetail detail;

  /// 2024 • 로맨스/드라마 • 124분 — 연도·장르가 없으면 빼고 표시합니다.
  String get _meta => [
    if (detail.year != null) '${detail.year}',
    if (detail.genres.isNotEmpty) detail.genres.join('/'),
    if (detail.runtimeMinutes != null) '${detail.runtimeMinutes}분',
  ].join(' • ');

  /// 1245 → 1,245
  static String _formatCount(int count) => count.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Manrope 400 / 14 / 20 / 0.25, #494551
    final captionStyle = textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목 — Manrope 500 / 28 / 36, #1B1C1A
          Text(
            detail.title,
            style: textTheme.headlineMedium?.copyWith(
              color: AppColors.detailText,
            ),
          ),
          const SizedBox(height: 4),
          Text(_meta, style: captionStyle),
          const SizedBox(height: 4),
          // 별점 섹션 — padding-top 12, gap 4
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              height: 24,
              child: Row(
                children: [
                  // 평균 평점 — RatingBarIndicator로 읽기 전용 표시, 별 하나 16.67
                  MovieRatingIndicator(
                    rating: detail.rating,
                    itemSize: 50 / 3,
                    showValue: false,
                  ),
                  const SizedBox(width: 4),
                  // 4.5 마진 — padding-left 8, Manrope 500 / 16 / 24 / 0.15, #1B1C1A
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      detail.rating.toStringAsFixed(1),
                      style: textTheme.titleMedium?.copyWith(
                        letterSpacing: 0.15,
                        color: AppColors.detailText,
                      ),
                    ),
                  ),
                  if (detail.reviewCount != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${_formatCount(detail.reviewCount!)})',
                      style: captionStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // 장르 칩 — padding-top 20, gap 8
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in detail.tags)
                  // 칩 하나 — 높이 28, padding 4 / 12, 배경 #E3E2DF
                  // 글자 Manrope 500 / 14 / 20 / 0.1, #494551
                  TagChip(
                    label: tag,
                    backgroundColor: colors.surfaceContainerHigh,
                    foregroundColor: colors.onSurfaceVariant,
                    textStyle: textTheme.titleSmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 시놉시스 섹션 — padding 16, gap 8, border-top 1px #CBC4D2
/// 본문 문단 사이 gap 26
class _SynopsisSection extends StatelessWidget {
  const _SynopsisSection({required this.paragraphs});

  final List<String> paragraphs;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Manrope 500 / 16 / 26 / 0.5, #494551
    const bodyStyle = AppTheme.synopsisBody;

    // Container는 테두리 두께(1)를 안쪽 여백에 더해 줘서 Figma 높이(563)와 맞습니다.
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Manrope 500 / 22 / 28, #1B1C1A
          Text(
            '시놉시스',
            style: textTheme.titleLarge?.copyWith(color: AppColors.detailText),
          ),
          const SizedBox(height: 8),
          // 줄거리(overview)가 없으면 안내 문구를 가운데에 표시
          if (paragraphs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('줄거리 정보가 없어요.', style: bodyStyle)),
            ),
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 26),
            Text(paragraphs[i], style: bodyStyle),
          ],
        ],
      ),
    );
  }
}

/// 하단 고정 액션 버튼 — 높이 81, padding 16, gap 8, 배경 #FAF9F5, border-top 1px #CBC4D2
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.bookmarked,
    required this.onBookmark,
    required this.onRate,
  });

  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 버튼 글자 — Manrope 500 / 14 / 20 / 0.1
    final labelStyle = Theme.of(context).textTheme.titleSmall;

    // Container는 테두리 두께(1)를 안쪽 여백에 더해 줘서 Figma 높이(81)와 맞습니다.
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Figma 너비 176 : 174
              Expanded(
                flex: 176,
                // 테두리형 — border 1px #6750A4, 아이콘 14 x 18
                child: PillButton(
                  label: '즐겨찾기',
                  // 즐겨찾기 상태는 제공된 북마크 아이콘(W3-REQ)을 사용합니다.
                  iconAsset: bookmarked
                      ? 'assets/icons/bookmark_filled.png'
                      : 'assets/icons/detail_bookmark.svg',
                  iconSize: const Size(14, 18),
                  color: colors.primary,
                  foregroundColor: colors.primary,
                  outlined: true,
                  textStyle: labelStyle,
                  selected: bookmarked,
                  onPressed: onBookmark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 174,
                // 채움형 — 배경 #6750A4, 아이콘 20 x 20 #FFFFFF, box-shadow 0 1 2 #0000000D
                child: PillButton(
                  label: '평점 남기기',
                  iconAsset: 'assets/icons/detail_rate_review.svg',
                  iconSize: const Size(20, 20),
                  color: colors.primary,
                  foregroundColor: colors.onPrimary,
                  textStyle: labelStyle,
                  shadows: AppShadows.card,
                  onPressed: onRate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
