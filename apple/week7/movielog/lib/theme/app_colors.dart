import 'package:flutter/material.dart';

/// Figma Design System에 정의된 원본 색상값입니다.
/// 위젯에서는 이 값을 직접 쓰지 않고 Theme.of(context).colorScheme을 통해 사용합니다.
class AppColors {
  const AppColors._();

  /// Primary — AppBar 제목, 체크박스, 활성 가입하기 버튼, 로그인 링크
  static const Color primary = Color(0xFF6750A4);

  /// Primary 위에 올라가는 색
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// 비활성 가입하기 버튼 배경 (#CCC2DC)
  static const Color primaryDisabled = Color(0xFFCCC2DC);

  /// Surface — 화면 배경, 헤더 배경
  static const Color surface = Color(0xFFFAF9F5);

  /// 제목 텍스트 (닉네임, 이메일, 비밀번호 라벨, 약관 문구)
  static const Color onSurface = Color(0xFF1D1B20);

  /// 보조 텍스트 (환영 문구, 이미 계정이 있나요?)
  static const Color onSurfaceVariant = Color(0xFF494551);

  /// 입력창 배경
  static const Color surfaceContainer = Color(0xFFF5F3F0);

  /// 입력창 플레이스홀더
  static const Color placeholder = Color(0xFF7A7582);

  /// 입력창 테두리
  static const Color outlineVariant = Color(0xFFCBC4D2);

  /// 사용자가 입력한 텍스트 (플레이스홀더보다 진한 색)
  static const Color inputText = Color(0xFF211F26);

  /// 오류 상태 — 테두리, 느낌표 아이콘, 경고 문구
  static const Color error = Color(0xFFB3261E);

  /// 오류 상태 입력창 배경
  static const Color errorContainer = Color(0xFFFFDAD6);

  /// 강조색 — 홈 헤더 로고·검색 아이콘, 배너 칩·상세보기 버튼
  static const Color accent = Color(0xFF4F378A);

  /// 하단 네비게이션 배경
  static const Color navBackground = Color(0xFFFFFFFF);

  /// 하단 네비게이션 테두리, 배너 이미지 로딩 전 배경
  static const Color containerHighest = Color(0xFFE6E0E9);

  /// 하단 네비게이션 선택 탭 배경 (pill)
  static const Color navIndicator = Color(0xFFE8DEF9);

  /// 하단 네비게이션 선택 탭 아이콘·글자
  static const Color navSelected = Color(0xFF686177);

  /// 별점 별 아이콘
  static const Color ratingStar = Color(0xFFC9A74D);

  /// 영화 목록 포스터 위 별점 칩 배경 (투명도 CC는 위젯에서 적용)
  static const Color inverseSurface = Color(0xFF322F35);

  /// 영화 목록 포스터 위 별점 칩 글자
  static const Color onInverseSurface = Color(0xFFF5EFF7);

  /// 평점 Dialog 제목, 회원가입 환영 문구·약관 문구 (#25232A)
  static const Color dialogTitle = Color(0xFF25232A);

  /// 평점 Dialog 선택되지 않은 별
  static const Color ratingUnrated = Color(0xFFD9D3DF);

  /// 마이페이지 장르 칩 배경, 통계 카드 테두리 (1주차)
  static const Color primaryContainer = Color(0xFFE9DDFF);

  /// 마이페이지 프로필 이미지 테두리 (1주차)
  static const Color avatarBorder = Color(0xFFD0BCFF);

  /// 영화 상세 히어로 배경, 장르 칩 배경
  static const Color surfaceContainerHigh = Color(0xFFE3E2DF);

  /// 영화 상세 제목·시놉시스 제목·평점 숫자, 시작 화면 제목 (#1B1C1A)
  /// 다른 화면의 onSurface(#1D1B20)와 미세하게 달라 상세 화면에서만 직접 사용합니다.
  static const Color detailText = Color(0xFF1B1C1A);

  // ---------------------------------------------------------------------------
  // 이미지 위에 올라가는 색 — 배경이 항상 어두운 포스터라 테마와 관계없이 고정입니다.
  // ---------------------------------------------------------------------------

  /// 포스터 위 어둡게 덮는 오버레이 (#000000B2)
  static const Color imageOverlay = Color(0xB2000000);

  /// 포스터 위 제목, 칩·버튼 글자
  static const Color onImage = Color(0xFFFFFFFF);

  /// 포스터 위 보조 텍스트 (장르·러닝타임)
  static const Color onImageVariant = Color(0xFFF8F2FA);

  /// 포스터 위 칩 테두리 (#FFFFFF33)
  static const Color onImageOutline = Color(0x33FFFFFF);

  /// 포스터 위 순위 칩 배경 (#00000099)
  static const Color rankChip = Color(0x99000000);

  /// 포스터 위 순위 칩 테두리 (#FFFFFF1A)
  static const Color rankChipOutline = Color(0x1AFFFFFF);

  /// 재시도 Dialog 아이콘 원 배경 (W5-01)
  static const Color retryIconBackground = Color(0xFFF0EBF8);

  /// 재시도 Dialog 안내 문구 (W5-01), 평점 카드 후기 (W6-02)
  static const Color retryDialogBody = Color(0xFF655F6C);

  /// 재시도 Dialog 취소 버튼 배경 (W5-01)
  static const Color retryCancelButton = Color(0xFFF4F0FA);

  /// 평점 카드 배경 (W6-02)
  static const Color ratingCardBackground = Color(0xFFFFFFFF);

  /// 평점 카드 테두리 (W6-02)
  static const Color ratingCardBorder = Color(0xFFD9D3E1);

  /// 마이페이지 내가 등록한 평점 카드 배경 (W6-ENTRY)
  static const Color entryCardBackground = Color(0xFFFFFFFF);

  /// 마이페이지 내가 등록한 평점 카드 테두리 (W6-ENTRY)
  static const Color entryCardBorder = Color(0xFFD6C9E8);

  /// 회원가입 입력창 배경 (W6-01)
  static const Color inputBackground = Color(0xFFFEFCF9);

  /// 회원가입 입력창 테두리 (W6-01)
  static const Color inputBorder = Color(0xFFD9D3E1);

  /// 공용 버튼 통신 중 배경 (W6-01)
  static const Color buttonLoading = Color(0xFF79747E);

  /// 중복 확인 통과 안내 — 사용 가능한 닉네임입니다. (W6-01)
  static const Color checkAvailable = Color(0xFF2E7D32);

  /// 중복 확인 진행 안내 — 사용 가능 여부를 확인 중입니다. (W6-01)
  static const Color checkInProgress = Color(0xFF1565C0);
}
