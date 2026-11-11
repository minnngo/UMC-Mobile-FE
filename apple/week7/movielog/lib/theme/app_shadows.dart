import 'package:flutter/material.dart';

/// Figma box-shadow / text-shadow를 옮긴 그림자 토큰입니다.
/// 위젯에서는 그림자 값을 직접 쓰지 않고 이 값을 사용합니다.
class AppShadows {
  const AppShadows._();

  /// 카드·칩·채움 버튼 — 0 1 2 #0000000D
  static const List<BoxShadow> card = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0D000000)),
  ];

  /// 떠 있는 버튼 (홈 배너 상세보기) — 0 2 4 -2 #0000001A, 0 4 6 -1 #0000001A
  static const List<BoxShadow> raisedButton = [
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: -2,
      color: Color(0x1A000000),
    ),
    BoxShadow(
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
      color: Color(0x1A000000),
    ),
  ];

  /// 하단 네비게이션 위쪽 그림자 — 0 -4 20 -10 #0000001A
  static const List<BoxShadow> navigationBar = [
    BoxShadow(
      offset: Offset(0, -4),
      blurRadius: 20,
      spreadRadius: -10,
      color: Color(0x1A000000),
    ),
  ];

  /// 이미지 위 글자 — 0 4 3 #00000012, 0 2 2 #0000000F
  static const List<Shadow> textOnImage = [
    Shadow(offset: Offset(0, 4), blurRadius: 3, color: Color(0x12000000)),
    Shadow(offset: Offset(0, 2), blurRadius: 2, color: Color(0x0F000000)),
  ];
}
