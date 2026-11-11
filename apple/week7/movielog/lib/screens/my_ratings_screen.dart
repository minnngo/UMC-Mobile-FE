import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/rating_dto.dart';
import '../data/models/rating_with_movie.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../view_models/my_ratings_view_model.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/movie_list_states.dart';
import '../widgets/dialog_action_button.dart';
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
///
/// W7-CH 다중 삭제 — 카드를 길게 누르면 선택 모드가 됩니다.
/// - 위: "N개 선택됨 / 취소", 아래: "선택한 N개 삭제"
/// - 삭제 중에는 [Stack]으로 화면 전체를 반투명 배경 + 로딩으로 덮어 터치를 막고,
///   [PopScope]로 뒤로가기도 막습니다. 선택 모드에서 뒤로가기는 선택만 취소합니다.
class MyRatingsScreen extends StatelessWidget {
  const MyRatingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyRatingsViewModel>(
      builder: (context, viewModel, child) {
        final selecting =
            viewModel.isSelecting &&
            viewModel.status == MyRatingsLoadStatus.success;

        return PopScope(
          canPop: !viewModel.isSelecting && !viewModel.isBulkDeleting,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !viewModel.isBulkDeleting) {
              viewModel.cancelSelection();
            }
          },
          child: Stack(
            children: [
              Scaffold(
                appBar: const CommonAppBar(
                  title: '내가 등록한 평점',
                  titleStyle: AppTheme.appBarTitleBold,
                ),
                body: _body(context, viewModel, selecting),
                bottomNavigationBar: selecting
                    ? _BulkDeleteBar(
                        count: viewModel.selectedIds.length,
                        onPressed: () => onBulkDeletePressed(context),
                      )
                    : null,
              ),
              // 다중 삭제 중 — 화면 전체(헤더 포함)를 덮어 다른 동작을 막습니다.
              if (viewModel.isBulkDeleting) const _BlockingIndicator(),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    MyRatingsViewModel viewModel,
    bool selecting,
  ) {
    if (selecting) return _SelectableRatingsList(viewModel: viewModel);
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
        onLongPress: viewModel.startSelection,
      ),
    };
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
  const _MyRatingsList({
    required this.ratings,
    required this.canModify,
    required this.onLongPress,
  });

  final List<RatingWithMovie> ratings;
  final bool canModify;

  /// 길게 누르면 그 평점을 선택한 채로 다중 삭제 모드를 시작합니다.
  final ValueChanged<int> onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      itemCount: ratings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final entry = ratings[index];
        final card = _RatingCard(
          entry: entry,
          // 목록 항목은 RatingWithMovie — 수정·삭제에는 서버 평점(entry.rating)을 넘깁니다.
          onEdit: canModify ? () => onEditPressed(context, entry.rating) : null,
          onDelete: canModify
              ? () => onDeletePressed(context, entry.rating)
              : null,
        );
        if (!canModify) return card;
        return GestureDetector(
          onLongPress: () => onLongPress(entry.rating.ratingId),
          child: card,
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
          if (hasActions) ...[
            const SizedBox(width: 8),
            // 수정·삭제 (W7-REQ) — 카드 안쪽 위에서 9, 오른쪽에서 1, 버튼 사이 8
            Padding(
              padding: const EdgeInsets.only(top: 9, right: 1),
              child: Column(
                children: [
                  _CardActionButton(
                    label: '수정',
                    backgroundColor: AppColors.ratingEditButton,
                    foregroundColor: AppColors.primary,
                    onPressed: onEdit,
                  ),
                  const SizedBox(height: 8),
                  _CardActionButton(
                    label: '삭제',
                    backgroundColor: AppColors.ratingDeleteButton,
                    foregroundColor: AppColors.error,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 평점 카드 수정·삭제 버튼 — 63 x 35, 글자 Manrope 700 / 13 / 100% 가운데 (W7-REQ)
/// - 수정: 배경 #F0EAF8, 글자 #6750A4
/// - 삭제: 배경 #FFF2F0, 글자 #B3261E
class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;

  static const Size size = Size(63, 35);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: size,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: size,
          padding: EdgeInsets.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: AppTheme.movieLogButton,
          // 모서리 반경은 Figma 수치가 없어 시안 비율로 추정했습니다.
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label),
      ),
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

/// 평점 삭제 확인 Dialog (W7-REQ 평점 삭제 확인)
///
/// 삭제 요청 중에는 버튼 로딩과 [PopScope]로 Dialog가 닫히지 않게 합니다.
/// 실패하면 닫지 않고 서버 문구를 보여줘 다시 시도하거나 취소할 수 있게 둡니다.
class _DeleteRatingDialog extends StatefulWidget {
  const _DeleteRatingDialog({
    this.title = '평점을 삭제할까요?',
    required this.onConfirm,
  });

  final String title;

  /// null이면 요청 없이 확인 결과(true)만 돌려줍니다.
  /// 다중 삭제는 화면 전체 로딩으로 진행하므로 Dialog 안에서 요청하지 않습니다.
  final Future<void> Function()? onConfirm;

  @override
  State<_DeleteRatingDialog> createState() => _DeleteRatingDialogState();
}

class _DeleteRatingDialogState extends State<_DeleteRatingDialog> {
  bool _isDeleting = false;
  String? _errorText;

  Future<void> _onConfirm() async {
    final onConfirm = widget.onConfirm;
    if (onConfirm == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isDeleting = true;
      _errorText = null;
    });
    try {
      await onConfirm();
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
      // W5-01 재시도 Dialog 틀 재사용 — 흰 배경, 반경 28, 화면 좌우 32 (W7-REQ)
      child: Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 40, 26, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목 — 높이 27, Manrope 700 / 20, #25232A
              SizedBox(
                height: 27,
                child: Center(
                  child: Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: AppTheme.dialogTitle,
                  ),
                ),
              ),
              const SizedBox(height: 13),
              const Text(
                '삭제한 평점은 복구할 수 없습니다.',
                textAlign: TextAlign.center,
                style: AppTheme.dialogBody,
              ),
              if (_errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  _errorText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 44),
              // 버튼 — 높이 44, 반경 8, 간격 24 / 취소 #F4F0FA, 삭제 #6750A4
              Row(
                children: [
                  Expanded(
                    child: DialogActionButton(
                      label: '취소',
                      primary: false,
                      height: 44,
                      borderRadius: 8,
                      onPressed: _isDeleting
                          ? null
                          : () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: DialogActionButton(
                      label: '삭제',
                      height: 44,
                      borderRadius: 8,
                      isLoading: _isDeleting,
                      onPressed: _onConfirm,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 다중 삭제 — 확인 Dialog를 거친 뒤 화면 전체 로딩으로 하나씩 삭제합니다.
Future<void> onBulkDeletePressed(BuildContext context) async {
  final viewModel = context.read<MyRatingsViewModel>();
  final total = viewModel.selectedIds.length;
  if (total == 0) return;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) =>
        _DeleteRatingDialog(title: '선택한 $total개 평점을 삭제할까요?', onConfirm: null),
  );
  if (!context.mounted || confirmed != true) return;

  final failed = await viewModel.deleteSelected();
  if (!context.mounted) return;
  if (failed == 0) {
    _showSavedMessage(context, viewModel, '$total개 평점을 삭제했습니다.');
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('$total개 중 $failed개를 삭제하지 못했습니다. 선택된 평점을 다시 삭제해 주세요.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// 선택 모드 목록 (W7-CH) — 위에 "N개 선택됨 / 취소", 카드마다 체크박스
class _SelectableRatingsList extends StatelessWidget {
  const _SelectableRatingsList({required this.viewModel});

  final MyRatingsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final ratings = viewModel.ratings;
    final selected = viewModel.selectedIds;
    const headerStyle = TextStyle(
      fontSize: 13,
      height: 1,
      fontWeight: FontWeight.w700,
      color: AppColors.primary,
    );

    return Column(
      children: [
        // N개 선택됨 / 취소 — 좌우 22, 헤더 아래 약 38
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 10, 0),
          child: Row(
            children: [
              Expanded(
                child: Text('${selected.length}개 선택됨', style: headerStyle),
              ),
              TextButton(
                onPressed: viewModel.cancelSelection,
                style: TextButton.styleFrom(textStyle: headerStyle),
                child: const Text('취소'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            itemCount: ratings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 18),
            itemBuilder: (context, index) {
              final entry = ratings[index];
              final id = entry.rating.ratingId;
              return _SelectableRatingCard(
                entry: entry,
                selected: selected.contains(id),
                onTap: () => viewModel.toggleSelection(id),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 선택 모드 카드 — 높이 124, 테두리는 평점 카드(W6-02)와 같음
/// 체크박스 26 (왼쪽 16) + "영화 제목 · 별점 N" + 후기
class _SelectableRatingCard extends StatelessWidget {
  const _SelectableRatingCard({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final RatingWithMovie entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    final title = entry.movie?.title ?? '영화 #${rating.movieId}';
    final comment = rating.comment;

    return Semantics(
      checked: selected,
      child: Material(
        color: AppColors.ratingCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.ratingCardBorder, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 124),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  SizedBox(
                    width: AppTheme.checkboxSize,
                    height: AppTheme.checkboxSize,
                    child: Checkbox(value: selected, onChanged: (_) => onTap()),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$title · 별점 ${rating.score}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.ratingCardTitle,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 하단 "선택한 N개 삭제" — 높이 48 pill, 좌우 22. 선택이 없으면 비활성
class _BulkDeleteBar extends StatelessWidget {
  const _BulkDeleteBar({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
        child: DialogActionButton(
          label: '선택한 $count개 삭제',
          height: 48,
          onPressed: count > 0 ? onPressed : null,
        ),
      ),
    );
  }
}

/// 다중 삭제 중 화면 전체를 덮는 로딩 (W7-CH Stack 인디케이터)
///
/// [ModalBarrier]가 아래 화면의 터치를 모두 막고, 가운데에 흰 로딩 표시를 둡니다.
class _BlockingIndicator extends StatelessWidget {
  const _BlockingIndicator();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          dismissible: false,
          color: Colors.black.withValues(alpha: 0.32),
        ),
        Center(
          child: Semantics(
            label: '삭제 중',
            child: const SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
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
