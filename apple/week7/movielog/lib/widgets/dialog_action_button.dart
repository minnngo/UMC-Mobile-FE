import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Dialog 하단 버튼 — W5-01 재시도 Dialog에서 꺼내 W7 평점·삭제 Dialog와 함께 씁니다.
///
/// - 기본(primary): 배경 #6750A4, 글자 흰색
/// - 보조(primary: false): 배경 #F4F0FA, 글자 #6750A4 — 취소
/// - 통신 중([isLoading]): 배경 #79747E + 흰색 로딩 표시 (MovieLogButton과 같은 규칙)
/// - 비활성([onPressed]가 null): 기본은 #CCC2DC, 보조는 그대로 두고 누를 수 없음
///
/// [borderRadius]가 null이면 양끝이 둥근 pill입니다.
class DialogActionButton extends StatelessWidget {
  const DialogActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.isLoading = false,
    this.height = 52,
    this.borderRadius,
    this.textStyle = const TextStyle(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w700,
    ),
  });

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool isLoading;
  final double height;
  final double? borderRadius;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = primary ? colors.primary : AppColors.retryCancelButton;
    final foreground = primary ? colors.onPrimary : colors.primary;
    final radius = borderRadius;

    return SizedBox(
      height: height,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: isLoading
              ? AppColors.buttonLoading
              : (primary ? AppColors.primaryDisabled : background),
          disabledForegroundColor: primary ? colors.onPrimary : foreground,
          shape: radius == null
              ? const StadiumBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radius),
                ),
          padding: EdgeInsets.zero,
          textStyle: textStyle,
        ),
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
