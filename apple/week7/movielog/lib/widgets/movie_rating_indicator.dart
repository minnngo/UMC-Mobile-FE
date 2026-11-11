import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

/// 수정할 필요가 없는 별점(내 별점, 평균 별점 등)을 읽기 전용으로 표시
/// 0.5 단위로 제한되지 않아 4.3 같은 값도 그대로 표시합니다.
///
/// 별 #6750A4, 채워지지 않은 부분 #D9D3DF (평점 Dialog와 같은 스타일)
/// 사용처: 영화 상세 평균 평점
class MovieRatingIndicator extends StatelessWidget {
  const MovieRatingIndicator({
    super.key,
    required this.rating,
    this.itemSize = 20,
    this.showValue = true,
  });

  final double rating;
  final double itemSize;

  /// 별 옆에 숫자(예: 4.3)를 함께 표시할지 여부
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingBarIndicator(
          rating: rating,
          itemCount: 5,
          itemSize: itemSize,
          unratedColor: AppColors.ratingUnrated,
          itemBuilder: (context, index) {
            // 별 모양(가로 800 : 세로 760)을 정사각형 칸 안에 맞춰 그립니다.
            return SvgPicture.asset(
              'assets/icons/rating_star_filled.svg',
              width: itemSize,
              height: itemSize * 760 / 800,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.primary,
                BlendMode.srcIn,
              ),
            );
          },
        ),
        if (showValue) ...[
          const SizedBox(width: 8),
          Text(rating.toStringAsFixed(1)),
        ],
      ],
    );
  }
}
