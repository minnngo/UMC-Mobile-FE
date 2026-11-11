import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 여러 화면이 함께 쓰는 공용 버튼 — 높이 44, radius 12, Manrope 700 / 13 (W6-01)
///
/// 상태는 화면(ViewModel)이 정해서 넘기고, 버튼은 그대로 표시만 합니다.
/// - 기본: [onPressed]가 있고 [isLoading]이 false — 배경 #6750A4
/// - 통신 중: [isLoading]이 true — 배경 #79747E + 가운데 로딩 표시 18x18
/// - 비활성: [onPressed]가 null — 배경 #CCC2DC (테마 기본값)
///
/// 너비는 [width]로 정합니다.
/// - null: 글자 길이에 맞춘 Intrinsic 너비 — 입력창 옆 중복 확인 버튼처럼 좁은 자리
/// - double.infinity: 부모가 허용하는 최대 너비 — Form 아래 가입하기 버튼처럼 넓은 자리.
///   너비 제약이 없는 Row 안에서는 기준이 없어 오류가 나므로 Expanded 등으로 먼저 감쌉니다.
/// - 숫자: 화면 크기와 관계없이 항상 같은 너비
class MovieLogButton extends StatelessWidget {
  const MovieLogButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  static const double _height = 44;

  bool get _disabled => isLoading || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      height: _height,
      child: ElevatedButton(
        onPressed: _disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          // 테마 기본값(높이 56, 상하 패딩 16)을 44 높이에 맞게 줄입니다.
          minimumSize: const Size(0, _height),
          // 중복 확인 버튼 102 = 글자 51 + 좌우 25.5 (W6-01)
          padding: const EdgeInsets.symmetric(horizontal: 25.5),
          textStyle: AppTheme.movieLogButton,
          // 통신 중일 때만 회색, 그 밖의 비활성은 테마 색(#CCC2DC)을 그대로 씁니다.
          disabledBackgroundColor: isLoading ? AppColors.buttonLoading : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // 통신 중에는 글자와 로딩 표시 중 하나만 그립니다.
        child: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
