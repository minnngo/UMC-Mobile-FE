import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// W5-01 영화 목록 요청 실패 재시도 Dialog (Challenge)
///
/// 326 x 282, 화면 좌우 32, padding 24 / 26 / 26 / 26
/// 다시 시도를 누르면 true, 취소·바깥을 누르면 false(null)를 showDialog 결과로 돌려줍니다.
class MovieRetryDialog extends StatelessWidget {
  const MovieRetryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // 버튼 글자 — Manrope 700 / 15
    const buttonTextStyle = TextStyle(
      fontSize: 15,
      height: 20 / 15,
      fontWeight: FontWeight.w700,
    );

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      // 모서리 반경은 Figma 수치가 없어 평점 Dialog와 같은 28을 사용합니다.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘 원 — 56 x 56, #F0EBF8 / 화살표 24, #6750A4
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.retryIconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restart_alt_rounded,
                size: 28,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 8),
            // 제목 — 높이 27, Manrope 700 / 20, #25232A
            const SizedBox(
              height: 27,
              child: Center(
                child: Text(
                  '영화를 불러오지 못했어요',
                  textAlign: TextAlign.center,
                  style: AppTheme.dialogTitle,
                ),
              ),
            ),
            const SizedBox(height: 13),
            // 안내 — 줄 높이 19, Manrope 400 / 14, #655F6C
            const Text(
              '네트워크 상태를 확인하고\n다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 19 / 14,
                fontWeight: FontWeight.w400,
                color: AppColors.retryDialogBody,
              ),
            ),
            const SizedBox(height: 38),
            // 버튼 — 126 x 52, 간격 22
            Row(
              children: [
                Expanded(
                  child: _DialogButton(
                    label: '취소',
                    backgroundColor: AppColors.retryCancelButton,
                    foregroundColor: colors.primary,
                    textStyle: buttonTextStyle,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 22),
                Expanded(
                  child: _DialogButton(
                    label: '다시 시도',
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    textStyle: buttonTextStyle,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog 버튼 하나 — 높이 52, 양끝이 둥근 pill
class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.textStyle,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final TextStyle textStyle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: const StadiumBorder(),
          padding: EdgeInsets.zero,
          textStyle: textStyle,
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}
