import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 시작 화면 — 1주차 W1-00을 가져왔습니다. Figma 프레임 390 x 884 기준
/// 시작하기 → 회원가입 (go로 이동해 회원가입에서 뒤로 돌아오지 않음)
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        // Main - Welcome Canvas: padding 32 / 16
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section:margin — padding-top 32
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Column(
                  children: [
                    // Margin — padding-bottom 24, Manrope 500 / 11 / 16 / 0.55
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Text('FLUTTER 1주차', style: textTheme.labelSmall),
                    ),
                    // Illustration:margin — 128 x 128, padding-bottom 32
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: SvgPicture.asset(
                        'assets/logos/movielog_logo.svg',
                        width: 128,
                        height: 128,
                        semanticsLabel: 'MovieLog 로고',
                      ),
                    ),
                    // 타이포 — padding 좌우 8, gap 8
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          // Manrope 500 / 28 / 36, #1B1C1A
                          Text(
                            '영화의 순간을\n기록하세요',
                            textAlign: TextAlign.center,
                            style: textTheme.headlineMedium?.copyWith(
                              color: AppColors.detailText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Manrope 500 / 14 / 20 / 0.25, #494551
                          Text(
                            '보고 싶은 영화부터 나만의 평점까지\n한곳에서 관리해요',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 하단 액션 버튼 — padding 좌우 16, 아래 24
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    // go: 시작 화면을 스택에서 빼서 회원가입에서 뒤로 돌아오지 않음
                    onPressed: () => context.go('/register'),
                    // 1주차 시작하기 버튼 — 배경 #4F378A, radius 16, Manrope 500 / 14 / 20 / 0.1
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.onPrimaryContainer,
                      foregroundColor: colors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      textStyle: textTheme.titleSmall,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('시작하기'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
