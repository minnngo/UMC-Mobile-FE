import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Figma Design System을 Flutter Theme로 옮긴 결과입니다.
/// MaterialApp의 theme에 AppTheme.light를 연결해서 사용합니다.
class AppTheme {
  const AppTheme._();

  /// 8px을 기본 간격 단위로 사용합니다.
  static const double spacingUnit = 8;

  /// 입력창, 가입하기 버튼의 모서리 반경입니다. (Figma: 8px)
  static const double radius = 8;

  /// 체크박스의 모서리 반경입니다. (Figma: 4px)
  static const double checkboxRadius = 4;

  /// 체크박스 한 변의 길이입니다. (Figma: 26px)
  static const double checkboxSize = 26;

  /// 가입하기 버튼의 높이입니다. (Figma: 56px)
  static const double buttonHeight = 56;

  /// 헤더 높이입니다. (Figma: 64px)
  static const double appBarHeight = 64;

  /// 입력창의 높이입니다. (W6-01 Figma: 44px)
  static const double inputHeight = 44;

  /// 마이페이지 통계 카드의 모서리 반경입니다. (1주차 Figma: 12px)
  static const double statRadius = 12;

  /// 마이페이지 통계 숫자 — Manrope 700 / 22 / 28 / 0, #4F378A (1주차)
  static const TextStyle statValue = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.accent,
  );

  /// 하단 네비게이션 선택 라벨 — Manrope 500 / 11, 높이 10.8 (Figma 박스 높이에서 역산)
  static const TextStyle navLabelSelected = TextStyle(
    fontSize: 11,
    height: 10.8 / 11,
    letterSpacing: 0,
    fontWeight: FontWeight.w500,
  );

  /// 평점 Dialog 제목 — Manrope 700 / 20 / 100%, #25232A
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.dialogTitle,
  );

  /// 평점 Dialog 확인 버튼 — Manrope 700 / 16 / 100%
  static const TextStyle dialogAction = TextStyle(
    fontSize: 16,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  /// 평점 Dialog 다시 선택하기 — Manrope 700 / 14 / 100%
  static const TextStyle dialogTextAction = TextStyle(
    fontSize: 14,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  /// 회원가입·내가 등록한 평점 헤더 제목 — Manrope 700 / 20 / 100%, #6750A4 (W6-01, W6-02)
  static const TextStyle appBarTitleBold = TextStyle(
    fontSize: 20,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /// 회원가입 환영합니다! — Manrope 700 / 16 / 100%, #25232A (W6-01)
  static const TextStyle signupWelcomeTitle = TextStyle(
    fontSize: 16,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.dialogTitle,
  );

  /// 회원가입 안내 문구 — Manrope 400 / 14 / 100%, #25232A (W6-01)
  static const TextStyle signupWelcomeBody = TextStyle(
    fontSize: 14,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: AppColors.dialogTitle,
  );

  /// 회원가입 필수 약관 문구 — Manrope 700 / 14 / 100%, #25232A (W6-01)
  static const TextStyle signupTerms = TextStyle(
    fontSize: 14,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.dialogTitle,
  );

  /// 마이페이지 내가 등록한 평점 — Manrope 700 / 16 / 100%, #25232A (W6-ENTRY)
  static const TextStyle entryCardTitle = TextStyle(
    fontSize: 16,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.dialogTitle,
  );

  /// 평점 카드 영화 제목 — Manrope 700 / 17, 줄 영역 23 (W6-02)
  static const TextStyle ratingCardTitle = TextStyle(
    fontSize: 17,
    height: 23 / 17,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.dialogTitle,
  );

  /// 평점 카드 별점 4 / 5 — Manrope 700 / 14, 줄 영역 19, #6750A4 (W6-02)
  static const TextStyle ratingCardScore = TextStyle(
    fontSize: 14,
    height: 19 / 14,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /// 평점 카드 후기·등록일 — Manrope 400 / 13, 줄 영역 18, #655F6C (W6-02)
  static const TextStyle ratingCardBody = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    leadingDistribution: TextLeadingDistribution.even,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: AppColors.retryDialogBody,
  );

  /// 공용 버튼(MovieLogButton) 글자 — Manrope 700 / 13 / 100% (W6-01)
  static const TextStyle movieLogButton = TextStyle(
    fontSize: 13,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  /// 중복 확인 상태 안내 문구 — Manrope 700 / 12 / 100% (W6-01)
  /// 색은 상태에 따라 위젯에서 입힙니다.
  static const TextStyle checkStatus = TextStyle(
    fontSize: 12,
    height: 1,
    letterSpacing: 0,
    fontWeight: FontWeight.w700,
  );

  /// 영화 상세 시놉시스 본문 — Manrope 500 / 16 / 26 / 0.5, #494551
  static const TextStyle synopsisBody = TextStyle(
    fontSize: 16,
    height: 26 / 16,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
  );

  static final ColorScheme _lightColorScheme = const ColorScheme.light()
      .copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        surfaceContainer: AppColors.surfaceContainer,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        errorContainer: AppColors.errorContainer,
        // 마이페이지 장르 칩·통계 카드 테두리
        primaryContainer: AppColors.primaryContainer,
        // 강조색 (헤더, 배너 칩·버튼)
        onPrimaryContainer: AppColors.accent,
        // 별점 별
        tertiary: AppColors.ratingStar,
        // 영화 목록 별점 칩
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.onInverseSurface,
        // 영화 상세 히어로·장르 칩 배경
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        // 하단 네비게이션
        surfaceContainerLowest: AppColors.navBackground,
        surfaceContainerHighest: AppColors.containerHighest,
        secondaryContainer: AppColors.navIndicator,
        onSecondaryContainer: AppColors.navSelected,
      );

  /// Figma Typography를 그대로 옮긴 TextTheme입니다.
  /// height는 line-height / font-size로 계산합니다.
  static const TextTheme _textTheme = TextTheme(
    // 홈 인사말·배너 제목, 영화 상세 제목 — Manrope 500 / 28 / 36 / 0
    headlineMedium: TextStyle(
      fontSize: 28,
      height: 36 / 28,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 회원가입 (헤더 제목) — Manrope 500 / 22 / 28 / 0
    titleLarge: TextStyle(
      fontSize: 22,
      height: 28 / 22,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 라벨, 약관 문구, 버튼, 환영 문구 — Manrope 500 / 16 / 24 / 0
    titleMedium: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 영화 상세 장르 칩·하단 버튼 — Manrope 500 / 14 / 20 / 0.1
    titleSmall: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.1,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurface,
    ),
    // 입력 텍스트 — Manrope 400 / 16 / 24 / 0
    bodyLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0,
      fontWeight: FontWeight.w400,
      color: AppColors.inputText,
    ),
    // 영화 상세 연도·장르·러닝타임, 별점 참여 수 — Manrope 400 / 14 / 20 / 0.25
    bodyMedium: TextStyle(
      fontSize: 14,
      height: 20 / 14,
      letterSpacing: 0.25,
      fontWeight: FontWeight.w400,
      color: AppColors.onSurface,
    ),
    // 오류 안내 문구 — Manrope 500 / 12 / 16
    bodySmall: TextStyle(
      fontSize: 12,
      height: 16 / 12,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
    ),
    // 시작 화면 FLUTTER 1주차 — Manrope 500 / 11 / 16 / 0.55 (1주차)
    labelSmall: TextStyle(
      fontSize: 11,
      height: 16 / 11,
      letterSpacing: 0.55,
      fontWeight: FontWeight.w500,
      color: AppColors.onSurfaceVariant,
    ),
    // 가입하기 — Manrope 500 / 16 / 24 / 0
    labelLarge: TextStyle(
      fontSize: 16,
      height: 24 / 16,
      letterSpacing: 0,
      fontWeight: FontWeight.w500,
    ),
  );

  static ThemeData get light {
    final colors = _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: appBarHeight,
        titleTextStyle: _textTheme.titleLarge?.copyWith(color: colors.primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: AppColors.primaryDisabled,
          disabledForegroundColor: colors.onPrimary,
          // box-shadow: 0px 1px 2px 0px #0000000D
          elevation: 1,
          shadowColor: const Color(0x0D000000),
          minimumSize: const Size(0, buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: _textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(colors.onPrimary),
        side: BorderSide(color: colors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(checkboxRadius),
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // 오류 상태(WidgetState.error)에서는 배경을 #FFDAD6으로 바꿉니다.
        // 기본 배경 #FEFCF9 (W6-01)
        fillColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.error)
              ? colors.errorContainer
              : AppColors.inputBackground,
        ),
        isDense: true,
        // W6-01 높이 44 — 글자 줄 높이 24 + 상하 10
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        // 플레이스홀더 — Manrope 500 / 16 #7A7582
        hintStyle: _textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: AppColors.placeholder,
        ),
        // 경고 문구 — Manrope 500 / 12 / 16 #B3261E, 입력창과 4px 간격(M3 기본값)
        errorStyle: _textTheme.bodySmall?.copyWith(color: colors.error),
        // 테두리 1px #D9D3E1 (W6-01)
        border: _inputBorder(AppColors.inputBorder),
        enabledBorder: _inputBorder(AppColors.inputBorder),
        focusedBorder: _inputBorder(colors.primary),
        errorBorder: _inputBorder(colors.error),
        focusedErrorBorder: _inputBorder(colors.error),
        // 상태 아이콘 20x20 + 오른쪽 여백 12 (W6-01)
        suffixIconConstraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 20,
        ),
      ),
    );
  }

  /// border: 1px solid, radius 8px
  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: BorderSide(color: color),
  );
}
