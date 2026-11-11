import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/movielog_button.dart';
import '../widgets/rating_dialog.dart';
import '../widgets/tmdb_poster_image.dart';

/// 마이페이지 → 내가 등록한 평점 화면입니다.
///
/// [MyRatingsViewModel]의 상태를 [Consumer]로 구독해 그대로 그립니다.
/// - 불러오는 중: [MovieListLoading]
/// - 실패: [MovieListError] (상태 코드별 안내 + 다시 시도)
/// - 빈 목록: [_MyRatingsEmpty]
/// - 성공: 평점 카드 목록 (W6-02) — TMDB 영화를 못 찾은 평점도 placeholder로 남깁니다.
///
/// 회원가입으로 얻은 학습용 memberId의 평점을 읽습니다. (로그인 인증은 아님)
/// 하단 NavigationBar 없이 root Navigator 위에 열립니다.
///
/// 7주차 — 본인 평점([MyRatingsViewModel.canModify])에만 수정·삭제 버튼을 보여줍니다.
/// - 수정: 기존 별점·코멘트를 채운 [RatingDialog]
/// - 삭제: 되돌릴 수 없으므로 확인 Dialog를 거쳐서만 요청
/// - 저장 성공 후 재조회만 실패하면 [MyRatingsViewModel.refreshWarning]과 조회 다시 시도
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
              // 저장 후 재조회 실패면 "저장은 완료됨"을 함께 알려 조회만 다시 하게 합니다.
              message: viewModel.refreshWarning ?? viewModel.message,
              onRetry: viewModel.load,
            ),
            MyRatingsLoadStatus.empty => const _MyRatingsEmpty(),
            MyRatingsLoadStatus.success => _MyRatingsList(
              ratings: viewModel.ratings,
              canModify: viewModel.canModify,
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
  const _MyRatingsList({required this.ratings, required this.canModify});

  final List<RatingWithMovie> ratings;
  final bool canModify;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      itemCount: ratings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final entry = ratings[index];
        return _RatingCard(
          entry: entry,
          // 목록 항목은 RatingWithMovie — 수정·삭제에는 서버 평점(entry.rating)을 넘깁니다.
          onEdit: canModify ? () => onEditPressed(context, entry.rating) : null,
          onDelete: canModify
              ? () => onDeletePressed(context, entry.rating)
              : null,
        );
      },
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
  const _RatingCard({required this.entry, this.onEdit, this.onDelete});

  final RatingWithMovie entry;

  /// 둘 다 null이면(본인 평점이 아니면) 수정·삭제 버튼을 그리지 않습니다.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

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

    final hasActions = onEdit != null || onDelete != null;

    final card = Container(
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
                  Padding(
                    // 오른쪽 위 수정·삭제 버튼과 제목이 겹치지 않게 비워 둡니다.
                    padding: EdgeInsets.only(right: hasActions ? 72 : 0),
                    child: Text(
                      movie?.title ?? '영화 #${rating.movieId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.ratingCardTitle,
                    ),
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

    if (!hasActions) return card;
    // 카드 크기(W6-02)는 그대로 두고 오른쪽 위에 버튼을 겹쳐 둡니다.
    return Stack(
      children: [
        card,
        Positioned(
          top: 6,
          right: 6,
          child: Row(
            children: [
              _CardActionButton(label: '수정', onPressed: onEdit),
              _CardActionButton(label: '삭제', onPressed: onDelete),
            ],
          ),
        ),
      ],
    );
  }
}

/// 평점 카드 오른쪽 위의 작은 글자 버튼 (수정 / 삭제)
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(36, 32),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: AppTheme.ratingCardScore,
      ),
      child: Text(label),
    );
  }
}

/// 수정 — 기존 별점·코멘트를 채운 [RatingDialog]를 다시 엽니다.
///
/// comment가 null이면 코멘트 칸은 빈 칸으로 시작합니다.
/// Dialog 안에서 값을 바꾸는 동안 [rating] 객체는 그대로라 취소해도 복구할 것이 없습니다.
/// 저장 실패는 [MyRatingsViewModel.updateRating]이 던져 Dialog 안에서 오류 문구로 보여줍니다.
Future<void> onEditPressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 저장 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => RatingDialog(
      title: '평점을 수정할까요?',
      initialScore: rating.score,
      initialComment: rating.comment,
      onSubmit: (score, comment) => viewModel.updateRating(
        ratingId: rating.ratingId,
        score: score,
        comment: comment,
      ),
    ),
  );
  if (!context.mounted || saved != true) return;
  _showSavedMessage(context, viewModel, '평점을 수정했습니다.');
}

/// 삭제 — 되돌릴 수 없으므로 확인 Dialog에서 "삭제"를 눌러야만 요청합니다.
/// "취소"는 요청을 보내지 않습니다.
Future<void> onDeletePressed(BuildContext context, RatingDto rating) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final deleted = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // 삭제 중 바깥 탭으로 닫히는 것도 막습니다.
    builder: (_) => _DeleteRatingDialog(
      onConfirm: () => viewModel.deleteRating(rating.ratingId),
    ),
  );
  // deleted는 실제로 삭제까지 마쳤을 때만 true입니다.
  if (!context.mounted || deleted != true) return;
  _showSavedMessage(context, viewModel, '평점을 삭제했습니다.');
}

/// 저장 성공 안내 — 재조회가 실패했으면 화면의 refreshWarning이 대신 안내하므로 띄우지 않습니다.
void _showSavedMessage(
  BuildContext context,
  MyRatingsViewModel viewModel,
  String message,
) {
  if (viewModel.refreshWarning != null) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

/// 평점 삭제 확인 Dialog (W7-04)
///
/// 삭제 요청 중에는 버튼 로딩과 [PopScope]로 Dialog가 닫히지 않게 합니다.
/// 실패하면 닫지 않고 서버 문구를 보여줘 다시 시도하거나 취소할 수 있게 둡니다.
class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({required this.onConfirm});

  final Future<void> Function() onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  Future<void> _onConfirm() async {
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await widget.onConfirm();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _errorText = error is WriteFailure
            ? error.message
            : '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isDeleting,
      child: AlertDialog(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          '평점을 삭제할까요?',
          textAlign: TextAlign.center,
          style: AppTheme.dialogTitle,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('삭제한 평점은 복구할 수 없습니다.', textAlign: TextAlign.center),
            if (_errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorText!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.error, fontSize: 13),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: MovieLogButton(
                  label: '취소',
                  width: double.infinity,
                  onPressed: _isDeleting
                      ? null
                      : () => Navigator.pop(context, false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MovieLogButton(
                  label: '삭제',
                  width: double.infinity,
                  isLoading: _isDeleting,
                  onPressed: _isDeleting ? null : _onConfirm,
                ),
              ),
            ],
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

/// 학습용 회원가입 전에 "내가 등록한 평점"에 들어왔을 때의 안내 화면입니다.
///
/// 다른 회원의 path(6주차 고정 ID 1)로 요청하지 않도록 API를 호출하지 않습니다.
class MyRatingsSignUpRequired extends StatelessWidget {
  const MyRatingsSignUpRequired({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CommonAppBar(
        title: '내가 등록한 평점',
        titleStyle: AppTheme.appBarTitleBold,
      ),
      body: Center(child: Text('학습용 회원가입이 필요합니다.')),
    );
  }
}
