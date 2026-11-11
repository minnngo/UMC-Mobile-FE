import 'package:flutter/material.dart';

import 'svg_icon_button.dart';

/// 화면 상단 공통 헤더 — 높이 64, padding 0 / 16, 배경 #FAF9F5
///
/// - 기본: 왼쪽 제목, 오른쪽 [trailing] (space-between)
/// - [centerTitle]: 좌우 아이콘 영역([sideWidth])을 두고 제목을 가운데 정렬
///
/// 사용처: 홈(MovieLog), 영화(영화), 영화 상세(Cinema Archive), 마이(내 프로필)
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.titleStyle,
    this.centerTitle = false,
    this.leading,
    this.trailing,
  });

  /// 홈·영화 탭 헤더 — 굵은 제목(#4F378A) + 검색 버튼
  const AppHeader.tab({super.key, required this.title})
    : titleStyle = null,
      centerTitle = false,
      leading = null,
      trailing = const HeaderSearchButton();

  static const double height = 64;

  /// 가운데 정렬일 때 좌우 아이콘 영역 너비 (Figma 상세: 32.02 + 293.96 + 32.02 = 358)
  static const double sideWidth = 32.02;

  final String title;

  /// null이면 탭 헤더 스타일 — Manrope 700 / 22 / 28 / -0.55, #4F378A
  final TextStyle? titleStyle;
  final bool centerTitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final style =
        titleStyle ??
        textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.55,
          color: colors.onPrimaryContainer,
        );

    return ColoredBox(
      color: colors.surface,
      // 상태 표시줄 영역까지 배경을 칠하고 내용은 그 아래에 배치
      child: SafeArea(
        bottom: false,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (centerTitle)
                SizedBox(
                  width: sideWidth,
                  child: Align(alignment: Alignment.centerLeft, child: leading),
                )
              else
                ?leading,
              Expanded(
                child: Text(
                  title,
                  textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                  style: style,
                ),
              ),
              if (centerTitle)
                SizedBox(
                  width: sideWidth,
                  // 아이콘 버튼이 영역보다 조금 넓어도(34 > 32.02) 가운데에 그대로 그림
                  child: OverflowBox(
                    maxWidth: double.infinity,
                    child: trailing,
                  ),
                )
              else
                ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// 탭 헤더 검색 버튼 — 34 x 34, padding 8, 아이콘 18 x 18 #4F378A
class HeaderSearchButton extends StatelessWidget {
  const HeaderSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgIconButton(
      asset: 'assets/icons/header_search.svg',
      iconSize: const Size(18, 18),
      color: Theme.of(context).colorScheme.onPrimaryContainer,
      tooltip: '검색',
      onPressed: () {}, // 검색 화면은 아직 연결하지 않습니다.
    );
  }
}
