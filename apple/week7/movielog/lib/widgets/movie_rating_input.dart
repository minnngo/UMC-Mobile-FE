import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 사용자가 직접 별점을 선택하는 위젯 (0.5점 단위)
///
/// W3-05 Figma: 별 하나 36.14 x 34.37, 별 사이 간격 11.86 (중심 간격 48)
/// 선택한 별 #6750A4, 선택하지 않은 별 #D9D3DF — 반 별은 왼쪽만 #6750A4
class MovieRatingInput extends StatelessWidget {
  const MovieRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  final double rating;
  final ValueChanged<double> onChanged;

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
          minRating: 0.5,
          allowHalfRating: true,
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
