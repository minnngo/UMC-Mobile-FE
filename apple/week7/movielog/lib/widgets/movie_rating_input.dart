import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 사용자가 직접 별점을 선택하는 위젯 (1점 단위)
///
/// 7주차 서버 연동 — v6 score는 1~5 정수라 반 점을 고를 수 없게 막습니다.
/// 반 점을 조용히 toInt()하지 않고 입력 단계에서 정수만 선택하게 합니다.
/// 값 타입은 여전히 double(1.0, 2.0 …)이므로 서버로 보내기 전 validateServerScore로 한 번 더 확인합니다.
///
/// W3-05 Figma: 별 하나 36.14 x 34.37, 별 사이 간격 11.86 (중심 간격 48)
/// 선택한 별 #6750A4, 선택하지 않은 별 #D9D3DF
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.enabled = true,
  });

  final double rating;
  final ValueChanged<double> onChanged;

  /// false면 탭·드래그를 무시합니다. (저장 중)
  final bool enabled;

  static const double _starWidth = 36.14;
  static const double _starHeight = 34.37;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // RatingBar는 별 하나를 정사각형(36.14)으로 그리므로, 실제 별 높이(34.37)만 차지하도록 감쌉니다.
    return SizedBox(
      height: _starHeight,
      child: OverflowBox(
        maxHeight: _starWidth,
        child: RatingBar.builder(
          initialRating: rating,
          minRating: 1,
          allowHalfRating: false,
          ignoreGestures: !enabled,
          itemCount: 5,
          itemSize: _starWidth,
          itemPadding: const EdgeInsets.symmetric(
            horizontal: (48 - _starWidth) / 2,
          ),
          // 선택하지 않은 부분은 같은 별 모양을 이 색으로 칠합니다.
          unratedColor: AppColors.ratingUnrated,
          // 누르거나 드래그하는 동안 별 주위에 생기는 빛 효과(기본 파란색)를 끕니다.
          glow: false,
          itemBuilder: (context, index) {
            return SvgPicture.asset(
              'assets/icons/rating_star_filled.svg',
              width: _starWidth,
              height: _starWidth * 760 / 800,
              colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
            );
          },
          onRatingUpdate: onChanged,
        ),
      ),
    );
  }
}
