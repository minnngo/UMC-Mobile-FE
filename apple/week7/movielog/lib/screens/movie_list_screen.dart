import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/tmdb_genre_dto.dart';
import '../theme/app_shadows.dart';
import '../view_models/movie_list_view_model.dart';
import '../widgets/app_header.dart';
import '../widgets/movie_grid.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movie_retry_dialog.dart';

/// W3-02 영화 목록 화면입니다.
///
/// 5주차부터 [MovieListViewModel]의 상태를 [Consumer]로 구독해 그대로 그립니다.
/// 화면은 API를 직접 부르지 않고, 장르 선택·다시 시도만 ViewModel에 전달합니다.
/// - 불러오는 중: [MovieListLoading] (장르 칩은 누를 수 없음)
/// - 성공 목록은 당겨서 새로고침([RefreshIndicator]) — 새로고침 중에도 기존 목록 유지
/// - 실패: [MovieListError] (다시 시도)
/// - 빈 목록: [MovieListEmpty]
/// - 성공: [MovieGrid] — TMDB Discover 최대 30개
///
/// 장르를 바꾸다 실패했는데 보여주던 목록이 있으면, 목록을 유지한 채 [MovieRetryDialog]를 띄웁니다.
class MovieListScreen extends StatefulWidget {
  const MovieListScreen({super.key});

  @override
  State<MovieListScreen> createState() => _MovieListScreenState();
}

class _MovieListScreenState extends State<MovieListScreen> {
  MovieListViewModel? _viewModel;
  bool _retryDialogOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dialog는 화면을 다시 그리는 일이 아니라 한 번 띄우는 일이라 build 대신 listener에서 처리합니다.
    final viewModel = context.read<MovieListViewModel>();
    if (viewModel != _viewModel) {
      _viewModel?.removeListener(_showRetryDialogIfNeeded);
      _viewModel = viewModel..addListener(_showRetryDialogIfNeeded);
    }
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_showRetryDialogIfNeeded);
    super.dispose();
  }

  Future<void> _showRetryDialogIfNeeded() async {
    final viewModel = _viewModel;
    if (viewModel == null ||
        !viewModel.retryDialogVisible ||
        _retryDialogOpen) {
      return;
    }

    _retryDialogOpen = true;
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => const MovieRetryDialog(),
    );
    _retryDialogOpen = false;
    if (!mounted) return;

    // 바깥을 눌러 닫으면(null) 취소와 같습니다.
    if (retry ?? false) {
      viewModel.retryLastRequest();
    } else {
      viewModel.cancelRetry();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader.tab(title: '영화'),
      body: Consumer<MovieListViewModel>(
        builder: (context, viewModel, child) {
          final content = switch (viewModel.status) {
            MovieListLoadStatus.idle ||
            MovieListLoadStatus.loading => const MovieListLoading(),
            MovieListLoadStatus.error => MovieListError(
              message: viewModel.message,
              onRetry: () => context.read<MovieListViewModel>().loadInitial(),
            ),
            MovieListLoadStatus.empty => const MovieListEmpty(),
            // Pull to Refresh — Flutter 기본 RefreshIndicator
            MovieListLoadStatus.success => RefreshIndicator(
              onRefresh: () => context.read<MovieListViewModel>().refresh(),
              // 목록 전체를 불러오는 중에는 당겨도 새로고침하지 않습니다.
              notificationPredicate: (notification) =>
                  !viewModel.isLoading && notification.depth == 0,
              child: MovieGrid(
                movies: viewModel.movies,
                genreNames: viewModel.genreNames,
              ),
            ),
          };

          // 장르 목록을 아직 못 불러왔으면 칩 없이 상태만 보여줍니다.
          if (viewModel.genres.isEmpty) return content;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 필터 칩 영역 — 358 x 40, 헤더 아래 8, 그리드와 간격 16
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _GenreFilterBar(
                  genres: viewModel.genres,
                  selectedGenreId: viewModel.selectedGenreId,
                  enabled: !viewModel.isRequesting,
                  onSelected: (genreId) =>
                      context.read<MovieListViewModel>().selectGenre(genreId),
                ),
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }
}

/// 필터 칩 영역 — 358 x 40, 가로 스크롤
/// 칩 높이는 32이고 아래 8은 그림자가 잘리지 않도록 남겨 둡니다.
/// 맨 앞 "전체"는 장르 id null — with_genres 없이 조회합니다.
class _GenreFilterBar extends StatelessWidget {
  const _GenreFilterBar({
    required this.genres,
    required this.selectedGenreId,
    required this.enabled,
    required this.onSelected,
  });

  static const _allGenresLabel = '전체';

  final List<TmdbGenreDto> genres;
  final int? selectedGenreId;

  /// false면 칩을 누를 수 없습니다. (Discover 요청 중)
  final bool enabled;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: genres.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _GenreChip(
              label: _allGenresLabel,
              selected: selectedGenreId == null,
              enabled: enabled,
              onTap: () => onSelected(null),
            );
          }

          final genre = genres[index - 1];
          final selected = genre.id == selectedGenreId;
          return _GenreChip(
            label: genre.name,
            selected: selected,
            enabled: enabled,
            // 선택된 장르를 다시 누르면 선택 해제 → 전체
            onTap: () => onSelected(selected ? null : genre.id),
          );
        },
      ),
    );
  }
}

/// 필터 칩 하나 — 높이 32, radius 9999, padding 8 / 16, box-shadow 0 1 2 #0000000D
/// 선택: 배경 #6750A4, 글자 #FFFFFF / 미선택: 배경 #E6E0E9, 글자 #494551
class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: selected,
      enabled: enabled,
      button: true,
      // 누를 수 없을 때는 선택되지 않은 칩을 흐리게 표시
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.38,
        child: DecoratedBox(
          decoration: const ShapeDecoration(
            shape: StadiumBorder(),
            shadows: AppShadows.card,
          ),
          child: Material(
            color: selected ? colors.primary : colors.surfaceContainerHighest,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                // Manrope 500 / 12 / 16, center
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
