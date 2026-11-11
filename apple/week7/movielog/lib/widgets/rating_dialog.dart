import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'movie_rating_input.dart';

/// 별점을 선택하는 커스텀 Dialog
/// 확인을 누르면 선택한 별점을 showDialog의 반환값으로 돌려줌
///
/// - W3-05 (Required): 342 x 212 — 제목, 별점, 확인
/// - W3-06 (Challenge): 342 x 260 — 별점을 고르면 '다시 선택하기'가 나타나 0점으로 되돌림
/// - 별을 고르기 전에는 확인 버튼이 비활성
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.movieId});

  /// 평점을 남길 영화의 TMDB id — 평점 저장 API의 movieId로 그대로 보냅니다.
  final int? movieId;

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  double rating = 0;

  /// 다시 선택하기를 누를 때마다 바뀌어 별점 입력을 처음 상태(0점)로 새로 만듭니다.
  /// RatingBar는 처음 받은 값만 그리기 때문에 key를 바꿔야 화면이 초기화됩니다.
  int _resetCount = 0;

  void _reset() {
    setState(() {
      rating = 0;
      _resetCount++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 컨테이너 — 너비 342 (좌우 24 여백), padding 24, 배경 #FAF9F5
    return Dialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      // 모서리 반경은 Figma 수치가 없어 M3 Dialog 기본값(28)을 사용합니다.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 영화는 어떠셨나요? — 박스 높이 27, Manrope 700 / 20, #25232A
              const SizedBox(
                height: 27,
                child: Center(
                  child: Text(
                    '영화는 어떠셨나요?',
                    textAlign: TextAlign.center,
                    style: AppTheme.dialogTitle,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: MovieRatingInput(
                  key: ValueKey(_resetCount),
                  rating: rating,
                  onChanged: (value) {
                    setState(() {
                      rating = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 28.63),
              // 다시 선택하기 (Challenge) — 별점을 골랐을 때만 표시
              if (rating > 0) ...[
                SizedBox(
                  height: 19,
                  child: Center(
                    child: InkWell(
                      onTap: _reset,
                      borderRadius: BorderRadius.circular(4),
                      // Manrope 700 / 14, #6750A4
                      child: Text(
                        '다시 선택하기',
                        style: AppTheme.dialogTextAction.copyWith(
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 29),
              ],
              // 확인 버튼 — 294 x 48, 배경 #6750A4, Manrope 700 / 16 #FFFFFF
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  // 별을 고르기 전(0점)에는 확인 버튼을 끕니다. — 선택값과 버튼 상태가 함께 갱신
                  onPressed: rating > 0
                      ? () {
                          Navigator.pop(context, rating);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    // 비활성 — 배경 #CCC2DC (2주차 가입하기 비활성과 같은 토큰)
                    disabledBackgroundColor: AppColors.primaryDisabled,
                    disabledForegroundColor: colors.onPrimary,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    padding: EdgeInsets.zero,
                    textStyle: AppTheme.dialogAction,
                    // 모서리 반경은 Figma 수치가 없어 시안 비율로 추정했습니다.
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('확인'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
